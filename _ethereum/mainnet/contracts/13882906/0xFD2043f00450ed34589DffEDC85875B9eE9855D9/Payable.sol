// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Payable
/// @author @MilkyTasteEth MilkyTaste:8662 https://milkytaste.xyz
/// Manage payables

import "./Ownable.sol";

contract Payable is Ownable {

    address private sammyAddress = 0x8bffc7415B1F8ceA3BF9e1f36EBb2FF15d175CF5;
    address private commyAddress = 0x6716D41029631116c5245096c46b04aca47D0Bd0;
    address payable private devAddress;

    constructor(address payable _devAddress) {
        devAddress = _devAddress;
    }

    /**
     * Withdraw funds
     */
    function withdraw() external {
        require(msg.sender == sammyAddress || msg.sender == devAddress, "Payable: Locked withdraw");
        uint256 five = address(this).balance / 20;
        devAddress.transfer(five * 3); // 15%
        payable(commyAddress).transfer(five * 5); // 25%
        payable(sammyAddress).transfer(five * 12); // 60%
    }

}
