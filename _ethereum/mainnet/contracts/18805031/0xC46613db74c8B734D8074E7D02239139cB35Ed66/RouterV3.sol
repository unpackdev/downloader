// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

// CREDIT
import "./ICreditManagerV3.sol";
import "./ICreditConfiguratorV3.sol";
import "./ICreditAccountV3.sol";
import "./GasPricer.sol";

//DATA
import "./PathOption.sol";
import "./ICreditFacadeV3.sol";
import "./Balances.sol";
import "./StrategyPathTask.sol";
import "./RouterResult.sol";
import "./SwapTask.sol";
import "./SwapOperation.sol";
import "./Constants.sol";
import "./PercentageMath.sol";
import "./MultiCall.sol";

// TOKENS AND COMPONENTS
import "./RouterComponent.sol";
import "./TokenType.sol";

// PATHFINDERS
import "./IRouterV3.sol";
import "./IPathResolver.sol";
import "./IClosePathResolver.sol";
import "./ISwapAggregator.sol";
import "./IRouterComponent.sol";
import "./ResolverConfigurator.sol";

struct TokenToTokenType {
    address token;
    uint8 tokenType;
}

struct TokenTypeToResolver {
    uint8 tokenType0;
    uint8 tokenType1;
    uint8 resolver;
}

contract RouterV3 is Ownable, GasPricer, IRouterV3 {
    using BalanceOps for Balance[];
    using MultiCallOps for MultiCall[];
    using PathOptionOps for PathOption[];
    using RouterResultOps for RouterResult;
    using StrategyPathTaskOps for StrategyPathTask;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => uint8) public tokenTypes;
    mapping(uint8 => mapping(uint8 => uint8)) public resolvers;

    mapping(uint8 => address) public override componentAddressById;

    // Contract version
    uint256 public constant version = 3_00;

    EnumerableSet.UintSet connectedResolvers;

    constructor(address _addressProvider, TokenToTokenType[] memory tokenToTokenTypes) GasPricer(_addressProvider) {
        unchecked {
            connectedResolvers.add(uint256(RC_SWAP_AGGREGATOR));
            connectedResolvers.add(uint256(RC_WRAP_AGGREGATOR));
            connectedResolvers.add(uint256(RC_CLOSE_PATH_RESOLVER));
            connectedResolvers.add(uint256(RC_CURVE_LP_PATH_RESOLVER));
            connectedResolvers.add(uint256(RC_BALANCER_LP_PATH_RESOLVER));
            connectedResolvers.add(uint256(RC_YEARN_PATH_RESOLVER));
            connectedResolvers.add(uint256(RC_CONVEX_PATH_RESOLVER));
            connectedResolvers.add(uint256(RC_ERC4626_PATH_RESOLVER));

            uint256 len = tokenToTokenTypes.length;

            for (uint256 i; i < len; i++) {
                TokenToTokenType memory ttt = tokenToTokenTypes[i];
                tokenTypes[ttt.token] = ttt.tokenType;
            }

            TokenTypeToResolver[20] memory ttrs = [
                TokenTypeToResolver({tokenType0: TT_NORMAL_TOKEN, tokenType1: TT_NORMAL_TOKEN, resolver: RC_SWAP_AGGREGATOR}),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_CURVE_LP_TOKEN,
                    resolver: RC_CURVE_LP_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CURVE_LP_TOKEN,
                    tokenType1: TT_CURVE_LP_TOKEN,
                    resolver: RC_CURVE_LP_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_BALANCER_LP_TOKEN,
                    resolver: RC_BALANCER_LP_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_BALANCER_LP_TOKEN,
                    tokenType1: TT_BALANCER_LP_TOKEN,
                    resolver: RC_BALANCER_LP_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_YEARN_ON_NORMAL_TOKEN,
                    resolver: RC_YEARN_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CURVE_LP_TOKEN,
                    tokenType1: TT_YEARN_ON_CURVE_TOKEN,
                    resolver: RC_YEARN_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_YEARN_ON_CURVE_TOKEN,
                    resolver: RC_YEARN_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_CONVEX_LP_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_CONVEX_STAKED_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CURVE_LP_TOKEN,
                    tokenType1: TT_CONVEX_LP_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CURVE_LP_TOKEN,
                    tokenType1: TT_CONVEX_STAKED_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CONVEX_LP_TOKEN,
                    tokenType1: TT_CONVEX_STAKED_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_ERC4626_VAULT_TOKEN,
                    resolver: RC_ERC4626_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CURVE_LP_TOKEN,
                    tokenType1: TT_ERC4626_VAULT_TOKEN,
                    resolver: RC_ERC4626_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_AURA_LP_TOKEN,
                    resolver: RC_AURA_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_AURA_STAKED_TOKEN,
                    resolver: RC_AURA_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_BALANCER_LP_TOKEN,
                    tokenType1: TT_AURA_LP_TOKEN,
                    resolver: RC_AURA_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_BALANCER_LP_TOKEN,
                    tokenType1: TT_AURA_STAKED_TOKEN,
                    resolver: RC_AURA_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_AURA_LP_TOKEN,
                    tokenType1: TT_AURA_STAKED_TOKEN,
                    resolver: RC_AURA_PATH_RESOLVER
                })
            ];

            len = ttrs.length;

            for (uint256 i; i < len; ++i) {
                _setResolver(ttrs[i]);
            }
        }
    }

    function findAllSwaps(SwapTask calldata swapTask, uint256 slippage)
        external
        override
        returns (RouterResult[] memory result)
    {
        StrategyPathTask memory task =
            createStrategyPathTask(swapTask.creditAccount, swapTask.tokenOut, swapTask.connectors, slippage, false);

        if (task.balances.getBalance(swapTask.tokenIn) < swapTask.amount) {
            task.balances.setBalance(swapTask.tokenIn, swapTask.amount);
        }

        task.leftoverBalances = task.balances.clone();
        task.leftoverBalances.setBalance(swapTask.tokenIn, task.balances.getBalance(swapTask.tokenIn) - swapTask.amount);

        task.initSlippageControl();

        StrategyPathTask[] memory tasks = ISwapAggregator(componentAddressById[RC_SWAP_AGGREGATOR]).findAllSwaps(
            swapTask.tokenIn, swapTask.amount, swapTask.swapOperation == SwapOperation.EXACT_INPUT_DIFF, task
        );

        uint256 len = tasks.length;
        result = new RouterResult[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                tasks[i].updateSlippageControl();
                result[i] = tasks[i].toRouterResult();
            }
        }
    }

    function findOneTokenPath(
        address tokenIn,
        uint256 amount,
        address tokenOut,
        address creditAccount,
        address[] calldata connectors,
        uint256 slippage
    ) external override returns (RouterResult memory) {
        StrategyPathTask memory task = createStrategyPathTask(creditAccount, tokenOut, connectors, slippage, false);

        if (task.balances.getBalance(tokenIn) < amount) {
            task.balances.setBalance(tokenIn, amount);
        }

        task.leftoverBalances = task.balances.clone();
        task.leftoverBalances.setBalance(tokenIn, task.balances.getBalance(tokenIn) - amount);

        uint8 ttIn = tokenTypes[tokenIn];
        uint8 ttOut = tokenTypes[task.target];
        task.targetType = ttOut;

        task.initSlippageControl();
        task = getResolver(ttIn, ttOut).findOneTokenPath(ttIn, tokenIn, amount, task);
        task.updateSlippageControl();

        return task.toRouterResult();
    }

    function findOpenStrategyPath(
        address creditManager,
        Balance[] calldata balances,
        Balance[] calldata leftoverBalances,
        address target,
        address[] calldata connectors,
        uint256 slippage
    ) external override returns (Balance[] memory, RouterResult memory) {
        StrategyPathTask memory task = createOpenStrategyPathTask(
            ICreditManagerV3(creditManager), balances, leftoverBalances, target, connectors, slippage
        );

        uint8 ttOut = tokenTypes[task.target];
        task.targetType = ttOut;

        task.initSlippageControl();

        task = getResolver(TT_NORMAL_TOKEN, ttOut).findOpenStrategyPath(task);

        task.updateSlippageControl(ICreditManagerV3(creditManager).creditFacade());

        return (task.balances, task.toRouterResult());
    }

    function findBestClosePath(
        address creditAccount,
        Balance[] calldata expectedBalances,
        Balance[] calldata leftoverBalances,
        address[] calldata connectors,
        uint256 slippage,
        PathOption[] memory pathOptions,
        uint256 loops,
        bool force
    ) external returns (RouterResult memory result, uint256 gasPriceTargetRAY) {
        ICreditManagerV3 creditManager = ICreditManagerV3(ICreditAccountV3(creditAccount).creditManager());

        StrategyPathTask memory task =
            createStrategyPathTask(creditAccount, creditManager.underlying(), connectors, slippage, force);

        task.leftoverBalances = leftoverBalances;

        if (expectedBalances.length > 0) {
            task.balances = expectedBalances;
        }

        task.initSlippageControl();

        task =
            IClosePathResolver(componentAddressById[RC_CLOSE_PATH_RESOLVER]).findBestClosePath(task, pathOptions, loops);

        task.updateSlippageControl();
        return (task.toRouterResult(), task.gasPriceTargetRAY);
    }

    function getResolver(uint8 ttIn, uint8 ttOut) public view returns (IPathResolver) {
        return IPathResolver(componentAddressById[resolvers[ttIn][ttOut]]);
    }

    function isRouterConfigurator(address account) external view returns (bool) {
        return account == owner();
    }

    function createStrategyPathTask(
        address creditAccount,
        address target,
        address[] calldata connectors,
        uint256 slippage,
        bool force
    ) public view returns (StrategyPathTask memory task) {
        ICreditManagerV3 creditManager = ICreditManagerV3(ICreditAccountV3(creditAccount).creditManager());

        uint256 len = creditManager.collateralTokensCount();
        Balance[] memory balances = new Balance[](len);
        {
            for (uint256 i; i < len; ++i) {
                (address token,) = creditManager.collateralTokenByMask(1 << i);
                uint256 balance = IERC20(token).balanceOf(creditAccount);
                balances[i] = Balance({token: token, balance: balance > 10 ? balance : 0});
            }
        }

        MultiCall[] memory calls;

        return StrategyPathTask({
            creditAccount: creditAccount,
            balances: balances,
            leftoverBalances: balances.clone(),
            target: target,
            connectors: connectors,
            adapters: getAdapters(creditManager),
            foundAdapters: new TokenAdapters[](0),
            slippage: slippage,
            gasPriceTargetRAY: getGasPriceTokenOutRAY(target),
            initTargetBalance: 0,
            gasUsage: 0,
            targetType: tokenTypes[target],
            calls: calls,
            force: force
        });
    }

    function createOpenStrategyPathTask(
        ICreditManagerV3 creditManager,
        Balance[] calldata balances,
        Balance[] calldata leftoverBalances,
        address target,
        address[] calldata connectors,
        uint256 slippage
    ) public view returns (StrategyPathTask memory task) {
        MultiCall[] memory calls;

        return StrategyPathTask({
            creditAccount: address(0),
            balances: balances,
            leftoverBalances: leftoverBalances,
            target: target,
            connectors: connectors,
            adapters: getAdapters(creditManager),
            foundAdapters: new TokenAdapters[](0),
            slippage: slippage,
            gasPriceTargetRAY: getGasPriceTokenOutRAY(target),
            initTargetBalance: 0,
            gasUsage: 0,
            targetType: tokenTypes[target],
            calls: calls,
            force: false
        });
    }

    function getAdapters(ICreditManagerV3 creditManager) public view returns (address[] memory result) {
        ICreditConfiguratorV3 configurator = ICreditConfiguratorV3(creditManager.creditConfigurator());
        result = configurator.allowedAdapters();
    }

    ///
    /// CONFIGURATION
    ///

    function setPathComponentBatch(address[] memory componentAddresses) external onlyOwner {
        uint256 len = componentAddresses.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                _setPathComponent(componentAddresses[i]);
            }
        }

        _updatePathComponentsInResolvers();
    }

    function setPathComponent(address componentAddress) external onlyOwner {
        _setPathComponent(componentAddress);
        _updatePathComponentsInResolvers();
    }

    function _setPathComponent(address componentAddress) internal {
        try IRouterComponent(componentAddress).getComponentId() returns (uint8 pfc) {
            if (componentAddressById[pfc] != componentAddress) {
                componentAddressById[pfc] = componentAddress;

                emit RouterComponentUpdate(pfc, componentAddress);
            }
        } catch {
            revert UnsupportedRouterComponent(componentAddress);
        }
    }

    function _updatePathComponentsInResolvers() internal {
        uint256 len = connectedResolvers.length();

        unchecked {
            for (uint256 i; i < len; ++i) {
                uint8 pfc = uint8(connectedResolvers.at(i));
                address resolver = componentAddressById[pfc];

                if (resolver != address(0)) {
                    ResolverConfigurator(resolver).updateComponents();
                }
            }
        }
    }

    function setTokenTypesBatch(TokenToTokenType[] memory tokensToTokenTypes) external onlyOwner {
        uint256 len = tokensToTokenTypes.length;
        for (uint256 i; i < len; i++) {
            _setTokenType(tokensToTokenTypes[i]);
        }
    }

    function _setTokenType(TokenToTokenType memory ttt) internal {
        uint8 groupType = _getGroupTokenType(ttt.tokenType);

        if (tokenTypes[ttt.token] != groupType) {
            tokenTypes[ttt.token] = groupType;
            emit TokenTypeUpdate(ttt.token, ttt.tokenType);
        }
    }

    function _getGroupTokenType(uint8 inputTokenType) internal view returns (uint8) {
        if (
            inputTokenType == TT_DIESEL_LP_TOKEN || inputTokenType == TT_C_TOKEN || inputTokenType == TT_AAVE_V2_A_TOKEN
                || inputTokenType == TT_WRAPPED_AAVE_V2_TOKEN
        ) {
            return TT_WRAPPED_TOKEN;
        }

        return inputTokenType;
    }

    function setResolversBatch(TokenTypeToResolver[] calldata tokenTypeToResolvers) external onlyOwner {
        uint256 len = tokenTypeToResolvers.length;
        for (uint256 i; i < len; i++) {
            _setResolver(tokenTypeToResolvers[i]);
        }
        _updatePathComponentsInResolvers();
    }

    function _setResolver(TokenTypeToResolver memory ttr) internal {
        if (resolvers[ttr.tokenType0][ttr.tokenType1] != ttr.resolver) {
            resolvers[ttr.tokenType0][ttr.tokenType1] = ttr.resolver;
            resolvers[ttr.tokenType1][ttr.tokenType0] = ttr.resolver;

            if (ttr.tokenType0 == TT_NORMAL_TOKEN && ttr.tokenType1 == TT_NORMAL_TOKEN) {
                resolvers[TT_WRAPPED_TOKEN][TT_WRAPPED_TOKEN] = ttr.resolver;
            }

            if (ttr.tokenType0 == TT_NORMAL_TOKEN) {
                resolvers[TT_WRAPPED_TOKEN][ttr.tokenType1] = ttr.resolver;
            }

            if (ttr.tokenType1 == TT_NORMAL_TOKEN) {
                resolvers[ttr.tokenType0][TT_WRAPPED_TOKEN] = ttr.resolver;
            }

            connectedResolvers.add(uint256(ttr.resolver));

            emit ResolverUpdate(ttr.tokenType0, ttr.tokenType1, ttr.resolver);
        }
    }
}
