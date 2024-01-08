// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Dev Payable
/// @author @MilkyTasteEth MilkyTaste:8662 https://milkytaste.xyz
/// Manage payables

import "./Ownable.sol";

contract DevPayable is Ownable {

    address payable private devAddress;

    constructor(address payable _devAddress) {
        devAddress = _devAddress;
    }

    /**
     * Withdraw funds
     */
    function withdraw() external {
        uint256 ten = address(this).balance / 10;
        devAddress.transfer(ten); // 10%
        payable(owner()).transfer(ten * 9); // 90%
    }

}
