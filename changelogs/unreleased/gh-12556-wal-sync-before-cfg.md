## bugfix

* Fixed crash (SIGSEGV) when calling `box.ctl.wal_sync()` before
  `box.cfg{}`. Now returns an error instead
  (gh-12556).
