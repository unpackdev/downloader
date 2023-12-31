// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./IFlashLoanRecipient.sol";
import "./IVault.sol";
import "./DefinitiveAssets.sol";
import "./DefinitiveErrors.sol";

abstract contract BalancerFlashloanBase {
    using DefinitiveAssets for IERC20;

    address private constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bool private isAuthenticated;

    function initiateFlashLoan(address borrowToken, uint256 amount, bytes memory userData) internal {
        (BalancerIERC20[] memory tokens, uint256[] memory amounts) = (new BalancerIERC20[](1), new uint256[](1));
        tokens[0] = BalancerIERC20(borrowToken);
        amounts[0] = amount;
        isAuthenticated = true;
        IVault(BALANCER_VAULT).flashLoan(IFlashLoanRecipient(address(this)), tokens, amounts, userData);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        // we must enforce that only the flashloan provider vault can call this function
        if (msg.sender != BALANCER_VAULT) {
            revert UntrustedFlashLoanSender(msg.sender);
        }

        // Enforce we initiated the flashloan
        if (!isAuthenticated) {
            revert UnauthenticatedFlashloan();
        }

        // Reset authentication
        isAuthenticated = false;

        onFlashLoanReceived(address(tokens[0]), amounts[0], feeAmounts[0], userData);

        // Send tokens back to the balancer vault
        // slither-disable-next-line arbitrary-send-erc20
        tokens[0].safeTransfer(BALANCER_VAULT, amounts[0] + feeAmounts[0]);
    }

    function onFlashLoanReceived(
        address token,
        uint256 amount,
        uint256 feeAmount,
        bytes memory userData
    ) internal virtual;
}
