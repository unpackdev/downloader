pragma solidity ^0.5.16;

import "./SafeMath.sol";

contract TreasuryVester {
    using SafeMath for uint;

    address public uni;
    address public recipient;

    uint public vestingAmount;
    uint public vestingBegin;
    uint public vestingCliff;
    uint public vestingEnd;

    uint public lastUpdate;

    bool public canDelegate;

    constructor(
        address uni_,
        address recipient_,
        address approveTo_,
        uint vestingAmount_,
        uint vestingBegin_,
        uint vestingCliff_,
        uint vestingEnd_,
        bool canDelegate_
    ) public {
        require(vestingBegin_ >= block.timestamp, 'TreasuryVester::constructor: vesting begin too early');
        require(vestingCliff_ >= vestingBegin_, 'TreasuryVester::constructor: cliff is too early');
        require(vestingEnd_ > vestingCliff_, 'TreasuryVester::constructor: end is too early');

        uni = uni_;
        if (approveTo_ != address(0)){
            IUni(uni).approve(approveTo_, uint256(-1));
        }
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
        canDelegate = canDelegate_;
    }

    function delegate(address delegatee) public {
        require(msg.sender == recipient, 'TreasuryVester::delegate: unauthorized');
        require(canDelegate, 'TreasuryVester::delegate: delegate not allowed');
        IUni(uni).delegate(delegatee);
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'TreasuryVester::setRecipient: unauthorized');
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, 'TreasuryVester::claim: not time yet');
        uint amount;
        if (block.timestamp >= vestingEnd) {
            amount = IUni(uni).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        IUni(uni).transfer(recipient, amount);
    }
}

interface IUni {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function delegate(address delegatee) external;
    function approve(address spender, uint rawAmount) external returns (bool);
}
