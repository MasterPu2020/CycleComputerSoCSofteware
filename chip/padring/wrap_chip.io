(globals
  version = 3
  io_order = counterclockwise
)
(iopad
  (topleft
    (inst
      name = "CORNER_1"
      cell = "CORNERP"
    )
  )
  (topright
    (inst
      name = "CORNER_2"
      cell = "CORNERP"
    )
  )
  (bottomleft
    (inst
      name = "CORNER_3"
      cell = "CORNERP"
    )
  )
  (bottomright
    (inst
      name = "CORNER_4"
      cell = "CORNERP"
    )
  )
  (top
    (locals
      io_order = counterclockwise
    )
    (inst
      name = "PAD_nFork"
      cell = "ICP"
    )
    (inst
      name = "PADS_VDD_1"
      cell = "VDD3ALLP"
    )
    (inst
      name = "PAD_nCrank"
      cell = "ICP"
    )
    (inst
      name = "PAD_SDI"
      cell = "ICP"
    )
    (inst
      name = "PAD_Test"
      cell = "ICP"
    )
    (inst
      name = "PAD_ScanEnable"
      cell = "ICP"
    )
    (inst
      name = "PAD_nTrip"
      cell = "ICP"
    )
  )
  (bottom
    (locals
      io_order = counterclockwise
    )
    (inst
      name = "PADS_GND_1"
      cell = "GND3ALLP"
    )
    (inst
      name = "PAD_SCLK"
      cell = "BU8P"
    )
    (inst
      name = "PAD_SegA"
      cell = "BU8P"
    )
    (inst
      name = "PAD_SegB"
      cell = "BU8P"
    )
    (inst
      name = "PAD_SegC"
      cell = "BU8P"
    )
    (inst
      name = "PAD_SegD"
      cell = "BU8P"
    )
    (inst
      name = "PAD_SegE"
      cell = "BU8P"
    )
  )
  (left
    (locals
      io_order = counterclockwise
    )
    (inst
      name = "PAD_nMode"
      cell = "ICP"
    )
    (inst
      name = "PAD_Clock"
      cell = "ICCK2P"
    )
    (inst
      name = "PAD_nReset"
      cell = "ICP"
    )
    (inst
      name = "CORE_VDD_1"
      cell = "VDD3IP"
    )
    (inst
      name = "PAD_SDO"
      cell = "ICP"
    )
    (inst
      name = "PAD_nCS"
      cell = "BU8P"
    )
    (inst
      name = "PAD_DnC"
      cell = "BU8P"
    )
    (inst
      name = "PAD_SDIN"
      cell = "BU8P"
    )
  )
  (right
    (locals
      io_order = counterclockwise
    )
    (inst
      name = "PAD_SegF"
      cell = "BU8P"
    )
    (inst
      name = "PAD_SegG"
      cell = "BU8P"
    )
    (inst
      name = "CORE_GND_1"
      cell = "GND3IP"
    )
    (inst
      name = "PAD_DP"
      cell = "BU8P"
    )
    (inst
      name = "PAD_nDigit_0"
      cell = "BU8P"
    )
    (inst
      name = "PAD_nDigit_1"
      cell = "BU8P"
    )
    (inst
      name = "PAD_nDigit_2"
      cell = "BU8P"
    )
    (inst
      name = "PAD_nDigit_3"
      cell = "BU8P"
    )
  )
)
