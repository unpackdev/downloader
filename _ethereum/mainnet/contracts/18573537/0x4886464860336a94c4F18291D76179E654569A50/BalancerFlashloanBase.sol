// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./Interfaces.sol";
import "./DefinitiveAssets.sol";
import "./DefinitiveErrors.sol";

abstract contract BalancerFlashloanBase {
    using DefinitiveAssets for IERC20;

    address private FLASHLOAN_PROVIDER_ADDRESS;
    bool private isAuthenticated;

    constructor(address _flashloanProvider) {
        FLASHLOAN_PROVIDER_ADDRESS = _flashloanProvider;
    }

    function initiateFlashLoan(address borrowToken, uint256 amount, bytes memory userData) internal {
        (IERC20[] memory tokens, uint256[] memory amounts) = (new IERC20[](1), new uint256[](1));
        tokens[0] = IERC20(borrowToken);
        amounts[0] = amount;
        isAuthenticated = true;
        IVault(FLASHLOAN_PROVIDER_ADDRESS).flashLoan(IFlashLoanRecipient(address(this)), tokens, amounts, userData);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        // we must enforce that only the flashloan provider vault can call this function
        if (msg.sender != FLASHLOAN_PROVIDER_ADDRESS) {
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
        tokens[0].safeTransfer(FLASHLOAN_PROVIDER_ADDRESS, amounts[0] + feeAmounts[0]);
    }

    function onFlashLoanReceived(
        address token,
        uint256 amount,
        uint256 feeAmount,
        bytes memory userData
    ) internal virtual;

    function setFlashloanProvider(address newProvider) external virtual;

    function _setFlashloanProvider(address newProvider) internal {
        FLASHLOAN_PROVIDER_ADDRESS = newProvider;
    }
}
