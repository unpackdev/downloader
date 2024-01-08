// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./BaseController.sol";

contract UniswapController is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Router02 public immutable UNISWAP_ROUTER;
    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Factory public immutable UNISWAP_FACTORY;

    constructor(
        IUniswapV2Router02 router,
        IUniswapV2Factory factory,
        address manager,
        address _addressRegistry
    ) public BaseController(manager, _addressRegistry) {
        require(address(router) != address(0), "INVALID_ROUTER");
        require(address(factory) != address(0), "INVALID_FACTORY");
        UNISWAP_ROUTER = router;
        UNISWAP_FACTORY = factory;
    }

    /// @notice Deploys liq to Uniswap LP pool
    /// @dev Calls to external contract
    /// @param data Bytes containing token addrs, amounts, pool addr, dealine to interact with Uni router
    function deploy(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(
                data,
                (address, address, uint256, uint256, uint256, uint256, address, uint256)
            );

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        _approve(IERC20(tokenA), amountADesired);
        _approve(IERC20(tokenB), amountBDesired);

        //(uint256 amountA, uint256 amountB, uint256 liquidity) =
        UNISWAP_ROUTER.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        // TODO: perform checks on amountA, amountB, liquidity
    }

    /// @notice Withdraws liq from Uni LP pool
    /// @dev Calls to external contract
    /// @param data Bytes contains tokens addrs, amounts, liq, pool addr, dealine for Uni router
    function withdraw(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(data, (address, address, uint256, uint256, uint256, address, uint256));

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        address pair = UNISWAP_FACTORY.getPair(tokenA, tokenB);
        require(pair != address(0), "pair doesn't exist");
        _approve(IERC20(pair), liquidity);

        //(uint256 amountA, uint256 amountB) =
        UNISWAP_ROUTER.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
        //TODO: perform checks on amountA and amountB
    }

    function _approve(IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), address(UNISWAP_ROUTER));
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(address(UNISWAP_ROUTER), currentAllowance);
        }
        token.safeIncreaseAllowance(address(UNISWAP_ROUTER), amount);
    }
}
