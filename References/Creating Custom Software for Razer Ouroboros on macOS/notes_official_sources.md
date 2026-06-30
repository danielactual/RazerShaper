# Razer Ouroboros official-source notes

## Official support page
Source: https://mysupport.razer.com/app/answers/detail/a_id/3771/~/razer-ouroboros-%7C-rz01-00770-support-%26-faqs
Updated on page: 08-Mar-2026

Key findings:
- Product name: **Razer Ouroboros | RZ01-00770**.
- Official configuration software reference: **Razer Synapse 2**.
- The support page links to an English user guide PDF and multiple translations.
- The page still hosts general FAQs, but the device is clearly a legacy product.

## English user guide PDF
Source: https://dl.razerzone.com/master-guides/Ouroboros/OuroborosOMG-ENG.pdf
Local file: /home/ubuntu/ouroboros/OuroborosOMG-ENG.pdf
Observed from pages 1-5.

Key findings from the guide:
- Marketed as an **ambidextrous wireless gaming mouse**.
- Sensor: **8200 dpi 4G laser sensor**.
- Supports **customizable ergonomics** with adjustable palm rest and back section.
- Mentions **two interchangeable side panels**.
- Supports **cut-off / lift-off tracking distance**, **surface calibration**, and a **clutch trigger** for temporary DPI changes.
- Technical specs page lists:
  - **11 programmable Hyperesponse buttons**
  - **1000 Hz ultrapolling**
  - Up to **200 inches per second / 50 g acceleration**
  - Approximate size: **122 mm - 134 mm (L) x 71 mm (W) x 42 mm (H)**
  - Approximate weight: **147 g / 0.32 lbs**
  - Battery life: about **12 hours** continuous gaming
- System requirements page explicitly lists **Mac OS X 10.6-10.8** support at launch, along with a free USB 2.0 port and internet connection.
- Device layout page labels the physical controls as follows:
  - A: Left Mouse Button
  - B: Right Mouse Button
  - C: Scroll Wheel
  - D: Sensitivity Stage Up
  - E: Sensitivity Stage Down
  - F: Adjustable Palm Rest and Rear Panel
  - G: Mouse Button 7
  - H: Mouse Button 6
  - I: Left Trigger
  - J: Mouse Button 9
  - K: Mouse Button 10
  - L: Right Trigger

Implications for custom macOS software:
- The guide confirms the mouse exposes more than the standard 5-button layout and that per-button remapping was expected through vendor software.
- The exact **logical button numbering** used by the hardware/driver still needs reverse-engineering from USB/HID descriptors, open-source drivers, or packet captures.
- Old Mac support existed historically, so there may be older Mac driver packages, preference panes, or USB identifiers available online.

Next research targets:
- USB vendor/product IDs and HID report descriptors
- Old Razer Synapse / legacy Mac driver packages
- Open-source Linux/macOS reverse-engineering projects mentioning Ouroboros
- Community posts documenting button events or receiver behavior
- Whether the wired/wireless dongle expose different USB interfaces

## Additional findings from user guide pages 5-9
Source: https://dl.razerzone.com/master-guides/Ouroboros/OuroborosOMG-ENG.pdf

The continuation of the device-layout section identifies several underside and accessory components that may matter for reverse-engineering. The underside includes **left trigger switch**, **right trigger switch**, the **8200 dpi 4G laser sensor**, a **recliner wheel**, and the **rechargeable NiMH AA battery**. The accessory diagrams show a **USB connector cable**, a **charging dock**, a **pairing button** on the dock, and interchangeable side panels described as a **finger rest panel** and **finger grip panel**. This suggests the wireless path likely involves a dock/receiver relationship rather than a simple cable-only device, so USB identifiers may differ between the mouse, dock, and wired mode.

The setup section confirms that the mouse has regional hardware variants. The **US model** uses screws to remove the rear panel, while the **non-US model** uses a **rear panel adjustment button**. For software purposes this probably does not change the USB behavior, but it is a useful distinction when comparing teardown photos, manuals, or forum posts.

These pages strengthen the working hypothesis that any complete macOS replacement utility may need to account for at least three operational contexts: **wired via USB cable**, **wireless through the dock/receiver path**, and **paired-device management through the charging dock**.

