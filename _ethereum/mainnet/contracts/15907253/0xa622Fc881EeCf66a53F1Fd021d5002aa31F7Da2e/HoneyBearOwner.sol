// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

interface IMinter {
    function mintTo(address _to, uint256 _amount) external;

    function setOwner(address _newOwner) external;
}

contract HoneyBearOwner is Ownable {
    IMinter immutable honeyMinter;

    mapping(address => uint) public minted;

    constructor(address _honeyMinter) {
        honeyMinter = IMinter(_honeyMinter);
    }

    function mint(uint _amount) public {
        require(minted[_msgSender()] + _amount < 6, "Max Mint Reached");

        minted[_msgSender()] += _amount;
        honeyMinter.mintTo(_msgSender(), _amount);
    }

    function setOwner(address _newOwner) external onlyOwner {
        honeyMinter.setOwner(_newOwner);
    }
}
