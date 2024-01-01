// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IWithdrawFacet.sol";
import "./FullMath.sol";

contract WithdrawFacet is IWithdrawFacet {
    error InvalidLength();
    error LimitUnderflow();

    using SafeERC20 for IERC20;

    function withdraw(
        uint256 lpAmount,
        uint256[] memory minTokenAmounts
    ) external override returns (uint256[] memory tokenAmounts) {
        try ILockFacet(address(this)).getLock() returns (bool isLocked, string memory reason) {
            if (isLocked) revert(reason);
        } catch {}

        IVaultFacet vaultFacet = IVaultFacet(address(this));
        LpToken lpToken = ILpTokenFacet(address(this)).lpToken();
        uint256 totalSupply = lpToken.totalSupply();
        lpToken.burn(msg.sender, lpAmount);
        (address[] memory tokens, uint256[] memory currentTokenAmounts) = vaultFacet.getTokensAndAmounts();

        if (minTokenAmounts.length != tokens.length) revert InvalidLength();
        tokenAmounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (currentTokenAmounts[i] == 0) {
                if (minTokenAmounts[i] != 0) revert LimitUnderflow();
                continue;
            }
            uint256 tokenAmount = FullMath.mulDiv(currentTokenAmounts[i], lpAmount, totalSupply);
            if (tokenAmount < minTokenAmounts[i]) revert LimitUnderflow();
            IERC20(tokens[i]).safeTransfer(msg.sender, tokenAmount);
            tokenAmounts[i] = tokenAmount;
        }
    }

    function withdrawInitialized() external pure returns (bool) {
        return true;
    }

    function withdrawSelectors() external pure returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](3);
        selectors_[0] = IWithdrawFacet.withdrawInitialized.selector;
        selectors_[1] = IWithdrawFacet.withdrawSelectors.selector;
        selectors_[2] = IWithdrawFacet.withdraw.selector;
    }
}
