// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./Ownable.sol";

contract LTWCOpenseaSplitter is Ownable {
    address public addressOne;
    address public addressTwo;
    uint256 public minPayAmount = 0.5 ether;

    constructor() {
        setAddressOne(0xdD4b5d3a733250B49b301e2a3419F0b1D1882857);
        setAddressTwo(0x899005EF9757df34159b95BabFfD4F13dA5B4129);
    }

    receive() external payable {
        if (address(this).balance > minPayAmount) {
            withdraw();
        }
    }

    function setAddressOne(address _addressOne) public onlyOwner {
        addressOne = _addressOne;
    }

    function setAddressTwo(address _addressTwo) public onlyOwner {
        addressTwo = _addressTwo;
    }

    function setMinPayAmount(uint256 _minPayAmount) public onlyOwner {
        minPayAmount = _minPayAmount;
    }

    function withdraw() public payable {
        (bool ss, ) = payable(addressTwo).call{value: address(this).balance / 2}("");
        require(ss);

        (bool os, ) = payable(addressOne).call{value: address(this).balance}("");
        require(os);
    }
}
