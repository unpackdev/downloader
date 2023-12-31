// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./ReentrancyGuardUpgradeable.sol";
import "./ICallProxy.sol";
import "./SafeCast.sol";
import "./DlnBase.sol";
import "./IDlnSource.sol";

contract DlnSource is DlnBase, ReentrancyGuardUpgradeable, IDlnSource {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using BytesLib for bytes;
    
    /* ========== STATE VARIABLES ========== */

    /// @dev Fixed fee in native asset
    uint88 public globalFixedNativeFee;
    /// @dev Transfer fee in BPS
    uint16 public globalTransferFeeBps;

    /// @dev Maps chainId to address of dlnDestination contract on that chain
    mapping(uint256 => bytes) public dlnDestinationAddresses;

    // @dev Maps orderId (see getOrderId) => state of order.
    /// Storage for information about orders
    /// Value is collected process fee for return it in order cancel case
    mapping(bytes32 => GiveOrderState) public giveOrders;

    /// Storage about give patches
    /// Values is `added` for order give amount in unlock | cancel moment
    mapping(bytes32 => uint256) public givePatches;

    /// Distributes a nonce for each order maker
    mapping(address => uint256) public masterNonce;

    // collected protocol fee
    mapping(address => uint256) public collectedFee;

    // mapping for wrong order. If claimed unlock and order in not correct status.
    // orderId => claim beneficiary
    mapping(bytes32 => address) public unexpectedOrderStatusForClaim;
    // mapping for wrong order. If claimed cancel and order in not correct status.
    // orderId => cancel beneficiary
    mapping(bytes32 => address) public unexpectedOrderStatusForCancel;

    // maps the amount of ETH per affiliate beneficiary (in case we failed to send ETH to him)
    // affiliateBeneficiary => amount
    mapping(address => uint256) public unclaimedAffiliateETHFees;

    /* ========== ENUMS ========== */

    enum OrderGiveStatus {
        /// Order not exist
        NotSet, //0
        /// Order created
        Created, // 1
        /// Order full filled and unlock command sent in give.chain_id by taker
        ClaimedUnlock, // 2
        /// Order canceled
        ClaimedCancel // 3
    }

    /* ========== STRUCTS ========== */


    struct GiveOrderState {
        OrderGiveStatus status;
        // stot optimisation
        uint160 giveTokenAddress;
        uint88 nativeFixFee;
        uint48 takeChainId;
        uint208 percentFee;
        uint256 giveAmount;
        address affiliateBeneficiary;
        uint256 affiliateAmount;
    }

    /* ========== EVENTS ========== */

    event CreatedOrder(
        DlnOrderLib.Order order,
        bytes32 orderId,
        bytes affiliateFee,
        uint256 nativeFixFee,
        uint256 percentFee,
        uint32 referralCode,
        bytes payload
    );

    event IncreasedGiveAmount(bytes32 orderId, uint256 orderGiveFinalAmount, uint256 finalPercentFee);

    event AffiliateFeePaid(
        bytes32 _orderId,
        address beneficiary,
        uint256 affiliateFee,
        address giveTokenAddress
    );

    event ClaimedUnlock(
        bytes32 orderId,
        address beneficiary,
        uint256 giveAmount,
        address giveTokenAddress
    );

    event UnexpectedOrderStatusForClaim(bytes32 orderId, OrderGiveStatus status, address beneficiary);

    event CriticalMismatchChainId(bytes32 orderId, address beneficiary, uint256 takeChainId,  uint256 submissionChainIdFrom);

    event ClaimedOrderCancel(
        bytes32 orderId,
        address beneficiary,
        uint256 paidAmount,
        address giveTokenAddress
    );

    event UnexpectedOrderStatusForCancel(bytes32 orderId, OrderGiveStatus status, address beneficiary);

    event SetDlnDestinationAddress(uint256 chainIdTo, bytes dlnDestinationAddress, DlnOrderLib.ChainEngine chainEngine);

    event WithdrawnFee(address tokenAddress, uint256 amount, address beneficiary);

    event GlobalFixedNativeFeeUpdated(uint88 oldGlobalFixedNativeFee, uint88 newGlobalFixedNativeFee);
    event GlobalTransferFeeBpsUpdated(uint16 oldGlobalTransferFeeBps, uint16 newGlobalTransferFeeBps);


    /* ========== ERRORS ========== */

    error WrongFixedFee(uint256 received, uint256 actual);
    error WrongAffiliateFeeLength();
    error MismatchNativeGiveAmount();
    error CriticalMismatchTakeChainId(bytes32 orderId, uint48 takeChainId, uint256 submissionsChainIdFrom);


    /* ========== CONSTRUCTOR  ========== */

    function initialize(
        IDeBridgeGate _deBridgeGate,
        uint88 _globalFixedNativeFee,
        uint16 _globalTransferFeeBps
    ) public initializer {
        _setFixedNativeFee(_globalFixedNativeFee);
        _setTransferFeeBps(_globalTransferFeeBps);

        __DlnBase_init(_deBridgeGate);
        __ReentrancyGuard_init();
    }

    /* ========== PUBLIC METHODS ========== */

    /**
     * @inheritdoc IDlnSource
     */
    function createOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        return _createSaltedOrder(
            _orderCreation,
            uint64(masterNonce[tx.origin]++),
            _affiliateFee,
            _referralCode,
            _permitEnvelope,
            bytes("")
        );
    }

    /**
     * @inheritdoc IDlnSource
     */
    function createSaltedOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        uint64 _salt,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope,
        bytes memory _payload
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        return _createSaltedOrder(
            _orderCreation,
            _salt,
            _affiliateFee,
            _referralCode,
            _permitEnvelope,
            _payload
        );
    }

    function _createSaltedOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        uint64 _salt,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope,
        bytes memory _payload
    ) internal returns (bytes32) {

        uint256 affiliateAmount;
        if (_affiliateFee.length > 0) {
            if (_affiliateFee.length != 52) revert WrongAffiliateFeeLength();
            affiliateAmount = BytesLib.toUint256(_affiliateFee, 20);
        }

        DlnOrderLib.Order memory _order = validateCreationOrder(_orderCreation, tx.origin, _salt);

        // take tokens from the user's wallet
        _pullTokens(_orderCreation, _order, _permitEnvelope);

        // reduce giveAmount on (percentFee + affiliateFee)
        uint256 percentFee = (globalTransferFeeBps * _order.giveAmount) / BPS_DENOMINATOR;
        _order.giveAmount -= percentFee + affiliateAmount;

        bytes32 orderId = getOrderId(_order);
        {
            GiveOrderState storage orderState = giveOrders[orderId];
            if (orderState.status != OrderGiveStatus.NotSet) revert IncorrectOrderStatus();

            orderState.status = OrderGiveStatus.Created;
            orderState.giveTokenAddress =  uint160(_orderCreation.giveTokenAddress);
            orderState.nativeFixFee = globalFixedNativeFee;
            orderState.takeChainId = _order.takeChainId.toUint48();
            orderState.percentFee = percentFee.toUint208();
            orderState.giveAmount = _order.giveAmount;
            // save affiliate_fee to storage
            if (affiliateAmount > 0) {
                address affiliateBeneficiary = BytesLib.toAddress(_affiliateFee, 0);
                if (affiliateAmount > 0 && affiliateBeneficiary == address(0)) revert ZeroAddress();
                orderState.affiliateAmount = affiliateAmount;
                orderState.affiliateBeneficiary = affiliateBeneficiary;
            }
        }

        emit CreatedOrder(
            _order,
            orderId,
            _affiliateFee,
            globalFixedNativeFee,
            percentFee,
            _referralCode,
            _payload
        );

        return orderId;
    }

    /// @dev Claim batch unlock orders that was called from orders take chain
    /// @param _orderIds Array of order ids for unlock
    /// @param _beneficiary User that will receive rewards
    /// # Allowed
    /// Can be called only from debridge external call with validation native sender
    function claimBatchUnlock(bytes32[] memory _orderIds, address _beneficiary)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 submissionChainIdFrom = _onlyDlnDestinationAddress();
        uint256 length = _orderIds.length;
        for (uint256 i; i < length; ++i) {
            _claimUnlock(_orderIds[i], _beneficiary, submissionChainIdFrom);
        }
    }

    /// @dev Claim unlock order that was called from take chain
    /// @param _orderId Order id for unlock
    /// @param _beneficiary User that will receive rewards
    /// # Allowed
    /// Can be called only from debridge external call with validation native sender
    function claimUnlock(bytes32 _orderId, address _beneficiary)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 submissionChainIdFrom = _onlyDlnDestinationAddress();
        _claimUnlock(_orderId, _beneficiary, submissionChainIdFrom);
    }

    /// @dev Claim batch cancel orders that was called from take chain
    /// @param _orderIds Array of order ids for cancel
    /// @param _beneficiary User that will receive full refund
    /// # Allowed
    /// Can be called only from debridge external call with validation native sender
    function claimBatchCancel(bytes32[] memory _orderIds, address _beneficiary)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 submissionChainIdFrom = _onlyDlnDestinationAddress();
        uint256 length = _orderIds.length;
        for (uint256 i; i < length; ++i) {
            _claimCancel(_orderIds[i], _beneficiary, submissionChainIdFrom);
        }
    }

    /// @dev Claim cancel order that was called from take chain
    /// @param _orderId  Order is for cancel
    /// @param _beneficiary User that will receive full refund
    /// # Allowed
    /// Can be called only from debridge external call with validation native sender
    function claimCancel(bytes32 _orderId, address _beneficiary)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 submissionChainIdFrom = _onlyDlnDestinationAddress();
        _claimCancel(_orderId, _beneficiary, submissionChainIdFrom);
    }

    /// @dev Patch give offer of order
    /// To increase the profitability of the order, add amount to the give part
    /// This amount will be kept on the contract until [`claimUnlock`] or [`claimCancel`]
    /// If a patch was previously made, then the new patch can only increase patch amount
    /// @param _order Full order information
    /// @param _addGiveAmount Added to give amount for use in [`claimUnlock`] and [`claimCancel`] methods
    /// @param _permitEnvelope Permit for approving the spender by signature.bytes (amount + deadline + signature)
    /// # Allowed
    /// Can be called only by user with givePatchAuthoritySrc rights
    function patchOrderGive(
        DlnOrderLib.Order memory _order,
        uint256 _addGiveAmount,
        bytes calldata _permitEnvelope
    ) external payable nonReentrant whenNotPaused {
        bytes32 orderId = getOrderId(_order);
        if (_order.givePatchAuthoritySrc.toAddress() != msg.sender)
            revert Unauthorized();
        if (_addGiveAmount == 0) revert WrongArgument();
        GiveOrderState storage orderState = giveOrders[orderId];
        if (orderState.status != OrderGiveStatus.Created) revert IncorrectOrderStatus();

        address giveTokenAddress = _order.giveTokenAddress.toAddress();
        if (giveTokenAddress == address(0)) {
            if (msg.value != _addGiveAmount) revert MismatchNativeGiveAmount();
        }
        else
        {
            _executePermit(giveTokenAddress, _permitEnvelope);
            _safeTransferFrom(
                giveTokenAddress,
                msg.sender,
                address(this),
                _addGiveAmount
            );
        }

        uint256 percentFee = (globalTransferFeeBps * _addGiveAmount) / BPS_DENOMINATOR;
        orderState.percentFee += percentFee.toUint208();
        givePatches[orderId] += _addGiveAmount - percentFee;
        emit IncreasedGiveAmount(orderId, _order.giveAmount + givePatches[orderId], orderState.percentFee);
    }

    /* ========== ADMIN METHODS ========== */

    /// @dev Set DLN destination contract address in another chain
    /// @param _chainIdTo Chain id
    /// @param _dlnDestinationAddress Contract address in another chain
    function setDlnDestinationAddress(uint256 _chainIdTo, bytes memory _dlnDestinationAddress, DlnOrderLib.ChainEngine _chainEngine)
        external
        onlyAdmin
    {
        if(_chainEngine == DlnOrderLib.ChainEngine.UNDEFINED) revert WrongArgument();
        dlnDestinationAddresses[_chainIdTo] = _dlnDestinationAddress;
        chainEngines[_chainIdTo] = _chainEngine;
        emit SetDlnDestinationAddress(_chainIdTo, _dlnDestinationAddress, _chainEngine);
    }

    /// @dev Withdraw collected fee
    /// @param _tokens List of tokens
    /// @param _beneficiary address who will receive tokens
    function withdrawFee(address[] memory _tokens, address _beneficiary) external nonReentrant onlyAdmin {
        uint256 length = _tokens.length;
        for (uint256 i; i < length; ++i) {
            address token = _tokens[i];
            uint256 feeAmount = collectedFee[token];
            _safeTransferEthOrToken(token, _beneficiary, feeAmount);
            collectedFee[token] = 0;
            emit WithdrawnFee(token, feeAmount, _beneficiary);
        }
    }

    /// @dev Update fallbacks for fixed fee in native asset and transfer fee
    /// @param _globalFixedNativeFee Fallback fixed fee in native asset
    /// @param _globalTransferFeeBps Fallback transfer fee in BPS
    function updateGlobalFee(
        uint88 _globalFixedNativeFee,
        uint16 _globalTransferFeeBps
    ) external onlyAdmin {
        _setFixedNativeFee(_globalFixedNativeFee);
        _setTransferFeeBps(_globalTransferFeeBps);
    }

    /* ========== VIEW ========== */

    /**
     * @dev Validates the creation of an order. Throws an exception if incorrect parameters are passed.
     * @param _orderCreation Details of the order to be validated.
     * @param _signer EOA (Externally Owned Account) address that will sign the transaction.
     * @return order Returns the validated order details.
     */
    function validateCreationOrder(DlnOrderLib.OrderCreation memory _orderCreation, address _signer)
        public
        view
        returns (DlnOrderLib.Order memory order)
    {
        return validateCreationOrder(_orderCreation, _signer, uint64(masterNonce[_signer]));
    }

    function validateCreationOrder(DlnOrderLib.OrderCreation memory _orderCreation, address _signer, uint64 _salt)
        public
        view
        returns (DlnOrderLib.Order memory order)
    {
        uint256 dstAddressLength = dlnDestinationAddresses[_orderCreation.takeChainId].length;

        if (dstAddressLength == 0) revert NotSupportedDstChain();
        if (
            _orderCreation.takeTokenAddress.length != dstAddressLength ||
            _orderCreation.receiverDst.length != dstAddressLength ||
            _orderCreation.orderAuthorityAddressDst.length != dstAddressLength ||
            (_orderCreation.allowedTakerDst.length > 0 &&
                _orderCreation.allowedTakerDst.length != dstAddressLength) ||
            (_orderCreation.allowedCancelBeneficiarySrc.length > 0 &&
                _orderCreation.allowedCancelBeneficiarySrc.length != EVM_ADDRESS_LENGTH)
        ) revert WrongAddressLength();

        order.giveChainId = getChainId();
        order.makerOrderNonce = _salt;
        order.makerSrc = abi.encodePacked(_signer);
        order.giveTokenAddress = abi.encodePacked(_orderCreation.giveTokenAddress);
        order.giveAmount = _orderCreation.giveAmount;
        order.takeTokenAddress = _orderCreation.takeTokenAddress;
        order.takeAmount = _orderCreation.takeAmount;
        order.takeChainId = _orderCreation.takeChainId;
        order.receiverDst = _orderCreation.receiverDst;
        order.givePatchAuthoritySrc = abi.encodePacked(_orderCreation.givePatchAuthoritySrc);
        order.orderAuthorityAddressDst = _orderCreation.orderAuthorityAddressDst;
        order.allowedTakerDst = _orderCreation.allowedTakerDst;
        order.externalCall = _orderCreation.externalCall;
        order.allowedCancelBeneficiarySrc = _orderCreation.allowedCancelBeneficiarySrc;
    }


    /* ========== INTERNAL ========== */

    function _pullTokens(DlnOrderLib.OrderCreation calldata _orderCreation, DlnOrderLib.Order memory _order, bytes calldata _permitEnvelope) internal {

        if (_orderCreation.giveTokenAddress == address(0)) {
            if (msg.value != _order.giveAmount + globalFixedNativeFee) revert MismatchNativeGiveAmount();
        }
        else
        {
            if (msg.value != globalFixedNativeFee) revert WrongFixedFee(msg.value, globalFixedNativeFee);

            _executePermit(_orderCreation.giveTokenAddress, _permitEnvelope);
            _safeTransferFrom(
                _orderCreation.giveTokenAddress,
                msg.sender,
                address(this),
                _order.giveAmount
            );
        }
    }

    /// @dev Claim unlock order that was called from take chain
    /// @param _orderId Order id for unlock
    /// @param _beneficiary User that will receive rewards
    /// @param _submissionChainIdFrom submission's chainId that got from deBridgeCallProxy
    function _claimUnlock(bytes32 _orderId, address _beneficiary, uint256 _submissionChainIdFrom) internal {
        GiveOrderState storage orderState = giveOrders[_orderId];
        if (orderState.status != OrderGiveStatus.Created) {
            unexpectedOrderStatusForClaim[_orderId] = _beneficiary;
            emit UnexpectedOrderStatusForClaim(_orderId, orderState.status, _beneficiary);
            return;
        }

        // a circuit breaker in case DlnDestination has been compromised  and is sending claim_unlock commands on behalf
        // of another chain
        if (orderState.takeChainId != _submissionChainIdFrom) {
            emit CriticalMismatchChainId(_orderId, _beneficiary, orderState.takeChainId, _submissionChainIdFrom);
            return;
        }

        uint256 amountToPay = orderState.giveAmount + givePatches[_orderId];
        orderState.status = OrderGiveStatus.ClaimedUnlock;
        address giveTokenAddress =  address(orderState.giveTokenAddress);
        _safeTransferEthOrToken(giveTokenAddress, _beneficiary, amountToPay);
        // send affiliateFee to affiliateFee beneficiary
        if (orderState.affiliateAmount > 0) {
            bool success;

            if (giveTokenAddress == address(0)) {
                (success, ) = orderState.affiliateBeneficiary.call{value: orderState.affiliateAmount, gas: 2300}(new bytes(0));
                if (!success) {
                    unclaimedAffiliateETHFees[orderState.affiliateBeneficiary] += orderState.affiliateAmount;
                }
            }
            else {
                IERC20Upgradeable(giveTokenAddress).safeTransfer(
                    orderState.affiliateBeneficiary,
                    orderState.affiliateAmount
                );
                success = true;
            }

            if (success) {
                emit AffiliateFeePaid(
                    _orderId,
                    orderState.affiliateBeneficiary,
                    orderState.affiliateAmount,
                    giveTokenAddress
                );
            }
        }
        emit ClaimedUnlock(
            _orderId,
            _beneficiary,
            amountToPay,
            giveTokenAddress
        );
        // Collected fee
        collectedFee[giveTokenAddress] += orderState.percentFee;
        collectedFee[address(0)] += orderState.nativeFixFee;
    }

    /// @dev Claim cancel order that was called from take chain
    /// @param _orderId  Order is for cancel
    /// @param _beneficiary User that will receive full refund
    /// @param _submissionChainIdFrom submission's chainId that got from deBridgeCallProxy
    function _claimCancel(bytes32 _orderId, address _beneficiary, uint256 _submissionChainIdFrom) internal {
        GiveOrderState storage orderState = giveOrders[_orderId];
        if (orderState.takeChainId != _submissionChainIdFrom) {
            revert CriticalMismatchTakeChainId(_orderId, orderState.takeChainId, _submissionChainIdFrom);
        }
        uint256 amountToPay = orderState.giveAmount +
                orderState.percentFee +
                orderState.affiliateAmount +
                givePatches[_orderId];
        if (orderState.status == OrderGiveStatus.Created) {
            orderState.status = OrderGiveStatus.ClaimedCancel;
            address giveTokenAddress = address(orderState.giveTokenAddress);
            _safeTransferEthOrToken(giveTokenAddress, _beneficiary, amountToPay);
            _safeTransferETH(_beneficiary, orderState.nativeFixFee);
            emit ClaimedOrderCancel(
                _orderId,
                _beneficiary,
                amountToPay,
                giveTokenAddress
            );
        } else {
            unexpectedOrderStatusForCancel[_orderId] = _beneficiary;
            emit UnexpectedOrderStatusForCancel(_orderId, orderState.status, _beneficiary);
        }
    }

    function _setFixedNativeFee(uint88 _globalFixedNativeFee) internal {
        uint88 oldGlobalFixedNativeFee = globalFixedNativeFee;
        if (oldGlobalFixedNativeFee != _globalFixedNativeFee) {
            globalFixedNativeFee = _globalFixedNativeFee;
            emit GlobalFixedNativeFeeUpdated(oldGlobalFixedNativeFee, _globalFixedNativeFee);
        }
    }

    function _setTransferFeeBps(uint16 _globalTransferFeeBps) internal {
        uint16 oldGlobalTransferFeeBps = globalTransferFeeBps;
        if (oldGlobalTransferFeeBps != _globalTransferFeeBps) {
            globalTransferFeeBps = _globalTransferFeeBps;
            emit GlobalTransferFeeBpsUpdated(oldGlobalTransferFeeBps, _globalTransferFeeBps);
        }
    }

    /// @dev Check that method was called by correct dlnDestinationAddresses from the take chain
    function _onlyDlnDestinationAddress() internal view returns (uint256 submissionChainIdFrom) {
        ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());
        if (address(callProxy) != msg.sender) revert CallProxyBadRole();

        bytes memory nativeSender = callProxy.submissionNativeSender();
        submissionChainIdFrom = callProxy.submissionChainIdFrom();
        if (keccak256(dlnDestinationAddresses[submissionChainIdFrom]) != keccak256(nativeSender)) {
            revert NativeSenderBadRole(nativeSender, submissionChainIdFrom);
        }
        return submissionChainIdFrom;
    }

    /* ========== Version Control ========== */

    /// @dev Get this contract's version
    function version() external pure returns (string memory) {
        return "1.3.0";
    }
}
