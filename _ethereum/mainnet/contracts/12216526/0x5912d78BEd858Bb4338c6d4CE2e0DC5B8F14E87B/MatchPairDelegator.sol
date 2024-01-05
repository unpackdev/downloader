// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

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
import "./IProxyRegistry.sol";
import "./DelegateCaller.sol";



abstract contract MatchPairDelegator is  DelegateCaller, IMatchPair, Ownable, MasterCaller{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    function stake(uint256 _index, address _user,uint256 _amount) public override onlyMasterCaller()  {
        
        delegateToImplementation(
            abi.encodeWithSignature("stake(uint256,address,uint256)",
                _index,
                _user,
                _amount
                )
        );
    }
    function untakeToken(uint256 _index, address _user,uint256 _amount) 
        public
        override
        onlyMasterCaller()
        returns (uint256 _tokenAmount, uint256 _leftAmount) 
    {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("untakeToken(uint256,address,uint256)",
              _index, _user, _amount
             ));
        return abi.decode(data, (uint256, uint256));
    }
    function queueTokenAmount(uint256 _index) public view override  returns (uint256) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("queueTokenAmount(uint256)",
              _index
             ));
        return abi.decode(data, (uint256));
    }

    function lPAmount(uint256 _index, address _user) public view returns (uint256) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("lPAmount(uint256,address)",
              _index, _user
             ));
        return abi.decode(data, (uint256));
    }

    function tokenAmount(uint256 _index, address _user) public view returns (uint256) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("tokenAmount(uint256,address)",
              _index, _user
             ));
        return abi.decode(data, (uint256));
    }

    function lp2TokenAmount(uint256 _liquidity) public view  returns (uint256, uint256) {

        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("lp2TokenAmount(uint256)",
             _liquidity
            ));
        return abi.decode(data, (uint256, uint256));
    }

    function maxAcceptAmount(uint256 _index, uint256 _molecular, uint256 _denominator, uint256 _inputAmount) public view override returns (uint256) {

        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("maxAcceptAmount(uint256,uint256,uint256,uint256)",
             _index,
             _molecular,
             _denominator,
             _inputAmount)
            );
        return abi.decode(data, (uint256));
    }
    
    function userPoint(uint256 _side, address _account) external view returns(uint256 ) {

        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("userPoint(uint256,address)",
             _side,
             _account
            ));
        return abi.decode(data, (uint256));
    }
}