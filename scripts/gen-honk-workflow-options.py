#!/usr/bin/env python3
"""Regenerate the choice lists of the CI workflow from the tree.

Usage:  python3 scripts/gen-honk-workflow-options.py [tree-dir]

The lists in .github/workflows/build-honk-doona.yml are generated: the
supported targets, subtargets and devices are derived from the tree, so a new
device profile shows up in the Actions dialog automatically.
"""
import os
import re
import sys

TREE = sys.argv[1] if len(sys.argv) > 1 else '.'
WF = os.path.join(TREE, '.github/workflows/build-honk-doona.yml')

# the same rule as package/honk/Makefile: a prebuilt core exists for
# x86_64, aarch64 and ARMv7-A
ARMV7_CPUS = ('cortex-a7', 'cortex-a8', 'cortex-a9', 'cortex-a15', 'cortex-a17',
              'cortex-a53', 'cortex-a55', 'cortex-a57', 'cortex-a72', 'cortex-a73',
              'cortex-a75', 'cortex-a76', 'cortex-a77', 'neoverse')
ARMV7_NO_CPU = {'ipq40xx_generic', 'ipq40xx_chromium', 'ipq40xx_mikrotik',
                'ipq806x_generic', 'ipq806x_chromium', 'bcm53xx_generic',
                'mxs_generic', 'omap_generic', 'zynq_generic'}


def subtargets():
    out = []
    tdir = os.path.join(TREE, 'target/linux')
    for d in sorted(os.listdir(tdir)):
        tm = os.path.join(tdir, d, 'Makefile')
        if not os.path.isfile(tm):
            continue
        txt = open(tm, encoding='utf-8', errors='replace').read()
        m = re.search(r'^SUBTARGETS\s*:?=\s*(.*)$', txt, re.M)
        if not m:
            continue
        t_arch = (re.search(r'^ARCH\s*:?=\s*(\S+)', txt, re.M) or [None, ''])[1]
        for sub in m.group(1).split():
            arch, cpu = '', ''
            stk = os.path.join(tdir, d, sub, 'target.mk')
            if os.path.isfile(stk):
                c2 = open(stk, encoding='utf-8', errors='replace').read()
                mm = re.search(r'^ARCH\s*:?=\s*(\S+)', c2, re.M)
                arch = mm.group(1) if mm else ''
                mm = re.search(r'^CPU_TYPE\s*:?=\s*(\S+)', c2, re.M)
                cpu = mm.group(1) if mm else ''
            arch = arch or t_arch
            ok = False
            if arch in ('x86_64', 'aarch64'):
                ok = True
            elif arch == 'arm':
                if cpu and any(c in cpu for c in ARMV7_CPUS):
                    ok = True
                elif not cpu and (d + '_' + sub) in ARMV7_NO_CPU:
                    ok = True
            if ok:
                out.append((d, sub, arch))
    return out


def devices(target, subtarget, kconfig):
    return re.findall(r'config TARGET_%s_%s_DEVICE_([A-Za-z0-9_.-]+)' % (target, subtarget), kconfig)


def block(name, items):
    body = ''.join("          - %s\n" % i for i in items)
    return ("          # BEGIN generated: %s\n" % name) + body + \
           ("          # END generated: %s\n" % name)


def main():
    kpath = os.path.join(TREE, 'tmp/.config-target.in')
    if not os.path.exists(kpath):
        print('ERROR: %s does not exist - run "make defconfig" first' % kpath)
        return 1
    kconfig = open(kpath, encoding='utf-8', errors='replace').read()

    subs = subtargets()
    targets = sorted(set(t for t, s, a in subs))
    subtargets_list = ['%s/%s' % (t, s) for t, s, a in subs]

    devs = []
    for t, s, a in subs:
        devs += devices(t, s, kconfig)
    devs = sorted(set(devs))

    print('targets    : %d' % len(targets))
    print('subtargets : %d' % len(subtargets_list))
    print('devices    : %d' % len(devs))

    txt = open(WF, encoding='utf-8').read()
    for name, items in (('target', targets), ('subtarget', subtargets_list), ('device', devs)):
        pat = re.compile(r'( *# BEGIN generated: %s\n).*?( *# END generated: %s\n)' % (name, name), re.S)
        if not pat.search(txt):
            print('ERROR: the marker for %s is missing in %s' % (name, WF))
            return 1
        txt = pat.sub(lambda m: m.group(1) + ''.join("          - %s\n" % i for i in items) +
                      m.group(2), txt)
    open(WF, 'w', encoding='utf-8').write(txt)
    print('written: %s (%d bytes)' % (WF, len(txt)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
