// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./DefinitiveConstants.sol";
import "./ILLSDStrategyV1.sol";

import "./BaseMultiUserStrategyV1.sol";

/// @notice Uses selected methods from IERC4626
interface IMultiUserLLSDStrategy is IBaseMultiUserStrategyV1 {
    struct RedeemEventData {
        address sender;
        address receiver;
        address owner;
        DefinitiveConstants.Assets tokensRemoved;
        uint256 assetsRemoved;
        uint256 shares;
    }

    struct MintEventData {
        address sender;
        address owner;
        DefinitiveConstants.Assets tokensAdded;
        uint256 assetsAdded;
        uint256 shares;
    }

    struct DepositParams {
        uint256 deadline;
        uint256 chainId;
        DefinitiveConstants.Assets depositTokens;
        ILLSDStrategyV1.EnterContext enterCtx;
    }

    struct RedeemParams {
        uint256 deadline;
        uint256 chainId;
        uint256 sharesBurned;
        uint256 sharesFees;
        uint256 sharesFeesAdditional;
        ILLSDStrategyV1.ExitContext exitCtx;
    }

    event Mint(MintEventData mintEvent);

    event NativeAssetWrap(address actor, uint256 amount, bool indexed wrappingToNative);

    event Redeem(RedeemEventData redeemEvent);

    event UpdateSafeLTVThreshold(address sender, uint256 threshold);

    event UpdateSharesToAssetsRatioThreshold(address sender, uint256 threshold);

    function deposit(
        address receiver,
        DepositParams calldata depositParams,
        bytes memory depositParamsSignature
    ) external payable returns (uint256 shares, uint256 assetsAdded);

    function redeem(
        address receiver,
        address owner,
        RedeemParams calldata redeemParams,
        bytes memory redeemParamsSignature
    ) external returns (DefinitiveConstants.Assets memory tokensRemoved);

    function setSafeLTVThreshold(uint256) external;

    function setSharesToAssetRatioThreshold(uint256) external;

    function asset() external view returns (address assetTokenAddress);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function totalAssets() external view returns (uint256 totalManagedAssets);
}
