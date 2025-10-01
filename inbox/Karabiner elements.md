```
{
    "description": "scroll left by right_control - a",
    "manipulators": [
        {
            "conditions": [
                {
                    "identifiers": [
                        {
                            "product_id": 641,
                            "vendor_id": 1452
                        }
                    ],
                    "type": "device_if"
                }
            ],
            "from": {
                "key_code": "a",
                "modifiers": {
                    "mandatory": [
                        "right_control"
                    ]
                }
            },
            "to": [
                {
                    "mouse_key": {
                        "horizontal_wheel": 80
                    }
                }
            ],
            "type": "basic"
        },
        {
            "conditions": [
                {
                    "identifiers": [
                        {
                            "product_id": 33,
                            "vendor_id": 1278
                        }
                    ],
                    "type": "device_if"
                }
            ],
            "from": {
                "key_code": "volume_decrement",
                "modifiers": {
                    "mandatory": [
                        "right_control"
                    ]
                }
            },
            "to": [
                {
                    "mouse_key": {
                        "horizontal_wheel": 80
                    }
                }
            ],
            "type": "basic"
        }
    ]
}
```