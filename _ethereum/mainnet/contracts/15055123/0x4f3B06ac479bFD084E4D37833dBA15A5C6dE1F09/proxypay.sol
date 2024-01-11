// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {Ownable} from "Ownable.sol";

contract ProxyPay is Ownable {
    address[] public devAddresses;
    uint256[] public ratio; // total of ratio cannot exceed 1000

    constructor(address[] memory addresses, uint256[] memory _ratio) onlyOwner {
        require(addresses.length == _ratio.length);
        ratio = _ratio;
        devAddresses = addresses;
    }

    receive() external payable {
        require(msg.value >= 0);
    }

    function updatePayout(address[] memory addresses, uint256[] memory _ratio)
        public
        onlyOwner
    {
        require(addresses.length == _ratio.length);
        ratio = _ratio;
        devAddresses = addresses;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        for (uint256 i; i < devAddresses.length; i++) {
            (bool success, ) = payable(devAddresses[i]).call{
                value: (balance * ratio[i]) / 1000
            }("");
            require(success);
        }
    }
}
