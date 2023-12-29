// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.21;

abstract contract IDOConstants {
    uint256 public constant SCALE = 1e18;

    uint256 public constant MATCH_CAP_TOTAL = 1500000 ether;

    uint256 public constant ETH_CAP_TOTAL = 375 ether;

    // Maximum 75 ETH will be received by IDO Whitelist Round
    uint256 public constant ETH_CAP_WL = 75 ether;

    // 2023-12-22 22:00 (UTC+8)
    uint256 public constant WL_START = 1703253600;
    // 2023-12-23 10:00 (UTC+8)
    uint256 public constant WL_END = 1703296800;

    // 2023-12-23 10:00 (UTC+8)
    uint256 public constant PUB_START = 1703296800;
    // 2023-12-25 22:00 (UTC+8)
    uint256 public constant PUB_END = 1703512800;
}

abstract contract IDOTestConstants {
    uint256 public constant SCALE = 1e18;

    uint256 public constant MATCH_CAP_TOTAL = 1500000 ether;

    uint256 public constant ETH_CAP_TOTAL = 2 ether;

    // Maximum 75 ETH will be received by IDO Whitelist Round
    uint256 public constant ETH_CAP_WL = 0.5 ether;

    // 2023-12-19 14:00 (UTC+8)
    uint256 public constant WL_START = 1702972800;
    // 2023-12-19 14:30 (UTC+8)
    uint256 public constant WL_END = 1702974600;

    // 2023-12-19 14:30 (UTC+8)
    uint256 public constant PUB_START = 1702974600;
    // 2023-12-19 15:00 (UTC+8)
    uint256 public constant PUB_END = 1702976400;
}
