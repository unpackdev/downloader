// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ConfirmedOwner.sol";
import "./CCIPReceiver.sol";
import "./Client.sol";
import "./IRouterClient.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./EnumerableSet.sol";
import "./Address.sol";

import "./BytesLib.sol";
import "./CCIPApprovedSource.sol";
import "./IERC20Wrapper.sol";
import "./Recoverable.sol";
import "./ITokenPool.sol";

/**
 * @title Noot Portal (https://noot.fun)
 *
 * @notice CCIP cross chain bridge to transfer NOOT between different chains.
 * When transfering NOOT, NOOT is wrappes as WNOOT and sent via CCIP TokenPool.
 *
 * @dev This contract has emergency recover methods callable by the owner. These methods are
 * meant to be used in case of a critical bug which requires migration to a new Portal contract.
 * Due to the nature of these methods, it is strongly recommended to transfer the ownership to
 * a multisig wallet and/or a timelock controller after the initial setup is completed.
 */
contract NootBridge is
    CCIPApprovedSource,
    CCIPReceiver,
    ReentrancyGuard,
    Pausable,
    Recoverable
{
    using BytesLib for bytes;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct FailedReceive {
        bool viaCustomTokenPool;
        uint64 sourceChainSelector;
        address recipient;
        uint256 amount;
    }

    IERC20Wrapper public immutable token;

    mapping(uint64 chainSelector => address portals) public crossChainTarget;
    mapping(uint64 chainSelector => bool) public transferEnabled;
    ITokenPool public customTokenPool;

    EnumerableSet.Bytes32Set internal _failedReceiveMessageIds;
    mapping(bytes32 messageId => FailedReceive) internal _failedReceives;

    error OnlySelf();
    error InvalidRecipient(address);
    error InvalidTokenAmounts(uint256);
    error InvalidToken(address);
    error InvalidData();
    error NoFailedReceiveFound(bytes32);
    error TransferNotEnabled(uint64 chainSelector);
    error InvalidDestinationChainSelector(uint64 chainSelector);
    error NoTokensSent();
    error InsufficientFees(uint256 fee, uint256 sent);
    error UnsafeRecovery();
    error NoTokenPoolSet();

    event CrossChainTagetChanged(uint64 chainSelector, address target);
    event TransferEnabledChanged(uint64 chainSelector, bool enabled);
    event CustomTokenPoolChanged(address tokenPool);

    event Sent(
        address indexed sender,
        address indexed recipient,
        uint256 amountSent,
        uint256 amountReceived,
        uint64 destinationChainSelector,
        bytes32 indexed messageId
    );
    event Received(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address indexed recipient,
        uint256 amount
    );
    event RecoverdReceive(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address indexed recipient,
        uint256 amount
    );
    event Failed(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address recipient,
        uint256 amount,
        bytes reason
    );

    modifier onlySelf() {
        if (msg.sender != address(this)) revert OnlySelf();
        _;
    }

    constructor(
        address _owner,
        address _router,
        address _token
    ) ConfirmedOwner(_owner) CCIPReceiver(_router) {
        token = IERC20Wrapper(_token);
    }

    /* -----------------------*/
    /* --- User interface --- */
    /* -----------------------*/

    /**
     * @notice Transfer `amount` NOOT from sender to `recipient` on `destinationChainSelector`.
     * @param destinationChainSelector  CCIP chain selector for destination chain.
     * @param recipient address to receive the token on destination chain.
     * @param amount amount of NOOT to transfer.
     * @param viaCustomTokenPool whether to use custom tokenPool or CCIP tokenPool
     * @param extraArgs CCIP extraArgs, encoding gasLimit on destination chain and possibly future protocol options.
     */
    function transfer(
        uint64 destinationChainSelector,
        address recipient,
        uint256 amount,
        bool viaCustomTokenPool,
        bytes calldata extraArgs
    ) external payable whenNotPaused nonReentrant {
        if (!transferEnabled[destinationChainSelector])
            revert TransferNotEnabled(destinationChainSelector);

        if (recipient == address(0)) revert InvalidRecipient(recipient);

        uint256 deposited = token.deposit(msg.sender, amount);
        if (deposited == 0) revert NoTokensSent();

        if (viaCustomTokenPool) {
            if (address(customTokenPool) == address(0)) revert NoTokenPoolSet();
            token.transfer(address(customTokenPool), deposited);
            customTokenPool.lockOrBurn(deposited);
        } else {
            token.approve(getRouter(), deposited);
        }

        (Client.EVM2AnyMessage memory message, uint256 fee) = _buildMessage(
            viaCustomTokenPool,
            destinationChainSelector,
            recipient,
            deposited,
            extraArgs
        );

        if (fee > msg.value) revert InsufficientFees(fee, msg.value);

        bytes32 messageId = IRouterClient(getRouter()).ccipSend{value: fee}(
            destinationChainSelector,
            message
        );

        emit Sent(
            msg.sender,
            recipient,
            amount,
            deposited,
            destinationChainSelector,
            messageId
        );

        if (msg.value > fee) {
            Address.sendValue(payable(msg.sender), msg.value - fee);
        }
    }

    /**
     * @notice Recover from a failed transfer on destination chain.
     * Possibly due to insufficient gas supplied for CCIP.
     * @param messageId CCIP messageId which failed to deliver the NOOT tokens.
     */
    function retry(bytes32 messageId) external whenNotPaused nonReentrant {
        FailedReceive memory data = _failedReceives[messageId];
        if (data.recipient == address(0)) {
            revert NoFailedReceiveFound(messageId);
        }

        this.handleReceived(
            data.viaCustomTokenPool,
            data.recipient,
            data.amount
        );

        emit RecoverdReceive(
            messageId,
            data.sourceChainSelector,
            data.recipient,
            data.amount
        );

        _failedReceiveMessageIds.remove(messageId);
        delete _failedReceives[messageId];
    }

    /**
     * @dev Handle receiving NOOT tokens from CCIP.
     * callable by this contract for catching reverts.
     * @param recipient recipient of NOOT
     * @param amount amount of NOOT
     */
    function handleReceived(
        bool viaCustomTokenPool,
        address recipient,
        uint256 amount
    ) external onlySelf whenNotPaused {
        if (viaCustomTokenPool) {
            if (address(customTokenPool) == address(0)) revert NoTokenPoolSet();

            customTokenPool.releaseOrMint(address(this), amount);
        }
        token.withdraw(recipient, amount);
    }

    /**
     * @notice Calculate CCIP transfer fees.
     * @param destinationChainSelector  CCIP chain selector for destination chain.
     * @param recipient address to receive the token on destination chain.
     * @param deposited amount of WNOOT received after wrapping.
     * @param viaCustomTokenPool whether to use custom tokenPool or CCIP tokenPool
     * @param extraArgs CCIP extraArgs, encoding gasLimit on destination chain and possibly future protocol options.
     */
    function calculateTransferFees(
        uint64 destinationChainSelector,
        address recipient,
        uint256 deposited,
        bool viaCustomTokenPool,
        bytes calldata extraArgs
    ) external view returns (uint256 fee) {
        (, fee) = _buildMessage(
            viaCustomTokenPool,
            destinationChainSelector,
            recipient,
            deposited,
            extraArgs
        );
    }

    /**
     * @notice Encode CCIP message data.
     * @param recipient address to receive the token on destination chain.
     * @param deposited amount of WNOOT received after wrapping.
     * @param viaCustomTokenPool whether to use custom tokenPool or CCIP tokenPool
     */
    function encodeMessage(
        address recipient,
        uint256 deposited,
        bool viaCustomTokenPool
    ) external pure returns (bytes memory) {
        return
            viaCustomTokenPool
                ? _encodeRecipientAndAmount(recipient, deposited)
                : _encodeRecipient(recipient);
    }

    /**
     * @notice Underlying token of the wrapped asset which is bridged.
     */
    function underlyingToken() external view returns (address) {
        return address(token.underlying());
    }

    /**
     * @notice List of CCIP messageIds which failed to execute.
     */
    function failedReceiveMessageIds()
        external
        view
        returns (bytes32[] memory)
    {
        return _failedReceiveMessageIds.values();
    }

    /**
     * @notice Detais of receives of NOOT which failed to execute.
     */
    function failedReceives()
        external
        view
        returns (bytes32[] memory messageIds, FailedReceive[] memory data)
    {
        data = new FailedReceive[](_failedReceiveMessageIds.length());
        messageIds = new bytes32[](_failedReceiveMessageIds.length());
        for (uint256 i = 0; i < _failedReceiveMessageIds.length(); ++i) {
            messageIds[i] = _failedReceiveMessageIds.at(i);
            data[i] = _failedReceives[_failedReceiveMessageIds.at(i)];
        }
    }

    /**
     * @notice Detais of receives of NOOT which failed to execute for given messageId.
     * @param messageId CCIP messageId which failed to execute.
     */
    function failedReceive(
        bytes32 messageId
    ) external view returns (FailedReceive memory) {
        return _failedReceives[messageId];
    }

    /* ------------------------*/
    /* --- Admin interface --- */
    /* ------------------------*/

    /**
     * @notice Configure the target CCIP message receiver on the given destination chain.
     * Only callable by owner.
     * @param chainSelector CCIP chain selector of destination chain to configure.
     * @param target Contract address to send messages to when targeting destination chain.
     */
    function setCrossChainTarget(
        uint64 chainSelector,
        address target
    ) external onlyOwner {
        crossChainTarget[chainSelector] = target;
        emit CrossChainTagetChanged(chainSelector, target);
    }

    /**
     * @notice Enable/Disable transfers from this contract to destination chain given by `chainSelector`.
     * Only callable by owner.
     * @param chainSelector CCIP chain selector of destination chain to configure.
     * @param enabled the new state for the given destination chain.
     */
    function setTransferEnabled(
        uint64 chainSelector,
        bool enabled
    ) external onlyOwner {
        transferEnabled[chainSelector] = enabled;
        emit TransferEnabledChanged(chainSelector, enabled);
    }

    /**
     * @notice Set custom tokenPool address managing lock/unlock or burn/mint of token.
     * Only callable by owner.
     * @param _customTokenPool custom tokenPool address
     */
    function setCustomTokenPool(address _customTokenPool) external onlyOwner {
        customTokenPool = ITokenPool(_customTokenPool);
        emit CustomTokenPoolChanged(_customTokenPool);
    }

    /**
     * @notice Change CCIP Router in case of a CCIP upgrade.
     * Only callable by owner.
     * @param router CCIP router address.
     */
    function setRouter(address router) external onlyOwner {
        _setRouter(router);
    }

    /**
     * @notice Pause all functionality of this contract.
     * Only callable by owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Resume all functionality of this contract.
     * Only callable by owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @param _recipient: recipient
     * @dev Callable by owner
     */
    function recoverERC20(
        address _token,
        address _recipient
    ) public virtual override onlyOwner {
        if (_token == address(token)) revert UnsafeRecovery();
        super.recoverERC20(_token, _recipient);
    }

    /**
     * @notice Allows the owner to recover the bridged token from this contract.
     * @param _recipient: recipient
     * @param _amount: token amount
     * @dev Callable by owner. This methid is meant to be used in case of stuck
     * funds due to failed messages which cannot be recoverd via `retry`.
     * The token is unwrapped on recovery.
     */
    function recoverToken(
        address _recipient,
        uint256 _amount
    ) external virtual onlyOwner {
        token.withdraw(_recipient, _amount);
    }

    /* -----------------------*/
    /* --- CCIP interface --- */
    /* -----------------------*/

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    )
        internal
        override
        onlyApprovedSource(message.sourceChainSelector, message.sender)
        nonReentrant
    {
        uint256 tokenAmount;
        address recipient;
        bool viaCustomTokenPool;
        if (message.destTokenAmounts.length == 0) {
            if (message.data.length != 52) revert InvalidData();
            recipient = message.data.readAddress(0);
            tokenAmount = message.data.readUInt256(20);
            viaCustomTokenPool = true;
        } else if (message.destTokenAmounts.length == 1) {
            Client.EVMTokenAmount memory tokenAndAmount = message
                .destTokenAmounts[0];
            if (tokenAndAmount.token != address(token))
                revert InvalidToken(tokenAndAmount.token);
            if (message.data.length != 20) revert InvalidData();
            tokenAmount = tokenAndAmount.amount;
            recipient = message.data.readAddress(0);
            viaCustomTokenPool = false;
        } else {
            revert InvalidTokenAmounts(message.destTokenAmounts.length);
        }

        if (recipient == address(this) || recipient == address(0))
            revert InvalidRecipient(recipient);

        try this.handleReceived(viaCustomTokenPool, recipient, tokenAmount) {
            emit Received(
                message.messageId,
                message.sourceChainSelector,
                recipient,
                tokenAmount
            );
        } catch (bytes memory reason) {
            _failedReceiveMessageIds.add(message.messageId);
            _failedReceives[message.messageId] = FailedReceive({
                viaCustomTokenPool: viaCustomTokenPool,
                sourceChainSelector: message.sourceChainSelector,
                recipient: recipient,
                amount: tokenAmount
            });
            emit Failed(
                message.messageId,
                message.sourceChainSelector,
                recipient,
                tokenAmount,
                reason
            );
        }
    }

    /* ---------------------------*/
    /* --- Internal interface --- */
    /* ---------------------------*/

    function _encodeRecipient(
        address recipient
    ) internal pure returns (bytes memory data) {
        data = new bytes(20);
        data.writeAddress(0, recipient);
    }

    function _encodeRecipientAndAmount(
        address recipient,
        uint256 amount
    ) internal pure returns (bytes memory data) {
        data = new bytes(52);
        data.writeAddress(0, recipient);
        data.writeUInt256(20, amount);
    }

    function _buildMessage(
        bool viaCustomTokenPool,
        uint64 destinationChainSelector,
        address recipient,
        uint256 deposited,
        bytes memory extraArgs
    )
        internal
        view
        returns (Client.EVM2AnyMessage memory message, uint256 fee)
    {
        address target = crossChainTarget[destinationChainSelector];
        if (target == address(0))
            revert InvalidDestinationChainSelector(destinationChainSelector);

        Client.EVMTokenAmount[] memory tokenAmounts;
        bytes memory data;

        if (viaCustomTokenPool) {
            tokenAmounts = new Client.EVMTokenAmount[](0);
            data = _encodeRecipientAndAmount(recipient, deposited);
        } else {
            tokenAmounts = new Client.EVMTokenAmount[](1);
            tokenAmounts[0] = Client.EVMTokenAmount({
                token: address(token),
                amount: deposited
            });
            data = _encodeRecipient(recipient);
        }

        message = Client.EVM2AnyMessage({
            receiver: abi.encode(target),
            data: data,
            tokenAmounts: tokenAmounts,
            extraArgs: extraArgs,
            feeToken: address(0)
        });

        fee = IRouterClient(getRouter()).getFee(
            destinationChainSelector,
            message
        );
    }
}
