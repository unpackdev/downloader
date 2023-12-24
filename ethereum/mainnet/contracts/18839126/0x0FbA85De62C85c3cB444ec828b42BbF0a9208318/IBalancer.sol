// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./IERC20Metadata.sol";

interface IBalancerGauge {
    function claim_rewards() external;
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function balanceOf(address _address) external view returns(uint256 _balance);
}

interface IBalancerVault {
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;
    function exitPool(bytes32 poolId, address sender, address recipient, ExitPoolRequest memory request) external payable;
    function getPoolTokens(bytes32 poolId) external view returns (IAsset[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external returns (uint256 amountOut);
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerPool is IERC20Metadata {
    function getPoolId() external view returns (bytes32);
    function getVault() external view returns (address);
    function getRate() external view returns (uint256);
    function getTokenRate(address) external view returns (uint256);
    function getScalingFactors() external view returns (uint256[] memory);
    function getAmplificationParameter() external view returns (uint256, bool, uint256);
}

struct SingleSwap {
   bytes32 poolId;
   SwapKind kind;
   IAsset assetIn;
   IAsset assetOut;
   uint256 amount;
   bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

interface IComposableStablePoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 amplificationParameter,
        IRateProvider[] memory rateProviders,
        uint256[] memory tokenRateCacheDurations,
        bool exemptFromYieldProtocolFeeFlag,
        uint256 swapFeePercentage,
        address owner,
        bytes32 salt
    ) external returns(address poolAddress);
}

interface IRateProvider {
    function getRate() external view returns (uint256);
}

enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT }
enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT, EXACT_BPT_IN_FOR_ALL_TOKENS_OUT }
enum SwapKind { GIVEN_IN, GIVEN_OUT }
