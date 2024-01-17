// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

// CREDIT
import "./ICreditManagerV2.sol";
import "./ICreditConfigurator.sol";
import "./ICreditAccount.sol";
import "./GasPricer.sol";

//DATA
import "./PathOption.sol";
import "./MultiCall.sol";
import "./Balances.sol";
import "./StrategyPathTask.sol";
import "./RouterResult.sol";
import "./SwapTask.sol";
import "./SwapQuote.sol";
import "./SwapOperation.sol";
import "./Constants.sol";
import "./PercentageMath.sol";

// PATHFINDERS
import "./IRouter.sol";
import "./IPathResolver.sol";
import "./IClosePathResolver.sol";
import "./ISwapAggregator.sol";
import "./IRouterComponent.sol";
import "./ResolverConfigurator.sol";

struct TokenToTokenType {
    address token;
    TokenType tokenType;
}

struct TokenTypeToResolver {
    TokenType tokenType0;
    TokenType tokenType1;
    RouterComponent resolver;
}

contract Router is Ownable, GasPricer, IRouter {
    using BalanceOps for Balance[];
    using MultiCallOps for MultiCall[];
    using PathOptionOps for PathOption[];
    using RouterResultOps for RouterResult;
    using StrategyPathTaskOps for StrategyPathTask;
    using SwapQuoteOps for SwapQuote;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => TokenType) public tokenTypes;
    mapping(TokenType => mapping(TokenType => RouterComponent))
        public resolvers;

    mapping(RouterComponent => address) public override componentAddressById;

    // Contract version
    uint256 public constant version = 1;

    EnumerableSet.UintSet connectedResolvers;

    constructor(
        address _addressProvider,
        TokenToTokenType[] memory tokenToTokenTypes
    ) GasPricer(_addressProvider) {
        unchecked {
            connectedResolvers.add(uint256(RouterComponent.SWAP_AGGREGATOR));
            connectedResolvers.add(
                uint256(RouterComponent.CLOSE_PATH_RESOLVER)
            );
            connectedResolvers.add(
                uint256(RouterComponent.CURVE_LP_PATH_RESOLVER)
            );
            connectedResolvers.add(
                uint256(RouterComponent.YEARN_PATH_RESOLVER)
            );
            connectedResolvers.add(
                uint256(RouterComponent.CONVEX_PATH_RESOLVER)
            );

            uint256 len = tokenToTokenTypes.length;

            for (uint256 i; i < len; i++) {
                TokenToTokenType memory ttt = tokenToTokenTypes[i];
                tokenTypes[ttt.token] = ttt.tokenType;
            }

            TokenTypeToResolver[11] memory ttrs = [
                TokenTypeToResolver({
                    tokenType0: TokenType.NORMAL_TOKEN,
                    tokenType1: TokenType.NORMAL_TOKEN,
                    resolver: RouterComponent.SWAP_AGGREGATOR
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.NORMAL_TOKEN,
                    tokenType1: TokenType.CURVE_LP_TOKEN,
                    resolver: RouterComponent.CURVE_LP_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.CURVE_LP_TOKEN,
                    tokenType1: TokenType.CURVE_LP_TOKEN,
                    resolver: RouterComponent.CURVE_LP_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.NORMAL_TOKEN,
                    tokenType1: TokenType.YEARN_ON_NORMAL_TOKEN,
                    resolver: RouterComponent.YEARN_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.CURVE_LP_TOKEN,
                    tokenType1: TokenType.YEARN_ON_CURVE_TOKEN,
                    resolver: RouterComponent.YEARN_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.NORMAL_TOKEN,
                    tokenType1: TokenType.YEARN_ON_CURVE_TOKEN,
                    resolver: RouterComponent.YEARN_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.NORMAL_TOKEN,
                    tokenType1: TokenType.CONVEX_LP_TOKEN,
                    resolver: RouterComponent.CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.NORMAL_TOKEN,
                    tokenType1: TokenType.CONVEX_STAKED_TOKEN,
                    resolver: RouterComponent.CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.CURVE_LP_TOKEN,
                    tokenType1: TokenType.CONVEX_LP_TOKEN,
                    resolver: RouterComponent.CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.CURVE_LP_TOKEN,
                    tokenType1: TokenType.CONVEX_STAKED_TOKEN,
                    resolver: RouterComponent.CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TokenType.CONVEX_LP_TOKEN,
                    tokenType1: TokenType.CONVEX_STAKED_TOKEN,
                    resolver: RouterComponent.CONVEX_PATH_RESOLVER
                })
            ];

            len = ttrs.length;

            for (uint256 i; i < len; ++i) {
                _setResolver(ttrs[i]);
            }
        }
    }

    function findAllSwaps(SwapTask calldata swapTask)
        external
        override
        returns (RouterResult[] memory result)
    {
        StrategyPathTask memory task = createStrategyPathTask(
            swapTask.creditAccount,
            swapTask.tokenOut,
            swapTask.connectors,
            swapTask.slippage,
            false
        );

        if (task.balances.getBalance(swapTask.tokenIn) < swapTask.amount) {
            task.balances.setBalance(swapTask.tokenIn, swapTask.amount);
        }

        task.initTargetBalance = task.balances.getBalance(task.target);

        StrategyPathTask[] memory tasks = ISwapAggregator(
            componentAddressById[RouterComponent.SWAP_AGGREGATOR]
        ).findAllSwaps(
                swapTask.tokenIn,
                swapTask.amount,
                swapTask.swapOperation == SwapOperation.EXACT_INPUT_ALL,
                task
            );

        uint256 len = tasks.length;
        result = new RouterResult[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
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
        StrategyPathTask memory task = createStrategyPathTask(
            creditAccount,
            tokenOut,
            connectors,
            slippage,
            false
        );

        if (task.balances.getBalance(tokenIn) < amount) {
            task.balances.setBalance(tokenIn, amount);
        }

        TokenType ttIn = tokenTypes[tokenIn];
        TokenType ttOut = tokenTypes[task.target];
        task.targetType = ttOut;

        task.initSlippageControl();
        task = getResolver(ttIn, ttOut).findOneTokenPath(
            ttIn,
            tokenIn,
            amount,
            task
        );
        task.updateSlippageControl();

        return task.toRouterResult();
    }

    function findOpenStrategyPath(
        address creditManager,
        Balance[] calldata balances,
        address target,
        address[] calldata connectors,
        uint256 slippage
    ) external override returns (Balance[] memory, RouterResult memory) {
        StrategyPathTask memory task = createOpenStrategyPathTask(
            ICreditManagerV2(creditManager),
            balances,
            target,
            connectors,
            slippage
        );

        TokenType ttOut = tokenTypes[task.target];
        task.targetType = ttOut;

        task.initSlippageControl();

        task = getResolver(TokenType.NORMAL_TOKEN, ttOut).findOpenStrategyPath(
            task
        );

        task.updateSlippageControl(
            ICreditManagerV2(creditManager).creditFacade()
        );

        return (task.balances, task.toRouterResult());
    }

    function findBestClosePath(
        address creditAccount,
        address[] calldata connectors,
        uint256 slippage,
        PathOption[] memory pathOptions,
        uint256 loops,
        bool force
    ) external returns (RouterResult memory result, uint256 gasPriceTargetRAY) {
        ICreditManagerV2 creditManager = ICreditManagerV2(
            ICreditAccount(creditAccount).creditManager()
        );

        StrategyPathTask memory task = createStrategyPathTask(
            creditAccount,
            creditManager.underlying(),
            connectors,
            slippage,
            force
        );

        task.initSlippageControl();

        task = IClosePathResolver(
            componentAddressById[RouterComponent.CLOSE_PATH_RESOLVER]
        ).findBestClosePath(task, pathOptions, loops);

        task.updateSlippageControl();
        return (task.toRouterResult(), task.gasPriceTargetRAY);
    }

    function getResolver(TokenType ttIn, TokenType ttOut)
        public
        view
        returns (IPathResolver)
    {
        return IPathResolver(componentAddressById[resolvers[ttIn][ttOut]]);
    }

    function isRouterConfigurator(address account)
        external
        view
        returns (bool)
    {
        return account == owner();
    }

    function createStrategyPathTask(
        address creditAccount,
        address target,
        address[] calldata connectors,
        uint256 slippage,
        bool force
    ) public view returns (StrategyPathTask memory task) {
        ICreditManagerV2 creditManager = ICreditManagerV2(
            ICreditAccount(creditAccount).creditManager()
        );

        Balance[] memory balances;

        uint256 len = creditManager.collateralTokensCount();
        balances = new Balance[](len);
        {
            for (uint256 i; i < len; ++i) {
                (address token, ) = creditManager.collateralTokens(i);
                uint256 balance = IERC20(token).balanceOf(creditAccount);
                balances[i] = Balance({
                    token: token,
                    balance: balance > 10 ? balance : 0
                });
            }
        }

        MultiCall[] memory calls;

        return
            StrategyPathTask({
                creditAccount: creditAccount,
                balances: balances,
                target: target,
                connectors: connectors,
                adapters: getAdapters(creditManager),
                foundAdapters: new TokenAdapters[](0),
                slippagePerStep: slippage,
                gasPriceTargetRAY: getGasPriceTokenOutRAY(target),
                initTargetBalance: 0,
                gasUsage: 0,
                targetType: tokenTypes[target],
                calls: calls,
                force: force
            });
    }

    function createOpenStrategyPathTask(
        ICreditManagerV2 creditManager,
        Balance[] calldata balances,
        address target,
        address[] calldata connectors,
        uint256 slippage
    ) public view returns (StrategyPathTask memory task) {
        MultiCall[] memory calls;

        return
            StrategyPathTask({
                creditAccount: address(0),
                balances: balances,
                target: target,
                connectors: connectors,
                adapters: getAdapters(creditManager),
                foundAdapters: new TokenAdapters[](0),
                slippagePerStep: slippage,
                gasPriceTargetRAY: getGasPriceTokenOutRAY(target),
                initTargetBalance: 0,
                gasUsage: 0,
                targetType: tokenTypes[target],
                calls: calls,
                force: false
            });
    }

    function getAdapters(ICreditManagerV2 creditManager)
        public
        view
        returns (address[] memory result)
    {
        ICreditConfigurator configurator = ICreditConfigurator(
            creditManager.creditConfigurator()
        );
        address[] memory allowedContracts = configurator.allowedContracts();

        uint256 len = allowedContracts.length;
        result = new address[](len);
        for (uint256 i; i < len; ) {
            result[i] = creditManager.contractToAdapter(allowedContracts[i]);
            unchecked {
                ++i;
            }
        }
    }

    ///
    /// CONFIGURATION
    ///

    function setPathComponentBatch(address[] memory componentAddresses)
        external
        onlyOwner
    {
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
        try IRouterComponent(componentAddress).getComponentId() returns (
            RouterComponent pfc
        ) {
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
                RouterComponent pfc = RouterComponent(
                    uint8(connectedResolvers.at(i))
                );
                address resolver = componentAddressById[pfc];

                if (resolver != address(0)) {
                    ResolverConfigurator(resolver).updateComponents();
                }
            }
        }
    }

    function setTokenTypesBatch(TokenToTokenType[] memory tokensToTokenTypes)
        external
        onlyOwner
    {
        uint256 len = tokensToTokenTypes.length;
        for (uint256 i; i < len; i++) {
            _setTokenType(tokensToTokenTypes[i]);
        }
    }

    function _setTokenType(TokenToTokenType memory ttt) internal {
        if (tokenTypes[ttt.token] != ttt.tokenType) {
            tokenTypes[ttt.token] = ttt.tokenType;
            emit TokenTypeUpdate(ttt.token, ttt.tokenType);
        }
    }

    function setResolversBatch(
        TokenTypeToResolver[] calldata tokenTypeToResolvers
    ) external onlyOwner {
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

            emit ResolverUpdate(ttr.tokenType0, ttr.tokenType1, ttr.resolver);
        }
    }
}
