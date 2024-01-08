// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

abstract contract BalancerOwnable {
    function setController(address controller) external virtual;
}

abstract contract AbstractPool is BalancerOwnable {
    function setSwapFee(uint256 swapFee) external virtual;

    function setPublicSwap(bool public_) external virtual;

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external
        virtual;

    function totalSupply() external virtual returns (uint256);
}

abstract contract ConfigurableRightsPool is AbstractPool {
    struct PoolParams {
        string poolTokenSymbol;
        string poolTokenName;
        address[] constituentTokens;
        uint256[] tokenBalances;
        uint256[] tokenWeights;
        uint256 swapFee;
    }

    struct CrpParams {
        uint256 initialSupply;
        uint256 minimumWeightChangeBlockPeriod;
        uint256 addTokenTimeLockInBlocks;
    }

    function createPool(
        uint256 initialSupply,
        uint256 minimumWeightChangeBlockPeriod,
        uint256 addTokenTimeLockInBlocks
    ) external virtual;

    function createPool(uint256 initialSupply) external virtual;

    function setCap(uint256 newCap) external virtual;

    function updateWeight(address token, uint256 newWeight) external virtual;

    function updateWeightsGradually(
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock
    ) external virtual;

    function commitAddToken(
        address token,
        uint256 balance,
        uint256 denormalizedWeight
    ) external virtual;

    function applyAddToken() external virtual;

    function removeToken(address token) external virtual;

    function whitelistLiquidityProvider(address provider) external virtual;

    function removeWhitelistedLiquidityProvider(address provider)
        external
        virtual;

    function bPool() external view virtual returns (BPool);
}

abstract contract BPool is AbstractPool {
    function finalize() external virtual;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external virtual;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external virtual;

    function unbind(address token) external virtual;

    function isBound(address t) external view virtual returns (bool);

    function getCurrentTokens()
        external
        view
        virtual
        returns (address[] memory);

    function getFinalTokens() external view virtual returns (address[] memory);

    function getBalance(address token) external view virtual returns (uint256);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure virtual returns (uint256 poolAmountOut);

    function calcPoolInGivenSingleOut(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure virtual returns (uint256 poolAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure virtual returns (uint256 poolAmountIn);

    function getDenormalizedWeight(address token)
        external
        view
        virtual
        returns (uint256);

    function getTotalDenormalizedWeight()
        external
        view
        virtual
        returns (uint256);

    function getSwapFee() external view virtual returns (uint256);
}

abstract contract ISmartPool is BalancerOwnable {
    function updateWeightsGradually(
        uint256[] memory,
        uint256,
        uint256
    ) external virtual;

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external virtual returns (uint256);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external virtual returns (uint256);

    function approve(address spender, uint256 value)
        external
        virtual
        returns (bool);

    function balanceOf(address owner) external view virtual returns (uint256);

    function totalSupply() external view virtual returns (uint256);

    function setSwapFee(uint256 swapFee) external virtual;

    function setPublicSwap(bool public_) external virtual;

    function getDenormalizedWeight(address token)
        external
        view
        virtual
        returns (uint256);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external
        virtual;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external
        virtual;

    function bPool() external view virtual returns (BPool);

    function applyAddToken() external virtual;

    function getSmartPoolManagerVersion()
        external
        view
        virtual
        returns (address);
}

abstract contract SmartPoolManager {
    function joinPool(
        ConfigurableRightsPool,
        BPool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external view virtual returns (uint256[] memory actualAmountsIn);

    function exitPool(
        ConfigurableRightsPool self,
        BPool bPool,
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    )
        external
        view
        virtual
        returns (
            uint256 exitFee,
            uint256 pAiAfterExitFee,
            uint256[] memory actualAmountsOut
        );

    function joinswapExternAmountIn(
        ConfigurableRightsPool self,
        BPool bPool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external view virtual returns (uint256 poolAmountOut);
}
