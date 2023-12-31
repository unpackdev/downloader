// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./GelatoActionsStandardFull.sol";
import "./IGelatoCore.sol";
import "./IERC20.sol";
import "./GelatoBytes.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IBatchExchange.sol";
import "./IGelatoCore.sol";

/// @title ActionPlaceOrderBatchExchange
/// @author Luis Schliesske & Hilmar Orth
/// @notice Gelato Action that
///  1) withdraws funds form user's  EOA,
///  2) deposits on Batch Exchange,
///  3) Places order on batch exchange and
//   4) requests future withdraw on batch exchange
contract ActionPlaceOrderBatchExchange is GelatoActionsStandardFull {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant MAX_UINT = type(uint256).max;
    uint32 public constant BATCH_TIME = 300;

    IBatchExchange public immutable batchExchange;

    constructor(IBatchExchange _batchExchange) public { batchExchange = _batchExchange; }

    // ======= DEV HELPERS =========
    /// @dev use this function to encode the data off-chain for the action data field
    /// Use "address _sellToken" and "address _buyToken" for Human Readable ABI.
    function getActionData(
        address _origin,
        address _sellToken,
        uint128 _sellAmount,
        address _buyToken,
        uint128 _buyAmount,
        uint32 _batchDuration
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.action.selector,
            _origin,
            _sellToken,
            _sellAmount,
            _buyToken,
            _buyAmount,
            _batchDuration
        );
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_IN_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_OUT_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    // ======= ACTION IMPLEMENTATION DETAILS =========
    /// @notice Place order on Batch Exchange and request future withdraw for buy/sell token
    /// @dev Use "address _sellToken" and "address _buyToken" for Human Readable ABI.
    /// @param _sellToken ERC20 Token to sell on Batch Exchange
    /// @param _sellAmount Amount to sell
    /// @param _buyToken ERC20 Token to buy on Batch Exchange
    /// @param _buyAmount Amount to receive (at least)
    /// @param _batchDuration After how many batches funds should be
    function action(
        address _origin,
        address _sellToken,
        uint128 _sellAmount,
        address _buyToken,
        uint128 _buyAmount,
        uint32 _batchDuration
    )
        public
        virtual
        delegatecallOnly("ActionPlaceOrderBatchExchange.action")
    {
        IERC20 sellToken = IERC20(_sellToken);

        // 1. Get current batch id
        uint32 withdrawBatchId = uint32(block.timestamp / BATCH_TIME) + _batchDuration;

        // 2. Optional: If light proxy, transfer from funds to proxy
        if (_origin != address(0) && _origin != address(this)) {
            sellToken.safeTransferFrom(
                _origin,
                address(this),
                _sellAmount,
                "ActionPlaceOrderBatchExchange.action:"
            );
        }

        // 3. Fetch token Ids for sell & buy token on Batch Exchange
        uint16 sellTokenId = batchExchange.tokenAddressToIdMap(_sellToken);
        uint16 buyTokenId = batchExchange.tokenAddressToIdMap(_buyToken);

        // 4. Approve _sellToken to BatchExchange Contract
        sellToken.safeIncreaseAllowance(
            address(batchExchange),
            _sellAmount,
            "ActionPlaceOrderBatchExchange.action:"
        );

        // 5. Deposit _sellAmount on BatchExchange
        try batchExchange.deposit(address(_sellToken), _sellAmount) {
        } catch {
            revert("ActionPlaceOrderBatchExchange.deposit _sellToken failed");
        }

        // 6. Place Order on Batch Exchange
        // uint16 buyToken, uint16 sellToken, uint32 validUntil, uint128 buyAmount, uint128 _sellAmount
        try batchExchange.placeOrder(
            buyTokenId,
            sellTokenId,
            withdrawBatchId,
            _buyAmount,
            _sellAmount
        ) {
        } catch {
            revert("ActionPlaceOrderBatchExchange.placeOrderfailed");
        }

        // 7. First check if we have a valid future withdraw request for the selltoken
        uint256 sellTokenWithdrawAmount = uint256(_sellAmount);
        try batchExchange.getPendingWithdraw(address(this), _sellToken)
            returns(uint256 reqWithdrawAmount, uint32 requestedBatchId)
        {
            // Check if the withdraw request is not in the past
            if (requestedBatchId >= uint32(block.timestamp / BATCH_TIME)) {
                // If we requested a max_uint withdraw, the withdraw amount will not change
                if (reqWithdrawAmount == MAX_UINT)
                    sellTokenWithdrawAmount = reqWithdrawAmount;
                // If not, we add the previous amount to the new one
                else
                    sellTokenWithdrawAmount = sellTokenWithdrawAmount.add(reqWithdrawAmount);
            }
        } catch {
            revert("ActionPlaceOrderBatchExchange.getPendingWithdraw _sellToken failed");
        }

        // 8. Request future withdraw on Batch Exchange for sellToken
        try batchExchange.requestFutureWithdraw(_sellToken, sellTokenWithdrawAmount, withdrawBatchId) {
        } catch {
            revert("ActionPlaceOrderBatchExchange.requestFutureWithdraw _sellToken failed");
        }

        // 9. Request future withdraw on Batch Exchange for buyToken
        // @DEV using MAX_UINT as we don't know in advance how much buyToken we will get
        try batchExchange.requestFutureWithdraw(_buyToken, MAX_UINT, withdrawBatchId) {
        } catch {
            revert("ActionPlaceOrderBatchExchange.requestFutureWithdraw _buyToken failed");
        }

    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.In
    //  => do not use for _actionData encoding
    function execWithDataFlowIn(bytes calldata _actionData, bytes calldata _inFlowData)
        external
        payable
        virtual
        override
    {
        (address sellToken, uint128 sellAmount) = _handleInFlowData(_inFlowData);
        (address origin,
         address buyToken,
         uint128 buyAmount,
         uint32 batchDuration) = _extractReusableActionData(_actionData);

        action(origin, sellToken, sellAmount, buyToken, buyAmount, batchDuration);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.Out
    //  => do not use for _actionData encoding
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address origin,
         address sellToken,
         uint128 sellAmount,
         address buyToken,
         uint128 buyAmount,
         uint32 batchDuration) = abi.decode(
            _actionData[4:],
            (address,address,uint128,address,uint128,uint32)
        );
        action(origin, sellToken, sellAmount, buyToken, buyAmount, batchDuration);
        return abi.encode(sellToken, sellAmount);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.InAndOut
    //  => do not use for _actionData encoding
    function execWithDataFlowInAndOut(
        bytes calldata _actionData,
        bytes calldata _inFlowData
    )
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address sellToken, uint128 sellAmount) = _handleInFlowData(_inFlowData);
        (address origin,
         address buyToken,
         uint128 buyAmount,
         uint32 batchDuration) = _extractReusableActionData(_actionData);

        action(origin, sellToken, sellAmount, buyToken, buyAmount, batchDuration);

        return abi.encode(sellToken, sellAmount);
    }

    // ======= ACTION TERMS CHECK =========
    // Overriding and extending GelatoActionsStandard's function (optional)
    function termsOk(
        uint256,  // taskReceipId
        address _userProxy,
        bytes calldata _actionData,
        DataFlow,
        uint256,  // value
        uint256  // cycleId
    )
        public
        view
        virtual
        override
        returns(string memory)  // actionCondition
    {
        if (this.action.selector != GelatoBytes.calldataSliceSelector(_actionData))
            return "ActionPlaceOrderBatchExchange: invalid action selector";

        (address origin, address _sellToken, uint128 sellAmount, address buyToken) = abi.decode(
            _actionData[4:132],
            (address,address,uint128,address)
        );

        IERC20 sellToken = IERC20(_sellToken);

        if (origin == address(0) || origin == _userProxy) {
            try sellToken.balanceOf(_userProxy) returns(uint256 proxySendTokenBalance) {
                if (proxySendTokenBalance < sellAmount)
                    return "ActionPlaceOrderBatchExchange: NotOkUserProxySendTokenBalance";
            } catch {
                return "ActionPlaceOrderBatchExchange: ErrorBalanceOf-1";
            }
        } else {
            try sellToken.balanceOf(origin) returns(uint256 originSendTokenBalance) {
                if (originSendTokenBalance < sellAmount)
                    return "ActionPlaceOrderBatchExchange: NotOkOriginSendTokenBalance";
            } catch {
                return "ActionPlaceOrderBatchExchange: ErrorBalanceOf-2";
            }

            try sellToken.allowance(origin, _userProxy)
                returns(uint256 userProxySendTokenAllowance)
            {
                if (userProxySendTokenAllowance < sellAmount)
                    return "ActionPlaceOrderBatchExchange: NotOkUserProxySendTokenAllowance";
            } catch {
                return "ActionPlaceOrderBatchExchange: ErrorAllowance";
            }
        }

        uint32 currentBatchId = uint32(block.timestamp / BATCH_TIME);

        try batchExchange.getPendingWithdraw(_userProxy, _sellToken)
            returns(uint256, uint32 requestedBatchId)
        {
            // Check if the withdraw request is valid => we need the withdraw to exec first
            if (requestedBatchId != 0 && requestedBatchId < currentBatchId) {
                return "ActionPlaceOrderBatchExchange WaitUntilPreviousBatchWasWithdrawn sellToken";
            }
        } catch {
            return "ActionPlaceOrderBatchExchange getPendingWithdraw failed sellToken";
        }

        try batchExchange.getPendingWithdraw(_userProxy, buyToken)
            returns(uint256, uint32 requestedBatchId)
        {
            // Check if the withdraw request is valid => we need the withdraw to exec first
            if (requestedBatchId != 0 && requestedBatchId < currentBatchId) {
                return "ActionPlaceOrderBatchExchange WaitUntilPreviousBatchWasWithdrawn buyToken";
            }
        } catch {
            return "ActionPlaceOrderBatchExchange getPendingWithdraw failed buyToken";
        }

        // STANDARD return string to signal actionConditions Ok
        return OK;
    }

    // ======= ACTION HELPERS =========
    function _handleInFlowData(bytes calldata _inFlowData)
        internal
        pure
        virtual
        returns(address sellToken, uint128 sellAmount)
    {
        uint256 sellAmount256;
        (sellToken, sellAmount256) = abi.decode(_inFlowData, (address,uint256));
        sellAmount = uint128(sellAmount256);
        require(
            sellAmount == sellAmount256,
            "ActionPlaceOrderBatchExchange._handleInFlowData: sellAmount conversion error"
        );
    }

    function _extractReusableActionData(bytes calldata _actionData)
        internal
        pure
        virtual
        returns (address origin, address buyToken, uint128 buyAmount, uint32 batchDuration)
    {
        (origin,/*sellToken*/,/*sellAmount*/, buyToken, buyAmount, batchDuration) = abi.decode(
            _actionData[4:],
            (address,address,uint128,address,uint128,uint32)
        );
    }
}