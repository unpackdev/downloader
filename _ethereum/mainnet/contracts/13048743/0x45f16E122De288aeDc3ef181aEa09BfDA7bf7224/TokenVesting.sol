// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./SafeMath.sol";

contract TokenVesting {
    using SafeMath for uint;
    
    address public hsf;
    address public recipient;
    uint public vestingAmount;
    uint public vestingBegin;
    uint public vestingCliff;
    uint public vestingEnd;

    uint public lastUpdate;
    
    event TokenClaimed(uint amount);

    constructor(
        address hsf_,
        address recipient_,
        uint vestingAmount_,
        uint vestingBegin_,
        uint vestingCliff_,
        uint vestingEnd_
    ) {
        require(vestingBegin_ >= block.timestamp, 'TokenVesting::constructor: vesting begin too early');
        require(vestingCliff_ >= vestingBegin_, 'TokenVesting::constructor: cliff is too early');
        require(vestingEnd_ > vestingCliff_, 'TokenVesting::constructor: end is too early');

        hsf = hsf_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;
        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'TokenVesting::setRecipient: unauthorized');
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, 'TokenVesting::claim: not time yet');
        uint amount;
        if (block.timestamp >= vestingEnd) {
            amount = IHsf(hsf).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        IHsf(hsf).transfer(recipient, amount);
        emit TokenClaimed(amount);
    }
}

interface IHsf {
    function balanceOf(address account) external view returns (uint);
    function transfer(address _to, uint _value) external returns (bool);
}