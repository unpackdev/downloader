// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ICustomGateway.sol";
import "./IGFlyL1.sol";
import "./CrosschainMessenger.sol";

/**
 * @title Implementation of a gFLY gateway to be deployed on L1
 */
contract L1GFlyGateway is Initializable, AccessControlUpgradeable, IL1CustomGateway {

    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    // Token bridge state variables
    address public l1GFlyToken;
    address public l2GFlyToken;
    address public l2Gateway;
    address public router;

    // Custom functionality
    bool public allowsDeposits;

    IInbox public inbox;

    /**
    * Emitted when calling sendTxToL2CustomRefund
    * @param from account that submitted the retryable ticket
     * @param to account recipient of the retryable ticket
     * @param seqNum id for the retryable ticket
     * @param data data of the retryable ticket
     */
    event TxToL2(
        address indexed from,
        address indexed to,
        uint256 indexed seqNum,
        bytes data
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * Contract constructor, sets the L1 router and Inbox to be used in the contract's functions.
     * @param router_ L1GatewayRouter address
     * @param inbox_ Inbox address
     * @param dao DAO address
     */
    function initialize(address router_, address inbox_, address dao) external initializer {
        __AccessControl_init();

        _setupRole(ADMIN_ROLE, dao);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        router = router_;
        inbox = IInbox(inbox_);
        allowsDeposits = false;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "ACCESS_DENIED");
        _;
    }

    modifier onlyCounterpartGateway(address l2Counterpart) {
        // A message coming from the counterpart gateway was executed by the bridge
        IBridge bridge = inbox.bridge();
        require(msg.sender == address(bridge), "NOT_FROM_BRIDGE");

        // And the outbox reports that the L2 address of the sender is the counterpart gateway
        address l2ToL1Sender = IOutbox(bridge.activeOutbox()).l2ToL1Sender();
        require(l2ToL1Sender == l2Counterpart, "ONLY_COUNTERPART_GATEWAY");

        _;
    }


    /**
     * Sets the information needed to use the gateway. To simplify the process of testing, this function can be called once
     * by the owner of the contract to set these addresses.
     * @param l1GFlyToken_ address of the gFLY token on L1
     * @param l2GFlyToken_ address of the gFLY token on L2
     * @param l2Gateway_ address of the counterpart gateway (on L2)
     */
    function setTokenBridgeInformation(
        address l1GFlyToken_,
        address l2GFlyToken_,
        address l2Gateway_
    ) public onlyAdmin {
        require(l1GFlyToken == address(0), "Token bridge information already set");
        l1GFlyToken = l1GFlyToken_;
        l2GFlyToken = l2GFlyToken_;
        l2Gateway = l2Gateway_;

        // Allows deposits after the information has been set
        allowsDeposits = true;
    }

    /// @dev See {ICustomGateway-outboundTransfer}
    function outboundTransfer(
        address l1Token,
        address to,
        uint256 amount,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) public payable override returns (bytes memory) {
        return outboundTransferCustomRefund(l1Token, to, to, amount, maxGas, gasPriceBid, data);
    }

    /// @dev See {IL1CustomGateway-outboundTransferCustomRefund}
    function outboundTransferCustomRefund(
        address l1Token,
        address refundTo,
        address to,
        uint256 amount,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) public payable override returns (bytes memory res) {
        // Only execute if deposits are allowed
        require(allowsDeposits == true, "Deposits are currently disabled");

        // Only allow calls from the router
        require(msg.sender == router, "Call not received from router");

        // Only allow the custom token to be bridged through this gateway
        require(l1Token == l1GFlyToken, "Token is not allowed through this gateway");

        address from;
        uint256 seqNum;
        {
            bytes memory extraData;
            uint256 maxSubmissionCost;
            (from, maxSubmissionCost, extraData) = _parseOutboundData(data);

            // The inboundEscrowAndCall functionality has been disabled, so no data is allowed
            require(extraData.length == 0, "EXTRA_DATA_DISABLED");

            // Burning the tokens from the gateway
            IGFlyL1(l1Token).bridgeBurn(from, amount);

            // We override the res field to save on the stack
            res = getOutboundCalldata(l1Token, from, to, amount, extraData);

            // Trigger the crosschain message
            seqNum = _sendTxToL2CustomRefund(
                l2Gateway,
                refundTo,
                from,
                msg.value,
                0,
                maxSubmissionCost,
                maxGas,
                gasPriceBid,
                res
            );
        }

        emit DepositInitiated(l1Token, from, to, seqNum, amount);
        res = abi.encode(seqNum);
    }

    /// @dev See {ICustomGateway-finalizeInboundTransfer}
    function finalizeInboundTransfer(
        address l1Token,
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) public payable override onlyCounterpartGateway(l2Gateway) {
        // Only allow the custom token to be bridged through this gateway
        require(l1Token == l1GFlyToken, "Token is not allowed through this gateway");

        // Decoding exitNum
        (uint256 exitNum, ) = abi.decode(data, (uint256, bytes));

        // Minting the tokens from the gateway
        IGFlyL1(l1Token).bridgeMint(to, amount);

        emit WithdrawalFinalized(l1Token, from, to, exitNum, amount);
    }

    /// @dev See {ICustomGateway-getOutboundCalldata}
    function getOutboundCalldata(
        address l1Token,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) public pure override returns (bytes memory outboundCalldata) {
        bytes memory emptyBytes = "";

        outboundCalldata = abi.encodeWithSelector(
            ICustomGateway.finalizeInboundTransfer.selector,
            l1Token,
            from,
            to,
            amount,
            abi.encode(emptyBytes, data)
        );

        return outboundCalldata;
    }

    /// @dev See {ICustomGateway-calculateL2TokenAddress}
    function calculateL2TokenAddress(address l1Token) public view override returns (address) {
        if (l1Token == l1GFlyToken) {
            return l2GFlyToken;
        }

        return address(0);
    }

    /// @dev See {ICustomGateway-counterpartGateway}
    function counterpartGateway() public view override returns (address) {
        return l2Gateway;
    }

    /**
     * Parse data received in outboundTransfer
     * @param data encoded data received
     * @return from account that initiated the deposit,
     *         maxSubmissionCost max gas deducted from user's L2 balance to cover base submission fee,
     *         extraData decoded data
     */
    function _parseOutboundData(bytes memory data)
    internal
    pure
    returns (
        address from,
        uint256 maxSubmissionCost,
        bytes memory extraData
    )
    {
        // Router encoded
        (from, extraData) = abi.decode(data, (address, bytes));

        // User encoded
        (maxSubmissionCost, extraData) = abi.decode(extraData, (uint256, bytes));
    }

    // --------------------
    // Custom methods
    // --------------------
    /**
     * Disables the ability to deposit funds
     */
    function disableDeposits() external onlyAdmin {
        allowsDeposits = false;
    }

    /**
     * Enables the ability to deposit funds
     */
    function enableDeposits() external onlyAdmin {
        require(l1GFlyToken != address(0), "Token bridge information has not been set yet");
        allowsDeposits = true;
    }

    /**
     * Creates the retryable ticket to send over to L2 through the Inbox
     * @param to account to be credited with the tokens in the destination layer
     * @param refundTo account, or its L2 alias if it have code in L1, to be credited with excess gas refund in L2
     * @param user account with rights to cancel the retryable and receive call value refund
     * @param l1CallValue callvalue sent in the L1 submission transaction
     * @param l2CallValue callvalue for the L2 message
     * @param maxSubmissionCost max gas deducted from user's L2 balance to cover base submission fee
     * @param maxGas max gas deducted from user's L2 balance to cover L2 execution
     * @param gasPriceBid gas price for L2 execution
     * @param data encoded data for the retryable
     * @return seqnum id for the retryable ticket
     */
    function _sendTxToL2CustomRefund(
        address to,
        address refundTo,
        address user,
        uint256 l1CallValue,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes memory data
    ) internal returns (uint256) {
        uint256 seqNum = inbox.createRetryableTicket{ value: l1CallValue }(
            to,
            l2CallValue,
            maxSubmissionCost,
            refundTo,
            user,
            maxGas,
            gasPriceBid,
            data
        );

        emit TxToL2(user, to, seqNum, data);
        return seqNum;
    }
}