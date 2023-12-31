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

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";

import "./IController.sol";
import "./Invoke.sol";
import "./IJasperVault.sol";
import "./ModuleBase.sol";
import "./Ownable.sol";
import "./PreciseUnitMath.sol";
import "./AddressArrayUtils.sol";
import "./IERC20.sol";
import "./ISubscribeFeePool.sol";
import "./IPriceOracle.sol";
/**
 * @title TradeModule
 * @author Set Protocol
 *
 * Module that enables SetTokens to perform atomic trades using Decentralized Exchanges
 * such as 1inch or Kyber. Integrations mappings are stored on the IntegrationRegistry contract.
 */
contract SignalSuscriptionModule is ModuleBase, Ownable, ReentrancyGuard {
    using SafeCast for int256;
    using SafeMath for uint256;

    using Invoke for IJasperVault;

    using PreciseUnitMath for uint256;
    using AddressArrayUtils for address[];

    mapping(address => address[]) public followers;

    mapping(address => bool) public isExectueFollow;

    uint256 public warningLine;
    uint256 public unsubscribeLine;
    //1%=1e16  100%=1e18
    uint256 public platformFee;
    address public platform_vault;

    address public mirrorToken;

    mapping(address => address) public Signal_provider;
    mapping(IJasperVault => uint256) public jasperVaultPreBalance;

    mapping(address => uint256) public followFees;

    mapping(address => uint256) public profitShareFees;

    ISubscribeFeePool public subscribeFeePool;

    event SetPlatformAndPlatformFee(
        ISubscribeFeePool _subscribeFeePool,
        uint256 _fee,
        address _platform_vault,
        uint256 _warningLine,
        uint256 _unsubscribeLine,
        address _mirrorToken
    );
    event RemoveFollower(address target, address follower);

    /* ============ Constructor ============ */

    constructor(
        IController _controller,
        ISubscribeFeePool _subscribeFeePool,
        uint256 _warningLine,
        uint256 _unsubscribeLine,
        uint256 _platformFee,
        address _platform_vault,
        address _mirrorToken
    ) public ModuleBase(_controller) {
        warningLine = _warningLine;
        unsubscribeLine = _unsubscribeLine;
        platformFee = _platformFee;
        subscribeFeePool = _subscribeFeePool;
        platform_vault = _platform_vault;
        mirrorToken = _mirrorToken;
    }

    /* ============ External Functions ============ */

    function exectueFollowStart(
        address _jasperVault
    ) external nonReentrant onlyManagerAndValidSet(IJasperVault(_jasperVault)) {
        require(
            !isExectueFollow[_jasperVault],
            "exectueFollow  status not false"
        );
        isExectueFollow[_jasperVault] = true;
    }

    function exectueFollowEnd(
        address _jasperVault
    ) external nonReentrant onlyManagerAndValidSet(IJasperVault(_jasperVault)) {
        require(isExectueFollow[_jasperVault], "exectueFollow status not true");
        isExectueFollow[_jasperVault] = false;
    }

    //1%=1e16  100%=1e18
    function setPlatformAndPlatformFee(
        ISubscribeFeePool _subscribeFeePool,
        address _platform_vault,
        uint256 _warningLine,
        uint256 _unsubscribeLine,
        uint256 _fee,
        address _mirrorToken
    ) external nonReentrant onlyOwner {
        require(_fee <= 10 ** 18, "fee can not be more than 1e18");
        subscribeFeePool = _subscribeFeePool;
        platformFee = _fee;
        platform_vault = _platform_vault;

        warningLine = _warningLine;
        unsubscribeLine = _unsubscribeLine;
        mirrorToken = _mirrorToken;
        emit SetPlatformAndPlatformFee(
            _subscribeFeePool,
            _fee,
            _platform_vault,
            _warningLine,
            _unsubscribeLine,
            _mirrorToken
        );
    }

    /**
     * Initializes this module to the JasperVault. Only callable by the JasperVault's manager.
     *
     * @param _jasperVault                 Instance of the JasperVault to initialize
     */
    function initialize(
        IJasperVault _jasperVault
    )
        external
        onlyValidAndPendingSet(_jasperVault)
        onlySetManager(_jasperVault, msg.sender)
    {
        _jasperVault.initializeModule();
    }

    /**
     * Removes this module from the JasperVault, via call by the JasperVault. Left with empty logic
     * here because there are no check needed to verify removal.
     */
    function removeModule() external override {}

    function subscribe(
        IJasperVault _jasperVault,
        address target
    ) external nonReentrant onlyManagerAndValidSet(_jasperVault) {
        uint256 preBalance = controller.getSetValuer().calculateSetTokenValuation(    
                _jasperVault,
                _jasperVault.masterToken()
            );
//        jasperVaultPreBalance[_jasperVault]=preBalance;
        followers[target].push(address(_jasperVault));
        Signal_provider[address(_jasperVault)] = target;
        profitShareFees[address(_jasperVault)] = IJasperVault(target).profitShareFee();         
    }

    function unsubscribe(
        IJasperVault _jasperVault,
        address target
    ) external nonReentrant onlyManagerAndValidSet(_jasperVault) {
        followers[target].removeStorage(address(_jasperVault));
    }

    function unsubscribeByMaster(
        address target
    ) external nonReentrant onlyManagerAndValidSet(IJasperVault(target)) {
        address[] memory list = followers[target];
        for (uint256 i = 0; i < list.length; i++) {
            followers[target].removeStorage(list[i]);
        }
    }

    function removeFollower(
        address target,
        address follower
    ) external nonReentrant onlyOwner {
        followers[target].removeStorage(follower);
        delete Signal_provider[follower];
        emit RemoveFollower(target, follower);
    }

    function get_followers(
        address target
    ) external view returns (address[] memory) {
        return followers[target];
    }

    function get_signal_provider(
        IJasperVault _jasperVault
    ) external view returns (address) {
        return Signal_provider[address(_jasperVault)];
    }

    //calculate fee
    function handleFee(
        IJasperVault _jasperVault
    ) external view  returns(address[] memory,uint256[] memory){
        uint256[] memory shareFee=new uint256[](2);
        address[] memory sharer=new address[](2); 
        uint256[3] memory param=[uint256(0),uint256(0),uint256(0)]; 
        address masterToken = _jasperVault.masterToken();
        address target = Signal_provider[address(_jasperVault)];

        param[0] = jasperVaultPreBalance[_jasperVault];

        param[1] = controller.getSetValuer().calculateSetTokenValuation(
                _jasperVault,
                _jasperVault.masterToken()
            );       
        if (param[1] > param[0]) {
            param[2] = _jasperVault.totalSupply();//总额
            IPriceOracle priceOracle = controller.getPriceOracle();

            uint256 componentPrice = priceOracle.getPrice(masterToken,  priceOracle.masterQuoteAsset());

            uint256 profit = param[1] - param[0];

            uint256 _strategistFee = profitShareFees[address(_jasperVault)]; 
            uint256 shareFeeBalance = profit.preciseMul(_strategistFee);
            uint256 platformFeeBalance = profit.preciseMul(platformFee);
             if (shareFeeBalance > profit) {
                platformFeeBalance =0;
                shareFeeBalance=profit;
             }      
             sharer[0]=target;
             shareFee[0]=shareFeeBalance.preciseMul(param[2]).preciseDiv(componentPrice);
             sharer[1]=platform_vault;
             shareFee[1]=platformFeeBalance.preciseMul(param[2]).preciseDiv(componentPrice);                    
        }
        return (sharer,shareFee);
    }

    function handleTransferShareFee(IJasperVault _jasperVault,address[] memory sharer,uint256[] memory shareFee) external nonReentrant onlyManagerAndValidSet(_jasperVault){      
            address masterToken=_jasperVault.masterToken();
            for(uint256 i;i<sharer.length;i++){
                if(shareFee[i]>0){
                   IERC20(masterToken).approve(address(subscribeFeePool), shareFee[i]);
                   subscribeFeePool.deposit(masterToken, sharer[i], shareFee[i]);
                }
            }   
            delete jasperVaultPreBalance[_jasperVault];
            delete Signal_provider[address(_jasperVault)];  
    }

    function handleResetFee(
        IJasperVault _target,
        IJasperVault _jasperVault,
        address _token,
        uint256 _amount
    ) external nonReentrant onlyManagerAndValidSet(_jasperVault) {
        if (_amount > 0) {
            IERC20(_token).approve(address(subscribeFeePool), _amount);
            subscribeFeePool.deposit(_token, address(_target), _amount);
        }
    }
}
