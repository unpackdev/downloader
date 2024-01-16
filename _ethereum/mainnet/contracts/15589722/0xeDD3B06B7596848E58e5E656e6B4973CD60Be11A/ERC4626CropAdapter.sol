// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import "./ERC4626Adapter.sol";
import "./BaseAdapter.sol";
import "./Crop.sol";
import "./Errors.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

/// @notice Adapter contract for ERC4626 Vaults
contract ERC4626CropAdapter is ERC4626Adapter, Crop {
    using SafeTransferLib for ERC20;

    constructor(
        address _divider,
        address _target,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams,
        address _reward
    ) ERC4626Adapter(_divider, _target, _rewardsRecipient, _ifee, _adapterParams) Crop(_divider, _reward) {}

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crop) {
        super.notify(_usr, amt, join);
    }

    function extractToken(address token) external override {
        // Check that token is neither the target, the stake nor the reward
        if (token == target || token == adapterParams.stake || token == reward) revert Errors.TokenNotSupported();
        ERC20 t = ERC20(token);
        uint256 tBal = t.balanceOf(address(this));
        t.safeTransfer(rewardsRecipient, tBal);
        emit RewardsClaimed(token, rewardsRecipient, tBal);
    }
}
