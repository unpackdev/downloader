// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";

import "./IStrategy.sol";

import "./IRebalanceFacet.sol";
import "./ProxyToken.sol";

contract RebalanceFacet is IRebalanceFacet {
    error InvalidState();
    error LimitUnderflow();

    using SafeERC20 for IERC20;

    function rebalance(address callback, bytes calldata data) external {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        IVaultFacet vaultFacet = IVaultFacet(address(this));
        (, , , uint256 startTimestamp, address strategy) = IDutchAuctionFacet(address(this)).auctionParams();
        if (startTimestamp == 0 || IStrategy(strategy).canStopAuction()) revert InvalidState();

        uint256 tvlBefore = vaultFacet.tvl();
        address[] memory tokens = vaultFacet.tokens();
        uint256 proxyTokensMask = vaultFacet.proxyTokensMask();
        for (uint256 i = 0; i < tokens.length; i++) {
            ITokensManagementFacet(address(this)).approve(tokens[i], callback, type(uint256).max);
            if (((proxyTokensMask >> i) & 1) != 0) {
                ProxyToken(payable(tokens[i])).setRebalanceFlag(true);
            }
        }

        (bool success, ) = callback.call(data);
        if (!success) revert InvalidState();

        IStrategy(strategy).saveState();

        uint256 tvlAfter = vaultFacet.tvl();
        if (!IStrategy(strategy).checkStateAfterRebalance()) revert InvalidState();
        if (!IDutchAuctionFacet(address(this)).checkTvlAfterRebalance(tvlBefore, tvlAfter)) revert LimitUnderflow();

        for (uint256 i = 0; i < tokens.length; i++) {
            ITokensManagementFacet(address(this)).approve(tokens[i], callback, 0);
            if (((proxyTokensMask >> i) & 1) != 0) {
                ProxyToken(payable(tokens[i])).setRebalanceFlag(false);
                if (ProxyToken(payable(tokens[i])).owner() != address(this)) revert InvalidState();
            }
        }

        IDutchAuctionFacet(address(this)).finishAuction();
    }

    function rebalanceInitialized() external pure returns (bool) {
        return true;
    }

    function rebalanceSelectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](3);
        selectors_[0] = IRebalanceFacet.rebalanceInitialized.selector;
        selectors_[1] = IRebalanceFacet.rebalanceSelectors.selector;
        selectors_[2] = IRebalanceFacet.rebalance.selector;
    }
}
