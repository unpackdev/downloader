//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IXVIX.sol";

contract Timelock {
    using SafeMath for uint256;

    uint256 public constant DELAY = 5 days;

    address public xvix;
    address public owner;
    address public nextGov;
    uint256 public unlockTime;

    event SuggestGov(address gov, uint256 unlockTime);

    modifier onlyOwner() {
        require(msg.sender == owner, "Timelock: forbidden");
        _;
    }

    constructor(address _xvix) public {
        owner = msg.sender;
        xvix = _xvix;
    }

    function suggestGov(address _gov) public onlyOwner {
        require(_gov != address(0), "Timelock: gov address is empty");
        unlockTime = block.timestamp.add(DELAY);
        nextGov = _gov;
        emit SuggestGov(_gov, unlockTime);
    }

    function setGov() public onlyOwner {
        require(unlockTime != 0 && unlockTime < block.timestamp, "Timelock: not unlocked");
        IXVIX(xvix).setGov(nextGov);
    }
}
