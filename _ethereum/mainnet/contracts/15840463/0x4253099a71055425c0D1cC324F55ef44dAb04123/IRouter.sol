// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./Balances.sol";
import "./RouterResult.sol";
import "./PathOption.sol";
import "./TokenType.sol";
import "./IVersion.sol";
import "./IGasPricer.sol";
import "./RouterComponent.sol";
import "./SwapTask.sol";

error PathNotFoundExceptionTyped(TokenType ttIn, address tokenOut);
error PathNotFoundException(address tokenIn, address tokenOut);
error PathToTargetNotFound(address tokenOut);
error UnsupportedAdapterType();
error UnsupportedRouterComponent(address);

interface IRouter is IGasPricer, IVersion {
    /// @dev Emits each time when routerComponent is set / updated
    event RouterComponentUpdate(RouterComponent indexed, address indexed);

    /// @dev Emits each time when resolver is set / updated
    event ResolverUpdate(
        TokenType indexed,
        TokenType indexed,
        RouterComponent indexed
    );

    event TokenTypeUpdate(address indexed, TokenType indexed);

    /// @dev Finds all available swaps for NORMAL tokens
    function findAllSwaps(SwapTask memory swapTask)
        external
        returns (RouterResult[] memory);

    /// @dev Finds best path to swap all Normal tokens and tokens "on the way" to target one and vice versa
    function findOneTokenPath(
        address tokenIn,
        uint256 amount,
        address tokenOut,
        address creditAccount,
        address[] calldata connectors,
        uint256 slippage
    ) external returns (RouterResult memory);

    /// @dev Finds the best swap to deposit (or swap) all provided tokens into target one
    /// Currently it takes ALL Normal tokens and all LP "on the way" tokens into target one.
    /// It some token is not "on the way" it would be skipped.
    /// @param creditManager Address of creditManager
    /// @param balances Expected balances on credit account
    /// @param target Address of target token
    /// @param connectors Addresses of "connectors" - internidiatery tokens which're used for swap operations
    /// @param slippage Slippage in PERCENTAGE_FORMAT
    function findOpenStrategyPath(
        address creditManager,
        Balance[] calldata balances,
        address target,
        address[] calldata connectors,
        uint256 slippage
    ) external returns (Balance[] memory, RouterResult memory);

    /// @dev Finds the best close path - withdraw all tokens and swap them into underlying one
    /// @param creditAccount Address of closing creditAccount
    /// @param connectors Addresses of "connectors" - internidiatery tokens which're used for swap operations
    /// @param slippage Slippage in PERCENTAGE_FORMAT
    /// @param pathOptions Starting point for iterating routes. More info in PathOption file
    /// @param iterations How many iterations algo should compute starting from PathOptions
    function findBestClosePath(
        address creditAccount,
        address[] memory connectors,
        uint256 slippage,
        PathOption[] memory pathOptions,
        uint256 iterations,
        bool force
    ) external returns (RouterResult memory result, uint256 gasPriceTargetRAY);

    /// @dev Returns TokenType for provided token
    function tokenTypes(address) external view returns (TokenType);

    /// @dev Returns current address for RouterComponent. Used for self-discovery
    function componentAddressById(RouterComponent pf)
        external
        view
        returns (address);

    /// @dev @return True if address is router configurator, otherwise false
    function isRouterConfigurator(address account) external view returns (bool);
}
