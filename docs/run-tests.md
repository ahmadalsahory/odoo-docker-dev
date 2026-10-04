# Run a module's tests

`test` creates a fresh, throwaway database, installs the module in it, and runs the module's tests. Your own databases are not touched.

Odoo must be running (`up`).

## Run the tests

Replace `my_module` with the module's technical name:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh test my_module` | `.\odoo.ps1 test my_module` |

Several modules at once: `test my_module,my_other_module`.

It takes a minute or more: most of the time goes into creating the database. The log scrolls while it runs.

## Read the result

One of the last lines tells you how it went:

```text
odoo.tests.result: 0 failed, 0 error(s) of 11 tests when loading database 'test_my_module'
```

**`0 failed, 0 error(s)`** means every test passed.

**Anything else** means some tests failed. Scroll up and look for lines with `FAIL:` or `ERROR:`. Each one names the test and is followed by the Python traceback that explains why it failed.

## Good to know

- The test database is named `test_<module>` (here `test_my_module`). It is deleted and created again on every run, so each run starts clean. It also shows up in the database list in your browser; you can ignore it.
- Browser tests (tours) need Chrome, which is not in the Odoo image, so they are skipped with a warning.
- Changed Python code? No need to restart before `test`: it starts a separate Odoo process with your current code.

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
