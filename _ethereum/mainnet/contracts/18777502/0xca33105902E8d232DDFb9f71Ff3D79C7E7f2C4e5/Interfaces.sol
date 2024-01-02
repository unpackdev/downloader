// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IERC20Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

}

interface IGlobalsLike {

    function canDeploy(address caller_) external view returns (bool canDeploy_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function governor() external view returns (address governor_);

    function isInstanceOf(bytes32 instanceId, address instance_) external view returns (bool isInstance_);

    function isValidScheduledCall(
        address caller_,
        address contract_,
        bytes32 functionId_,
        bytes calldata callData_
    ) external view returns (bool isValid_);

    function operationalAdmin() external view returns (address operationalAdmin_);

    function securityAdmin() external view returns (address securityAdmin_);

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

    function mapleGlobals() external returns (address globals_);

}

interface IPoolLike {

    function asset() external view returns (address asset_);

    function manager() external view returns (address poolManager_);

    function previewRedeem(uint256 shares_) external view returns (uint256 assets_);

    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

    function totalSupply() external view returns (uint256 totalSupply_);

}

interface IPoolManagerLike {

    function factory() external view returns (address factory_);

    function poolDelegate() external view returns (address poolDelegate_);

    function totalAssets() external view returns (uint256 totalAssets_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}
