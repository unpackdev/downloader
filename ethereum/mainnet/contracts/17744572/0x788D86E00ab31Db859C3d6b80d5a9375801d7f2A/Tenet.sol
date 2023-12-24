// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./OFTWithFee.sol";

contract Tenet is OFTWithFee {
    constructor(address _lzEndpoint) OFTWithFee("TENET", "TENET", 6, _lzEndpoint) {}
}
