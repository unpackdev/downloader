// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Presale is Ownable, ReentrancyGuard {
    
    modifier isPresaleActive() {
        require(isPresaleActivated(), "Presale Not Active!");
        _;
    }

    uint256 public presaleStart;
    uint256 public presaleEnd;

     constructor(uint256 _presaleStart, uint256 _presaleEnd) {
        presaleStart = _presaleStart;
        presaleEnd = _presaleEnd;
    }

    function isPresaleActivated() public view returns (bool) {
        return  presaleStart > 0 &&
                presaleEnd > 0 &&
                block.timestamp >= presaleStart &&
                block.timestamp <= presaleEnd;
    }

    function setTimeStampPresale(uint256 _presaleStart, uint256 _presaleEnd) external onlyOwner nonReentrant{
        presaleStart = _presaleStart;
        presaleEnd = _presaleEnd;
    }

}