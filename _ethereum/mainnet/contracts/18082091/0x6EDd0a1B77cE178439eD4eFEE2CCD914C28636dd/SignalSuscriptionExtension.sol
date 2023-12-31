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

import "./IJasperVault.sol";
import "./ISignalSuscriptionModule.sol";

import "./BaseGlobalExtension.sol";
import "./IDelegatedManager.sol";
import "./IManagerCore.sol";
import "./AddressArrayUtils.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
interface IOwnable {
    function owner() external view returns (address);
}
interface IAaveLeverageModule{
    function  sync(IJasperVault _jasperVault) external ;
}

contract SignalSuscriptionExtension is BaseGlobalExtension {   
    /* ============ Events ============ */
    using AddressArrayUtils for address[];
    using SafeERC20 for IERC20;
    event SignalSuscriptionExtensionInitialized(
        address indexed _jasperVault,
        address indexed _delegatedManager
    );

    event EditFeeAndInfo(
        IJasperVault indexed _jasperVault,
        uint256 _profitShareFee,
        uint256 _delay
    );

    // event SetSubscribeTarget(
    //      address indexed _jasperVault,
    //      address target
    // );
    event SetSubscribeStatus(IJasperVault indexed _jasperVault, uint256 status);

    event SetWhiteList(
        IJasperVault indexed _jasperVault,
        address user,
        bool status
    );

    /* ============ State Variables ============ */

    // Instance of SignalSuscriptionModule
    ISignalSuscriptionModule public immutable signalSuscriptionModule;

    mapping(IJasperVault => address[]) public whiteList;
    mapping(IJasperVault => bool) public allowSubscribe;

    mapping(IJasperVault => uint256) public allowMaxSubscribe;
    mapping(IJasperVault => uint256) public currentSubscribeNumber;
    //settleType == 1 outSettle
    mapping(IJasperVault=> uint256) public settleTypes;
    IAaveLeverageModule public aaveLeverageModule;
    /* ============ Constructor ============ */

    constructor(
        IManagerCore _managerCore,
        ISignalSuscriptionModule _signalSuscriptionModule,
        IAaveLeverageModule _aaveLeverageModule
    ) public BaseGlobalExtension(_managerCore) {
        signalSuscriptionModule = _signalSuscriptionModule;
        aaveLeverageModule = _aaveLeverageModule;
    }

    /* ============ External Functions ============ */

    function setWhiteListAndSubscribeStatus(
        IJasperVault _jasperVault,
        address[] memory _addList,
        uint256[] memory _settleType, 
        address[] memory _delList,
        uint256 _allowMaxSubscribe,
        bool _status
    ) external onlyOperator(_jasperVault) {
        allowSubscribe[_jasperVault] = _status;
        address[] memory currentWhiteList=whiteList[_jasperVault];
        allowMaxSubscribe[_jasperVault]=1;
        for (uint256 i = 0; i < _addList.length; i++) {
            bool isExist = currentWhiteList.contains(_addList[i]);
            if (!isExist) {
                settleTypes[_jasperVault]=_settleType[i];
                whiteList[_jasperVault].push(_addList[i]);
                emit SetWhiteList(_jasperVault, _addList[i], true);
            }
        }
        for (uint256 i = 0; i < _delList.length; i++) {
            bool isExist = currentWhiteList.contains(_delList[i]);
            if (isExist) {
                delete  settleTypes[_jasperVault];
                whiteList[_jasperVault].removeStorage(_delList[i]);
                emit SetWhiteList(_jasperVault, _delList[i], false);
            }
        }
    }

    /**
     * ONLY OWNER: Initializes SignalSuscriptionModule on the JasperVault associated with the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     */
    function initializeModule(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        require(
            _delegatedManager.isInitializedExtension(address(this)),
            "Extension must be initialized"
        );

        _initializeModule(_delegatedManager.jasperVault(), _delegatedManager);
    }

    /**
     * ONLY OWNER: Initializes TradeExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        require(
            _delegatedManager.isPendingExtension(address(this)),
            "Extension must be pending"
        );

        IJasperVault jasperVault = _delegatedManager.jasperVault();

        _initializeExtension(jasperVault, _delegatedManager);

        emit SignalSuscriptionExtensionInitialized(
            address(jasperVault),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY OWNER: Initializes TradeExtension to the DelegatedManager and TradeModule to the JasperVault
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        require(
            _delegatedManager.isPendingExtension(address(this)),
            "Extension must be pending"
        );

        IJasperVault jasperVault = _delegatedManager.jasperVault();

        _initializeExtension(jasperVault, _delegatedManager);
        _initializeModule(jasperVault, _delegatedManager);

        emit SignalSuscriptionExtensionInitialized(
            address(jasperVault),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY MANAGER: Remove an existing JasperVault and DelegatedManager tracked by the TradeExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        IJasperVault jasperVault = delegatedManager.jasperVault();

        _removeExtension(jasperVault, delegatedManager);
    }

    function editFeeAndInfo(
        IJasperVault _jasperVault,
        address _masterToken,
        uint256 _profitShareFee,
        uint256 _delay
    ) external onlyReset(_jasperVault) onlyOperator(_jasperVault) {
        address[] memory followers = signalSuscriptionModule.get_followers(
            address(_jasperVault)
        );
        for (uint256 i = 0; i < followers.length; i++) {
            bytes memory callData = abi.encodeWithSelector(
                ISignalSuscriptionModule.unsubscribe.selector,
                followers[i],
                address(_jasperVault)
            );
            _invokeManager(
                _manager(IJasperVault(followers[i])),
                address(signalSuscriptionModule),
                callData
            );
            _manager(IJasperVault(followers[i])).setSubscribeStatus(2);   
            emit SetSubscribeStatus(IJasperVault(followers[i]), 2);
        }
        _manager(_jasperVault).setBaseFeeAndToken(
            _masterToken,
            _profitShareFee,
            _delay
        );
        currentSubscribeNumber[_jasperVault]=0;
        emit EditFeeAndInfo(_jasperVault, _profitShareFee, _delay);
    }

    function subscribe(
        IJasperVault _jasperVault,
        address target
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyPrimeMember(_jasperVault, target)
    {
        checkWhiteList(IJasperVault(target));
        bytes memory callData = abi.encodeWithSelector(
            ISignalSuscriptionModule.subscribe.selector,
            _jasperVault,
            target
        );
        _invokeManager(
            _manager(_jasperVault),
            address(signalSuscriptionModule),
            callData
        );
        _manager(_jasperVault).setSubscribeStatus(1);
        currentSubscribeNumber[IJasperVault(target)] =
            currentSubscribeNumber[IJasperVault(target)] +
            1;
        emit SetSubscribeStatus(_jasperVault, 1);
    }

    function unsubscribe(
        IJasperVault _jasperVault,
        address target
    ) external onlySubscribed(_jasperVault) onlyOperator(_jasperVault) {
        _unsubscribe(_jasperVault, target);
    }

    function unsubscribeByExtension(
        IJasperVault _jasperVault,
        address target
    )
        external
        onlySubscribed(_jasperVault)
        onlyExtension(IJasperVault(target))
    {
        _unsubscribe(_jasperVault, target);
    }

    function _unsubscribe(IJasperVault _jasperVault, address target) internal {
        bytes memory callData = abi.encodeWithSelector(
            ISignalSuscriptionModule.unsubscribe.selector,
            _jasperVault,
            target
        );
        _invokeManager(
            _manager(_jasperVault),
            address(signalSuscriptionModule),
            callData
        );
        _manager(_jasperVault).setSubscribeStatus(2);
        currentSubscribeNumber[IJasperVault(target)] =
            currentSubscribeNumber[IJasperVault(target)] -
            1;
        emit SetSubscribeStatus(_jasperVault, 2);
    }

    //masterVault unsubscribe  followVault
    function unsubscribeByMaster(
        IJasperVault _target,
        bool _isAll,
        address[] memory _followers
    ) external onlyOperator(_target) {
        address[] memory allFollower = signalSuscriptionModule.get_followers(
            address(_target)
        );
        if(allFollower.length>0){
            if (_isAll) {
                delete currentSubscribeNumber[_target];
                bytes memory callData = abi.encodeWithSelector(
                    ISignalSuscriptionModule.unsubscribeByMaster.selector,
                    _target
                );
                _invokeManager(
                    _manager(_target),
                    address(signalSuscriptionModule),
                    callData
                );
                //edit subscribeStatus
                for (uint256 i = 0; i < allFollower.length; i++) {
                    _manager(IJasperVault(allFollower[i])).setSubscribeStatus(2);
                }
            } else {
                for (uint256 i = 0; i < _followers.length; i++) {
                    if (allFollower.contains(_followers[i])) {
                        bytes memory callData = abi.encodeWithSelector(
                            ISignalSuscriptionModule.unsubscribe.selector,
                            IJasperVault(_followers[i]),
                            _target
                        );
                        _invokeManager(
                            _manager(IJasperVault(_followers[i])),
                            address(signalSuscriptionModule),
                            callData
                        );
                        _manager(IJasperVault(_followers[i])).setSubscribeStatus(2);
                        currentSubscribeNumber[_target] =
                            currentSubscribeNumber[_target] -
                            1;
                    }
                }
            }
        }
    }

    function exectueFollowEnd(
        address _jasperVault
    ) external onlyExtension(IJasperVault(_jasperVault)) {
        bytes memory callData = abi.encodeWithSelector(
            ISignalSuscriptionModule.exectueFollowEnd.selector,
            _jasperVault
        );
        _invokeManager(
            _manager(IJasperVault(_jasperVault)),
            address(signalSuscriptionModule),
            callData
        );
    }

    function reset(IJasperVault _jasperVault) external  onlyUnSubscribed(_jasperVault) onlyOperator(_jasperVault){
        address target= signalSuscriptionModule.get_signal_provider(_jasperVault);

        if(settleTypes[IJasperVault(target)]!=1){
        (address[] memory sharer,uint256[] memory shareFee)=signalSuscriptionModule.handleFee(_jasperVault);
         uint256 amount;
         for(uint i;i<shareFee.length;i++){
             amount+=shareFee[i];
         }
         address metamask=IOwnable(msg.sender).owner();
         address masterToken=_jasperVault.masterToken();
         IERC20(masterToken).safeTransferFrom(metamask,address(signalSuscriptionModule), amount);
         bytes memory callData = abi.encodeWithSelector(
            ISignalSuscriptionModule.handleTransferShareFee.selector,
            _jasperVault,
            sharer,
            shareFee
        );
        _invokeManager(
            _manager(IJasperVault(_jasperVault)),
            address(signalSuscriptionModule),
            callData
        );
        }
        _manager(_jasperVault).setSubscribeStatus(0);
        emit SetSubscribeStatus(_jasperVault,0);
    }

    /* ============ view Functions ============ */
    function getFollowers(
        address _jasperVault
    ) external view returns (address[] memory) {
        return signalSuscriptionModule.get_followers(_jasperVault);
    }

    function isWhiteListByMaster(
        IJasperVault _target,
        address _user
    ) external view returns (bool) {
        address[] memory list = whiteList[_target];
        bool isSubscribe = list.contains(_user);
        return isSubscribe;
    }

    function getWhiteList(
        IJasperVault _jasperVault
    ) external view returns (address[] memory) {
        return whiteList[_jasperVault];
    }

    function getExectueFollow(
        address _jasperVault
    ) external view returns (bool) {
        return signalSuscriptionModule.isExectueFollow(_jasperVault);
    }

    function warningLine() external view returns (uint256) {
        return signalSuscriptionModule.warningLine();
    }

    function unsubscribeLine() external view returns (uint256) {
        return signalSuscriptionModule.unsubscribeLine();
    }



    /* ============ Internal Functions ============ */
    function checkWhiteList(IJasperVault _jasperVault) internal view{
        require(
            allowSubscribe[_jasperVault],
            "jasperVault not allow subscribe"
        );
        require(
            currentSubscribeNumber[_jasperVault] <
                allowMaxSubscribe[_jasperVault],
            "target subscribe number already full"
        );
        require(isContract(msg.sender),"caller not contract");
        address owner = IOwnable(msg.sender).owner();
        address[] memory list = whiteList[_jasperVault];
        bool isExist = list.contains(owner);
        require(isExist, "user is not in the whitelist");
    }
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }
    /**
     * Internal function to initialize TradeModule on the JasperVault associated with the DelegatedManager.
     *
     * @param _jasperVault             Instance of the JasperVault corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     */
    function _initializeModule(
        IJasperVault _jasperVault,
        IDelegatedManager _delegatedManager
    ) internal {
        bytes memory callData = abi.encodeWithSignature(
            "initialize(address)",
            _jasperVault
        );
        _invokeManager(
            _delegatedManager,
            address(signalSuscriptionModule),
            callData
        );
    }
}
