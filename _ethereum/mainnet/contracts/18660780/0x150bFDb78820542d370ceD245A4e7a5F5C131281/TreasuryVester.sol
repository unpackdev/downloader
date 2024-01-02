// SPDX-License-Identifier: MIT

/* 
   _____ _                   ______ _     _     
  / ____| |                 |  ____(_)   | |    
 | |    | |__   ___  ___ ___| |__   _ ___| |__  
 | |    | '_ \ / _ \/ __/ __|  __| | / __| '_ \ 
 | |____| | | |  __/\__ \__ \ |    | \__ \ | | |
  \_____|_| |_|\___||___/___/_|    |_|___/_| |_|
                             
*/

/// @title ChessFish Treasury Vester
/// @author Uniswap & updated by ChessFish
/// @notice https://github.com/Uniswap/governance/blob/master/contracts/TreasuryVester.sol
/// @notice https://github.com/Chess-Fish

pragma solidity ^0.8.22;

import "./SafeMath.sol";
import "./IERC20.sol";

contract TreasuryVester {
    using SafeMath for uint;

    address public splitter;

    address public cfsh;
    address public recipient;

    uint public vestingAmount;
    uint public vestingBegin;
    uint public vestingCliff;
    uint public vestingEnd;

    uint public lastUpdate;

    constructor(
        address cfsh_,
        address recipient_,
        uint vestingAmount_,
        uint vestingBegin_,
        uint vestingCliff_,
        uint vestingEnd_
    ) {
        require(vestingBegin_ >= block.timestamp, "TreasuryVester::constructor: vesting begin too early");
        require(vestingCliff_ >= vestingBegin_, "TreasuryVester::constructor: cliff is too early");
        require(vestingEnd_ > vestingCliff_, "TreasuryVester::constructor: end is too early");

        cfsh = cfsh_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, "TreasuryVester::setRecipient: unauthorized");
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, "TreasuryVester::claim: not time yet");
        uint amount;
        if (block.timestamp >= vestingEnd) {
            amount = ICFSH(cfsh).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        ICFSH(cfsh).transfer(recipient, amount);
    }

    function releaseDividendsERC20(address token) external {
        uint amount = IPaymentSplitter(splitter).releasableERC20(token, address(this));
        IPaymentSplitter(splitter).releaseERC20(token, address(this));
        IERC20(token).transfer(recipient, amount);
    }

    function releaseDividendsNative() external {
        uint amount = IPaymentSplitter(splitter).releasableNative(address(this));
        IPaymentSplitter(splitter).releaseNative(address(this));
        payable(recipient).transfer(amount);
    }

    function setSplitterContract(address _splitter) external {
        require(msg.sender == recipient, "TreasuryVester::setRecipient: unauthorized");
        splitter = _splitter;
    }
}

interface ICFSH {
    function balanceOf(address account) external view returns (uint);

    function transfer(address dst, uint rawAmount) external returns (bool);
}

interface IPaymentSplitter {
    function releasableERC20(address token, address account) external returns (uint256);

    function releasableNative(address account) external returns (uint256);

    function releaseERC20(address token, address account) external;

    function releaseNative(address account) external;
}
