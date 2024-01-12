// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "./IERC3156FlashLender.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVault.sol";
import "./FixedPoint.sol";
import "./IProtocolFeesCollector.sol";

contract BalancerERC3156 is IERC3156FlashLender, IFlashLoanRecipient {
    using SafeERC20 for IERC20;

    IERC3156FlashBorrower borrower = IERC3156FlashBorrower(address(0));
    address executor = address(0);

    IVault public vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    function maxFlashLoan(address) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function flashFee(address, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        // 1. Get fee percentage.
        address feesCollector = vault.getProtocolFeesCollector();
        uint256 rate = IProtocolFeesCollector(feesCollector)
            .getFlashLoanFeePercentage();
        return FixedPoint.mulUp(amount, rate);
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        borrower = receiver;
        executor = msg.sender;
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(token);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        vault.flashLoan(IFlashLoanRecipient(this), tokens, amounts, data);
        return true;
    }

    function receiveFlashLoan(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external override {
        // Check flashloan initator and loaner
        require(msg.sender == address(vault), "denied");
        require(executor != address(0), "reEntrance");
        tokens[0].safeTransfer(address(borrower), amounts[0]);

        borrower.onFlashLoan(
            executor,
            address(tokens[0]),
            amounts[0],
            fees[0],
            data
        );
        tokens[0].safeTransferFrom(
            address(borrower),
            address(vault),
            amounts[0] + fees[0]
        );

        // Reset process variable
        borrower = IERC3156FlashBorrower(address(0));
        executor = address(0);
    }
}
