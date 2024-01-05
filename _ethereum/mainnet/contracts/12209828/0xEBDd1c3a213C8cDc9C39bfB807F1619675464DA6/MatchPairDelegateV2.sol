// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./TransferHelper.sol";

import "./MasterCaller.sol";
import "./IStakeGatling.sol";
import "./IMatchPair.sol";
import "./IPriceSafeChecker.sol";
import "./MatchPairStorageV2.sol";




// Logic layer implementation of MatchPair
contract MatchPairDelegateV2 is MatchPairStorageV2, IMatchPair, Ownable, MasterCaller{
    using SafeERC20 for IERC20;
    using SafeMath for uint256; 

    constructor() public {
    }

    function delegateVersion() public view returns (uint256) {
        return 1;
    }

    /**
     * @notice Just logic layer
     */
    function stake(uint256 _index, address _user,uint256 _amount) public  override {

        // 1. updateLpAmount
        _updateLpProfit();
        (uint256 lpTokenAmount, uint256 lpTokenAmount1) = stakeGatling.totalToken();

        if (_index == 1) {
            lpTokenAmount = lpTokenAmount1;
        }
        (uint256 pendingAmount, uint256 totalPoint) = _getPendingAndPoint(_index);

        uint256 userPoint;
        {
            if(totalPoint == 0 || lpTokenAmount.add(pendingAmount) == 0) {
                userPoint = _amount;
            }else {
                userPoint = _amount.mul(totalPoint).div(lpTokenAmount.add(pendingAmount));
            }
        }
        _addTotalPoint(_index, _user, userPoint);
        _addPendingAmount(_index, _amount);
        updatePool();
    }

    function _getPendingAndPoint(uint256 _index) private returns (uint256 pendingAmount,uint256 totalPoint) {
        if(_index == 0) {
            return (pendingToken0, totalTokenPoint0);
        }else {
            return (pendingToken1, totalTokenPoint1);
        }
    }
    
    function updatePool() private {

        if( pendingToken0 > minMintToken0 && pendingToken1 > minMintToken1 ) {
            
            (uint amountA, uint amountB) = getPairAmount( pendingToken0, pendingToken1 ); 
            if( amountA > minMintToken0 && amountB > minMintToken1 ) {
                TransferHelper.safeTransfer(lpToken.token0(), address(lpToken), amountA);
                TransferHelper.safeTransfer(lpToken.token1(), address(lpToken), amountB);
                pendingToken0 = pendingToken0.sub(amountA);
                pendingToken1 = pendingToken1.sub(amountB);
                //mint LP
                uint liquidity = lpToken.mint(stakeGatling.lpStakeDst());
                //send Token to UniPair
                stakeGatling.stake(liquidity);
            }
        }
    }
    function getPairAmount(
        uint amountADesired,
        uint amountBDesired  ) private returns ( uint amountA, uint amountB) {
            
        (uint reserveA, uint reserveB,) = lpToken.getReserves();
        _checkPrice(reserveA, reserveB);

        uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }
    function untakeToken(uint256 _index, address _user,uint256 _amount) 
        public
        override
        returns (uint256 _withdrawAmount, uint256 _leftAmount) 
    {
        _updateLpProfit();
        address tokenCurrent = _index == 0 ? lpToken.token0() : lpToken.token1();

        uint256 totalTokenAmount = totalTokenAmount(_index);
        (uint256 pendingAmount, uint256 totalPoint) = _getPendingAndPoint(_index);
        uint256 userAmount =  _userAmountByPoint( userPoint(_index, _user) , totalPoint, totalTokenAmount);

        if(_amount > userAmount) {
            _amount = userAmount;
        }
        {
            if(_amount <=  pendingAmount) {
                _withdrawAmount = _amount;
                _subPendingAmount(_index, _withdrawAmount);
            }else  {
                uint256 amountRequerViaLp =  _amount.sub(pendingAmount);

                _withdrawAmount = pendingAmount;
                if(_index == 0){
                    pendingToken0 = 0;
                }else {
                    pendingToken1 = 0;
                }

                uint256 amountBurned = burnFromLp(_index, amountRequerViaLp, tokenCurrent);

                _withdrawAmount = _withdrawAmount.add(amountBurned);
            }
        }

        uint256 pointAmount = _withdrawAmount.mul(totalPoint).div(totalTokenAmount);
        _subTotalPoint(_index, _user, pointAmount);

        _leftAmount = userAmount.sub(_withdrawAmount);
        // transfer to Master
        TransferHelper.safeTransfer(tokenCurrent, masterCaller(), _withdrawAmount);
        
    }

    /**
     * @notice price feeded by  Oracle
     */
    function _checkPrice(uint256 reserve0, uint256 reserve1) private {
        if(address(priceChecker) != address(0) ) {
            priceChecker.checkPrice(reserve0, reserve1);
        }
    }
    /**
     * @notice Compound interest calculation in Gatling layer
     */
    function _updateLpProfit() private {

        stakeGatling.withdraw(0);

    }

    /**
     * @notice Desire Token via burn LP
     */
    function burnFromLp(uint256 _index, uint256 amountRequerViaLp, address tokenCurrent) private returns(uint256) {

        (uint reserveA, uint reserveB,) = lpToken.getReserves();
        _checkPrice(reserveA, reserveB);

        uint256 requirLp = amountRequerViaLp.mul(lpToken.totalSupply()).div(IERC20(tokenCurrent).balanceOf(address(lpToken)));
        if(requirLp >  sentinelAmount) { // small amount lp cause Exception in UniswapV2.burn();

            (uint256 amountC, uint256 amountOther) = untakeLP(_index, requirLp);
            _addPendingAmount( (_index +1)%2 ,  amountOther);
            return amountC;
        }
    }

    function _subPendingAmount(uint256 _index, uint256 _amount) private {
        if(_index == 0) {
            pendingToken0 = pendingToken0.sub(_amount);
        }else {
            pendingToken1 = pendingToken1.sub(_amount);
        }
    }

    function _addPendingAmount(uint256 _index, uint256 _amount) private {
        if(_index == 0) {
            pendingToken0 = pendingToken0.add(_amount);
        }else {
            pendingToken1 = pendingToken1.add(_amount);
        }
    }

    function _subTotalPoint(uint256 _index, address _user, uint256 _amount) private {
        UserInfo storage userInfo = _index == 0? userInfo0[_user] : userInfo1[_user];
        userInfo.tokenPoint = userInfo.tokenPoint.sub(_amount);
        if(_index == 0) {

            totalTokenPoint0 = totalTokenPoint0.sub(_amount);
        }else {
            totalTokenPoint1 = totalTokenPoint1.sub(_amount);
        }
    }

    function _addTotalPoint(uint256 _index, address _user, uint256 _amount) private {
        UserInfo storage userInfo = _index == 0? userInfo0[_user] : userInfo1[_user];
        userInfo.tokenPoint = userInfo.tokenPoint.add(_amount);
        if(_index == 0) {
            totalTokenPoint0 = totalTokenPoint0.add(_amount);
        }else {
            totalTokenPoint1 = totalTokenPoint1.add(_amount);
        }
    }
    function untakeLP(uint256 _index,uint256 _untakeLP) private returns (uint256 amountC, uint256 amountPaired) {
        
        (amountC, amountPaired) = stakeGatling.burn(address(this), _untakeLP);
        if(_index == 1) {
             (amountC , amountPaired) = (amountPaired, amountC);
        }
    }
    
    function token(uint256 _index) public view override returns (address) {
        return _index == 0 ? lpToken.token0() : lpToken.token1();
    }

    function lPAmount(uint256 _index, address _user) public view returns (uint256) {
        uint256 totalPoint = _index == 0? totalTokenPoint0 : totalTokenPoint1;
        return stakeGatling.totalLPAmount().mul(userPoint(_index, _user)).div(totalPoint);
    }

    function tokenAmount(uint256 _index, address _user) public view returns (uint256) {
        
        uint256 userPoint = userPoint(_index, _user);
        uint256 totalPoint = _index == 0? totalTokenPoint0 : totalTokenPoint1;
        uint256 totalTokenAmount = _index == 0? pendingToken0 : pendingToken1;

        return _userAmountByPoint(userPoint, totalPoint, totalTokenAmount);
    }

    function userPoint(uint256 _index, address _user) public view returns (uint256 point) {
        UserInfo memory userInfo = _index == 0? userInfo0[_user] : userInfo1[_user];
        return userInfo.tokenPoint;
    }

    function _userAmountByPoint(uint256 _point, uint256 _totalPoint, uint256 _totalAmount ) 
        private view returns (uint256) {
        return _point.mul(_totalAmount).div(_totalPoint);
    }

    function queueTokenAmount(uint256 _index) public view override  returns (uint256) {
        return _index == 0 ? pendingToken0: pendingToken1;
    }

    function totalTokenAmount(uint256 _index) public view  returns (uint256) {
        (uint256 amount0, uint256 amount1) = stakeGatling.totalToken();
        if(_index == 0) {
            return amount0.add(pendingToken0);
        }else {
            return amount1.add(pendingToken1);   
        }
    }

    function lp2TokenAmount(uint256 _liquidity) public view  returns (uint256 amount0, uint256 amount1) {

        uint256 _totalSupply = lpToken.totalSupply();
        (address _token0, address _token1) = (lpToken.token0(), lpToken.token1());

        uint balance0 = IERC20(_token0).balanceOf(address(lpToken));
        uint balance1 = IERC20(_token1).balanceOf(address(lpToken));

        amount0 = _liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = _liquidity.mul(balance1) / _totalSupply;
    }

    function maxAcceptAmount(uint256 _index, uint256 _molecular, uint256 _denominator, uint256 _inputAmount) public view override returns (uint256) {
        
        (uint256 amount0, uint256 amount1) = stakeGatling.totalToken();

        uint256 pendingTokenAmount = _index == 0 ? pendingToken0 : pendingToken1;
        uint256 lpTokenAmount =  _index == 0 ? amount0 : amount1;

        require(lpTokenAmount.mul(_molecular).div(_denominator) > pendingTokenAmount, "Amount in pool less than PendingAmount");
        uint256 maxAmount = lpTokenAmount.mul(_molecular).div(_denominator).sub(pendingTokenAmount);
        
        return _inputAmount > maxAmount ? maxAmount : _inputAmount ; 
    }

}
