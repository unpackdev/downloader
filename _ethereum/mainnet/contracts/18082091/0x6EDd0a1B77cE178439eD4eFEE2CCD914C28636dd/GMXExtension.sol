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
import "./console.sol";

import "./IJasperVault.sol";
import "./IWETH.sol";
import "./IGMXModule.sol";
import "./IGMXAdapter.sol";

import "./BaseGlobalExtension.sol";
import "./IDelegatedManager.sol";
import "./IManagerCore.sol";
import "./ISignalSubscriptionModule.sol";

/**
 * @title GMXExtension
 * @author Set Protocol
 *
 * Smart contract global extension which provides DelegatedManager operator(s) the ability to GMX
 * via third party protocols.
 *
 */
contract GMXExtension is BaseGlobalExtension {
    /* ============ Events ============ */

    event GMXExtensionInitialized(
        address indexed _jasperVault,
        address indexed _delegatedManager
    );
    event InvokeFail(
        address indexed _manage,
        address _wrapModule,
        string _reason,
        bytes _callData
    );
    /* ============ State Variables ============ */

    // Instance of GMXModule
    IGMXModule public immutable GMXModule;

    ISignalSubscriptionModule public immutable signalSubscriptionModule;

    /* ============ Constructor ============ */

    /**
     * Instantiate with ManagerCore address and GMXModule address.
     *
     * @param _managerCore              Address of ManagerCore contract
     * @param _GMXModule               Address of GMXModule contract
     */
    constructor(
        IManagerCore _managerCore,
        IGMXModule _GMXModule,
        ISignalSubscriptionModule _signalSubscriptionModule
    ) public BaseGlobalExtension(_managerCore) {
        GMXModule = _GMXModule;
        signalSubscriptionModule = _signalSubscriptionModule;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY OWNER: Initializes GMXModule on the JasperVault associated with the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the GMXModule for jasperVault
     */
    function initializeModule(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        _initializeModule(_delegatedManager.jasperVault(), _delegatedManager);
    }

    /**
     * ONLY OWNER: Initializes GMXExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        IJasperVault jasperVault = _delegatedManager.jasperVault();

        _initializeExtension(jasperVault, _delegatedManager);

        emit GMXExtensionInitialized(
            address(jasperVault),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY OWNER: Initializes GMXExtension to the DelegatedManager and TradeModule to the JasperVault
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        IJasperVault jasperVault = _delegatedManager.jasperVault();

        _initializeExtension(jasperVault, _delegatedManager);
        _initializeModule(jasperVault, _delegatedManager);

        emit GMXExtensionInitialized(
            address(jasperVault),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY MANAGER: Remove an existing JasperVault and DelegatedManager tracked by the GMXExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        IJasperVault jasperVault = delegatedManager.jasperVault();

        _removeExtension(jasperVault, delegatedManager);
    }

    function increasingPosition(
        IJasperVault _jasperVault,
        IGMXAdapter.IncreasePositionRequest memory request
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
    // onlyAllowedAsset(_jasperVault, request._path[0])
    // ValidAdapter(_jasperVault, address(GMXModule), request._integrationName)
    {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.increasingPosition.selector,
            _jasperVault,
            request
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
    }

    function increasingPositionWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.IncreasePositionRequest memory request
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyAllowedAsset(_jasperVault, request._path[0])
        ValidAdapter(_jasperVault, address(GMXModule), request._integrationName)
    {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.increasingPosition.selector,
            _jasperVault,
            request
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
        _executeIncreasingPositionWithFollowers(_jasperVault, request);
        callData = abi.encodeWithSelector(
            ISignalSubscriptionModule.exectueFollowStart.selector,
            address(_jasperVault)
        );
        _invokeManager(
            _manager(_jasperVault),
            address(signalSubscriptionModule),
            callData
        );
    }

    function _executeIncreasingPositionWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.IncreasePositionRequest memory _positionData
    ) internal {
        address[] memory followers = signalSubscriptionModule.get_followers(
            address(_jasperVault)
        );
        for (uint256 i = 0; i < followers.length; i++) {
            bytes memory callData = abi.encodeWithSelector(
                IGMXModule.increasingPosition.selector,
                IJasperVault(followers[i]),
                _positionData
            );
            _execute(
                _manager(IJasperVault(followers[i])),
                address(GMXModule),
                callData
            );
        }
    }

    function _execute(
        IDelegatedManager manager,
        address module,
        bytes memory callData
    ) internal {
        try manager.interactManager(module, callData) {} catch Error(
            string memory reason
        ) {
            emit InvokeFail(address(manager), module, reason, callData);
        }
    }

    function decreasingPosition(
        IJasperVault _jasperVault,
        IGMXAdapter.DecreasePositionRequest memory request
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyAllowedAsset(_jasperVault, request._path[0])
        ValidAdapter(_jasperVault, address(GMXModule), request._integrationName)
    {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.decreasingPosition.selector,
            _jasperVault,
            request
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
    }

    function decreasingPositionWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.DecreasePositionRequest memory request
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyAllowedAsset(_jasperVault, request._path[0])
        ValidAdapter(_jasperVault, address(GMXModule), request._integrationName)
    {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.decreasingPosition.selector,
            _jasperVault,
            request
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
        _executeDecreasingPositionWithFollowers(_jasperVault, request);
        callData = abi.encodeWithSelector(
            ISignalSubscriptionModule.exectueFollowStart.selector,
            address(_jasperVault)
        );
        _invokeManager(
            _manager(_jasperVault),
            address(signalSubscriptionModule),
            callData
        );
    }

    function _executeDecreasingPositionWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.DecreasePositionRequest memory request
    ) internal {
        address[] memory followers = signalSubscriptionModule.get_followers(
            address(_jasperVault)
        );
        for (uint256 i = 0; i < followers.length; i++) {
            bytes memory callData = abi.encodeWithSelector(
                IGMXModule.decreasingPosition.selector,
                IJasperVault(followers[i]),
                request
            );
            _execute(
                _manager(IJasperVault(followers[i])),
                address(GMXModule),
                callData
            );
        }
    }

    function swap(
        IJasperVault _jasperVault,
        IGMXAdapter.SwapData memory data
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyAllowedAsset(_jasperVault, data._path[0])
        ValidAdapter(_jasperVault, address(GMXModule), data._integrationName)
    {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.swap.selector,
            _jasperVault,
            data
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
    }

    function swapWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.SwapData memory data
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyAllowedAsset(_jasperVault, data._path[0])
        ValidAdapter(_jasperVault, address(GMXModule), data._integrationName)
    {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.swap.selector,
            _jasperVault,
            data
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
        _executeSwapWithFollowers(_jasperVault, data);
        callData = abi.encodeWithSelector(
            ISignalSubscriptionModule.exectueFollowStart.selector,
            address(_jasperVault)
        );
        _invokeManager(
            _manager(_jasperVault),
            address(signalSubscriptionModule),
            callData
        );
    }

    function _executeSwapWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.SwapData memory data
    ) internal {
        address[] memory followers = signalSubscriptionModule.get_followers(
            address(_jasperVault)
        );
        for (uint256 i = 0; i < followers.length; i++) {
            bytes memory callData = abi.encodeWithSelector(
                IGMXModule.swap.selector,
                IJasperVault(followers[i]),
                data
            );
            _execute(
                _manager(IJasperVault(followers[i])),
                address(GMXModule),
                callData
            );
        }
    }

    function creatOrder(
        IJasperVault _jasperVault,
        IGMXAdapter.CreateOrderData memory _orderData
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        ValidAdapter(
            _jasperVault,
            address(GMXModule),
            _orderData._integrationName
        )
    {
        executeOrder(_jasperVault, _orderData);
    }

    function creatOrderWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.CreateOrderData memory _orderData
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        ValidAdapter(
            _jasperVault,
            address(GMXModule),
            _orderData._integrationName
        )
    {
        executeOrder(_jasperVault, _orderData);
        _executeCreateOrderWithFollowers(_jasperVault, _orderData);
        bytes memory callData = abi.encodeWithSelector(
            ISignalSubscriptionModule.exectueFollowStart.selector,
            address(_jasperVault)
        );
        _invokeManager(
            _manager(_jasperVault),
            address(signalSubscriptionModule),
            callData
        );
    }

    function executeOrder(
        IJasperVault _jasperVault,
        IGMXAdapter.CreateOrderData memory _orderData
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.creatOrder.selector,
            _jasperVault,
            _orderData
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
    }

    function _executeCreateOrderWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.CreateOrderData memory _orderData
    ) internal {
        address[] memory followers = signalSubscriptionModule.get_followers(
            address(_jasperVault)
        );
        for (uint256 i = 0; i < followers.length; i++) {
            executeOrder(IJasperVault(followers[i]), _orderData);
        }
    }

    function GMXStake(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGMXData memory _stakeData
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyAllowedAsset(_jasperVault, _stakeData._collateralToken)
        ValidAdapter(
            _jasperVault,
            address(GMXModule),
            _stakeData._integrationName
        )
    {
        executeStake(_jasperVault, _stakeData);
    }

    function executeStake(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGMXData memory _stakeData
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.stakeGMX.selector,
            _jasperVault,
            _stakeData
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
    }

    function GMXStakeWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGMXData memory _stakeData
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyAllowedAsset(_jasperVault, _stakeData._collateralToken)
        ValidAdapter(
            _jasperVault,
            address(GMXModule),
            _stakeData._integrationName
        )
    {
        executeStake(_jasperVault, _stakeData);
        _executeGMXStakeWithFollowers(_jasperVault, _stakeData);
        bytes memory callData = abi.encodeWithSelector(
            ISignalSubscriptionModule.exectueFollowStart.selector,
            address(_jasperVault)
        );
        _invokeManager(
            _manager(_jasperVault),
            address(signalSubscriptionModule),
            callData
        );
    }

    function _executeGMXStakeWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGMXData memory _stakeData
    ) internal {
        address[] memory followers = signalSubscriptionModule.get_followers(
            address(_jasperVault)
        );
        for (uint256 i = 0; i < followers.length; i++) {
            executeStake(IJasperVault(followers[i]), _stakeData);
        }
    }

    function stakeGLP(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGLPData memory _stakeData
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyAllowedAsset(_jasperVault, _stakeData._token)
        ValidAdapter(
            _jasperVault,
            address(GMXModule),
            _stakeData._integrationName
        )
    {
        executeGLPStake(_jasperVault, _stakeData);
    }

    function executeGLPStake(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGLPData memory _stakeData
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.stakeGLP.selector,
            _jasperVault,
            _stakeData
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
    }

    function stakeGLPWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGLPData memory _stakeData
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        onlyAllowedAsset(_jasperVault, _stakeData._token)
        ValidAdapter(
            _jasperVault,
            address(GMXModule),
            _stakeData._integrationName
        )
    {
        executeGLPStake(_jasperVault, _stakeData);
        _executeStakeGLPWithFollowers(_jasperVault, _stakeData);
        bytes memory callData = abi.encodeWithSelector(
            ISignalSubscriptionModule.exectueFollowStart.selector,
            address(_jasperVault)
        );
        _invokeManager(
            _manager(_jasperVault),
            address(signalSubscriptionModule),
            callData
        );
    }

    function _executeStakeGLPWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGLPData memory _stakeData
    ) internal {
        address[] memory followers = signalSubscriptionModule.get_followers(
            address(_jasperVault)
        );
        for (uint256 i = 0; i < followers.length; i++) {
            executeGLPStake(IJasperVault(followers[i]), _stakeData);
        }
    }

    function handleRewards(
        IJasperVault _jasperVault,
        IGMXAdapter.HandleRewardData calldata rewardData
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        ValidAdapter(
            _jasperVault,
            address(GMXModule),
            rewardData._integrationName
        )
    {
        executeHandleRewards(_jasperVault, rewardData);
    }

    function handleRewardsWithFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.HandleRewardData calldata rewardData
    )
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
        ValidAdapter(
            _jasperVault,
            address(GMXModule),
            rewardData._integrationName
        )
    {
        executeHandleRewards(_jasperVault, rewardData);
        _executeHandleRewardsFollowers(_jasperVault, rewardData);
        bytes memory callData = abi.encodeWithSelector(
            ISignalSubscriptionModule.exectueFollowStart.selector,
            address(_jasperVault)
        );
        _invokeManager(
            _manager(_jasperVault),
            address(signalSubscriptionModule),
            callData
        );
    }

    function _executeHandleRewardsFollowers(
        IJasperVault _jasperVault,
        IGMXAdapter.HandleRewardData calldata rewardData
    ) internal {
        address[] memory followers = signalSubscriptionModule.get_followers(
            address(_jasperVault)
        );
        for (uint256 i = 0; i < followers.length; i++) {
            bytes memory callData = abi.encodeWithSelector(
                IGMXModule.handleRewards.selector,
                _jasperVault,
                rewardData
            );
            _invokeManager(
                _manager(_jasperVault),
                address(GMXModule),
                callData
            );
        }
    }

    function executeHandleRewards(
        IJasperVault _jasperVault,
        IGMXAdapter.HandleRewardData calldata rewardData
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.handleRewards.selector,
            _jasperVault,
            rewardData
        );
        _invokeManager(_manager(_jasperVault), address(GMXModule), callData);
    }

    /**
     * Internal function to initialize GMXModule on the JasperVault associated with the DelegatedManager.
     *
     * @param _jasperVault             Instance of the JasperVault corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the GMXModule for
     */
    function _initializeModule(
        IJasperVault _jasperVault,
        IDelegatedManager _delegatedManager
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            IGMXModule.initialize.selector,
            _jasperVault
        );
        _invokeManager(_delegatedManager, address(GMXModule), callData);
    }
}
