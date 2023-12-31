/*
    Copyright 2021 Set Labs Inc.

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

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeCast.sol";
import "./SafeMath.sol";

import "./IController.sol";
import "./IIntegrationRegistry.sol";
import "./Invoke.sol";
import "./IJasperVault.sol";
import "./IDelegatedManager.sol";
import "./IGMXAdapter.sol";
import "./IGMXCallBack.sol";
import "./IGMXReader.sol";
import "./ModuleBase.sol";
import "./Position.sol";
import "./PreciseUnitMath.sol";
import "./IGMXModule.sol";
import "./IWETH.sol";
import "./Ownable.sol";

interface IERC20MetaData {
    function decimals() external view returns (uint256);

    function stakedAmounts(address accmount) external view returns (uint256);
}

contract GMXModule is
    ModuleBase,
    ReentrancyGuard,
    IPositionRouterCallbackReceiver,
    IGMXModule,
    Ownable
{
    using SafeCast for int256;
    using PreciseUnitMath for uint256;
    using PreciseUnitMath for int256;

    using Position for uint256;
    using SafeMath for uint256;

    using Invoke for IJasperVault;
    using Position for IJasperVault.Position;
    using Position for IJasperVault;

    /* ============ Events ============ */

    event InCreasingPosition(
        IJasperVault _jasperVault,
        IGMXAdapter.IncreasePositionRequest,
        bytes key
    );
    event DeCreasingPosition(
        IJasperVault _jasperVault,
        IGMXAdapter.DecreasePositionRequest
    );
    event Swap(IJasperVault _jasperVault, IGMXAdapter.SwapData);
    event CreatOrder(IJasperVault _jasperVault, IGMXAdapter.CreateOrderData);
    event StakeGMX(IJasperVault _jasperVault, IGMXAdapter.StakeGMXData);
    event StakeGLP(IJasperVault _jasperVault, IGMXAdapter.StakeGLPData);
    event HandleRewards(
        IJasperVault _jasperVault,
        IGMXAdapter.HandleRewardData
    );
    event UpdatePosition(
        IJasperVault _jasperVault,
        address _token,
        uint256 coinType,
        uint256 tokanBalance
    );

    event GMXPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease,
        PositionData PositionModuleData,
        IJasperVault.Position[] oldPosition,
        IJasperVault.Position[] newPosition
    );

    /* ============ State Variables ============ */
    function weth() external view override returns (IWETH) {
        return IWETH(address(0));
    }

    uint256 public immutable coinTypeIndexToken = 11;
    uint256 public immutable coinTypeStakeGMX = 12;
    uint256 public gmxPositionDecimals = 30;

    struct PositionData {
        address _jasperVault;
        address _collateralToken;
        address _indexToken;
    }

    mapping(bytes => PositionData) requestKey2Position;
    address public usdcAddr;
    address public gmxReader;
    address public gmxVault;
    address public sbfGMXToken;
    address public sGLP;
    address public glpManager;

    /* ============ Constructor ============ */

    /*
  @param _controller               Address of controller contract
   */
    constructor(
        IController _controller,
        address _usdcAddr,
        address _gmxReader,
        address _gmxVault,
        address _sbfGMXToken,
        address _sGLP,
        address _GlpRewardRouter
    ) public ModuleBase(_controller) {
        usdcAddr = _usdcAddr;
        gmxReader = _gmxReader;
        gmxVault = _gmxVault;
        sbfGMXToken = _sbfGMXToken;
        sGLP = _sGLP;
        glpManager = _GlpRewardRouter;
    }

    function manageAddress(
        IController _controller,
        address _usdcAddr,
        address _gmxReader,
        address _gmxVault,
        address _sbfGMXToken,
        address _sGLP,
        address _GlpRewardRouter
    ) public onlyOwner {
        usdcAddr = _usdcAddr;
        gmxReader = _gmxReader;
        gmxVault = _gmxVault;
        sbfGMXToken = _sbfGMXToken;
        sGLP = _sGLP;
        glpManager = _GlpRewardRouter;
    }

    /**
     * Initializes this module to the JasperVault. Only callable by the JasperVault's manager.
     *
     * @param _jasperVault             Instance of the JasperVault to issue
     */
    function initialize(
        IJasperVault _jasperVault
    ) external override onlySetManager(_jasperVault, msg.sender) {
        require(
            controller.isSet(address(_jasperVault)),
            "Must be controller-enabled JasperVault"
        );
        require(
            isSetPendingInitialization(_jasperVault),
            "Must be pending initialization"
        );
        _jasperVault.initializeModule();
    }

    /**
     * Removes this module from the JasperVault, via call by the JasperVault.
     */
    function removeModule() external override {}

    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external override {
        PositionData memory _positionDict = requestKey2Position[
            abi.encodePacked(positionKey)
        ];
        bytes memory _data;
        IJasperVault _jasperVault = IJasperVault(_positionDict._jasperVault);
        IJasperVault.Position[] memory oldPosition = _jasperVault
            .getPositions();

        _updatePosition(_jasperVault, _positionDict._collateralToken, 0);
        _updatePosition(
            _jasperVault,
            _positionDict._indexToken,
            coinTypeIndexToken
        );

        IJasperVault.Position[] memory newPosition = _jasperVault
            .getPositions();
        emit GMXPositionCallback(
            positionKey,
            isExecuted,
            isIncrease,
            _positionDict,
            oldPosition,
            newPosition
        );
    }

    function increasingPosition(
        IJasperVault _jasperVault,
        IGMXAdapter.IncreasePositionRequest memory request
    ) external override nonReentrant onlyManagerAndValidSet(_jasperVault) {
        _validateAndIncreasingPosition(
            _jasperVault,
            request._integrationName,
            request
        );
    }

    function _validateAndIncreasingPosition(
        IJasperVault _jasperVault,
        string memory _integrationName,
        IGMXAdapter.IncreasePositionRequest memory request
    ) internal {
        // Snapshot pre OpenPosition balances
        if (request._amountInUnits < 0) {
            request._amountIn = _getBalance(_jasperVault, request._path[0]);
        } else {
            request._amountIn = _jasperVault
                .totalSupply()
                .getDefaultTotalNotional(request._amountInUnits.abs());
        }
        request._minOut = _jasperVault.totalSupply().getDefaultTotalNotional(
            request._minOutUnits
        );

        request._sizeDelta = _jasperVault.totalSupply().getDefaultTotalNotional(
            request._sizeDeltaUnits
        );

        IGMXAdapter gmxAdapter = IGMXAdapter(
            getAndValidateAdapter(_integrationName)
        );
        _jasperVault.invokeApprove(
            request._path[0],
            gmxAdapter.GMXRouter(),
            request._amountIn
        );
        // Get function call key and invoke on JasperVault
        bytes memory key = _createIncreasingPositionCallDataAndInvoke(
            _jasperVault,
            gmxAdapter,
            request
        );
        requestKey2Position[key]._jasperVault = address(_jasperVault);
        requestKey2Position[key]._collateralToken = request._path[0];
        requestKey2Position[key]._indexToken = request._indexToken;

        _updatePosition(_jasperVault, request._path[0], 0);
        _updatePosition(_jasperVault, request._indexToken, coinTypeIndexToken);
        emit InCreasingPosition(_jasperVault, request, key);

        return;
    }

    /**
     * Create the memory for _positionData and then invoke the call on the JasperVault.
     */
    function _createIncreasingPositionCallDataAndInvoke(
        IJasperVault _jasperVault,
        IGMXAdapter _gmxAdapter,
        IGMXAdapter.IncreasePositionRequest memory request
    ) internal returns (bytes memory) {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _gmxAdapter.getInCreasingPositionCallData(request);

        return _jasperVault.invoke(callTarget, callValue, callByteData);
    }

    function decreasingPosition(
        IJasperVault _jasperVault,
        IGMXAdapter.DecreasePositionRequest memory request
    ) external override nonReentrant onlyManagerAndValidSet(_jasperVault) {
        _validateAndDecreasingPosition(
            _jasperVault,
            request._integrationName,
            request
        );
    }

    /**
     * The module calculates the total notional Decreasing token to GMX, then invokes the JasperVault to call
     * decreasing position by passing its memory along.
     *
     * Returns notional amount of underlying tokens  _decreasingPosition and tokens postActionPosition.
     */
    function _validateAndDecreasingPosition(
        IJasperVault _jasperVault,
        string memory _integrationName,
        IGMXAdapter.DecreasePositionRequest memory request
    ) internal {
        request._collateralDelta = _jasperVault
            .totalSupply()
            .getDefaultTotalNotional(request._collateralUnits.abs());

        request._sizeDelta = _jasperVault.totalSupply().getDefaultTotalNotional(
            request._sizeDeltaUnits.abs()
        );
        request._minOut = _jasperVault.totalSupply().getDefaultTotalNotional(
            request._minOutUnits
        );

        IGMXAdapter gmxAdapter = IGMXAdapter(
            getAndValidateAdapter(_integrationName)
        );
        // Get function call data and invoke on JasperVault
        _createDecreasingPositionDataAndInvoke(
            _jasperVault,
            gmxAdapter,
            request
        );
        //_collateralTokens
        _updatePosition(
            _jasperVault,
            request._path[request._path.length - 1],
            0
        );
        _updatePosition(_jasperVault, request._indexToken, coinTypeIndexToken);
        emit DeCreasingPosition(_jasperVault, request);
        return;
    }

    /**
     * Create the memory for gmx decreasing position and then invoke the call on the JasperVault.
     */
    function _createDecreasingPositionDataAndInvoke(
        IJasperVault _jasperVault,
        IGMXAdapter _gmxAdapter,
        IGMXAdapter.DecreasePositionRequest memory request
    ) internal {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _gmxAdapter.getDeCreasingPositionCallData(request);

        _jasperVault.invoke(callTarget, callValue, callByteData);
    }

    /**
     * Take snapshot of JasperVault's balance of  tokens.
     */
    function _getBalance(
        IJasperVault _jasperVault,
        address _collateralToken
    ) internal view returns (uint256) {
        return IERC20(_collateralToken).balanceOf(address(_jasperVault));
    }

    function toBytes(bytes32 _data) public pure returns (bytes memory) {
        return abi.encodePacked(_data);
    }

    /**
     *
     * @param _jasperVault             Instance of the JasperVault
     */
    function swap(
        IJasperVault _jasperVault,
        IGMXAdapter.SwapData memory data
    ) external override nonReentrant onlyManagerAndValidSet(_jasperVault) {
        (
            uint256 preActionUnderlyingNotional,
            uint256 postActionPosition
        ) = _validateAndSwap(_jasperVault, data._integrationName, data);
        emit Swap(_jasperVault, data);
    }

    /**
     * The GMXModule calculates the total notional underlying to Open Increasing Position, approves the underlying to the 3rd party
     * integration contract, then invokes the JasperVault to call Increasing Position by passing its memory along.
     * Returns notional amount of underlying tokens and positionToken.
     */
    function _validateAndSwap(
        IJasperVault _jasperVault,
        string memory _integrationName,
        IGMXAdapter.SwapData memory data
    ) internal returns (uint256, uint256) {
        // Snapshot pre OpenPosition balances
        uint256 preActionUnderlyingNotional = _getBalance(
            _jasperVault,
            data._path[0]
        );

        if (data._amountInUnits < 0) {
            data._amountIn = preActionUnderlyingNotional;
        } else {
            data._amountIn = _jasperVault.totalSupply().getDefaultTotalNotional(
                data._amountInUnits.abs()
            );
        }
        data._minOut = _jasperVault.totalSupply().getDefaultTotalNotional(
            data._minOutUnits
        );
        IGMXAdapter gmxAdapter = IGMXAdapter(
            getAndValidateAdapter(_integrationName)
        );
        _jasperVault.invokeApprove(
            data._path[0],
            gmxAdapter.GMXRouter(),
            data._amountIn
        );
        // Get function call data and invoke on JasperVault
        _createSwapCallDataAndInvoke(_jasperVault, gmxAdapter, data);

        uint256 postActionPosition = _getBalance(_jasperVault, data._path[0]);
        _updatePosition(_jasperVault, data._path[0], 0);
        _updatePosition(_jasperVault, data._path[data._path.length - 1], 0);
        return (preActionUnderlyingNotional, postActionPosition);
    }

    /**
     * Create the memory for _positionData and then invoke the call on the JasperVault.
     */
    function _createSwapCallDataAndInvoke(
        IJasperVault _jasperVault,
        IGMXAdapter _gmxAdapter,
        IGMXAdapter.SwapData memory data
    ) internal returns (bytes memory) {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _gmxAdapter.getSwapCallData(data);
        return _jasperVault.invoke(callTarget, callValue, callByteData);
    }

    function creatOrder(
        IJasperVault _jasperVault,
        IGMXAdapter.CreateOrderData memory data
    ) external override nonReentrant onlyManagerAndValidSet(_jasperVault) {
        _validateAndCreateOrder(
            _jasperVault,
            data._integrationName,
            data._isLong,
            data._positionData
        );
        emit CreatOrder(_jasperVault, data);
    }

    function _validateAndCreateOrder(
        IJasperVault _jasperVault,
        string memory _integrationName,
        bool _isLong,
        bytes memory _positionData
    ) internal {
        IGMXAdapter gmxAdapter = IGMXAdapter(
            getAndValidateAdapter(_integrationName)
        );

        if (_isLong) {
            IGMXAdapter.IncreaseOrderData memory data = abi.decode(
                _positionData,
                (IGMXAdapter.IncreaseOrderData)
            );
            // Snapshot pre OpenPosition balances
            uint256 preActionUnderlyingNotional = _getBalance(
                _jasperVault,
                data._path[0]
            );
            if (data._amountInUnits < 0) {
                data._amountIn = preActionUnderlyingNotional;
            } else {
                data._amountIn = _jasperVault
                    .totalSupply()
                    .getDefaultTotalNotional(data._amountInUnits.abs());
            }
            _jasperVault.invokeApprove(
                data._path[0],
                gmxAdapter.GMXRouter(),
                data._amountIn
            );

            data._minOut = _jasperVault.totalSupply().getDefaultTotalNotional(
                data._minOutUnits
            );
            data._sizeDelta = _jasperVault
                .totalSupply()
                .getDefaultTotalNotional(data._sizeDeltaUnits);
            // Get function call data and invoke on JasperVault
            _createIncreaseOrderCallDataAndInvoke(
                _jasperVault,
                gmxAdapter,
                data
            );
            _updatePosition(_jasperVault, data._path[0], 0);
            _updatePosition(_jasperVault, data._indexToken, coinTypeIndexToken);
        } else {
            IGMXAdapter.DecreaseOrderData memory data = abi.decode(
                _positionData,
                (IGMXAdapter.DecreaseOrderData)
            );
            data._sizeDelta = _jasperVault
                .totalSupply()
                .getDefaultTotalNotional(data._sizeDeltaUnits);
            data._collateralDelta = _jasperVault
                .totalSupply()
                .getDefaultTotalNotional(data._collateralDeltaUnits);
            // Get function call data and invoke on JasperVault
            _createDecreaseOrderCallDataAndInvoke(
                _jasperVault,
                gmxAdapter,
                data
            );
            _updatePosition(_jasperVault, data._indexToken, 0);
            _updatePosition(
                _jasperVault,
                data._collateralToken,
                coinTypeIndexToken
            );
        }
        return;
    }

    /**
     * Create the memory for _positionData and then invoke the call on the JasperVault.
     */
    function _createIncreaseOrderCallDataAndInvoke(
        IJasperVault _jasperVault,
        IGMXAdapter _gmxAdapter,
        IGMXAdapter.IncreaseOrderData memory _data
    ) internal returns (bytes memory) {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _gmxAdapter.getCreateIncreaseOrderCallData(_data);
        return _jasperVault.invoke(callTarget, callValue, callByteData);
    }

    /**
     * Create the memory for _positionData and then invoke the call on the JasperVault.
     */
    function _createDecreaseOrderCallDataAndInvoke(
        IJasperVault _jasperVault,
        IGMXAdapter _gmxAdapter,
        IGMXAdapter.DecreaseOrderData memory _data
    ) internal returns (bytes memory) {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _gmxAdapter.getCreateDecreaseOrderCallData(_data);
        return _jasperVault.invoke(callTarget, callValue, callByteData);
    }

    function getGMXPositionTotalUnit(
        IJasperVault _jasperVault,
        address _indexToken
    ) public returns (int256) {
        address[] memory _collateralTokens = new address[](1);
        _collateralTokens[0] = usdcAddr;
        address[] memory _indexTokens = new address[](1);
        _indexTokens[0] = _indexToken;
        bool[] memory _isLong = new bool[](1);
        uint256[] memory _IncreasingGMXPosition = IGMXReader(gmxReader)
            .getPositions(
                gmxVault,
                address(_jasperVault),
                _collateralTokens,
                _indexTokens,
                _isLong
            );
        _isLong[0] = true;
        uint256[] memory _DecreasingGMXPosition = IGMXReader(gmxReader)
            .getPositions(
                gmxVault,
                address(_jasperVault),
                _collateralTokens,
                _indexTokens,
                _isLong
            );
        return
            int256(_IncreasingGMXPosition[0]) -
            int256(_DecreasingGMXPosition[0]);
    }

    function _createStakeGMXCallDataAndInvoke(
        IJasperVault _jasperVault,
        IGMXAdapter _gmxAdapter,
        address _collateralToken,
        uint256 _stakeAmount,
        bool _isStake,
        bytes memory _data
    ) internal returns (bytes memory) {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _gmxAdapter.getStakeGMXCallData(
                address(_jasperVault),
                _stakeAmount,
                _isStake,
                _data
            );

        return _jasperVault.invoke(callTarget, callValue, callByteData);
    }

    function stakeGMX(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGMXData memory data
    ) external override nonReentrant onlyManagerAndValidSet(_jasperVault) {
        // Snapshot pre OpenPosition balances
        uint256 preActionUnderlyingNotional = _getBalance(
            _jasperVault,
            data._collateralToken
        );

        uint256 notionalUnderlying;

        if (data._underlyingUnits < 0) {
            notionalUnderlying = preActionUnderlyingNotional;
        } else {
            notionalUnderlying = _jasperVault
                .totalSupply()
                .getDefaultTotalNotional(data._underlyingUnits.abs());
        }
        if (data._isStake) {
            _jasperVault.invokeApprove(
                data._collateralToken,
                sbfGMXToken,
                notionalUnderlying
            );
        }
        IGMXAdapter gmxAdapter = IGMXAdapter(
            getAndValidateAdapter(data._integrationName)
        );
        // Get function call data and invoke on JasperVault
        _createStakeGMXCallDataAndInvoke(
            _jasperVault,
            gmxAdapter,
            data._collateralToken,
            notionalUnderlying,
            data._isStake,
            data._positionData
        );

        _updatePosition(_jasperVault, data._collateralToken, 0);
        _updatePosition(_jasperVault, data._collateralToken, coinTypeStakeGMX);
        emit StakeGMX(_jasperVault, data);
    }

    function _createStakeGLPCallDataAndInvoke(
        IJasperVault _jasperVault,
        IGMXAdapter _gmxAdapter,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp,
        bool _isStake,
        bytes memory _data
    ) internal returns (bytes memory) {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _gmxAdapter.getStakeGLPCallData(
                address(_jasperVault),
                _token,
                _amount,
                _minUsdg,
                _minGlp,
                _isStake,
                _data
            );

        return _jasperVault.invoke(callTarget, callValue, callByteData);
    }

    function stakeGLP(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGLPData memory data
    ) external override nonReentrant onlyManagerAndValidSet(_jasperVault) {
        uint256 _tokeAmount;
        if (data._amountUnits < 0) {
            if (data._isStake) {
                _tokeAmount = _getBalance(_jasperVault, data._token);
            } else {
                _tokeAmount = _getBalance(_jasperVault, sGLP);
            }
        } else {
            _tokeAmount = _jasperVault.totalSupply().getDefaultTotalNotional(
                data._amountUnits.abs()
            );
        }
        data._minUsdg = _jasperVault.totalSupply().getDefaultTotalNotional(
            data._minUsdgUnits
        );
        data._minGlp = _jasperVault.totalSupply().getDefaultTotalNotional(
            data._minGlpUnits
        );
        if (data._isStake) {
            _jasperVault.invokeApprove(data._token, glpManager, _tokeAmount);
        }
        IGMXAdapter gmxAdapter = IGMXAdapter(
            getAndValidateAdapter(data._integrationName)
        );
        // Get function call data and invoke on JasperVault
        _createStakeGLPCallDataAndInvoke(
            _jasperVault,
            gmxAdapter,
            data._token,
            _tokeAmount,
            data._minUsdg,
            data._minGlp,
            data._isStake,
            data._data
        );

        _updatePosition(_jasperVault, data._token, 0);
        _updatePosition(_jasperVault, sGLP, 0);
        emit StakeGLP(_jasperVault, data);
    }

    function handleRewards(
        IJasperVault _jasperVault,
        IGMXAdapter.HandleRewardData memory data
    ) external override nonReentrant onlyManagerAndValidSet(_jasperVault) {
        IGMXAdapter gmxAdapter = IGMXAdapter(
            getAndValidateAdapter(data._integrationName)
        );
        // Get function call data and invoke on JasperVault
        _createHandleRewardsCallDataAndInvoke(_jasperVault, gmxAdapter, data);
        emit HandleRewards(_jasperVault, data);
    }

    function _createHandleRewardsCallDataAndInvoke(
        IJasperVault _jasperVault,
        IGMXAdapter _gmxAdapter,
        IGMXAdapter.HandleRewardData memory data
    ) internal {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _gmxAdapter.getHandleRewardsCallData(data);

        _jasperVault.invoke(callTarget, callValue, callByteData);
    }

    function _updatePositionModuleAndCoinType(
        IJasperVault _jasperVault,
        address _token,
        address module,
        uint256 coinType
    ) internal {
        if (!_jasperVault.isExternalPositionModule(_token, address(this))) {
            _jasperVault.addExternalPositionModule(_token, address(this));
        }
        _jasperVault.editExternalPositionCoinType(
            _token,
            address(this),
            coinType
        );
    }

    function _updatePositionByBalance(
        IJasperVault _jasperVault,
        string memory _integrationName,
        address _token
    ) public {
        require(
            IDelegatedManager(_jasperVault.manager()).owner() == msg.sender,
            "only _jasperVault Owner"
        );
        IGMXAdapter gmxAdapter = IGMXAdapter(
            getAndValidateAdapter(_integrationName)
        );
        uint256 tokenBalance = gmxAdapter.getTokenBalance(
            _token,
            address(_jasperVault)
        );
        _jasperVault.editDefaultPosition(
            _token,
            tokenBalance.mul(1 ether).div(_jasperVault.totalSupply())
        );
    }

    /**
     * edit position with new token
     */
    function _updatePosition(
        IJasperVault _jasperVault,
        address _token,
        uint256 coinType
    ) public {
        bytes memory _data;
        if (coinType == coinTypeIndexToken) {
            int256 tokenUint = getGMXPositionTotalUnit(_jasperVault, _token);
            int256 tokenBalance = (tokenUint *
                int256(10 ** IERC20MetaData(_token).decimals())) /
                int256(10 ** gmxPositionDecimals);
            emit UpdatePosition(
                _jasperVault,
                _token,
                coinType,
                uint256(tokenBalance)
            );
            int256 newTokenUnit = (tokenBalance * int256(1 ether)) /
                int256(_jasperVault.totalSupply());
            _jasperVault.editExternalPosition(
                _token,
                address(this),
                newTokenUnit,
                _data
            );
            _updatePositionModuleAndCoinType(
                _jasperVault,
                _token,
                address(this),
                coinType
            );
        } else if (coinType == coinTypeStakeGMX) {
            int256 tokenBalance = int256(
                IERC20MetaData(sbfGMXToken).stakedAmounts(address(_jasperVault))
            );
            int256 newTokenUnit = (tokenBalance * int256(1 ether)) /
                int256(_jasperVault.totalSupply());
            _jasperVault.editExternalPosition(
                _token,
                address(this),
                newTokenUnit,
                _data
            );
            _updatePositionModuleAndCoinType(
                _jasperVault,
                _token,
                address(this),
                coinType
            );
        } else {
            uint256 tokenBalance = IERC20(_token).balanceOf(
                address(_jasperVault)
            );
            emit UpdatePosition(_jasperVault, _token, coinType, tokenBalance);
            uint256 newTokenUnit = tokenBalance.mul(1 ether).div(
                _jasperVault.totalSupply()
            );
            _jasperVault.editDefaultPosition(_token, newTokenUnit);
        }
    }
}
