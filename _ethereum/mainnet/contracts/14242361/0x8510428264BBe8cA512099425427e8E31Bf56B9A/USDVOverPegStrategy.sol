// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";
import "./Auth.sol";
import "./SafeTransferLib.sol";
import "./SafeCastLib.sol";
import "./FixedPointMathLib.sol";
import "./Strategy.sol";
import "./VaderGateway.sol";
import "./StrategyInterfaces.sol";

contract USDVOverPegStrategy is Auth, ERC20("USDVOverPegStrategy", "aUSDVOverPegStrategy", 18), ERC20Strategy {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    ERC20 public constant DAI = ERC20(address(0x6B175474E89094C44Da98b954EedeAC495271d0F));  //our flip
    ERC20 public constant USDC = ERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); //our flap
    ERC20 public constant USDT = ERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); //our flop
    ERC20 public constant USDV = ERC20(address(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe));

    ERC20 public immutable WETH;
    ICurve public immutable POOL;
    IUniswap public immutable UNISWAP;
    IXVader public immutable XVADER;
    IVaderMinter public immutable VADERGATEWAY;

    constructor(
        ERC20 UNDERLYING_,
        address GOVERNANCE_,
        Authority AUTHORITY_,
        address POOL_,
        address XVADER_,
        address VADERGATEWAY_,
        address UNIROUTER_,
        address WETH_
    ) Auth(GOVERNANCE_, AUTHORITY_) { //set authority to something that enables operators for aphra
        UNDERLYING = UNDERLYING_; //vader
        BASE_UNIT = 10e18;

        POOL = ICurve(POOL_);
        XVADER = IXVader(XVADER_);

        VADERGATEWAY = IVaderMinter(VADERGATEWAY_); // our partner minter
        UNISWAP = IUniswap(UNIROUTER_);
        WETH = ERC20(WETH_);

        USDV.safeApprove(POOL_, type(uint256).max); //set unlimited approval to the pool for usdv
        DAI.safeApprove(UNIROUTER_, type(uint256).max);
        USDC.safeApprove(UNIROUTER_, type(uint256).max);
        USDT.safeApprove(UNIROUTER_, type(uint256).max);
        WETH.safeApprove(UNIROUTER_, type(uint256).max); //prob not needed
        UNDERLYING.safeApprove(XVADER_, type(uint256).max);
        UNDERLYING.safeApprove(VADERGATEWAY_, type(uint256).max);
    }

    /* //////////////////////////////////////////////////////////////
                             STRATEGY LOGIC
    ///////////////////////////////////////////////////////////// */


    function hit(uint256 vAmount_, int128 exitCoin_, address[] memory pathToVader_) external requiresAuth () {
        _unstakeUnderlying(vAmount_);
        uint uAmount = VADERGATEWAY.partnerMint(UNDERLYING.balanceOf(address(this)), uint(1));
        uint vAmount = _swapUSDVToVader(uAmount, exitCoin_, pathToVader_);
        _stakeUnderlying(vAmount);
        require(vAmount > vAmount_, "Failed to arb for profit");
    unchecked {
        require( POOL.balances(1) * 1e3 / (POOL.balances(0)) >= 1e3, "peg must be at or above 1");
    }

    }

    function isCEther() external pure override returns (bool) {
        return false;
    }

    function ethToUnderlying(uint256 ethAmount_) external view returns (uint256) {
        if (ethAmount_ == 0) {
            return 0;
        }

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(UNDERLYING);
        uint256[] memory amounts = UNISWAP.getAmountsOut(ethAmount_, path);

        return amounts[amounts.length - 1];
    }

    function underlying() external view override returns (ERC20) {
        return UNDERLYING;
    }

    function mint(uint256 amount) external requiresAuth override returns (uint256) {
        _mint(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));
        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);
        _stakeUnderlying(UNDERLYING.balanceOf(address(this)));
        return 0;
    }

    function redeemUnderlying(uint256 amount) external override returns (uint256) {
        _burn(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));

        if (UNDERLYING.balanceOf(address(this)) < amount) {
            uint leaveAmount = amount - UNDERLYING.balanceOf(address(this));
            _unstakeUnderlying(leaveAmount);
        }
        UNDERLYING.safeTransfer(msg.sender, amount);

        return 0;
    }

    function balanceOfUnderlying(address user) external view override returns (uint256) {
        return balanceOf[user].fmul(_exchangeRate(), BASE_UNIT);
    }

    /* //////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    ///////////////////////////////////////////////////////////// */

    ERC20 internal immutable UNDERLYING;

    uint256 internal immutable BASE_UNIT;

    function _stakeUnderlying(uint vAmount) internal {
        XVADER.enter(vAmount);
    }

    function _computeStakedSharesForUnderlying(uint vAmount) internal view returns(uint256) {
        return (vAmount * XVADER.totalSupply()) / UNDERLYING.balanceOf(address(XVADER));
    }

    function _unstakeUnderlying(uint vAmount) internal {
        uint shares = _computeStakedSharesForUnderlying(vAmount);
        XVADER.leave(shares);
    }

    function _swapUSDVToVader(uint uAmount_, int128 exitCoin_, address[] memory path_) internal returns (uint vAmount) {
        //get best exit address
        //get mins for swap
        address exitCoinAddr = address(DAI);
        if (exitCoin_ == int128(2)) {
            exitCoinAddr = address(USDC);
        } else if (exitCoin_ == int128(3)) {
            exitCoinAddr = address(USDT);
        }
        POOL.exchange_underlying(0, exitCoin_, uAmount_, uint(1));

        address[] memory path;
        if(path_.length == 0) {
            path = new address[](3);
            path[0] = exitCoinAddr;
            path[1] = address(WETH);
            path[2] = address(UNDERLYING); //vader eth pool has the best depth for vader
        } else {
            path = path_;
        }

        uint256 amountIn = ERC20(exitCoinAddr).balanceOf(address(this));
        uint256[] memory amounts = UNISWAP.getAmountsOut(amountIn, path);
        vAmount = amounts[amounts.length - 1];
        UNISWAP.swapExactTokensForTokens(
            amountIn,
            vAmount,
            path,
            address(this),
            block.timestamp
        );

    }

    function _computeStakedUnderlying() internal view returns (uint256) {
        return (XVADER.balanceOf(address(this)) * UNDERLYING.balanceOf(address(XVADER))) / XVADER.totalSupply();
    }

    function _exchangeRate() internal view returns (uint256) {
        uint256 cTokenSupply = totalSupply;

        if (cTokenSupply == 0) return BASE_UNIT;
        uint underlyingBalance;
        uint stakedBalance = _computeStakedUnderlying();
        unchecked {
            underlyingBalance = UNDERLYING.balanceOf(address(this)) + stakedBalance;
        }
        return underlyingBalance.fdiv(cTokenSupply, BASE_UNIT);
    }
}

