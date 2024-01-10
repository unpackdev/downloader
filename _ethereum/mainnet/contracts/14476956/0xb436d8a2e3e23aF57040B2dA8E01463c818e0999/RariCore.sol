// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IAave.sol";
import "./IComptroller.sol";
import "./CompoundStrategy.sol";
import "./IFusePoolDirectory.sol";

/// @title This library provide core operations for Rari
library RariCore {
    /**
     * @notice Gets Comptroller
     * @param _fusePoolDir address of the Fuse Pool Directory
     * @param _fusePoolId Fuse Pool ID
     */
    function getComptroller(IFusePoolDirectory _fusePoolDir, uint256 _fusePoolId)
        internal
        view
        returns (address _comptroller)
    {
        (, , _comptroller, , ) = _fusePoolDir.pools(_fusePoolId);
    }

    /**
     * @notice Gets the cToken to mint for a Fuse Pool
     * @param _fusePoolDir address of the Fuse Pool Directory
     * @param _fusePoolId Fuse Pool ID
     * @param _collateralToken address of the collateralToken
     */
    function getCTokenByUnderlying(
        IFusePoolDirectory _fusePoolDir,
        uint256 _fusePoolId,
        address _collateralToken
    ) internal view returns (address _cToken) {
        address _comptroller = getComptroller(_fusePoolDir, _fusePoolId);
        require(_comptroller != address(0), "rari-fuse-invalid-comptroller");
        _cToken = IComptroller(_comptroller).cTokensByUnderlying(_collateralToken);
        require(_cToken != address(0), "rari-fuse-invalid-ctoken");
    }

    /**
     * @notice Automatically finds rewardToken set for the current Fuse Pool
     * @param _fusePoolDir address of the Fuse Pool Directory
     * @param _fusePoolId Fuse Pool ID
     */
    function getRewardToken(IFusePoolDirectory _fusePoolDir, uint256 _fusePoolId)
        internal
        view
        returns (address _rewardDistributor, address _rewardToken)
    {
        uint256 _success;
        address _comptroller = getComptroller(_fusePoolDir, _fusePoolId);
        bytes4 _selector = IComptroller(_comptroller).rewardsDistributors.selector;

        // Low level static call to prevent revert in case the Comptroller doesn't have
        // rewardsDistributors function exposed
        // which may happen to older Fuse Pools
        uint256 _comptrollerSize;
        assembly {
            _comptrollerSize := extcodesize(_comptroller)
        }
        require(_comptrollerSize > 0, "comptroller-not-a-contract");

        assembly {
            let x := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(x, _selector) // Place signature at beginning of empty storage
            mstore(add(x, 0x04), 0) // Place first argument directly next to signature

            _success := staticcall(
                30000, // 30k gas
                _comptroller, // To addr
                x, // Inputs are stored at location x
                0x24, // Inputs are 36 bytes long
                x, // Store output over input (saves space)
                0x20
            ) // Outputs are 32 bytes long

            _rewardDistributor := mload(x) // Load the result
        }
        if (_rewardDistributor != address(0)) {
            _rewardToken = IRariRewardDistributor(_rewardDistributor).rewardToken();
        }
    }
}
