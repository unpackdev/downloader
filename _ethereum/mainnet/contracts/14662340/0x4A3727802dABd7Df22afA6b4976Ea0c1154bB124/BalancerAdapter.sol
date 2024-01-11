// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IExchangeAdapter.sol";
import "./IERC20.sol";

interface IBalancerStructs {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
}

interface IBalancer is IBalancerStructs {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;
}

interface IBalancerPool {
    function getPoolId() external returns (bytes32);
}

contract BalancerAdapter is IExchangeAdapter, IBalancerStructs {
    IBalancer public constant balancer =
        IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        bytes32 poolId = IBalancerPool(pool).getPoolId();

        SingleSwap memory singleSwap = SingleSwap(
            poolId,
            SwapKind.GIVEN_IN,
            fromToken,
            toToken,
            amount,
            ""
        );
        FundManagement memory funds = FundManagement(
            address(this),
            false,
            payable(address(this)),
            false
        );

        return balancer.swap(singleSwap, funds, 0, type(uint256).max);
    }

    // 0x73ec962e  =>  enterPool(address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256) {
        bytes32 poolId = IBalancerPool(pool).getPoolId();
        address[] memory assets;
        (assets, , ) = balancer.getPoolTokens(poolId);
        uint256 assetsLength = assets.length;
        uint256[] memory maxAmountsIn = new uint256[](assetsLength);
        uint256[] memory amountsIn = new uint256[](assetsLength);

        for (uint256 i = 0; i < assetsLength; i++) {
            maxAmountsIn[i] = type(uint256).max;
            if (assets[i] == fromToken) amountsIn[i] = amount;
        }

        bytes memory userData = abi.encode(
            uint256(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT),
            amountsIn,
            0
        );

        JoinPoolRequest memory request = JoinPoolRequest(
            assets,
            maxAmountsIn,
            userData,
            false
        );

        balancer.joinPool(poolId, address(this), address(this), request);

        return IERC20(pool).balanceOf(address(this));
    }

    // 0x660cb8d4  =>  exitPool(address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        bytes32 poolId = IBalancerPool(pool).getPoolId();
        address[] memory assets;
        (assets, , ) = balancer.getPoolTokens(poolId);
        uint256 assetsLength = assets.length;
        uint256[] memory minAmountsOut = new uint256[](assetsLength);
        uint256 tokenIndex = 0;
        for (uint256 i = 0; i < assetsLength; i++) {
            if (toToken == assets[i]) tokenIndex = i + 1;
        }
        require(tokenIndex != 0, "BalancerAdapter: can't exit");

        bytes memory data = abi.encode(
            uint256(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT),
            amount,
            tokenIndex - 1
        );

        ExitPoolRequest memory request = ExitPoolRequest(
            assets,
            minAmountsOut,
            data,
            false
        );

        balancer.exitPool(
            poolId,
            address(this),
            payable(address(this)),
            request
        );

        return IERC20(toToken).balanceOf(address(this));
    }
}
