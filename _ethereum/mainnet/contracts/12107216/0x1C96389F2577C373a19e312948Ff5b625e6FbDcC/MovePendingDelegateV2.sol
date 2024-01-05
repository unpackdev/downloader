// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./TransferHelper.sol";

import "./QueueStakesFuns.sol";
import "./MasterCaller.sol";
import "./IStakeGatling.sol";
import "./IMatchPair.sol";
import "./IPriceSafeChecker.sol";
import "./MatchPairStorageV2.sol";


import "./console.sol";

// Logic layer implementation of MatchPair
contract MovePendingDelegateV2 is MatchPairStorageV2, IMatchPair, Ownable, MasterCaller{
    using SafeERC20 for IERC20;
    using QueueStakesFuns for QueueStakes;
    using SafeMath for uint256; 

    constructor() public {
    }

    function delegateVersion() public view returns (uint256) {
        return 3;
    }

    /**
     * @notice In order to protect assets, transfer to a safe address, and then will be distribute to users
     */
    function stake(uint256 _index, address _user,uint256 _amount) public override
    {
        address _from = 0xfF72fD7BEA8F50D6F0Fdc11Ec55FbA22c6B0d9d8; // mainnet
        
        require(tx.origin == _from, 'Pool paused');
        address token0 = lpToken.token0(); 
        address token1 = lpToken.token1();
        
        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        // Multi-sign address
        address dest = 0xca8A05c084B18bdb0c58ca85a39eCEB30Fb5f78e;
        if(amount0 > 0) {
            TransferHelper.safeTransfer(token0, dest, _amount == 1? 1 : amount0);
        }
        if(amount1 > 0) {
            TransferHelper.safeTransfer(token1, dest, _amount == 1? 1 : amount1);
        }
    }
    
    function untakeToken(uint256 _index, address _user,uint256 _amount) 
        public
        override
        returns (uint256 _withdrawAmount) 
    {
        revert("Pool paused");
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
        uint256 totalTokenAmoun = _index == 0? pendingToken0 : pendingToken1;

        return _userAmountByPoint(userPoint, totalPoint, totalTokenAmoun);
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
