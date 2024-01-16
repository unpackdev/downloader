// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import "./ERC4626Adapter.sol";
import "./BaseAdapter.sol";
import "./Crops.sol";
import "./Errors.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

/// @notice Adapter contract for ERC4626 Vaults
contract ERC4626CropsAdapter is ERC4626Adapter, Crops {
    using SafeTransferLib for ERC20;

    constructor(
        address _divider,
        address _target,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams,
        address[] memory _rewardTokens
    ) ERC4626Adapter(_divider, _target, _rewardsRecipient, _ifee, _adapterParams) Crops(_divider, _rewardTokens) {}

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crops) {
        super.notify(_usr, amt, join);
    }

    function extractToken(address token) external override {
        for (uint256 i = 0; i < rewardTokens.length; ) {
            if (token == rewardTokens[i]) revert Errors.TokenNotSupported();
            unchecked {
                ++i;
            }
        }

        // Check that token is neither the target nor the stake
        if (token == target || token == adapterParams.stake) revert Errors.TokenNotSupported();
        ERC20 t = ERC20(token);
        uint256 tBal = t.balanceOf(address(this));
        t.safeTransfer(rewardsRecipient, tBal);
        emit RewardsClaimed(token, rewardsRecipient, tBal);
    }
}
