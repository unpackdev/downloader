/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity ^0.6.10;
pragma experimental "ABIEncoderV2";

import "./IController.sol";
import "./ReentrancyGuard.sol";
import "./ModuleBase.sol";
import "./Invoke.sol";
import "./IJasperVault.sol";
import "./ModuleBase.sol";
import "./IExchangeAdapter.sol";

import "./IAToken.sol";
import "./ILendingPool.sol";
import "./IFlashLoanReceiver.sol";
import "./IERC20.sol";
import "./PreciseUnitMath.sol";
import "./SafeERC20.sol";
import "./IGMXAdapter.sol";

contract UtilsModule is ModuleBase, ReentrancyGuard, IFlashLoanReceiver {
    using PreciseUnitMath for int256;
    using SafeERC20 for IERC20;
    uint256 internal constant BORROW_RATE_MODE = 2;
    ILendingPool public lendingPool;
    address public aaveLeverageModule;

    uint256 public positionMultiplier = 10 ** 18;
    constructor(
        IController _controller,
        ILendingPool _lendingPool,
        address _aaveLeverageModule
    ) public ModuleBase(_controller) {
        lendingPool = _lendingPool;
        aaveLeverageModule=_aaveLeverageModule;
    }


     struct ParamInterInfo{
        address[]  flashAtoken;
        uint256[]  flashAunit;
        address[]  flashDtoken;
        uint256[]  flashDunit;
        uint256 flashAIndex;
        uint256 flashDindex;
        address jasperVault;
        address[] positionAToken;
        uint256 positionAIndex;
        address[] positionDToken;
        uint256 positionDIndex;

        address[] aaveBorrowToken;
        uint256[] aaveBorrowUnit;
        uint256 aaveBorrowIndex;

        address[] aaveWithdrawToken;
        uint256[] aaveWithdrawUnit;
        uint256 aaveWithdrawIndex;
       
     }
    struct  SwapInfo{
        string  exchangeName;
        address assetIn;
        address assetOut;
        uint256 amountIn;
        uint256 amountLimit;
        uint256 approveAmont;
        bool isExact;
        bytes   data;    
    }

    struct Param{
        IJasperVault target;
        IJasperVault follow;
        uint256 positionRate;
        address[]  aTokens;
        address[]  dTokens;
        SwapInfo[] masterToOther;
        SwapInfo[] otherToMaster;    
        int256   rate;  //1000
        SwapInfo[] beforeSwap;
        SwapInfo[] afterSwap;
        address[] spotTokens;
        bool isMirror;
    }
    function reset(Param memory param) external nonReentrant onlyValidAndInitializedSet(param.follow){
          _beforeAndAfterSwap(param.follow,param.beforeSwap);
          ParamInterInfo memory info;
          info.positionAToken=new address[](param.aTokens.length);
          info.positionDToken=new address[](param.dTokens.length);
          //-
          info.flashAtoken=new address[](param.aTokens.length);
          info.flashAunit=new uint256[](param.aTokens.length);
          info.flashDtoken=new address[](param.dTokens.length);
          info.flashDunit=new uint256[](param.dTokens.length);

          info.aaveBorrowToken=new address[](param.aTokens.length+param.dTokens.length);
          info.aaveBorrowUnit=new uint256[](param.aTokens.length+param.dTokens.length);

          info.aaveWithdrawToken=new address[](param.aTokens.length+param.dTokens.length);
          info.aaveWithdrawUnit=new uint256[](param.aTokens.length+param.dTokens.length);

          info.jasperVault=address(param.follow);
          address underlyAsset;

          int256 tBalance;
          int256 fBalance;
          int256 diff;
          for(uint256 i;i<param.aTokens.length;i++){
              tBalance= param.isMirror ? int256(IERC20(param.aTokens[i]).balanceOf(address(param.target))):0;
               //get position list

              info.positionAToken[info.positionAIndex]=param.aTokens[i];
              info.positionAIndex++;

              fBalance= int256(IERC20(param.aTokens[i]).balanceOf(address(param.follow)));
    

              diff=tBalance.mul(param.rate).preciseMul(int256(param.positionRate)) .div(1000).sub(fBalance);
              underlyAsset=IAToken(param.aTokens[i]).UNDERLYING_ASSET_ADDRESS();
         
              //Borrow from flash
              if(diff>0){
                  info.flashAtoken[info.flashAIndex]= underlyAsset;
                  info.flashAunit[info.flashAIndex]=diff.abs();
                  info.flashAIndex++;
              }
              if(diff<0){
                info.aaveWithdrawToken[info.aaveWithdrawIndex]=underlyAsset;
                info.aaveWithdrawUnit[info.aaveWithdrawIndex]=diff.abs();
                info.aaveWithdrawIndex++;        
              }
          }

          for(uint256 i;i<param.dTokens.length;i++){
              tBalance=param.isMirror ?  int256(IERC20(param.dTokens[i]).balanceOf(address(param.target))):0;
              //get position list

              info.positionDToken[info.positionDIndex]=param.dTokens[i];
              info.positionDIndex++;

              fBalance= int256(IERC20(param.dTokens[i]).balanceOf(address(param.follow)));  
              diff=tBalance.mul(param.rate).preciseMul(int256(param.positionRate)).div(1000).sub(fBalance);
              underlyAsset=IAToken(param.dTokens[i]).UNDERLYING_ASSET_ADDRESS();
              if(diff<0){
                  info.flashDtoken[info.flashDindex]=underlyAsset;
                  info.flashDunit[info.flashDindex]=diff.abs();   
                  info.flashDindex++;  
              }
              if(diff>0){
                info.aaveBorrowToken[info.aaveBorrowIndex]=underlyAsset;
                info.aaveBorrowUnit[info.aaveBorrowIndex]=diff.abs();
                info.aaveBorrowIndex++;         
              }
          }
          if(info.flashDindex>0 || info.flashAIndex>0){
              _handleFlash(info,param);
          }else{
              _handleFlashLever(info,param);
          }

          _beforeAndAfterSwap(param.follow,param.afterSwap);
          //update aave Position
          _updateAavePostion(info);
          for(uint256 i;i<param.spotTokens.length;i++){
             _updateMasterToken(param.follow,param.spotTokens[i]);
          }
         
    }

    function _updateMasterToken(IJasperVault follow,address _token) internal {
           address masterToken=_token;
           uint256 totalSupply=follow.totalSupply();
           uint256 balance = IERC20(masterToken).balanceOf(
               address(follow)
            );
            balance = uint256(int256(balance).preciseDiv(int256(totalSupply)));
            _updatePosition(follow, masterToken, balance, 0);
    }



    function _handleFlash(ParamInterInfo memory info,Param memory param) internal {
          address[] memory flashToken=new address[](info.flashAIndex+info.flashDindex);
          uint256[] memory flashUnit=new uint256[](info.flashAIndex+info.flashDindex);
          uint256[] memory flashMode=new uint256[](info.flashAIndex+info.flashDindex);
          uint256 index;
          for(uint256 i;i<info.flashAIndex;i++){
              flashToken[index]=info.flashAtoken[i];
              flashUnit[index]=info.flashAunit[i];
              index++;
          }
          for(uint256 i;i<info.flashDindex;i++){
              flashToken[index]=info.flashDtoken[i];
              flashUnit[index]=info.flashDunit[i];
              index++;
          }
          bytes memory infoBytes=abi.encode(info,param);
          lendingPool.flashLoan(address(this), flashToken,flashUnit,flashMode,address(this),infoBytes,0);
    }

    function _handleFlashLever(ParamInterInfo memory info,Param memory param) internal {
          address _callContract;
          uint256 _callValue;
          bytes memory _callByteData; 
          for(uint256 i;i<info.aaveBorrowIndex;i++){
                 (_callContract,_callValue,_callByteData )=  getAaveBorrowCallData(info.aaveBorrowToken[i],info.aaveBorrowUnit[i],address(param.follow));
                  param.follow.invoke(_callContract,_callValue, _callByteData);      
                  _handleOMAsset(param.follow,info.aaveBorrowToken[i],info.aaveBorrowUnit[i],param.otherToMaster);
          }
          for(uint256 i;i<info.aaveWithdrawIndex;i++){

                (_callContract,_callValue,_callByteData )=  getAaveWithdrawCallData(info.aaveWithdrawToken[i],info.aaveWithdrawUnit[i],address(param.follow));
                param.follow.invoke(_callContract,_callValue, _callByteData);  
                _handleOMAsset(param.follow,info.aaveWithdrawToken[i],info.aaveWithdrawUnit[i],param.otherToMaster);
          }
    }


    function _handleFlashDelever(ParamInterInfo memory info) internal{
         address _callContract;
          uint256 _callValue;
          bytes memory _callByteData;
          for(uint256 i;i<info.flashAIndex;i++){
               IJasperVault(info.jasperVault).invokeApprove(
                        info.flashAtoken[i],
                        address(lendingPool),
                        info.flashAunit[i]
                    );
             (_callContract,_callValue,_callByteData )=  getAaveDepositCallData(info.flashAtoken[i],info.flashAunit[i],info.jasperVault);
              IJasperVault(info.jasperVault).invoke(_callContract,_callValue, _callByteData);
          }
          for(uint256 i;i<info.flashDindex;i++){
               IJasperVault(info.jasperVault).invokeApprove(
                        info.flashDtoken[i],
                        address(lendingPool),
                        info.flashDunit[i]
            );
              (_callContract,_callValue,_callByteData )=  getAaveRepayCallData(info.flashDtoken[i],info.flashDunit[i],info.jasperVault);
              IJasperVault(info.jasperVault).invoke(_callContract,_callValue, _callByteData);
          }    


    }
    function _updateAavePostion(ParamInterInfo memory info) internal{
         uint256 balance;
         int256 totalSupply=int256(IJasperVault(info.jasperVault).totalSupply());
         address underlyAsset;
         for(uint256 i;i<info.positionAIndex;i++){
            balance=IERC20(info.positionAToken[i]).balanceOf(info.jasperVault);
            balance = uint256(int256(balance).preciseDiv(totalSupply));
            _updatePosition(IJasperVault(info.jasperVault),info.positionAToken[i],balance,1);
         }

         for(uint i;i<info.positionDIndex;i++){
            int256 zero=0;
            balance=IERC20(info.positionDToken[i]).balanceOf(info.jasperVault);
            int256 result =zero.sub(int256(balance).preciseDiv(totalSupply));
            underlyAsset=IAToken(info.positionDToken[i]).UNDERLYING_ASSET_ADDRESS();
            _updateExternalPosition(IJasperVault(info.jasperVault),underlyAsset,aaveLeverageModule,result,1);
         }
    }
    function _updatePosition(ParamInterInfo memory info) internal{
         uint256 balance;
         int256 totalSupply=int256(IJasperVault(info.jasperVault).totalSupply());
         address underlyAsset;
         for(uint256 i;i<info.positionAIndex;i++){
            balance=IERC20(info.positionAToken[i]).balanceOf(info.jasperVault);
            balance = uint256(int256(balance).preciseDiv(totalSupply));
            _updatePosition(IJasperVault(info.jasperVault),info.positionAToken[i],balance,1);
         }
}

    //masterToken->other
    function _handleMOAsset(IJasperVault follow,address asset,uint256 amount, SwapInfo[] memory masterToOther) internal {
            uint256 balance=IERC20(follow.masterToken()).balanceOf(address(follow));
            for(uint256 i;i<masterToOther.length;i++){
                if(masterToOther[i].assetOut==asset){
                   SwapInfo memory info=masterToOther[i];
                   info.amountIn=amount;
                   info.amountLimit=balance;
                    (
                    address  _callContract,
                    uint256 _callValue,
                    bytes memory  _callByteData,
                    address  _spender
                    ) = getUniswapTokenCallData(
                        info,
                        address(follow)
                    );
                    follow.invokeApprove(
                        follow.masterToken(),
                        _spender,
                        balance
                    );
                    follow.invoke(_callContract, _callValue, _callByteData);
                    break;
                }
           }
    }
    //other->masterToken
    // need add amount limit out
    function _handleOMAsset(IJasperVault follow,address asset,uint256 amount, SwapInfo[] memory otherToMaster) internal {
            for(uint256 i;i<otherToMaster.length;i++){
                if(otherToMaster[i].assetIn==asset){
                   SwapInfo memory info=otherToMaster[i];
                   info.amountIn=amount;
//                   info.amountLimit=amount.mul(95).div(100);
                    (
                    address  _callContract,
                    uint256 _callValue,
                    bytes memory  _callByteData,
                    address  _spender
                    ) = getUniswapTokenCallData(
                        info,
                        address(follow)
                    );
                    follow.invokeApprove(
                        asset,
                        _spender,
                        info.amountIn
                    );
                    follow.invoke(_callContract, _callValue, _callByteData);
                    break;
                }
           }
    }
    //
    function _beforeAndAfterSwap(IJasperVault follow,SwapInfo[] memory info) internal {
            for(uint256 i;i<info.length;i++){
                if(info[i].isExact){
                   info[i].amountIn=IERC20(info[i].assetIn).balanceOf(address(follow));
//                   info[i].amountLimit=info[i].amountLimit.mul(95).div(100);
                   info[i].approveAmont=info[i].amountIn;
                }
                    (
                    address  _callContract,
                    uint256 _callValue,
                    bytes memory  _callByteData,
                    address  _spender
                    ) = getUniswapTokenCallData(
                        info[i],
                        address(follow)
                    );
                    follow.invokeApprove(
                        info[i].assetIn,
                        _spender,
                        info[i].approveAmont
                    );
                    try  follow.invoke(_callContract, _callValue, _callByteData){                  
                    } catch{

                    }
           }
    }

    //
    function _replayFlash(IJasperVault follow,address[] memory assets, uint256[] memory amounts,uint256[] memory premiums,SwapInfo[] memory masterToOther) internal{
             for(uint256 i;i<assets.length;i++){
                 uint256 amount=amounts[i].add(premiums[i]);
                 _handleMOAsset(follow,assets[i],amount,masterToOther);
             }
            for (uint256 i = 0; i < assets.length; i++) {
                follow.invokeTransfer(
                 assets[i],
                  address(this),
                  (amounts[i] + premiums[i])
                 );
            }
            for (uint i = 0; i < assets.length; i++) {
                 IERC20(assets[i]).approve(
                  address(lendingPool),
                   (amounts[i] + premiums[i])
             );
           }
    }

    function executeOperation(
        address[] calldata assets,
        uint[] calldata amounts,
        uint[] calldata premiums,
        address /*initiator*/,
        bytes calldata params
    ) external override returns (bool) {
        (ParamInterInfo memory info,Param memory param)= abi.decode(params, (ParamInterInfo,Param));
        //current contract  transfer jaspervault
        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i]).safeTransfer(
                address(info.jasperVault),
                amounts[i]
            );
        }
        _handleFlashDelever(info);
        _handleFlashLever(info,param);
        _replayFlash(IJasperVault(info.jasperVault),assets,amounts,premiums,param.masterToOther);
   
        return true;
    }
   //-----------
    function initialize(IJasperVault _jasperVault) external {
        _jasperVault.initializeModule();
    }
    //-------------------
    function getAaveDepositCallData(
        address _asset,
        uint256 _amount,
        address _onBehalfOf
    ) internal view returns (address, uint256, bytes memory) {
        bytes memory callData = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)",
            _asset,
            _amount,
            _onBehalfOf,
            0
        );
        return (address(lendingPool), 0, callData);
    }

    function getAaveBorrowCallData(
        address _asset,
        uint256 _amount,
        address _onBehalfOf
    ) internal view returns (address, uint256, bytes memory) {
        bytes memory callData = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint16,address)",
            _asset,
            _amount,
            BORROW_RATE_MODE,
            0,
            _onBehalfOf
        );

        return (address(lendingPool), 0, callData);
    }

    function getAaveRepayCallData(
        address _assset,
        uint256 _amount,
        address _onBehalfOf
    ) internal view returns (address, uint256, bytes memory) {
        bytes memory callData = abi.encodeWithSignature(
            "repay(address,uint256,uint256,address)",
            _assset,
            _amount,
            BORROW_RATE_MODE,
            _onBehalfOf
        );

        return (address(lendingPool), 0, callData);
    }

    function getAaveWithdrawCallData(
        address _asset,
        uint256 _amount,
        address _to
    ) internal view returns (address, uint256, bytes memory) {
        bytes memory callData = abi.encodeWithSignature(
            "withdraw(address,uint256,address)",
            _asset,
            _amount,
            _to
        );

        return (address(lendingPool), 0, callData);
    }

    function getUniswapTokenCallData(
        SwapInfo memory _swapInfo,
        address _to
    )
        internal
        view
        returns (
            address targetExchange,
            uint256 callValue,
            bytes memory methodData,
            address uniswapRouter
        )
    {
        IExchangeAdapter exchangeAdapter = IExchangeAdapter(
            getAndValidateAdapter(_swapInfo.exchangeName)
        );
        uniswapRouter = exchangeAdapter.getSpender();
        (targetExchange, callValue, methodData) = exchangeAdapter
            .getTradeCalldata(
                _swapInfo.assetIn,
                _swapInfo.assetOut,
                _to,
                _swapInfo.amountIn,
                _swapInfo.amountLimit,
                _swapInfo.data
            );
        return (targetExchange, callValue, methodData, uniswapRouter);
    }
    function _updatePosition(
        IJasperVault _jasperVault,
        address _token,
        uint256 _newPositionUnit,
        uint256 _coinType
    ) internal {
        _jasperVault.editCoinType(_token, _coinType);
        _jasperVault.editDefaultPosition(_token, _newPositionUnit);
    }

    function _updateExternalPosition(
        IJasperVault _jasperVault,
        address _token,
        address _module,
        int256 _newPositionUnit,
        uint256 _coinType
    ) internal {
        _jasperVault.editExternalCoinType(_token, _module, _coinType);
        _jasperVault.editExternalPosition(
            _token,
            _module,
            _newPositionUnit,
            ""
        );
    }

    function removeModule() external override {}
}