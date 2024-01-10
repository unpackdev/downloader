// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./AccessControl.sol";

import "./IWrappedEther.sol";
import "./IExchangeAdapter.sol";

contract Exchange is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;

    // struct size - 64 bytes, 2 slots
    struct RouteEdge {
        uint32 swapProtocol; // 0 - unknown edge, 1 - UniswapV2, 2 - Curve...
        address pool; // address of pool to call
        address fromCoin; // address of coin to deposit to pool
        address toCoin; // address of coin to get from pool
    }

    // struct size - 32 bytes, 1 slots
    struct LpToken {
        uint32 swapProtocol; // 0 - unknown edge, 1 - UniswapV2, 2 - Curve...
        address pool; // address of pool to call
    }

    // returns true if address is registered as major token, false otherwise
    mapping(address => bool) public isMajorCoin;

    // returns true if pool received approve of token. First address is pool,
    // second is token
    mapping(address => mapping(address => bool)) public approveCompleted;

    // Storage of routes between major coins. Normally, any major coin should
    // have route to any other major coin that is saved here
    mapping(address => mapping(address => RouteEdge[]))
        private internalMajorRoute;

    // Storage of single edges from minor coin to major
    mapping(address => RouteEdge) public minorCoins;

    // Storage of LP tokens that are registeres in exchange
    mapping(address => LpToken) public lpTokens;

    // Storage of swap execution method for different protocols
    mapping(uint32 => address) public adapters;

    // Wrapped ether token that is used for native ether swaps
    IWrappedEther public wrappedEther =
        IWrappedEther(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // bytes4(keccak256(bytes("executeSwap(address,address,address,uint256)")))
    bytes4 public constant executeSwapSigHash = 0x6012856e;

    // bytes4(keccak256(bytes("enterPool(address,address,uint256)")))
    bytes4 public constant enterPoolSigHash = 0x73ec962e;

    // bytes4(keccak256(bytes("exitPool(address,address,uint256)")))
    bytes4 public constant exitPoolSigHash = 0x660cb8d4;

    constructor(address gnosis, bool isTesting) {
        require(gnosis.isContract(), "Exchange: not contract");
        _grantRole(DEFAULT_ADMIN_ROLE, gnosis);
        if (isTesting) _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Execute exchange of coins through predefined routes
    /// @param from swap input token
    /// @param to swap output token
    /// @param amountIn amount of `from `tokens to be taken from caller
    /// @param minAmountOut minimum amount of output tokens, revert if less
    /// @return Amount of tokens that are returned
    function exchange(
        address from,
        address to,
        uint256 amountIn,
        uint256 minAmountOut
    ) external payable nonReentrant returns (uint256) {
        require(from != to, "Exchange: from == to");

        if (lpTokens[to].swapProtocol != 0) {
            IERC20(from).safeTransferFrom(msg.sender, address(this), amountIn);

            uint256 amountOut = _enterLiquidityPool(from, to, amountIn);
            require(amountOut >= minAmountOut, "Exchange: slippage");

            IERC20(to).safeTransfer(msg.sender, amountOut);

            return amountOut;
        }

        if (lpTokens[from].swapProtocol != 0) {
            IERC20(from).safeTransferFrom(msg.sender, address(this), amountIn);

            uint256 amountOut = _exitLiquidityPool(from, to, amountIn);
            require(amountOut >= minAmountOut, "Exchange: slippage");

            IERC20(to).safeTransfer(msg.sender, amountOut);

            return amountOut;
        }

        if (
            from == address(0) ||
            from == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) {
            require(
                to != address(0) &&
                    to != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                "Exchange: ETH to ETH"
            );
            require(amountIn == msg.value, "Exchange: value/amount discrep");

            wrappedEther.deposit{value: msg.value}();

            uint256 amountOut = _exchange(address(wrappedEther), to, amountIn);
            require(amountOut >= minAmountOut, "Exchange: slippage");
            IERC20(to).safeTransfer(msg.sender, amountOut);

            return amountOut;
        }

        IERC20(from).safeTransferFrom(msg.sender, address(this), amountIn);

        if (
            to == address(0) || to == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) {
            uint256 amountOut = _exchange(
                from,
                address(wrappedEther),
                amountIn
            );
            require(amountOut >= minAmountOut, "Exchange: slippage");

            wrappedEther.withdraw(amountOut);

            Address.sendValue(payable(msg.sender), amountOut);

            return amountOut;
        }
        uint256 amountOut_ = _exchange(from, to, amountIn);

        require(amountOut_ >= minAmountOut, "Exchange: slippage");

        IERC20(to).safeTransfer(msg.sender, amountOut_);

        return amountOut_;
    }

    /// @notice Register swap/lp token adapters
    /// @param protocolId protocol id of adapter to add
    function registerAdapters(
        address[] calldata adapters_,
        uint32[] calldata protocolId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = adapters_.length;
        require(
            adapters_.length == protocolId.length,
            "Exchange: length discrep"
        );
        for (uint256 i = 0; i < length; i++) {
            adapters[protocolId[i]] = adapters_[i];
        }
    }

    /// @notice Unregister swap/lp token adapters
    /// @param protocolId protocol id of adapter to remove
    function unregisterAdapters(uint32[] calldata protocolId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = protocolId.length;
        for (uint256 i = 0; i < length; i++) {
            delete adapters[protocolId[i]];
        }
    }

    /// @notice Create single edge of a route from minor coin to major
    /// @dev In order for swap from/to minor coin to be working, `toCoin` should
    /// be registered as major
    /// @param edges array of edges to store
    function createMinorCoinEdge(RouteEdge[] calldata edges)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = edges.length;
        for (uint256 i = 0; i < length; i++) {
            // validate protocol id - zero is interpreted as
            // non-existing route
            require(edges[i].swapProtocol != 0, "Exchange: protocol type !set");
            require(
                edges[i].fromCoin != edges[i].toCoin,
                "Exchange: edge is loop"
            );

            if (!approveCompleted[edges[i].pool][edges[i].fromCoin]) {
                IERC20(edges[i].fromCoin).safeApprove(
                    edges[i].pool,
                    type(uint256).max
                );
                approveCompleted[edges[i].pool][edges[i].fromCoin] = true;
            }

            if (!approveCompleted[edges[i].pool][edges[i].toCoin]) {
                IERC20(edges[i].toCoin).safeApprove(
                    edges[i].pool,
                    type(uint256).max
                );
                approveCompleted[edges[i].pool][edges[i].toCoin] = true;
            }

            minorCoins[edges[i].fromCoin] = edges[i];
        }
    }

    /// @notice Remove internal minor route piece
    /// @param edges source coin of route to delete
    function deleteMinorCoinEdge(address[] calldata edges)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < edges.length; i++) {
            delete minorCoins[edges[i]];
        }
    }

    /// @notice Create route between two tokens and set them as major
    /// @param routes array of routes
    function createInternalMajorRoutes(RouteEdge[][] calldata routes)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < routes.length; i++) {
            RouteEdge[] memory route = routes[i];

            // extract start and beginning of given route
            address start = route[0].fromCoin;
            address end = route[route.length - 1].toCoin;
            require(start != end, "Exchange: route is loop");

            if (internalMajorRoute[start][end].length != 0) {
                delete internalMajorRoute[start][end];
            }

            // validate protocol id - zero is interpreted as non-existing route
            require(route[0].swapProtocol != 0, "Exchange: protocol type !set");

            // set approve of the token to the pool
            if (!approveCompleted[route[0].pool][route[0].fromCoin]) {
                IERC20(route[0].fromCoin).safeApprove(
                    route[0].pool,
                    type(uint256).max
                );
                approveCompleted[route[0].pool][route[0].fromCoin] = true;
            }

            require(
                route[0].fromCoin != route[0].toCoin,
                "Exchange: edge is loop"
            );

            // starting to save this route
            internalMajorRoute[start][end].push(route[0]);

            // if route is simple, then we've done everything for it
            if (route.length == 1) {
                // as route between these coins is set, we consider them as major
                isMajorCoin[start] = true;
                isMajorCoin[end] = true;

                continue;
            }

            // loop through whole route to check its continuity
            address node = route[0].toCoin;
            for (uint256 j = 1; j < route.length; j++) {
                require(route[j].fromCoin == node, "Exchange: route broken");
                node = route[j].toCoin;

                // validate protocol id - zero is interpreted as
                // non-existing route
                require(
                    route[j].swapProtocol != 0,
                    "Exchange: protocol type !set"
                );

                require(
                    route[j].fromCoin != route[j].toCoin,
                    "Exchange: edge is loop"
                );

                // set approve of the token to the pool
                if (!approveCompleted[route[j].pool][route[j].fromCoin]) {
                    IERC20(route[j].fromCoin).safeApprove(
                        route[j].pool,
                        type(uint256).max
                    );
                    approveCompleted[route[j].pool][route[j].fromCoin] = true;
                }

                // continiuing to save this route
                internalMajorRoute[start][end].push(route[j]);
            }

            // as route between these coins is set, we consider them as major
            isMajorCoin[start] = true;
            isMajorCoin[end] = true;
        }
    }

    /// @notice Remove internal major routes and unregister them on demand
    /// @param from source coin of route to delete
    /// @param to destination coin of route to delete
    /// @param removeMajor true if need to no longer recognize source and destination coin as major
    function deleteInternalMajorRoutes(
        address[] calldata from,
        address[] calldata to,
        bool removeMajor
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(from.length == to.length, "Exchange: length discrep");
        for (uint256 i = 0; i < from.length; i++) {
            delete internalMajorRoute[from[i]][to[i]];
            if (removeMajor) {
                isMajorCoin[from[i]] = false;
                isMajorCoin[to[i]] = false;
            }
        }
    }

    /// @notice Force unapprove of some coin to any pool
    /// @param coins coins list
    /// @param spenders pools list
    function removeApproval(
        address[] calldata coins,
        address[] calldata spenders
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(coins.length == spenders.length, "Exchange: length discrep");
        for (uint256 i = 0; i < coins.length; i++) {
            IERC20(coins[i]).safeApprove(spenders[i], 0);
            approveCompleted[spenders[i]][coins[i]] = false;
        }
    }

    /// @notice Force approve of some coin to any pool
    /// @param coins coins list
    /// @param spenders pools list
    function createApproval(
        address[] calldata coins,
        address[] calldata spenders
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(coins.length == spenders.length, "Exchange: length discrep");
        for (uint256 i = 0; i < coins.length; i++) {
            IERC20(coins[i]).safeApprove(spenders[i], type(uint256).max);
            approveCompleted[spenders[i]][coins[i]] = true;
        }
    }

    /// @notice Add all info for enabling LP token swap and set up coin approval
    /// @param edges info about protocol type and pools
    /// @param lpTokensAddress coins that will be recognized as LP tokens
    /// @param entryCoins coins which require approval to pool
    function createLpToken(
        LpToken[] calldata edges,
        address[] calldata lpTokensAddress,
        address[][] calldata entryCoins
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            edges.length == entryCoins.length &&
                entryCoins.length == lpTokensAddress.length,
            "Exchange: length discrep"
        );
        for (uint256 i = 0; i < edges.length; i++) {
            LpToken memory edge = edges[i];
            require(edge.swapProtocol != 0, "Exchange: protocol type !set");

            for (uint256 j = 0; j < entryCoins[i].length; j++) {
                if (!approveCompleted[edge.pool][entryCoins[i][j]]) {
                    IERC20(entryCoins[i][j]).safeApprove(
                        edge.pool,
                        type(uint256).max
                    );
                    approveCompleted[edge.pool][entryCoins[i][j]] = true;
                }
            }

            lpTokens[lpTokensAddress[i]] = edge;
        }
    }

    /// @notice Set addresses to be no longer recognized as LP tokens
    /// @param edges list of LP tokens
    function deleteLpToken(address[] calldata edges)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < edges.length; i++) {
            delete lpTokens[edges[i]];
        }
    }

    /// @inheritdoc	AccessControl
    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        require(account.isContract(), "Exchange: not contract");
        _grantRole(role, account);
    }

    /// @notice Build highest liquidity swap route between two ERC20 coins
    /// @param from address of coin to start route from
    /// @param to address of route destination coin
    /// @return route containing liquidity pool addresses
    function buildRoute(address from, address to)
        public
        view
        returns (RouteEdge[] memory)
    {
        bool isFromMajorCoin = isMajorCoin[from];
        bool isToMajorCoin = isMajorCoin[to];

        if (isFromMajorCoin && isToMajorCoin) {
            // Moscow - Heathrow
            // in this case route of major coins is predefined
            RouteEdge[] memory majorToMajor = internalMajorRoute[from][to];

            // check if this part of route exists
            require(
                majorToMajor.length > 0,
                "Exchange: 1!path from major coin"
            );

            return majorToMajor;
        } else if (!isFromMajorCoin && isToMajorCoin) {
            // Tomsk - Heathrow
            // getting predefined route from minor coin to major coin
            RouteEdge memory minorToMajor = minorCoins[from];

            // revert if route is not predefined
            require(
                minorToMajor.swapProtocol != 0,
                "Exchange: 2!path from input coin"
            );

            // if predefined route from minor to major coin is what we wanted
            // to get, simply return it
            if (minorToMajor.toCoin == to) {
                RouteEdge[] memory result = new RouteEdge[](1);
                result[0] = minorToMajor;
                return result;
            }

            // find continuation of the route, if these major coins don't match
            RouteEdge[] memory majorToMajor = internalMajorRoute[
                minorToMajor.toCoin
            ][to];

            // check if this part of route exists
            require(
                majorToMajor.length > 0,
                "Exchange: 2!path from major coin"
            );

            // concatenate route and return it
            RouteEdge[] memory route = new RouteEdge[](majorToMajor.length + 1);
            route[0] = minorToMajor;

            for (uint256 i = 0; i < majorToMajor.length; i++) {
                route[i + 1] = majorToMajor[i];
            }

            return route;
        } else if (isFromMajorCoin && !isToMajorCoin) {
            // Heathrow - Sochi
            // getting predefined route from any major coin to target minor coin
            RouteEdge memory majorToMinor = reverseRouteEdge(minorCoins[to]);

            // revert if route is not predefined
            require(
                majorToMinor.swapProtocol != 0,
                "Exchange: 3!path from input coin"
            );

            // if predefined route from major to minor coin is what we wanted
            // to get, simply return it
            if (majorToMinor.fromCoin == from) {
                RouteEdge[] memory result = new RouteEdge[](1);
                result[0] = majorToMinor;
                return result;
            }

            // find beginning of route from start major coin to major coin
            // that is linked to destination
            RouteEdge[] memory majorToMajor = internalMajorRoute[from][
                majorToMinor.fromCoin
            ];

            // check if this part of route exists
            require(
                majorToMajor.length > 0,
                "Exchange: 3!path from major coin"
            );

            // concatenate route and return it
            RouteEdge[] memory route = new RouteEdge[](majorToMajor.length + 1);
            route[majorToMajor.length] = majorToMinor;

            for (uint256 i = 0; i < majorToMajor.length; i++) {
                route[i] = majorToMajor[i];
            }

            return route;
        } else {
            // Chelyabinsk - Glasgow
            //       minor - minor
            // get paths from source and target coin to
            // corresponding major coins
            RouteEdge memory minorToMajor = minorCoins[from];
            RouteEdge memory majorToMinor = reverseRouteEdge(minorCoins[to]);

            // revert if routes are not predefined
            require(
                minorToMajor.swapProtocol != 0,
                "Exchange: 4!path from input coin"
            );
            require(
                majorToMinor.swapProtocol != 0,
                "Exchange: 4!path from out coin"
            );

            // if these paths overlap on one coin, simply return it
            if (minorToMajor.toCoin == majorToMinor.fromCoin) {
                RouteEdge[] memory result = new RouteEdge[](2);
                result[0] = minorToMajor;
                result[1] = majorToMinor;
                return result;
            }

            // connect input and output coins with major coins
            RouteEdge[] memory majorToMajor = internalMajorRoute[
                minorToMajor.toCoin
            ][majorToMinor.fromCoin];

            // check if this part of route exists
            require(
                majorToMajor.length > 0,
                "Exchange: 4!path from major coin"
            );

            // concatenate route and return it
            RouteEdge[] memory route = new RouteEdge[](majorToMajor.length + 2);
            route[0] = minorToMajor;
            route[majorToMajor.length + 1] = majorToMinor;

            for (uint256 i = 0; i < majorToMajor.length; i++) {
                route[i + 1] = majorToMajor[i];
            }

            return route;
        }
    }

    /// @notice Get prebuilt route between two major coins
    /// @param from major coin to start route from
    /// @param to major coin that should be end of route
    /// @return Prebuilt route between major coins
    function getMajorRoute(address from, address to)
        external
        view
        returns (RouteEdge[] memory)
    {
        return internalMajorRoute[from][to];
    }

    function _exchange(
        address from,
        address to,
        uint256 amountIn
    ) private returns (uint256) {
        // this code was written at late evening of 14 Feb
        // i would like to say to solidity: i love you <3
        // you're naughty bitch, but anyway

        RouteEdge[] memory edges = buildRoute(from, to);

        uint256 swapAmount = amountIn;
        for (uint256 i = 0; i < edges.length; i++) {
            RouteEdge memory edge = edges[i];

            address adapter = adapters[edge.swapProtocol];
            require(adapter != address(0), "Exchange: adapter not found");

            // using delegatecall for gas savings (no need to transfer tokens
            // to/from adapter)
            bytes memory returnedData = adapter.functionDelegateCall(
                abi.encodeWithSelector(
                    executeSwapSigHash,
                    edge.pool,
                    edge.fromCoin,
                    edge.toCoin,
                    swapAmount
                )
            );
            // extract return value from delegatecall
            swapAmount = abi.decode(returnedData, (uint256));
        }

        return swapAmount;
    }

    function _enterLiquidityPool(
        address from,
        address to,
        uint256 amountIn
    ) private returns (uint256) {
        LpToken memory edge = lpTokens[to];
        address adapter = adapters[edge.swapProtocol];
        require(adapter != address(0), "Exchange: adapter not found");

        // using delegatecall for gas savings (no need to transfer tokens
        // to adapter)
        bytes memory returnedData = adapter.functionDelegateCall(
            abi.encodeWithSelector(enterPoolSigHash, edge.pool, from, amountIn)
        );
        // extract return value from delegatecall
        return abi.decode(returnedData, (uint256));
    }

    function _exitLiquidityPool(
        address from,
        address to,
        uint256 amountIn
    ) private returns (uint256) {
        LpToken memory edge = lpTokens[from];
        address adapter = adapters[edge.swapProtocol];
        require(adapter != address(0), "Exchange: adapter not found");

        // using delegatecall for gas savings (no need to transfer tokens
        // to adapter)
        bytes memory returnedData = adapter.functionDelegateCall(
            abi.encodeWithSelector(exitPoolSigHash, edge.pool, to, amountIn)
        );
        // extract return value from delegatecall
        return abi.decode(returnedData, (uint256));
    }

    function reverseRouteEdge(RouteEdge memory route)
        private
        pure
        returns (RouteEdge memory)
    {
        address cache = route.fromCoin;
        route.fromCoin = route.toCoin;
        route.toCoin = cache;

        return route;
    }

    receive() external payable {}
}
