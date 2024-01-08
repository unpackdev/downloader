// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ICHIVault.sol";
import "./ICHIDepositCallBack.sol";

interface ICHIManager is ICHIDepositCallBack {
    // CHI config
    struct CHIConfig {
        bool paused;
        bool archived;
        uint256 maxUSDLimit;
    }

    // CHI data
    struct CHIData {
        address operator;
        address pool;
        address vault;
        CHIConfig config;
    }

    struct MintParams {
        address recipient;
        address token0;
        address token1;
        uint24 fee;
    }

    struct RangeParams {
        int24 tickLower;
        int24 tickUpper;
    }

    function chi(uint256 tokenId)
        external
        view
        returns (
            address owner,
            address operator,
            address pool,
            address vault,
            uint256 accruedProtocolFees0,
            uint256 accruedProtocolFees1,
            uint24 fee,
            uint256 totalShares
        );

    function config(uint256 tokenId)
        external
        view
        returns (
            bool isPaused,
            bool isArchived,
            uint256 maxUSDLimit
        );

    function chiVault(uint256 tokenId)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 collect0,
            uint256 collect1
        );

    function mint(MintParams calldata params, bytes32[] calldata merkleProof)
        external
        returns (uint256 tokenId, address vault);

    function subscribeSingle(
        uint256 yangId,
        uint256 tokenId,
        bool zeroForOne,
        uint256 exactAmount,
        uint256 maxTokenAmount,
        uint256 minShares
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    function subscribe(
        uint256 yangId,
        uint256 tokenId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    function unsubscribeSingle(
        uint256 yangId,
        uint256 tokenId,
        bool zeroForOne,
        uint256 shares,
        uint256 amountOutMin
    ) external returns (uint256 amount);

    function unsubscribe(
        uint256 yangId,
        uint256 tokenId,
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint256 amount0, uint256 amount1);

    function addAndRemoveRanges(
        uint256 tokenId,
        RangeParams[] calldata addRanges,
        RangeParams[] calldata removeRanges
    ) external;

    function collectProtocol(uint256 tokenId) external;

    function addAllLiquidityToPosition(
        uint256 tokenId,
        uint256[] calldata ranges,
        uint256[] calldata amount0Totals,
        uint256[] calldata amount1Totals
    ) external;

    function removeRangesLiquidityFromPosition(
        uint256 tokenId,
        uint256[] calldata ranges,
        uint128[] calldata liquidities
    ) external;

    function removeRangesAllLiquidityFromPosition(
        uint256 tokenId,
        uint256[] calldata ranges
    ) external;

    function pausedCHI(uint256 tokenId) external;

    function unpausedCHI(uint256 tokenId) external;

    function archivedCHI(uint256 tokenId) external;

    function sweep(
        uint256 tokenId,
        address token,
        address to
    ) external;

    function emergencyBurn(
        uint256 tokenId,
        int24 tickLower,
        int24 tickUpper
    ) external;

    function swap(uint256 tokenId, ICHIVault.SwapParams memory params)
        external
        returns (uint256);

    function yang(uint256 yangId, uint256 chiId)
        external
        view
        returns (uint256 shares);

    event Create(
        uint256 tokenId,
        address pool,
        address vault,
        uint256 vaultFee
    );

    event ChangeLiquidity(uint256 tokenId, address vault);

    event UpdateMerkleRoot(
        address account,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot
    );
    event UpdateVaultFee(
        address account,
        uint256 oldVaultFee,
        uint256 newVaultFee
    );
    event UpdateProviderFee(
        address account,
        uint256 oldProviderFee,
        uint256 newProviderFee
    );
    event UpdateGovernance(
        address account,
        address oldGovernance,
        address newGovernance
    );
    event UpdateMaxUSDLimit(
        address account,
        uint256 oldMaxUSDLimit,
        uint256 newMaxUSDLimit
    );
    event UpdateSwapSwitch(
        address account,
        bool oldStatus,
        bool newStatus
    );

    // Events

    event Sweep(
        address account,
        address recipient,
        address token,
        uint256 tokenId
    );
    event EmergencyBurn(
        address account,
        uint256 tokenId,
        int24 tickLower,
        int24 tickUpper
    );
    event Swap(
        uint256 tokenId,
        address tokenIn,
        address tokenOut,
        uint256 percentage,
        uint256 amountOut
    );

}
