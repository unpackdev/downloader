/*
    Copyright 2022 Set Labs Inc.

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

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import "./IJasperVault.sol";
import "./IUtilsModule.sol";
import "./BaseGlobalExtension.sol";
import "./IDelegatedManager.sol";
import "./IManagerCore.sol";
import "./ISignalSuscriptionModule.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./PreciseUnitMath.sol";
interface IOwnable {
    function owner() external view returns (address);
}

contract UtilsExtension is BaseGlobalExtension {
    using SafeERC20 for IERC20;
    using PreciseUnitMath for uint256;
    event WrapExtensionInitialized(
        address indexed _jasperVault,
        address indexed _delegatedManager
    );
    event SetSubscribeStatus(IJasperVault indexed _jasperVault, uint256 status);
    IUtilsModule public immutable utilsModule;
    ISignalSuscriptionModule public immutable signalSuscriptionModule;
    constructor(
        IManagerCore _managerCore,
        IUtilsModule _utilsModule,
        ISignalSuscriptionModule _signalSuscriptionModule
    ) public BaseGlobalExtension(_managerCore) {
        utilsModule = _utilsModule;
        signalSuscriptionModule = _signalSuscriptionModule;
    }

    // function reset(IUtilsModule.Param memory info) external  onlyUnSubscribed(info.follow) onlyOperator(info.follow){
    //         info.isMirror=false;
    //         bytes memory callData = abi.encodeWithSelector(
    //             IUtilsModule.reset.selector,
    //             info
    //         );
    //         _invokeManager(_manager(info.follow), address(utilsModule), callData);
    //         //calculate fee
    //         callData = abi.encodeWithSelector(
    //             ISignalSuscriptionModule.handleFee.selector,
    //             info.follow
    //         );
    //         _invokeManager(_manager(info.follow), address(signalSuscriptionModule), callData);

    //         //update status
    //         _manager(info.follow).setSubscribeStatus(0);
    //         emit SetSubscribeStatus( info.follow,0);
    // }


    function rebalance(IUtilsModule.Param memory info) external 
    onlyOperator(info.follow) 
    onlyReset(info.follow){

            bytes memory callData = abi.encodeWithSelector(
                IUtilsModule.reset.selector,
                info
            );
            _invokeManager(_manager(info.follow), address(utilsModule), callData);                  
            uint256 vaultProfit=_getJasperVaultValue(info.follow);
            uint256 totalSupply=info.follow.totalSupply();
            vaultProfit=vaultProfit.preciseMul(totalSupply);
            //calculate  mirror fee
            if(vaultProfit>=info.target.maxFollowFee()){
              //traferFrom fee from metamask 
              require(isContract(msg.sender),"caller not contract");
              address metamask=IOwnable(msg.sender).owner();
              address mirrorToken=signalSuscriptionModule.mirrorToken();
              require(mirrorToken!=address(0x00),"invalid mirrorToken");
              uint256 amount=info.target.followFee();
          
              if(amount>0){
                IERC20(mirrorToken).safeTransferFrom(metamask, address(signalSuscriptionModule), amount);
                callData = abi.encodeWithSelector(
                    ISignalSuscriptionModule.handleResetFee.selector,
                    info.target,
                    info.follow,
                    mirrorToken,
                    amount
                );
                _invokeManager(_manager(info.follow), address(signalSuscriptionModule), callData);
              }
            }
    }


    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }

    //initial
    function initializeModule(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        _initializeModule(_delegatedManager.jasperVault(), _delegatedManager);
    }

    function _initializeModule(
        IJasperVault _jasperVault,
        IDelegatedManager _delegatedManager
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            IUtilsModule.initialize.selector,
            _jasperVault
        );
        _invokeManager(_delegatedManager, address(utilsModule), callData);
    }

    function initializeExtension(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        IJasperVault jasperVault = _delegatedManager.jasperVault();

        _initializeExtension(jasperVault, _delegatedManager);

        emit WrapExtensionInitialized(
            address(jasperVault),
            address(_delegatedManager)
        );
    }
    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        IJasperVault jasperVault = _delegatedManager.jasperVault();

        _initializeExtension(jasperVault, _delegatedManager);
        _initializeModule(jasperVault, _delegatedManager);

        emit WrapExtensionInitialized(
            address(jasperVault),
            address(_delegatedManager)
        );
    }

    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        IJasperVault jasperVault = delegatedManager.jasperVault();
        _removeExtension(jasperVault, delegatedManager);
    }

  


}
