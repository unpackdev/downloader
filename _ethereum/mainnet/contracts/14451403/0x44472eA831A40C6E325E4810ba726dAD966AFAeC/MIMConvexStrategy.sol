// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IConvexVault.sol";
import "./ICurvePool.sol";
import "./IStableSwap2Pool.sol";
import "./IStableSwap3Pool.sol";
import "./BaseStrategy.sol";
import "./ExtendedIERC20.sol";
import "./ICVXMinter.sol";
import "./IHarvester.sol";

contract MIMConvexStrategy is BaseStrategy {
    // used for Crv -> weth -> [mim/3crv] -> mimCrv route
    address public immutable crv;
    address public immutable cvx;

    address public immutable crvethPool;
    address public immutable cvxethPool;

    address public immutable mim;
    address public immutable crv3;

    uint256 public immutable pid;
    IConvexVault public immutable convexVault;
    IConvexRewards public immutable crvRewards;
    IStableSwap2Pool public immutable stableSwap2Pool;
    IStableSwap3Pool public immutable stableSwap3Pool;

    /**
     * @param _name The strategy name
     * @param _want The desired token of the strategy
     * @param _crvethPool The address of crvEthPool
     * @param _cvxethPool The address of cvxEthPool
     * @param _weth The address of WETH
     * @param _mim The address of MIM
     * @param _crv3 The address of 3CRV
     * @param _stableSwap3Pool The address of the 3CRV pool
     * @param _pid The pool id of convex
     * @param _convexVault The address of the convex vault
     * @param _stableSwap2Pool The address of the stable swap pool
     * @param _controller The address of the controller
     * @param _manager The address of the manager
     * @param _routerArray The address array of routers for swapping tokens
     */
    constructor(
        string memory _name,
        address _want,
        address _crvethPool,
        address _cvxethPool,
        address _weth,
        address _mim,
        address _crv3,
        IStableSwap3Pool _stableSwap3Pool,
        uint256 _pid,
        IConvexVault _convexVault,
        IStableSwap2Pool _stableSwap2Pool,
        address _controller,
        address _manager,
        address[] memory _routerArray
    ) public BaseStrategy(_name, _controller, _manager, _want, _weth, _routerArray) {
        require(address(_mim) != address(0), '!_mim');
        require(address(_crv3) != address(0), '!_crv3');
        require(address(_convexVault) != address(0), '!_convexVault');
        require(address(_stableSwap2Pool) != address(0), '!_stableSwap2Pool');
        require(address(_stableSwap3Pool) != address(0), '!_stableSwap3Pool');

        (, , , address _crvRewards, , ) = _convexVault.poolInfo(_pid);
        crv = ICurvePool(_crvethPool).coins(1);
        cvx = ICurvePool(_cvxethPool).coins(1);
        mim = _mim;
        crv3 = _crv3;
        crvethPool = _crvethPool;
        cvxethPool = _cvxethPool;
        pid = _pid;
        convexVault = _convexVault;
        crvRewards = IConvexRewards(_crvRewards);
        stableSwap2Pool = _stableSwap2Pool;
        stableSwap3Pool = _stableSwap3Pool;
        // Required to overcome "Stack Too Deep" error
        _setApprovals(
            _want,
            _crvethPool,
            _cvxethPool,
            _mim,
            _crv3,
            address(_convexVault),
            address(_stableSwap2Pool)
        );
        _setMoreApprovals(address(_stableSwap3Pool), _crvRewards, _routerArray);
    }
    
    function _setMoreApprovals(address _stableSwap3Pool, address _crvRewards, address[] memory _routerArray) internal {
        IERC20(IStableSwap3Pool(_stableSwap3Pool).coins(0)).safeApprove(_stableSwap3Pool, type(uint256).max);
        IERC20(IStableSwap3Pool(_stableSwap3Pool).coins(1)).safeApprove(_stableSwap3Pool, type(uint256).max);
        IERC20(IStableSwap3Pool(_stableSwap3Pool).coins(2)).safeApprove(_stableSwap3Pool, type(uint256).max);   
        uint _routerArrayLength = _routerArray.length;
        for(uint i=0; i<_routerArrayLength; i++) {
            address _router = _routerArray[i];
            uint rewardsLength = IConvexRewards(_crvRewards).extraRewardsLength();
            if (rewardsLength > 0) {
                for(uint j=0; j<rewardsLength; j++) {
                    IERC20(IConvexRewards(IConvexRewards(_crvRewards).extraRewards(j)).rewardToken()).safeApprove(_router, type(uint256).max);
                }
            }
        }	 	
    }

    function _setApprovals(
        address _want,
        address _crvethPool,
        address _cvxethPool,
        address _mim,
        address _crv3,
        address _convexVault,
        address _stableSwap2Pool
    ) internal {
        IERC20(_want).safeApprove(address(_convexVault), type(uint256).max);
        IERC20(ICurvePool(_crvethPool).coins(1)).safeApprove(_crvethPool, 0);
        IERC20(ICurvePool(_crvethPool).coins(1)).safeApprove(_crvethPool, type(uint256).max);
        IERC20(ICurvePool(_cvxethPool).coins(1)).safeApprove(_cvxethPool, 0);
        IERC20(ICurvePool(_cvxethPool).coins(1)).safeApprove(_cvxethPool, type(uint256).max);
        IERC20(_mim).safeApprove(address(_stableSwap2Pool), type(uint256).max);
        IERC20(_crv3).safeApprove(address(_stableSwap2Pool), type(uint256).max);
        IERC20(_want).safeApprove(address(_stableSwap2Pool), type(uint256).max);
    }

    function _deposit() internal override {
        if (balanceOfWant() > 0) {
            convexVault.depositAll(pid, true);
        }
    }

    function _claimReward() internal {
        crvRewards.getReward(address(this), true);
    }

    function _addLiquidity(uint256 estimate) internal {
        uint256[2] memory amounts;
        amounts[1] = IERC20(crv3).balanceOf(address(this));
        stableSwap2Pool.add_liquidity(amounts, estimate);
    }

    function _addLiquidity3CRV(uint256 estimate) internal {
        uint256[3] memory amounts;
        (address targetCoin, uint256 targetIndex) = getMostPremium();
        amounts[targetIndex] = IERC20(targetCoin).balanceOf(address(this));
        stableSwap3Pool.add_liquidity(amounts, estimate);
    }

    function getMostPremium() public view returns (address, uint256) {
        uint256 daiBalance = stableSwap3Pool.balances(0);
        uint256 usdcBalance = (stableSwap3Pool.balances(1)).mul(10**18).div(ExtendedIERC20(stableSwap3Pool.coins(1)).decimals());
        uint256 usdtBalance = (stableSwap3Pool.balances(2)).mul(10**12); 

        if (daiBalance <= usdcBalance && daiBalance <= usdtBalance) {
            return (stableSwap3Pool.coins(0), 0);
        }

        if (usdcBalance <= daiBalance && usdcBalance <= usdtBalance) {
            return (stableSwap3Pool.coins(1), 1);
        }

        if (usdtBalance <= daiBalance && usdtBalance <= usdcBalance) {
            return (stableSwap3Pool.coins(2), 2);
        }

        return (stableSwap3Pool.coins(0), 0); // If they're somehow equal, we just want DAI
    }

    function _harvest(uint256[] calldata _estimates) internal override {
        _claimReward();
        uint256 _cvxBalance = IERC20(cvx).balanceOf(address(this));
        if (_cvxBalance > 0) {
            _swapTokensCurve(cvxethPool, 1, 0, _cvxBalance, 1);
        }

        uint256 _extraRewardsLength = crvRewards.extraRewardsLength();
        for (uint256 i = 0; i < _extraRewardsLength; i++) {
            address _rewardToken = IConvexRewards(crvRewards.extraRewards(i)).rewardToken();
            uint256 _extraRewardBalance = IERC20(_rewardToken).balanceOf(address(this));
            if (_extraRewardBalance > 0) {
                _swapTokens(_rewardToken, weth, _extraRewardBalance, 1);
            }
        }
        uint256 _crvBalance = IERC20(crv).balanceOf(address(this));
        if (_crvBalance > 0) {
            _swapTokensCurve(crvethPool, 1, 0, _crvBalance, 1);
        }
        uint256 _remainingWeth = _payHarvestFees();
        if (_remainingWeth > 0) {
            (address _token, ) = getMostPremium(); // stablecoin we want to convert to
            _swapTokens(weth, _token, _remainingWeth, 1);
            _addLiquidity3CRV(0);
            _addLiquidity(_estimates[0]);
            _deposit();
        }
    }

    function _withdrawAll() internal override {
        crvRewards.withdrawAllAndUnwrap(false);
    }

    function _withdraw(uint256 _amount) internal override {
        crvRewards.withdrawAndUnwrap(_amount, false);
    }

    function balanceOfPool() public view override returns (uint256) {
        return IERC20(address(crvRewards)).balanceOf(address(this));
    }
}
