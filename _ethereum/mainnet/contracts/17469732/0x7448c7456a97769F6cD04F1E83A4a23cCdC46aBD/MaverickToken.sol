// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OFT.sol";

contract MaverickToken is OFT {
    constructor(address _layerZeroEndpoint, address mintToAddress) OFT("Maverick Token", "MAV", _layerZeroEndpoint) {
        if (mintToAddress != address(0)) _mint(mintToAddress, 2_000_000_000 * 1e18);
    }
}
