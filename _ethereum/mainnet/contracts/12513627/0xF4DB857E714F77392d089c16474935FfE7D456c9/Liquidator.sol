// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./Ownable.sol";
import "./SafeERC20.sol";

// Import Compound components
import "./ICErc20.sol";
import "./ICEther.sol";
import "./IComptroller.sol";
import "./IPriceOracle.sol";

// Import Uniswap components
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Callee.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";

contract Liquidator is Ownable, IUniswapV2Callee {
    using SafeERC20 for IERC20;

    address constant public ETHER = address(0);
    address immutable public CETH;
    address immutable public WETH;
    address immutable public ROUTER;
    address immutable public FACTORY;

    IComptroller public comptroller;
    IPriceOracle public priceOracle;

    uint private closeFact;
    uint private liqIncent;
    uint private gasThreshold = 2000000;

    event RevenueWithdrawn(address owner, address token, uint256 amount);

    constructor(
        address _ceth,
        address _weth,
        address _router,
        address _factory,
        address _comptrollerAddress
    ) public {
        CETH = _ceth;
        WETH = _weth;
        ROUTER = _router;
        FACTORY = _factory;
        setComptroller(_comptrollerAddress);
    }

    receive() external payable {}

    function setComptroller(address _comptrollerAddress) public onlyOwner {
        comptroller = IComptroller(_comptrollerAddress);
        priceOracle = IPriceOracle(comptroller.oracle());
        closeFact = comptroller.closeFactorMantissa();
        liqIncent = comptroller.liquidationIncentiveMantissa();
    }

    function liquidate(address _borrower, address _repayCToken, address _seizeCToken) public {
        ( , uint liquidity, ) = comptroller.getAccountLiquidity(_borrower);
        require(liquidity == 0, "Nothing to liquidate");
        // uint(10**18) adjustments ensure that all place values are dedicated
        // to repay and seize precision rather than unnecessary closeFact and liqIncent decimals
        uint repayMax = ICErc20(_repayCToken).borrowBalanceCurrent(_borrower) * closeFact / uint(10**18);
        uint seizeMax = ICErc20(_seizeCToken).balanceOfUnderlying(_borrower) * uint(10**18) / liqIncent;
        uint uPriceRepay = priceOracle.getUnderlyingPrice(_repayCToken);
        // Gas savings -- instead of making new vars `repayMax_Eth` and `seizeMax_Eth` just reassign
        repayMax *= uPriceRepay;
        seizeMax *= priceOracle.getUnderlyingPrice(_seizeCToken);
        // Gas savings -- instead of creating new var `repay_Eth = repayMax < seizeMax ? ...` and then
        // converting to underlying units by dividing by uPriceRepay, we can do it all in one step
        _liquidate(_borrower, _repayCToken, _seizeCToken, ((repayMax < seizeMax) ? repayMax : seizeMax) / uPriceRepay);
    }

    function _liquidate(address _borrower, address _repayCToken, address _seizeCToken, uint _amount) internal {
        address pair;
        address r;

        if (_repayCToken == CETH) {
            r = WETH;
            pair = IUniswapV2Factory(FACTORY).getPair(WETH, ICErc20Storage(_seizeCToken).underlying());
        } else {
            r = ICErc20Storage(_repayCToken).underlying();
            pair = IUniswapV2Factory(FACTORY).getPair(WETH, r);
        }

        // Initiate flash swap
        bytes memory data = abi.encode(_borrower, _repayCToken, _seizeCToken);
        uint amount0 = IUniswapV2Pair(pair).token0() == r ? _amount : 0;
        uint amount1 = IUniswapV2Pair(pair).token1() == r ? _amount : 0;

        IUniswapV2Pair(pair).swap(amount0, amount1, address(this), data);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) override external {
        // Unpack parameters sent from the `liquidate` function
        // NOTE: these are being passed in from some other contract, and cannot necessarily be trusted
        (address borrower, address repayCToken, address seizeCToken) = abi.decode(data, (address, address, address));

        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(msg.sender == IUniswapV2Factory(FACTORY).getPair(token0, token1));

        if (repayCToken == seizeCToken) {
            uint amount = amount0 != 0 ? amount0 : amount1;
            address estuary = amount0 != 0 ? token0 : token1;

            // Perform the liquidation
            IERC20(estuary).safeApprove(repayCToken, amount);
            ICErc20(repayCToken).liquidateBorrow(borrower, amount, seizeCToken);

            // Redeem cTokens for underlying ERC20
            ICErc20(seizeCToken).redeem(IERC20(seizeCToken).balanceOf(address(this)));

            // Compute debt and pay back pair
            IERC20(estuary).transfer(msg.sender, (amount * 1000 / 997) + 1);
            return;
        }

        if (repayCToken == CETH) {
            uint amount = amount0 != 0 ? amount0 : amount1;
            address estuary = amount0 != 0 ? token1 : token0;

            // Convert WETH to ETH
            IWETH(WETH).withdraw(amount);

            // Perform the liquidation
            ICEther(repayCToken).liquidateBorrow{value: amount}(borrower, seizeCToken);

            // Redeem cTokens for underlying ERC20
            ICErc20(seizeCToken).redeem(IERC20(seizeCToken).balanceOf(address(this)));

            // Compute debt and pay back pair
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(msg.sender).getReserves();
            (uint reserveIn, uint reserveOut) = token0 == estuary ? (reserve0, reserve1) : (reserve1, reserve0);
            IERC20(estuary).transfer(msg.sender, UniswapV2Library.getAmountIn(amount, reserveIn, reserveOut));
            return;
        }

        if (seizeCToken == CETH) {
            uint amount = amount0 != 0 ? amount0 : amount1;
            address source = amount0 != 0 ? token0 : token1;

            // Perform the liquidation
            IERC20(source).safeApprove(repayCToken, amount);
            ICErc20(repayCToken).liquidateBorrow(borrower, amount, seizeCToken);

            // Redeem cTokens for underlying ERC20 or ETH
            ICErc20(seizeCToken).redeem(IERC20(seizeCToken).balanceOf(address(this)));

            // Convert ETH to WETH
            IWETH(WETH).deposit{value: address(this).balance}();

            // Compute debt and pay back pair
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(msg.sender).getReserves();
            (uint reserveIn, uint reserveOut) = token0 == source ? (reserve1, reserve0) : (reserve0, reserve1);
            // (uint reserveOut, uint reserveIn) = UniswapV2Library.getReserves(FACTORY, source, WETH);
            IERC20(WETH).transfer(msg.sender, UniswapV2Library.getAmountIn(amount, reserveIn, reserveOut));
            return;
        }

        uint amount;
        address source;
        if (amount0 != 0) {
            amount = amount0;
            source = token0;
        } else {
            amount = amount1;
            source = token1;
        }

        // Perform the liquidation
        IERC20(source).safeApprove(repayCToken, amount);
        ICErc20(repayCToken).liquidateBorrow(borrower, amount, seizeCToken);

        // Redeem cTokens for underlying ERC20 or ETH
        uint seized_uUnits = ICErc20(seizeCToken).balanceOfUnderlying(address(this));
        ICErc20(seizeCToken).redeem(IERC20(seizeCToken).balanceOf(address(this)));
        address seizeUToken = ICErc20Storage(seizeCToken).underlying();

        // Compute debt
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(msg.sender).getReserves();
        (uint reserveIn, uint reserveOut) = token0 == source ? (reserve1, reserve0) : (reserve0, reserve1);
        // (uint reserveOut, uint reserveIn) = UniswapV2Library.getReserves(FACTORY, source, estuary);
        uint debt = UniswapV2Library.getAmountIn(amount, reserveIn, reserveOut);

        IERC20(seizeUToken).safeApprove(ROUTER, seized_uUnits);
        // Define swapping path
        address[] memory path = new address[](2);
        path[0] = seizeUToken;
        path[1] = WETH;

        IUniswapV2Router02(ROUTER).swapTokensForExactTokens(debt, seized_uUnits, path, address(this), now + 1 minutes);
        IERC20(seizeUToken).safeApprove(ROUTER, 0);

        // Pay back pair
        IERC20(WETH).transfer(msg.sender, debt);
    }

    function withdraw(address _token) external onlyOwner {
        require(owner() != address(0), "cannot send to zero address");

        uint amount;
        if (_token == ETHER) {
            address self = address(this); // workaround for a possible solidity bug
            amount = self.balance;
            (bool success, ) = owner().call{value: amount}("");
            require(success, "withdraw failed");
        } else {
            amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(owner(), amount);
        }
        emit RevenueWithdrawn(owner(), _token, amount);
    }
}
