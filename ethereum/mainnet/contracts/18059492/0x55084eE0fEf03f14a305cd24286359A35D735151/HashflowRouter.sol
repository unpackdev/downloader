/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.18;

import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./draft-IERC20Permit.sol";
import "./SignatureChecker.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Initializable.sol";

import "./IHashflowPool.sol";
import "./IHashflowRouter.sol";
import "./IWETH.sol";

import "./IHashflowXChainMessenger.sol";

/// @title HashflowRouter
/// @author Victor Ionescu
/// @notice Implementation of IHashflowRouter.
contract HashflowRouter is
    IHashflowRouter,
    EIP712,
    ReentrancyGuard,
    Ownable2Step,
    Initializable
{
    using Address for address payable;
    using Address for address;
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    mapping(address => bool) public authorizedPools;
    mapping(bytes32 => mapping(uint16 => mapping(bytes32 => bool)))
        public authorizedXChainPools;
    mapping(address => mapping(uint16 => mapping(bytes32 => bool)))
        public authorizedXChainCallers;
    mapping(address => mapping(address => bool))
        public authorizedXChainMessengersByPool;
    mapping(address => mapping(address => bool))
        public authorizedXChainMessengersByCallee;

    /// @dev This is used to interact with external accounts, where native token needs to be wrapped.
    address public immutable _WETH;

    address public factory;

    address public limitOrderGuardian;

    /// @dev To be used for RFQ-m trades, verified by the router.
    bytes32 internal constant QUOTE_TYPEHASH =
        keccak256(
            'Quote(bytes32 txid,address trader,address pool,address externalAccount,address baseToken,address quoteToken,uint256 baseTokenAmount,uint256 quoteTokenAmount,uint256 quoteExpiry)'
        );

    /// @dev To be used for RFQ-m trades, verified by the router.
    bytes32 internal constant QUOTE_LIMIT_ORDER_TYPEHASH =
        keccak256(
            'Quote(bytes32 txid,address baseToken,address quoteToken,uint256 baseTokenAmount,uint256 quoteTokenAmount,uint256 quoteExpiry)'
        );

    /// @dev To be used for cross-chain RFQ-m trades, verified by the router.
    bytes32 internal constant XCHAIN_QUOTE_TYPEHASH =
        keccak256(
            'XChainQuote(bytes32 txid,uint256 srcChainId,uint256 dstChainId,bytes32 dstTrader,address srcPool,address srcExternalAccount,bytes32 dstPool,bytes32 dstExternalAccount,address baseToken,bytes32 quoteToken,uint256 baseTokenAmount,uint256 quoteTokenAmount,uint256 quoteExpiry)'
        );

    mapping(bytes32 => bool) private _usedTxids;

    constructor(address weth) EIP712('Hashflow - Router', '1.0') {
        require(weth != address(0), 'HashflowRouter: WETH is 0 address.');

        _WETH = weth;
    }

    /// @inheritdoc IHashflowRouter
    function initialize(address _factory)
        external
        override
        initializer
        onlyOwner
    {
        require(
            _factory != address(0),
            'HashflowRouter::initialize Factory cannot be 0 address.'
        );
        factory = _factory;
    }

    /// @inheritdoc IHashflowRouter
    function tradeRFQT(RFQTQuote memory quote) external payable override {
        _validateRFQTQuote(quote);

        if (quote.baseToken == address(0)) {
            require(
                msg.value == quote.effectiveBaseTokenAmount,
                'HashflowRouter::tradeRFQT msg.value should equal effectiveBaseTokenAmount.'
            );
        } else {
            require(
                msg.value == 0,
                'HashflowRouter::tradeRFQT msg.value should be 0.'
            );
        }

        _executeRFQTTrade(quote, false);
    }

    /// @inheritdoc IHashflowRouter
    function tradeRFQTWithPermit(
        RFQTQuote memory quote,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    ) external override {
        _validateRFQTQuote(quote);

        require(
            quote.baseToken != address(0),
            'HashflowRouter::tradeRFQTWithPermit baseToken cannot be the native token.'
        );

        require(
            amountToApprove >= quote.effectiveBaseTokenAmount,
            'HashflowRouter::tradeRFQTWithPermit Insufficient amount to approve.'
        );

        _permitERC20(
            quote.baseToken,
            _msgSender(),
            amountToApprove,
            deadline,
            v,
            r,
            s
        );

        _executeRFQTTrade(quote, false);
    }

    /// @inheritdoc IHashflowRouter
    function tradeRFQM(RFQMQuote memory quote) external override {
        _validateRFQMQuote(quote);
        _validateRFQMSignature(quote);

        _executeRFQMTrade(quote);
    }

    /// @inheritdoc IHashflowRouter
    function tradeRFQMWithPermit(
        RFQMQuote memory quote,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    ) external override {
        _validateRFQMQuote(quote);
        _validateRFQMSignature(quote);

        require(
            amountToApprove >= quote.baseTokenAmount,
            'HashflowRouter::tradeRFQMWithPermit Insufficient amount to approve.'
        );

        _permitERC20(
            quote.baseToken,
            quote.trader,
            amountToApprove,
            deadline,
            v,
            r,
            s
        );

        _executeRFQMTrade(quote);
    }

    /// @inheritdoc IHashflowRouter
    function tradeRFQMLimitOrder(
        RFQMQuote memory quote,
        bytes memory guardianSignature
    ) external override {
        _validateRFQMQuote(quote);
        _validateRFQMLimitOrderSignature(quote, guardianSignature);

        _executeRFQMTrade(quote);
    }

    /// @inheritdoc IHashflowRouter
    function tradeRFQMLimitOrderWithPermit(
        RFQMQuote memory quote,
        bytes memory guardianSignature,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    ) external override {
        _validateRFQMQuote(quote);
        _validateRFQMLimitOrderSignature(quote, guardianSignature);

        require(
            amountToApprove >= quote.baseTokenAmount,
            'HashflowRouter::tradeRFQMLimitOrderWithPermit Insufficient amount to approve.'
        );

        _permitERC20(
            quote.baseToken,
            quote.trader,
            amountToApprove,
            deadline,
            v,
            r,
            s
        );

        _executeRFQMTrade(quote);
    }

    /// @inheritdoc IHashflowRouter
    function tradeXChainRFQT(
        XChainRFQTQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata
    ) external payable override nonReentrant {
        _validateXChainRFQTQuote(quote);

        _executeXChainRFQTTrade(quote, dstContract, dstCalldata);
    }

    /// @inheritdoc IHashflowRouter
    function tradeXChainRFQTWithPermit(
        XChainRFQTQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    ) external payable override nonReentrant {
        _validateXChainRFQTQuote(quote);

        require(
            quote.baseToken != address(0),
            'HashflowRouter::tradeXChainRFQTWithPermit baseToken cannot be the native token.'
        );

        require(
            amountToApprove >= quote.effectiveBaseTokenAmount,
            'HashflowRouter::tradeXChainRFQTWithPermit Insufficient amount to approve.'
        );

        _permitERC20(
            quote.baseToken,
            _msgSender(),
            amountToApprove,
            deadline,
            v,
            r,
            s
        );

        _executeXChainRFQTTrade(quote, dstContract, dstCalldata);
    }

    function tradeXChainRFQM(
        XChainRFQMQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata
    ) external payable override {
        _validateXChainRFQMQuote(quote);

        _executeXChainRFQMTrade(quote, dstContract, dstCalldata);
    }

    /// @inheritdoc IHashflowRouter
    function tradeXChainRFQMWithPermit(
        XChainRFQMQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    ) external payable override {
        _validateXChainRFQMQuote(quote);

        require(
            amountToApprove >= quote.baseTokenAmount,
            'HashflowRouter::tradeXChainRFQmWithPermit Insufficient amount to approve.'
        );

        _permitERC20(
            quote.baseToken,
            quote.trader,
            amountToApprove,
            deadline,
            v,
            r,
            s
        );

        _executeXChainRFQMTrade(quote, dstContract, dstCalldata);
    }

    /// @inheritdoc IHashflowRouter
    function fillXChain(XChainFillMessage memory fillMessage)
        external
        override
    {
        require(
            authorizedXChainMessengersByPool[fillMessage.dstPool][_msgSender()],
            'HashflowRouter::fillXChain Unauthorized messenger.'
        );
        require(
            authorizedXChainPools[
                bytes32(uint256(uint160(fillMessage.dstPool)))
            ][fillMessage.srcHashflowChainId][fillMessage.srcPool],
            'HashflowRouter::fillXChain Unauthorized peer pool.'
        );

        if (fillMessage.dstContract != address(0)) {
            require(
                authorizedXChainCallers[fillMessage.dstContract][
                    fillMessage.srcHashflowChainId
                ][fillMessage.srcCaller],
                'HashflowRouter::fillXChain Unauthorized x-caller.'
            );
            require(
                authorizedXChainMessengersByCallee[fillMessage.dstContract][
                    _msgSender()
                ],
                'HashflowRouter::fillXChain Unauthorized messenger for x-call.'
            );
        }

        IHashflowPool(fillMessage.dstPool).fillXChain(
            fillMessage.dstExternalAccount,
            fillMessage.txid,
            fillMessage.dstTrader,
            fillMessage.quoteToken,
            fillMessage.quoteTokenAmount
        );

        if (fillMessage.dstContract != address(0)) {
            fillMessage.dstContract.functionCall(
                fillMessage.dstContractCalldata
            );
        }
    }

    /// @inheritdoc IHashflowRouter

    function updateXChainPoolAuthorization(
        uint16 otherHashflowChainId,
        bytes32 otherPool,
        bool authorized
    ) external override {
        require(
            authorizedPools[_msgSender()],
            'HashflowRouter::updateXChainPoolAuthorization Pool not authorized.'
        );

        bytes32 evmAgnosticSender = bytes32(uint256(uint160(_msgSender())));

        authorizedXChainPools[evmAgnosticSender][otherHashflowChainId][
            otherPool
        ] = authorized;

        emit UpdateXChainPoolAuthorization(
            _msgSender(),
            otherHashflowChainId,
            otherPool,
            authorized
        );
    }

    function updateXChainCallerAuthorization(
        uint16 otherHashflowChainId,
        bytes32 caller,
        bool authorized
    ) external override {
        require(
            msg.sender.isContract(),
            'HashflowRouter::updateXChainCallerAuthorization Sender must be a contract.'
        );

        require(
            caller != bytes32(0),
            'HashflowRouter::updateXChainCallerAuthorization Caller is empty.'
        );

        authorizedXChainCallers[msg.sender][otherHashflowChainId][
            caller
        ] = authorized;

        emit UpdateXChainCallerAuthorization(
            msg.sender,
            otherHashflowChainId,
            caller,
            authorized
        );
    }

    /// @inheritdoc IHashflowRouter
    function updateXChainMessengerAuthorization(
        address xChainMessenger,
        bool authorized
    ) external override {
        require(
            authorizedPools[_msgSender()],
            'HashflowRouter::updateXChainMessengerAuthorization Pool not authorized.'
        );

        authorizedXChainMessengersByPool[_msgSender()][
            xChainMessenger
        ] = authorized;

        emit UpdateXChainMessengerAuthorization(
            _msgSender(),
            xChainMessenger,
            authorized
        );
    }

    function updateXChainMessengerCallerAuthorization(
        address xChainMessenger,
        bool authorized
    ) external override {
        authorizedXChainMessengersByCallee[msg.sender][
            xChainMessenger
        ] = authorized;

        emit UpdateXChainMessengerCallerAuthorization(
            msg.sender,
            xChainMessenger,
            authorized
        );
    }

    /// @inheritdoc IHashflowRouter
    function forceUnauthorizePool(address pool) external override onlyOwner {
        require(
            authorizedPools[pool],
            'HashflowRouter::forceUnauthorizePool Pool is not authorized.'
        );

        authorizedPools[pool] = false;

        emit UpdatePoolAuthorizaton(pool, false);
    }

    /// @inheritdoc IHashflowRouter
    function updatePoolAuthorization(address pool, bool authorized)
        external
        override
    {
        require(
            _msgSender() == factory,
            'HashflowRouter: msg.sender should be the Factory.'
        );

        authorizedPools[pool] = authorized;

        emit UpdatePoolAuthorizaton(pool, authorized);
    }

    /// @inheritdoc IHashflowRouter

    function killswitchPool(address pool, bool enabled)
        external
        override
        onlyOwner
    {
        IHashflowPool(pool).killswitchOperations(enabled);
    }

    /// @inheritdoc IHashflowRouter
    function withdrawFunds(address token) external override onlyOwner {
        if (token == address(0)) {
            payable(_msgSender()).sendValue(address(this).balance);
        } else {
            IERC20(token).safeTransfer(
                _msgSender(),
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    /// @inheritdoc IHashflowRouter
    function updateLimitOrderGuardian(address guardian)
        external
        override
        onlyOwner
    {
        require(
            guardian != address(0),
            'HashflowRouter::updateLimitOrderGuardian Guardian cannot be 0 address.'
        );
        limitOrderGuardian = guardian;

        emit UpdateLimitOrderGuardian(guardian);
    }

    /// @dev We do not allow the owner to renounce ownership.
    function renounceOwnership() public view override onlyOwner {
        revert('HashflowRouter: Renouncing ownership not allowed.');
    }

    // Section: Intra-chain RFQ-T.

    function _validateRFQTQuote(RFQTQuote memory quote) private view {
        require(
            quote.effectiveBaseTokenAmount <= quote.baseTokenAmount,
            'HashflowRouter::_validateRFQTQuote effectiveBaseTokenAmount too high.'
        );

        require(
            quote.quoteExpiry >= block.timestamp,
            'HashflowRouter::_validateRFQTQuote Quote has expired.'
        );

        require(
            quote.nonce <= (block.timestamp + 180) * 1000,
            'HashflowRouter::_validateRFQTQuote Nonce too high.'
        );

        require(
            authorizedPools[quote.pool],
            'HashflowRouter::_validateRFQTQuote Pool not authorized.'
        );
    }

    function _executeRFQTTrade(RFQTQuote memory quote, bool multihop) private {
        uint256 msgValue;

        if (quote.baseToken == address(0)) {
            if (quote.externalAccount == address(0)) {
                msgValue = quote.effectiveBaseTokenAmount;
            } else {
                // Instead of transferring native token to an external account, we transfer
                // wrapped native token.
                IWETH(_WETH).deposit{value: quote.effectiveBaseTokenAmount}();
                IERC20(_WETH).safeTransfer(
                    quote.externalAccount,
                    quote.effectiveBaseTokenAmount
                );
            }
        } else {
            // If the external account is present we transfer to it. Otherwise we transfer
            // to the pool.
            address accountToTransferTo = quote.externalAccount != address(0)
                ? quote.externalAccount
                : quote.pool;

            if (multihop) {
                IERC20(quote.baseToken).safeTransfer(
                    accountToTransferTo,
                    quote.effectiveBaseTokenAmount
                );
            } else {
                IERC20(quote.baseToken).safeTransferFrom(
                    _msgSender(),
                    accountToTransferTo,
                    quote.effectiveBaseTokenAmount
                );
            }
        }

        IHashflowPool(quote.pool).tradeRFQT{value: msgValue}(quote);
    }

    // Section: Intra-chain RFQ-M.

    function _validateRFQMQuote(RFQMQuote memory quote) private {
        require(
            quote.quoteExpiry >= block.timestamp,
            'HashflowRouter::_validateRFQMQuote Quote has expired.'
        );
        require(
            authorizedPools[quote.pool],
            'HashflowRouter::_validateRFQMQuote Pool not authorized.'
        );
        require(
            quote.baseToken != address(0),
            'HashflowRouter::_validateRFQMQuote RFQ-M does not support native tokens.'
        );

        require(
            !_usedTxids[quote.txid],
            'HashflowRouter::_validateRFQMQuote txid has already been used.'
        );
        _usedTxids[quote.txid] = true;
    }

    function _validateRFQMSignature(RFQMQuote memory quote) private view {
        bytes32 quoteHash = _hashQuoteRFQM(quote);

        require(
            SignatureChecker.isValidSignatureNow(
                quote.trader,
                quoteHash,
                quote.takerSignature
            ),
            'HashflowRouter::_validateRFQMSignature Invalid signer.'
        );
    }

    function _executeRFQMTrade(RFQMQuote memory quote) private {
        IERC20(quote.baseToken).safeTransferFrom(
            quote.trader,
            quote.externalAccount != address(0)
                ? quote.externalAccount
                : quote.pool,
            quote.baseTokenAmount
        );
        IHashflowPool(quote.pool).tradeRFQM(quote);
    }

    // Section: Limit orders.

    function _validateRFQMLimitOrderSignature(
        RFQMQuote memory quote,
        bytes memory guardianSignature
    ) private view {
        bytes32 traderHash = _hashQuoteLimitOrderRFQM(quote);

        require(
            SignatureChecker.isValidSignatureNow(
                quote.trader,
                traderHash,
                quote.takerSignature
            ),
            'HashflowRouter::_validateRFQMLimitOrderSignature Invalid trader signer.'
        );

        bytes32 guardianHash = _hashGuardianQuoteRFQM(quote);

        require(
            guardianHash.recover(guardianSignature) == limitOrderGuardian,
            'HashflowRouter::_validateRFQMLimitOrderSignature Invalid guardian signer.'
        );
    }

    // Section: X-Chain RFQ-T.

    function _validateXChainRFQTQuote(XChainRFQTQuote memory quote)
        private
        view
    {
        require(
            quote.effectiveBaseTokenAmount <= quote.baseTokenAmount,
            'HashflowRouter::_validateXChainRFQTQuote effectiveBaseTokenAmount too high.'
        );
        require(
            quote.quoteExpiry >= block.timestamp,
            'HashflowRouter::_validateXChainRFQTQuote Quote has expired.'
        );
        require(
            authorizedPools[quote.srcPool],
            'HashflowRouter::_validateXChainRFQTQuote Pool not authorized.'
        );
        require(
            quote.nonce <= (block.timestamp + 180) * 1000,
            'HashflowRouter::_validateXChainRFQTQuote Nonce too high.'
        );
        require(
            authorizedXChainMessengersByPool[quote.srcPool][
                quote.xChainMessenger
            ],
            'HashflowRouter::_validateXChainRFQTQuote Unauthorized messenger for pool.'
        );
        require(
            authorizedXChainPools[bytes32(uint256(uint160(quote.srcPool)))][
                quote.dstChainId
            ][quote.dstPool],
            'HashflowRouter::_validateXChainRFQTQuote Unauthorized x-chain peer pool.'
        );
    }

    function _executeXChainRFQTTrade(
        XChainRFQTQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata
    ) private {
        uint256 xChainFees = msg.value;

        if (quote.baseToken == address(0)) {
            require(
                msg.value >= quote.effectiveBaseTokenAmount,
                'HashflowRouter::tradeXChainRFQT msg.value should be >= effectiveBaseTokenAmount.'
            );
            xChainFees = msg.value - quote.effectiveBaseTokenAmount;
        }

        uint256 effectiveQuoteTokenAmount = quote.quoteTokenAmount;
        if (quote.effectiveBaseTokenAmount < quote.baseTokenAmount) {
            effectiveQuoteTokenAmount =
                (quote.quoteTokenAmount * quote.effectiveBaseTokenAmount) /
                quote.baseTokenAmount;
        }

        uint256 msgValue = 0;

        if (quote.baseToken == address(0)) {
            if (quote.srcExternalAccount == address(0)) {
                msgValue = quote.effectiveBaseTokenAmount;
            } else {
                IWETH(_WETH).deposit{value: quote.effectiveBaseTokenAmount}();
                IERC20(_WETH).safeTransfer(
                    quote.srcExternalAccount,
                    quote.effectiveBaseTokenAmount
                );
            }
        } else {
            IERC20(quote.baseToken).safeTransferFrom(
                _msgSender(),
                quote.srcExternalAccount != address(0)
                    ? quote.srcExternalAccount
                    : quote.srcPool,
                quote.effectiveBaseTokenAmount
            );
        }

        IHashflowPool(quote.srcPool).tradeXChainRFQT{value: msgValue}(
            quote,
            _msgSender()
        );

        IHashflowXChainMessenger.XChainQuote memory uaQuote;
        uaQuote.srcChainId = quote.srcChainId;
        uaQuote.dstChainId = quote.dstChainId;
        uaQuote.srcPool = quote.srcPool;
        uaQuote.dstPool = quote.dstPool;
        uaQuote.srcExternalAccount = quote.srcExternalAccount;
        uaQuote.dstExternalAccount = quote.dstExternalAccount;
        uaQuote.trader = _msgSender();
        uaQuote.dstTrader = quote.dstTrader;
        uaQuote.baseToken = quote.baseToken;
        uaQuote.quoteToken = quote.quoteToken;
        uaQuote.baseTokenAmount = quote.effectiveBaseTokenAmount;
        uaQuote.quoteTokenAmount = effectiveQuoteTokenAmount;
        uaQuote.txid = quote.txid;

        IHashflowXChainMessenger(quote.xChainMessenger).tradeXChain{
            value: xChainFees
        }(uaQuote, _msgSender(), dstContract, dstCalldata);
    }

    // Section: X-Chain RFQ-M.

    function _validateXChainRFQMQuote(XChainRFQMQuote memory quote) private {
        require(
            quote.quoteExpiry >= block.timestamp,
            'HashflowRouter::_validateXChainRFQMQuote Quote has expired.'
        );
        require(
            authorizedPools[quote.srcPool],
            'HashflowRouter::_validateXChainRFQMQuote Pool not authorized.'
        );
        require(
            authorizedXChainMessengersByPool[quote.srcPool][
                quote.xChainMessenger
            ],
            'HashflowRouter::_validateXChainRFQMQuote Unauthorized messenger for pool.'
        );
        require(
            authorizedXChainPools[bytes32(uint256(uint160(quote.srcPool)))][
                quote.dstChainId
            ][quote.dstPool],
            'HashflowRouter::_validateXChainRFQMQuote Unauthorized x-chain peer pool.'
        );

        require(
            quote.baseToken != address(0),
            'HashflowRouter::_validateXChainRFQMQuote RFQ-M does not support native tokens.'
        );
        require(
            !_usedTxids[quote.txid],
            'HashflowRouter::_validateXChainRFQMQuote txid has already been used.'
        );
        _usedTxids[quote.txid] = true;

        bytes32 quoteHash = _hashXChainQuoteRFQM(quote);
        require(
            SignatureChecker.isValidSignatureNow(
                quote.trader,
                quoteHash,
                quote.takerSignature
            ),
            'HashflowRouter::_validateXChainRFQMQuote Invalid signer.'
        );
    }

    function _executeXChainRFQMTrade(
        XChainRFQMQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata
    ) private {
        IERC20(quote.baseToken).safeTransferFrom(
            quote.trader,
            quote.srcExternalAccount != address(0)
                ? quote.srcExternalAccount
                : quote.srcPool,
            quote.baseTokenAmount
        );

        IHashflowPool(quote.srcPool).tradeXChainRFQM(quote);

        IHashflowXChainMessenger.XChainQuote memory uaQuote;
        uaQuote.srcChainId = quote.srcChainId;
        uaQuote.dstChainId = quote.dstChainId;
        uaQuote.srcPool = quote.srcPool;
        uaQuote.dstPool = quote.dstPool;
        uaQuote.srcExternalAccount = quote.srcExternalAccount;
        uaQuote.dstExternalAccount = quote.dstExternalAccount;
        uaQuote.trader = quote.trader;
        uaQuote.dstTrader = quote.dstTrader;
        uaQuote.baseToken = quote.baseToken;
        uaQuote.quoteToken = quote.quoteToken;
        uaQuote.baseTokenAmount = quote.baseTokenAmount;
        uaQuote.quoteTokenAmount = quote.quoteTokenAmount;
        uaQuote.txid = quote.txid;

        IHashflowXChainMessenger(quote.xChainMessenger).tradeXChain{
            value: msg.value
        }(uaQuote, _msgSender(), dstContract, dstCalldata);
    }

    function _permitERC20(
        address erc20Permit,
        address trader,
        uint256 amountToApprove,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        IERC20Permit(erc20Permit).safePermit(
            trader,
            address(this),
            amountToApprove,
            deadline,
            v,
            r,
            s
        );
    }

    function _hashQuoteLimitOrderRFQM(RFQMQuote memory quote)
        private
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        QUOTE_LIMIT_ORDER_TYPEHASH,
                        quote.txid,
                        quote.baseToken,
                        quote.quoteToken,
                        quote.baseTokenAmount,
                        quote.quoteTokenAmount,
                        quote.quoteExpiry
                    )
                )
            );
    }

    /// @dev Helper for EIP-712 Quote hash generation.
    function _hashQuoteRFQM(RFQMQuote memory quote)
        private
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        QUOTE_TYPEHASH,
                        quote.txid,
                        quote.trader,
                        quote.pool,
                        quote.externalAccount,
                        quote.baseToken,
                        quote.quoteToken,
                        quote.baseTokenAmount,
                        quote.quoteTokenAmount,
                        quote.quoteExpiry
                    )
                )
            );
    }

    /// @dev Helper for EIP-712 Quote hash generation.
    function _hashXChainQuoteRFQM(XChainRFQMQuote memory quote)
        private
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        XCHAIN_QUOTE_TYPEHASH,
                        quote.txid,
                        uint256(quote.srcChainId),
                        uint256(quote.dstChainId),
                        quote.dstTrader,
                        quote.srcPool,
                        quote.srcExternalAccount,
                        quote.dstPool,
                        quote.dstExternalAccount,
                        quote.baseToken,
                        quote.quoteToken,
                        quote.baseTokenAmount,
                        quote.quoteTokenAmount,
                        quote.quoteExpiry
                    )
                )
            );
    }

    function _hashGuardianQuoteRFQM(RFQMQuote memory quote)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    '\x19Ethereum Signed Message:\n32',
                    keccak256(
                        abi.encodePacked(
                            quote.pool,
                            quote.externalAccount,
                            quote.trader,
                            quote.txid,
                            block.chainid
                        )
                    )
                )
            );
    }
}
