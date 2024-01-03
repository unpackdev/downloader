// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StableSwap3.sol";
import "./PickleJar.sol";
import "./MasterChef.sol";

import "./StrategyBase.sol";
import "./UseUniswap.sol";

contract StrategyP3Crv is StrategyBase, UseUniswap {
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // DAI = 0 | USDC = 1 | USDT = 2
    uint internal underlyingIndex;
    // precision to convert 10 ** 18  to underlying decimals
    uint internal precisionDiv = 1;

    // Curve //
    // 3Crv
    address private constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    // StableSwap3
    address private constant CURVE = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    // Pickle //
    address private constant JAR = 0x1BB74b5DdC1f4fC91D6f9E7906cf68bc93538e33;
    address private constant CHEF = 0xbD17B1ce622d73bD438b9E658acA5996dc394b0d;
    address private constant PICKLE = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;

    // POOL ID for 3Crv JAR
    uint private constant POOL_ID = 14;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyBase(_controller, _vault, _underlying) {
        // Assets that cannot be swept by admin
        assets[PICKLE] = true;
    }

    // TODO security: vulnerable to price manipulation
    function _totalAssets() internal view override returns (uint) {
        // getRatio() is multiplied by 10 ** 18
        uint pricePerShare = PickleJar(JAR).getRatio();
        (uint shares, ) = MasterChef(CHEF).userInfo(POOL_ID, address(this));

        return shares.mul(pricePerShare).div(precisionDiv) / 1e18;
    }

    function _deposit(address _token, uint _index) private {
        // token to THREE_CRV
        uint bal = IERC20(_token).balanceOf(address(this));
        if (bal > 0) {
            IERC20(_token).safeApprove(CURVE, 0);
            IERC20(_token).safeApprove(CURVE, bal);
            // mint THREE_CRV
            uint[3] memory amounts;
            amounts[_index] = bal;
            StableSwap3(CURVE).add_liquidity(amounts, 0);
            // Now we have 3Crv
        }

        // deposit 3Crv into PICKLE
        uint threeBal = IERC20(THREE_CRV).balanceOf(address(this));
        if (threeBal > 0) {
            IERC20(THREE_CRV).safeApprove(JAR, 0);
            IERC20(THREE_CRV).safeApprove(JAR, threeBal);
            PickleJar(JAR).deposit(threeBal);
        }

        // stake p3crv
        uint p3crvBal = IERC20(JAR).balanceOf(address(this));
        if (p3crvBal > 0) {
            IERC20(JAR).safeApprove(CHEF, 0);
            IERC20(JAR).safeApprove(CHEF, p3crvBal);
            MasterChef(CHEF).deposit(POOL_ID, p3crvBal);
        }
        // TODO stake
    }

    function _depositUnderlying() internal override {
        _deposit(underlying, underlyingIndex);
    }

    function _getTotalShares() internal view override returns (uint) {
        (uint p3CrvBal, ) = MasterChef(CHEF).userInfo(POOL_ID, address(this));
        return p3CrvBal;
    }

    function _withdrawUnderlying(uint _p3CrvAmount) internal override {
        // unstake
        MasterChef(CHEF).withdraw(POOL_ID, _p3CrvAmount);

        // withdraw THREE_CRV from  PICKLE
        PickleJar(JAR).withdraw(_p3CrvAmount);

        // withdraw underlying
        uint threeBal = IERC20(THREE_CRV).balanceOf(address(this));
        // creates THREE_CRV dust
        StableSwap3(CURVE).remove_liquidity_one_coin(
            threeBal,
            int128(underlyingIndex),
            0
        );
        // Now we have underlying
    }

    /*
    @notice Returns address and index of token with lowest balance in CURVE pool
    */
    function _getMostPremiumToken() private view returns (address, uint) {
        uint[] memory balances = new uint[](3);
        balances[0] = StableSwap3(CURVE).balances(0); // DAI
        balances[1] = StableSwap3(CURVE).balances(1).mul(1e12); // USDC
        balances[2] = StableSwap3(CURVE).balances(2).mul(1e12); // USDT

        // DAI
        if (balances[0] <= balances[1] && balances[0] <= balances[2]) {
            return (DAI, 0);
        }

        // USDC
        if (balances[1] <= balances[0] && balances[1] <= balances[2]) {
            return (USDC, 1);
        }

        // USDT
        return (USDT, 2);
    }

    function _swapPickleFor(address _token) private {
        uint pickleBal = IERC20(PICKLE).balanceOf(address(this));
        if (pickleBal > 0) {
            _swap(PICKLE, _token, pickleBal);
            // Now this contract has underlying token
        }
    }

    /*
    @notice Sell PICKLE and deposit most premium token into CURVE
    */
    function harvest() external override onlyAuthorized {
        // TODO: claim Pickle
        // MasterChef(CHER).deposit(POOL_ID, 0);

        (address token, uint index) = _getMostPremiumToken();

        _swapPickleFor(token);

        uint bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) {
            // transfer fee to treasury
            uint fee = bal.mul(performanceFee) / PERFORMANCE_FEE_MAX;
            if (fee > 0) {
                address treasury = IController(controller).treasury();
                require(treasury != address(0), "treasury = zero address");

                IERC20(token).safeTransfer(treasury, fee);
            }

            _deposit(token, index);
        }
    }

    /*
    @dev Caller should implement guard agains slippage
    */
    function exit() external override onlyAuthorized {
        // PICKLE is minted on withdraw so here we
        // 1. Withdraw from MasterChef
        // 2. Sell PICKLE
        // 3. Transfer underlying to vault
        _withdrawAll();
        _swapPickleFor(underlying);

        uint underlyingBal = IERC20(underlying).balanceOf(address(this));
        if (underlyingBal > 0) {
            IERC20(underlying).safeTransfer(vault, underlyingBal);
        }
    }
}
