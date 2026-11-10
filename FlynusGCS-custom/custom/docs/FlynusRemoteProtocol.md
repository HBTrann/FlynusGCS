# Flynus GCS ↔ Flynus Remote – MAVLink interface (draft v0.1)

Interface the Flynus GCS "Remote" page uses to pair the air unit and set the remote's
channel output order. All messages are standard MAVLink common messages; nothing custom
has to be added to the dialect.

## 1. Addressing

| Item | Value (draft) |
|---|---|
| Remote system id | `REMOTE_SYSID`, default **254** (configurable in the GCS) |
| Remote component id | **MAV_COMP_ID_PAIRING_MANAGER (174)** for pairing commands, the same id for parameters |
| GCS system/component | QGC default (255 / 190) |
| Link | Any link the GCS has open (USB/serial to the STM32, or UDP via CM4) |

The remote sends `HEARTBEAT` at 1 Hz from (254, 174) with `type = MAV_TYPE_GCS` (6) and
`autopilot = MAV_AUTOPILOT_INVALID` (8), so QGC does **not** treat it as a vehicle. The GCS
uses the heartbeat to show "Remote connected", the model and the firmware version.

Optional: `SYS_STATUS` or `BATTERY_STATUS` from (254, 174) for the remote's own battery.

## 2. Pairing the air unit

GCS → remote: `COMMAND_LONG`
- `command = MAV_CMD_START_RX_PAIR (500)`
- `param1` = RC type: 0 = generic / own link (for now)
- `param2` = sub-type, 0
- `param3..7` = 0

Remote → GCS: `COMMAND_ACK` for command 500
- `MAV_RESULT_IN_PROGRESS (5)` while searching, `progress` = 0..100 (or 255 if unknown), resent every ~1 s
- `MAV_RESULT_ACCEPTED (0)` when paired
- `MAV_RESULT_FAILED (4)` on timeout/error; `result_param2` may carry an error code
- `MAV_RESULT_CANCELLED (6)` if cancelled

Cancel: GCS sends `COMMAND_CANCEL` (`command = 500`) to (254, 174).

After pairing, the remote reports the paired air unit through the parameters `AIR_ID`
(read-only, numeric id) and, when the link is up, `AIR_RSSI` (dBm, read-only).

## 3. Channel output order (parameters on the remote)

The GCS uses the normal parameter protocol addressed to (254, 174):
`PARAM_REQUEST_LIST` / `PARAM_REQUEST_READ` / `PARAM_SET`, and the remote answers with `PARAM_VALUE`.

| Name | Type | Meaning |
|---|---|---|
| `CH1_SRC` … `CH16_SRC` | INT8 | Source assigned to output channel N (table below) |
| `STICK_MODE` | INT8 | 1 = Mode 1, 2 = Mode 2 (swaps physical sticks) |
| `CH_SAVE` | INT8 | Write 1 = store to flash (with CRC/rollback, see Requirement.txt) |
| `CH_DEFAULT` | INT8 | Write 1 = restore factory channel order |
| `FW_VERSION` | INT32 | Read-only, e.g. 10003 = v1.0.3 |

Source ids (draft):

| Id | Source |
|---|---|
| 0 | Not used |
| 1 | Roll (aileron) |
| 2 | Pitch (elevator) |
| 3 | Throttle |
| 4 | Yaw (rudder) |
| 5 | Flight mode switch |
| 6 | RTH button |
| 7 | Left knob |
| 8 | Right knob |
| 9..15 | Reserved for extra buttons/switches |

Presets in the GCS write these values:
- **AETR**: CH1=1, CH2=2, CH3=3, CH4=4
- **TAER**: CH1=3, CH2=1, CH3=2, CH4=4

## 4. Live values

The remote sends `RC_CHANNELS` (msg 65) at 10 Hz from (254, 174) with its **output**
channels (µs). The GCS shows them as live bars next to each channel.

## 5. Notes for firmware

- Only accept `PARAM_SET` / `MAV_CMD_START_RX_PAIR` while the vehicle is **disarmed**
  (the remote knows this from the vehicle's HEARTBEAT), and reply `MAV_RESULT_DENIED` otherwise.
- Apply a new channel order only after `CH_SAVE`, or apply it immediately but keep the
  last saved order as a fallback after reboot.
