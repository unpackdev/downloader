// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";

import "./IFlashloanReceiver.sol";
import "./IBalancer.sol";
import "./IETHLeverage.sol";
import "./TransferHelper.sol";

contract BalancerReceiver is OwnableUpgradeable, IFlashloanReceiver {
    using SafeMath for uint256;

    // Balancer V2 Vault
    address public balancer;

    // Balancer Fee Pool
    address public balancerFee;

    // Substrategy address
    address public subStrategy;

    // Fee Decimal
    uint256 public constant feeDecimal = 1e18;

    // Fee Magnifier
    uint256 public constant magnifier = 1e4;

    // Registered balancer caller
    mapping(address => bool) public balancerCaller;

    // Flash loan state
    bool private isLoan;

    function initialize(
        address _balancer,
        address _balancerFee,
        address _subStrategy
    ) public initializer {
        balancer = _balancer;
        balancerFee = _balancerFee;
        subStrategy = _subStrategy;
    }

    receive() external payable {}

    modifier loanProcess() {
        isLoan = true;
        _;
        isLoan = false;
    }

    modifier onlySS() {
        require(_msgSender() == subStrategy, "ONLY_SS_CALLABLE");
        _;
    }

    function getFee() external view override returns (uint256 fee) {
        fee = (IBalancer(balancerFee).getFlashLoanFeePercentage() * magnifier) / feeDecimal;
    }

    function flashLoan(address token, uint256 amount) external override loanProcess onlySS {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        bytes memory userData = "0x0";

        tokens[0] = token;
        amounts[0] = amount;

        IBalancer(balancer).flashLoan(address(this), tokens, amounts, userData);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) public payable {
        require(msg.sender == balancer, "ONLY_FLASHLOAN_VAULT");
        require(isLoan, "NOT_LOAN_REQUESTED");

        IERC20 token = tokens[0];
        uint256 loanAmt = amounts[0];
        uint256 feeAmt = feeAmounts[0];

        // Transfer Loan Token to ETH Leverage SS
        TransferHelper.safeTransfer(address(token), subStrategy, loanAmt);

        // Call Loan Fallback function in SS
        IETHLeverage(subStrategy).loanFallback(loanAmt, feeAmt);

        // Pay back flash loan
        require(token.balanceOf(address(this)) >= loanAmt + feeAmt, "INSUFFICIENT_REFUND");
        TransferHelper.safeTransfer(address(token), balancer, loanAmt + feeAmt);
    }
}
