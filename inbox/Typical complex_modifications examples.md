---
title: Typical complex_modifications examples
source: https://karabiner-elements.pqrs.org/docs/json/typical-complex-modifications-examples/#change-right_shift-x2-to-mission_control
author:
  - "[[Karabiner-Elements]]"
published: 
created: 2025-06-21
description: 'Swap ; and : (Equal to swap ; and shift-;)💡 How to use this example { "description": "Swap ; and :", "manipulators": [ { "type": "basic", "from": { "key_code": "semicolon", "modifiers": { "mandatory": ["shift"], "optional": ["caps_lock"] } }, "to": [{ "key_code": "semicolon" }] }, { "type": "basic", "from": { "key_code": "semicolon", "modifiers": { "optional": ["caps_lock"] } }, "to": [{ "key_code": "semicolon", "modifiers": ["left_shift"] }] } ] } Change control-h to delete And change control-option-h to option-delete.'
tags:
  - clippings
status: unread
aliases: 
updated: 250623 09:41:04
---
## Swap; and:

(Equal to swap `;` and `shift-;`)

```
💡 How to use this example
```
```json
{
    "description": "Swap ; and :",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "key_code": "semicolon",
                "modifiers": {
                    "mandatory": ["shift"],
                    "optional": ["caps_lock"]
                }
            },
            "to": [{ "key_code": "semicolon" }]
        },
        {
            "type": "basic",
            "from": {
                "key_code": "semicolon",
                "modifiers": {
                    "optional": ["caps_lock"]
                }
            },
            "to": [{ "key_code": "semicolon", "modifiers": ["left_shift"] }]
        }
    ]
}
```

## Change control-h to delete

And change `control-option-h` to `option-delete`.

```
💡 How to use this example
```
```json
{
    "description": "Change control-h to delete",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "key_code": "h",
                "modifiers": {
                    "mandatory": ["control"],
                    "optional": ["caps_lock", "option"]
                }
            },
            "to": [{ "key_code": "delete_or_backspace" }]
        }
    ]
}
```

## Disable command-l on Finder

```
💡 How to use this example
```
```json
{
    "description": "Disable command-l on Finder",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "key_code": "l",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["caps_lock"]
                }
            },
            "conditions": [
                {
                    "type": "frontmost_application_if",
                    "bundle_identifiers": ["^com\\.apple\\.finder$"]
                }
            ]
        }
    ]
}
```

## Post escape if left\_control is pressed alone

```
💡 How to use this example
```
```json
{
    "description": "Post escape if left_control is tapped",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "key_code": "left_control",
                "modifiers": { "optional": ["any"] }
            },
            "to": [
                {
                    "key_code": "left_control",
                    "lazy": true
                }
            ],
            "to_if_alone": [{ "key_code": "escape" }],
            "to_if_held_down": [{ "key_code": "left_control" }],
            "parameters": {
                "basic.to_if_alone_timeout_milliseconds": 100,
                "basic.to_if_held_down_threshold_milliseconds": 100
            }
        }
    ]
}
```

## Open Safari if escape is held down

```
💡 How to use this example
```
```json
{
    "description": "Open Safari if escape is held down",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "key_code": "escape",
                "modifiers": { "optional": ["caps_lock"] }
            },
            "parameters": {
                "basic.to_if_alone_timeout_milliseconds": 250,
                "basic.to_if_held_down_threshold_milliseconds": 250
            },
            "to_if_alone": [{ "key_code": "escape" }],
            "to_if_held_down": [
                { "shell_command": "open -b 'com.apple.Safari'" }
            ]
        }
    ]
}
```

## Paste (command+v) if escape is held down

```
💡 How to use this example
```
```json
{
    "description": "Paste (command+v) if escape is held down",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "key_code": "escape",
                "modifiers": { "optional": ["any"] }
            },
            "parameters": {
                "basic.to_if_alone_timeout_milliseconds": 250,
                "basic.to_if_held_down_threshold_milliseconds": 250
            },
            "to_if_alone": [{ "key_code": "escape" }],
            "to_if_held_down": [
                {
                    "key_code": "v",
                    "modifiers": ["left_command"],
                    "repeat": false
                }
            ]
        }
    ]
}
```

## Change right\_shift x2 to mission\_control

```
💡 How to use this example
```
```json
{
    "description": "Change right_shift x2 to mission_control",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "key_code": "right_shift",
                "modifiers": { "optional": ["any"] }
            },
            "to": [
                { "apple_vendor_keyboard_key_code": "mission_control" },
                { "key_code": "vk_none" }
            ],
            "conditions": [
                {
                    "type": "variable_if",
                    "name": "right_shift pressed",
                    "value": 1
                }
            ]
        },
        {
            "type": "basic",
            "from": {
                "key_code": "right_shift",
                "modifiers": { "optional": ["any"] }
            },
            "to": [
                {
                    "set_variable": {
                        "name": "right_shift pressed",
                        "value": 1
                    }
                },
                { "key_code": "right_shift" }
            ],
            "to_delayed_action": {
                "to_if_invoked": [
                    {
                        "set_variable": {
                            "name": "right_shift pressed",
                            "value": 0
                        }
                    }
                ],
                "to_if_canceled": [
                    {
                        "set_variable": {
                            "name": "right_shift pressed",
                            "value": 0
                        }
                    }
                ]
            }
        }
    ]
}
```

## Change double press of q to escape

This example is available since Karabiner-Elements 15.3.7.

```
💡 How to use this example
```
```json
{
    "description": "Change double press of q to escape",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "key_code": "q",
                "modifiers": { "optional": ["any"] }
            },
            "to": [
                { "set_variable": { "name": "q pressed", "value": false } },
                { "key_code": "escape" }
            ],
            "conditions": [
                { "type": "variable_if", "name": "q pressed", "value": true }
            ]
        },
        {
            "type": "basic",
            "from": {
                "key_code": "q",
                "modifiers": { "optional": ["any"] }
            },
            "to": [{ "set_variable": { "name": "q pressed", "value": true } }],
            "to_delayed_action": {
                "to_if_invoked": [
                    {
                        "key_code": "q",
                        "conditions": [
                            {
                                "type": "variable_if",
                                "name": "q pressed",
                                "value": true
                            }
                        ]
                    },
                    { "set_variable": { "name": "q pressed", "value": false } }
                ],
                "to_if_canceled": [
                    {
                        "key_code": "q",
                        "conditions": [
                            {
                                "type": "variable_if",
                                "name": "q pressed",
                                "value": true
                            }
                        ]
                    },
                    { "set_variable": { "name": "q pressed", "value": false } }
                ]
            }
        }
    ]
}
```

## Change equal+delete to forward\_delete if these keys are pressed simultaneously

```
💡 How to use this example
```
```json
{
    "description": "Change equal+delete to forward_delete if these keys are pressed simultaneously",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "simultaneous": [
                    { "key_code": "equal_sign" },
                    { "key_code": "delete_or_backspace" }
                ],
                "modifiers": { "optional": ["any"] }
            },
            "to": [{ "key_code": "delete_forward" }]
        }
    ]
}
```