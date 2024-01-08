pragma solidity ^0.6.10;

import "./IERC20.sol";
import "./SafeMath.sol";


contract Vesting {
    using SafeMath for uint256;

    address public visr;
    address public recipient;

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

    uint256 public lastUpdate;

    constructor(
        address visr_,
        address recipient_,
        uint256 vestingAmount_,
        uint256 vestingBegin_,
        uint256 vestingCliff_,
        uint256 vestingEnd_
    ) public {
        require(vestingBegin_ >= block.timestamp, "TreasuryVester.constructor: vesting begin too early");
        require(vestingCliff_ >= vestingBegin_, "TreasuryVester.constructor: cliff is too early");
        require(vestingEnd_ > vestingCliff_, "TreasuryVester.constructor: end is too early");

        visr = visr_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, "TreasuryVester.setRecipient: unauthorized");
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, "TreasuryVester.claim: not time yet");
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = IERC20(visr).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp.sub(lastUpdate)).div(vestingEnd.sub(vestingBegin));
            lastUpdate = block.timestamp;
        }
        IERC20(visr).transfer(recipient, amount);
    }

    function recoverToken(address token_) public {
        require(token_ != visr, "TreasuryVester.recoverToken: only recover tokens accidentally sent to the contract");
        uint256 amount = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(recipient, amount);
    }
}
