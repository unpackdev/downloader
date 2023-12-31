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

import "./IGMXAdapter.sol";
import "./IGMXRouter.sol";
import "./IGMXOrderBook.sol";
import "./IGMXStake.sol";
import "./IGlpRewardRouter.sol";
import "./IRewardRouter.sol";

import "./IJasperVault.sol";
import "./Invoke.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/**
 * @title GMXAdapter
 * GMX adapter for GMX that returns data for (opening/increasing position)/(closing/decreasing position) of tokens
 */
contract GMXAdapter is Ownable, IGMXAdapter {
    using Invoke for IJasperVault;
    address public override PositionRouter;
    address public override GMXRouter;
    address public override ETH_TOKEN;
    address public override OrderBook;
    address public override Vault;
    address public override GlpRewardRouter;
    address public RewardRouter;
    address public AdapterManager;
    address public override StakedGmx;
    mapping(address => bool) whiteList;
    uint256 GMXDecimals = 10 ** 30;
    enum SwapType {
        SwapToken,
        SwapTokensToETH,
        SwapETHToTokens
    } // 枚举

    /* ============ Constructor ============ */
    constructor(
        address _manager,
        address _positionRouter,
        address _GMXRouter,
        address _OrderBook,
        address _RewardRouter,
        address _GlpRewardRouter,
        address _StakedGmx,
        address[] memory _whiteList
    ) public {
        AdapterManager = _manager;
        for (uint i; i < _whiteList.length; i++) {
            whiteList[_whiteList[i]] = true;
        }
        //Address of Curve Eth/StEth stableswap pool.
        PositionRouter = _positionRouter;
        GMXRouter = _GMXRouter;
        OrderBook = _OrderBook;
        RewardRouter = _RewardRouter;
        GlpRewardRouter = _GlpRewardRouter;
        StakedGmx = _StakedGmx;
    }

    /* ============ External Functions ============ */
    function updateWhiteList(
        address[] calldata _addList,
        address[] calldata removeList
    ) public onlyOwner {
        for (uint i; i < _addList.length; i++) {
            whiteList[_addList[i]] = true;
        }
        for (uint i; i < removeList.length; i++) {
            whiteList[removeList[i]] = false;
        }
    }

    function approvePositionRouter()
        external
        view
        override
        returns (address, uint256, bytes memory)
    {
        bytes memory approveCallData = abi.encodeWithSignature(
            "approvePlugin(address)",
            PositionRouter
        );
        return (GMXRouter, 0, approveCallData);
    }

    function getInCreasingPositionCallData(
        IncreasePositionRequest memory request
    ) external view override returns (address, uint256, bytes memory) {
        if (
            !IGMXRouter(GMXRouter).approvedPlugins(
                request._jasperVault,
                PositionRouter
            )
        ) {
            bytes memory approveCallData = abi.encodeWithSignature(
                "approvePlugin(address)",
                PositionRouter
            );
            return (GMXRouter, 0, approveCallData);
        }

        require(whiteList[request._indexToken], "_indexToken not in whiteList");
        for (uint i; i < request._path.length; i++) {
            require(whiteList[request._path[i]], "_path not in whiteList");
        }
        bytes memory callData = abi.encodeWithSignature(
            "createIncreasePosition(address[],address,uint256,uint256,uint256,bool,uint256,uint256,bytes32,address)",
            request._path,
            request._indexToken,
            request._amountIn,
            request._minOut,
            request._sizeDelta,
            request._isLong,
            request._acceptablePrice,
            request._executionFee,
            request._referralCode,
            request._callbackTarget
        );
        return (PositionRouter, request._executionFee, callData);
    }

    function getDeCreasingPositionCallData(
        DecreasePositionRequest memory request
    ) external view override returns (address, uint256, bytes memory) {
        require(whiteList[request._indexToken], "_indexToken not in whiteList");
        for (uint i; i < request._path.length; i++) {
            require(whiteList[request._path[i]], "_path not in whiteList");
        }
        bytes memory callData = abi.encodeWithSignature(
            "createDecreasePosition(address[],address,uint256,uint256,bool,address,uint256,uint256,uint256,bool,address)",
            request._path,
            request._indexToken,
            request._collateralDelta,
            request._sizeDelta,
            request._isLong,
            request._receiver,
            request._acceptablePrice,
            request._minOut,
            request._executionFee,
            request._withdrawETH,
            request._callbackTarget
        );

        return (PositionRouter, request._executionFee, callData);
    }

    function IsApprovedPlugins(
        address _Vault
    ) public view override returns (bool) {
        return IGMXRouter(GMXRouter).approvedPlugins(_Vault, PositionRouter);
    }

    /**
     * @return address        Target contract address
     * @return uint256        Total quantity of decreasing token units to position. This will always be 215000000000000 for decreasing
     * @return bytes          Position calldata
     **/
    function getSwapCallData(
        SwapData memory data
    ) external view override returns (address, uint256, bytes memory) {
        for (uint i; i < data._path.length; i++) {
            require(whiteList[data._path[i]], "_path not in whiteList");
        }
        bytes memory callData;
        if (data._swapType == uint256(SwapType.SwapToken)) {
            callData = abi.encodeWithSelector(
                IGMXRouter.swap.selector,
                data._path,
                data._amountIn,
                data._minOut,
                data._jasperVault
            );
            return (GMXRouter, 0, callData);
        } else if (data._swapType == uint256(SwapType.SwapTokensToETH)) {
            callData = abi.encodeWithSelector(
                IGMXRouter.swapTokensToETH.selector,
                data._path,
                data._amountIn,
                data._minOut,
                data._jasperVault
            );
            return (GMXRouter, 0, callData);
        } else if (data._swapType == uint256(SwapType.SwapETHToTokens)) {
            callData = abi.encodeWithSelector(
                IGMXRouter.swapETHToTokens.selector,
                data._path,
                data._minOut,
                data._jasperVault
            );
            return (GMXRouter, data._amountIn, callData);
        }
        return (GMXRouter, 0, callData);
    }

    function getCreateIncreaseOrderCallData(
        IncreaseOrderData memory data
    ) external view override returns (address, uint256, bytes memory) {
        require(whiteList[data._indexToken], "_indexToken not in whiteList");
        for (uint i; i < data._path.length; i++) {
            require(whiteList[data._path[i]], "_path not in whiteList");
        }
        bytes memory callData = abi.encodeWithSelector(
            IGMXOrderBook.createIncreaseOrder.selector,
            data._amountIn,
            data._indexToken,
            data._minOut,
            data._sizeDelta,
            data._collateralToken,
            data._isLong,
            data._triggerPrice,
            data._triggerAboveThreshold,
            data._executionFee,
            data._shouldWrap
        );
        return (OrderBook, data._fee, callData);
    }

    /**
     * Generates the calldata to Create Decrease Order CallData .
     * @param data       Data of order
     *
     * @return address        Target contract address
     * @return uint256        Call data value
     * @return bytes          Order Calldata
     **/
    function getCreateDecreaseOrderCallData(
        DecreaseOrderData memory data
    ) external view override returns (address, uint256, bytes memory) {
        require(whiteList[data._indexToken], "_indexToken not in whiteList");

        bytes memory callData = abi.encodeWithSelector(
            IGMXOrderBook.createDecreaseOrder.selector,
            data._indexToken,
            data._sizeDelta,
            data._collateralToken,
            data._collateralDelta,
            data._isLong,
            data._triggerPrice,
            data._triggerAboveThreshold
        );
        return (OrderBook, data._fee, callData);
    }

    function getTokenBalance(
        address _token,
        address _jasperVault
    ) external view override returns (uint256) {
        require(whiteList[_token], "token not in whiteList");
        return IERC20(_token).balanceOf(_jasperVault);
    }

    function getStakeGMXCallData(
        address _jasperVault,
        uint256 _stakeAmount,
        bool _isStake,
        bytes calldata _data
    )
        external
        view
        override
        returns (address _subject, uint256 _value, bytes memory _calldata)
    {
        if (_isStake) {
            bytes memory callData = abi.encodeWithSelector(
                IGMXStake(RewardRouter).stakeGmx.selector,
                _stakeAmount
            );
            return (RewardRouter, 0, callData);
        } else {
            bytes memory callData = abi.encodeWithSelector(
                IGMXStake(RewardRouter).unstakeGmx.selector,
                _stakeAmount
            );
            return (RewardRouter, 0, callData);
        }
        return (RewardRouter, 0, _calldata);
    }

    function getStakeGLPCallData(
        address _jasperVault,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp,
        bool _isStake,
        bytes calldata _data
    )
        external
        view
        override
        returns (address _subject, uint256 _value, bytes memory _calldata)
    {
        if (_isStake) {
            bytes memory callData = abi.encodeWithSelector(
                IGlpRewardRouter(GlpRewardRouter).mintAndStakeGlp.selector,
                _token,
                _amount,
                _minUsdg,
                _minGlp
            );
            return (GlpRewardRouter, 0, callData);
        } else {
            bytes memory callData = abi.encodeWithSelector(
                IGlpRewardRouter(GlpRewardRouter).unstakeAndRedeemGlp.selector,
                _token,
                _amount,
                _minGlp,
                _jasperVault
            );
            return (GlpRewardRouter, 0, callData);
        }
        return (GlpRewardRouter, 0, _calldata);
    }

    function getHandleRewardsCallData(
        HandleRewardData memory _rewardData
    )
        external
        view
        override
        returns (address _subject, uint256 _value, bytes memory _calldata)
    {
        bytes memory callData = abi.encodeWithSelector(
            IRewardRouter(RewardRouter).handleRewards.selector,
            _rewardData._shouldClaimGmx,
            _rewardData._shouldStakeGmx,
            _rewardData._shouldClaimEsGmx,
            _rewardData._shouldStakeEsGmx,
            _rewardData._shouldStakeMultiplierPoints,
            _rewardData._shouldClaimWeth,
            _rewardData._shouldConvertWethToEth
        );
        return (RewardRouter, 0, callData);
    }
}
