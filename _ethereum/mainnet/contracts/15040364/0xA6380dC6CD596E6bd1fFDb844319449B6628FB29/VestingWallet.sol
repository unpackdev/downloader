//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SafeMath.sol";

contract VestingWallet {
    using SafeMath for uint;

    address public sax;
    address public recipient;

    uint public vestingAmount;
    uint public vestingBegin;
    uint public vestingCliff;
    uint public vestingEnd;

    uint public lastUpdate;

    constructor(
        address sax_,
        address recipient_,
        uint vestingAmount_,
        uint vestingBegin_,
        uint vestingCliff_,
        uint vestingEnd_
    ) {
        require(vestingBegin_ >= block.timestamp, 'VestingWallet::constructor: vesting begin too early');
        require(vestingCliff_ >= vestingBegin_, 'VestingWallet::constructor: cliff is too early');
        require(vestingEnd_ > vestingCliff_, 'VestingWallet::constructor: end is too early');

        sax = sax_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'VestingWallet::setRecipient: unauthorized');
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, 'VestingWallet::claim: not time yet');
        uint amount;
        if (block.timestamp >= vestingEnd) {
            amount = IERC20(sax).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        IERC20(sax).transfer(recipient, amount);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}