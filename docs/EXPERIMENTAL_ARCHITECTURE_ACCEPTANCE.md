# Experimental architecture acceptance

The experimental MeowOS architecture is accepted only when both commands pass:

```sh
./scripts/audit-experimental-architecture.sh
./scripts/audit-experimental-architecture.sh --live
```

The static audit covers the bounded priority scheduler, absence of legacy
QtConcurrent I/O, one-foreground-app policy, portable HAL boundaries, semantic
RGB design tokens, Git hygiene, CI and the strict quality gate. The live audit
also builds the standalone contracts and full Qt shell on the target, checks
the service, and measures idle CPU, RSS, thread count and context switches.

Initial A5E baseline for MeowOS 0.3.77:

- idle CPU over 30 seconds: 0.30%;
- RSS: 90,640 KiB;
- threads: 8;
- context switches over 30 seconds: 55;
- normal service restart failures: 0.

