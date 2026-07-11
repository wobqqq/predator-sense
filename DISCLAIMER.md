# Disclaimer

**THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.**

`predator-sense` builds and loads an out-of-tree **Linux kernel module** and
changes low-level system configuration, including:

- CPU/GPU **power/thermal profiles**,
- **fan** behaviour (including manual speeds),
- **battery** charge limiting and calibration,
- **keyboard backlight** and input-key remapping (udev/hwdb),
- blacklisting the stock `acer_wmi` driver and autoloading a replacement.

By downloading, building, installing, or running any part of this project you
acknowledge and agree that:

1. You do so **entirely at your own risk**.
2. The authors and contributors are **NOT responsible or liable** for any
   direct, indirect, incidental, or consequential damage of any kind —
   including but not limited to **overheating, thermal throttling, hardware
   damage or failure, reduced battery lifespan, data loss, system instability,
   or a voided manufacturer warranty**.
3. This project is **not affiliated with, endorsed by, or associated with Acer**
   or the "PredatorSense" product. "Acer", "Predator" and "PredatorSense" are
   trademarks of their respective owners and are used here only to describe
   hardware compatibility.
4. Manual **fan** and **profile** settings can cause the machine to run hotter
   than the firmware defaults. Keeping the hardware within safe temperatures is
   **your responsibility**.
5. It is tested only on the **Acer Predator PT316-51s (Triton 300 SE)**. Behaviour
   on any other model or firmware is undefined.

If you do not accept these terms, **do not use this software**.

See also [LICENSE](LICENSE) (GPL-3.0).
