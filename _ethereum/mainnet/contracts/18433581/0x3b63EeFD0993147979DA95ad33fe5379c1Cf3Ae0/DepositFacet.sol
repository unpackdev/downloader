// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IDepositFacet.sol";

import "./FullMath.sol";

contract DepositFacet is IDepositFacet {
    error InvalidLength();
    error LimitOverflow();
    error LimitUnderflow();
    error ZeroTokenAmounts();

    using SafeERC20 for IERC20;

    function deposit(
        uint256[] calldata tokenAmounts,
        uint256 minLpAmount
    ) external override returns (uint256 lpAmount, uint256[] memory actualTokenAmounts) {
        try ILockFacet(address(this)).getLock() returns (bool isLocked, string memory reason) {
            if (isLocked) revert(reason);
        } catch {}

        IVaultFacet vaultFacet = IVaultFacet(address(this));

        (address[] memory tokens, uint256[] memory currentTokenAmounts) = vaultFacet.getTokensAndAmounts();
        if (tokenAmounts.length != currentTokenAmounts.length) revert InvalidLength();
        LpToken lpToken = ILpTokenFacet(address(this)).lpToken();
        uint256 totalSupply = lpToken.totalSupply();

        address vaultAddress = ITokensManagementFacet(address(this)).vault();
        if (totalSupply == 0) {
            for (uint256 i = 0; i < tokenAmounts.length; i++) {
                if (tokenAmounts[i] == 0) continue;
                IERC20(tokens[i]).safeTransferFrom(msg.sender, vaultAddress, tokenAmounts[i]);
                if (lpAmount < tokenAmounts[i]) {
                    lpAmount = tokenAmounts[i];
                }
            }
            if (lpAmount == 0) revert ZeroTokenAmounts();
            if (minLpAmount > type(uint128).max) revert LimitOverflow();
            lpToken.mint(address(this), minLpAmount);
            return (0, tokenAmounts);
        }

        lpAmount = type(uint256).max;
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            if (currentTokenAmounts[i] == 0) continue;
            uint256 amount = FullMath.mulDiv(totalSupply, tokenAmounts[i], currentTokenAmounts[i]);
            if (lpAmount > amount) {
                lpAmount = amount;
            }
        }

        if (lpAmount < minLpAmount) revert LimitUnderflow();
        actualTokenAmounts = new uint256[](tokenAmounts.length);
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            uint256 amount = FullMath.mulDiv(currentTokenAmounts[i], lpAmount, totalSupply);
            if (amount == 0) continue;
            IERC20(tokens[i]).safeTransferFrom(msg.sender, vaultAddress, amount);
            actualTokenAmounts[i] = amount;
        }

        lpToken.mint(msg.sender, lpAmount);
    }

    function depositInitialized() external pure returns (bool) {
        return true;
    }

    function depositSelectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](3);
        selectors_[0] = IDepositFacet.depositInitialized.selector;
        selectors_[1] = IDepositFacet.depositSelectors.selector;
        selectors_[2] = IDepositFacet.deposit.selector;
    }
}
