Hardware Validation Templates
=============================

A FoundationBluePrint can carry a `validation_template`.  When a physical machine
bootstraps, it reports its hardware (the `id_map`: DMI information, PCI devices,
total RAM/CPU, network interfaces and disks).  Contractor checks that `id_map` against the
validation template of the Foundation's BluePrint, and reports *every* mismatch
found, so you can fix everything wrong in one pass instead of one problem per reboot.
If the BluePrint does not have a template, the BluePrints in its `parent_list`
are searched, the first one found is used.  A BluePrint with no template anywhere
in its parents accepts any hardware.

The template is a JSON dictionary shaped like the `id_map` it is checked against.
The template is checked when the BluePrint is saved, a malformed template is rejected.

Matching rules
--------------

Dict node
  A plain dictionary.  Each key must be present in the `id_map` and its value is
  checked against the sub template.  Matching is exact by default, any key in the
  `id_map` not named in the template is an error.  The key `*` is a wildcard,
  its sub template is applied to every key not otherwise named.  Naming every
  expected key (ie: every disk bay) also implies an exact count.

List node
  `[ sub_template ]`, or `{ "$each": sub_template, "$count": ... }`.  Every
  element of the list is checked against the sub template.  Order is not significant.

Leaf node
  A dictionary of the reserved `$` keys below which constrain a value directly.

Leaf keys
---------

 * `$match` - a regular expression, the whole value must match.  Avoid nested quantifiers, the value comes from the machine being bootstrapped and is not trusted.
 * `$min` / `$max` - inclusive bounds.  Compared as a number, then as a dotted version (`1.12.3`), then as a string.  Use both for a range.
 * `$eq` - exactly this value, same comparison as `$min`/`$max`
 * `$in` - one of a list of values
 * `$type` - one of `str`, `int`, `float`, `number`, `bool`, `list`, `dict`, `null`
 * `$count` - the number of items (list elements or dict keys), either an exact number or `{ "$min": n, "$max": m }`
 * `$any` - `true`, accept any value

Any node
--------

 * `$optional` - `true`, do not fail if the item is missing
 * `$exists` - `false`, fail if the item is present
 * `$loose` - `true`, this node and every dict under it accept keys that are not named, without needing a `*`.  Set `"$loose": false` on a branch to make it exact again.
 * `$contains` - at least one element/value must match the sub template.  Useful for things like `pci`, which is keyed by bus address.  May also be a list of `{ "$template": ..., "$count": ... }` clauses to require several things at once (ie: exactly 2 network cards and 4 GPUs)
 * `$contains_count` - how many matches a single `$contains` requires (default at least 1)
 * `$or` - a list of sub templates, at least one must match.  Useful when a field is spelled differently by different vendors.

Example
-------

Require a specific server model with 2 sockets, at least 128GiB of RAM, and
don't care about anything else::

  {
    "$loose": true,
    "hardware": {
      "dmi": {
        "System Info": [ { "Manufacturer": { "$eq": "Dell Inc." }, "Product Name": { "$match": "PowerEdge R6[34]0" } } ]
      },
      "total_cpu_sockets": { "$eq": 2 },
      "total_ram": { "$min": 137438953472 }
    },
    "disks": { "SAS 0:0": { "isSSD": { "$eq": true } } }
  }

NOTE: `disks` is keyed by the drive's physical location (ie: `SAS 0:0`, `NVME 1:0`),
so specific bays can be pinned.
