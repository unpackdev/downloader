// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Messaging.sol";
import "./ErrorLib.sol";

// Abstract contract to hold shared components
abstract contract FWBase is
    Messaging,
    AccessControl,
    ReentrancyGuard,
    Pausable
{
    // Shared Events
    event BridgeUserHandled(RecipientInfo[] recipients);
    event BatchProcessed(RequestPayload payload);

    address public _l1Bridge;
    uint256 public _l2Bridge;
    uint256 public _l2FW;
    uint256 public _underlyingBalance;
    int256 public _dueAmount;
    uint256 public _batchCounter;
    uint256 public _lastL2Block;
    uint256 public constant WAD = 10 ** 18;
    uint256 public constant FIELD_PRIME =
        0x800000000000011000000000000000000000000000000000000000000000001;
    bytes32 public constant PROCESS_ROLE = keccak256("0x01");
    bytes32 public constant PAUSE_ROLE = keccak256("0x02");
    bytes32 public constant LP_ROLE = keccak256("0x03");

    struct RequestPayload {
        uint256 nonce;
        uint256 amountUnderlying;
        uint256 amountLpFees;
    }

    struct RecipientInfo {
        address payable user;
        uint256 debt;
        uint256 l2Block;
    }

    /**
     * @dev Receive Ether function
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}

    constructor(
        address starknetCore,
        uint256 l2FW,
        uint256 l2Bridge,
        address l1Bridge
    ) {
        _grantRole(0, msg.sender);
        _grantRole(PROCESS_ROLE, msg.sender);
        _grantRole(PAUSE_ROLE, msg.sender);
        _grantRole(LP_ROLE, msg.sender);
        Messaging.initializeMessaging(starknetCore);
        _checkValidL2Address(l2FW);
        _l2FW = l2FW;
        _checkValidL2Address(l2Bridge);
        _l2Bridge = l2Bridge;
        _l1Bridge = l1Bridge;
        _lastL2Block = 1;
    }

    /**
     * @dev Pauses the contract, preventing further execution of transactions. Only the contract admin can perform this action.
     */
    function pause() external onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing execution of transactions. Only the contract admin can perform this action.
     */
    function unpause() external onlyRole(0) {
        _unpause();
    }

    /**
     * @dev Handles bridge users' transactions, distributing tokens
     * Only the relayer can call this function.
     * @param recipients An array of recipient information for handling transactions.
     */
    function handleBridgeUsers(
        RecipientInfo[] memory recipients
    ) external onlyRole(PROCESS_ROLE) whenNotPaused {
        if (recipients.length == 0) revert ErrorLib.EmptyArray();
        for (uint256 i = 0; i < recipients.length; ) {
            if (_lastL2Block > recipients[i].l2Block)
                revert ErrorLib.BlockAlreadyProcessed();
            _lastL2Block = recipients[i].l2Block;
            _handleBridge(recipients[i].user, recipients[i].debt);
            unchecked {
                i++;
            }
        }
        emit BridgeUserHandled(recipients);
    }

    /**
     * @dev Handles bridge users' transactions manually, function used only if we missed users
     * Only the relayer can call this function.
     * @param recipients An array of recipient information for handling transactions.
     */
    function handleBridgeUsersManually(
        RecipientInfo[] memory recipients
    ) external onlyRole(0) {
        if (recipients.length == 0) revert ErrorLib.EmptyArray();
        for (uint256 i = 0; i < recipients.length; ) {
            _handleBridge(recipients[i].user, recipients[i].debt);
            unchecked {
                i++;
            }
        }
        emit BridgeUserHandled(recipients);
    }

    /**
     * @dev Executes a batch of transactions, processing messages from L2 and handling refunding + paying liquidity providers
     * Can only be called when the contract is not paused and is non-reentrant.
     * @param _payload The payload containing batch information.
     */
    function executeBatch(
        RequestPayload calldata _payload
    ) external virtual nonReentrant whenNotPaused {
        if (_batchCounter != _payload.nonce)
            revert ErrorLib.InvalidBatchNonce();

        _batchCounter += 1;
        _consumeL2Message(_l2FW, _getRequestMessageData(_payload));

        _dueAmount -= int256(_payload.amountUnderlying);

        uint256 totalAmountRefunded = _payload.amountUnderlying +
            _payload.amountLpFees;

        _underlyingBalance += totalAmountRefunded;

        _withdrawTokenFromBridge(
            _l1Bridge,
            _l2Bridge,
            address(this),
            totalAmountRefunded
        );
        emit BatchProcessed(_payload);
    }

    /**
     * @dev Retrieves the message data for a request payload.
     * @param _payload The request payload for which to retrieve the message data.
     * @return data The message data containing payload details.
     */
    function _getRequestMessageData(
        RequestPayload memory _payload
    ) internal pure returns (uint256[] memory data) {
        (uint256 lowNonce, uint256 highNonce) = u256(_payload.nonce);
        (uint256 lowAmountUnderlying, uint256 highAmountUnderlying) = u256(
            _payload.amountUnderlying
        );
        (uint256 lowAmountLpFees, uint256 highAmountLpFees) = u256(
            _payload.amountLpFees
        );

        data = new uint256[](6);
        data[0] = lowNonce;
        data[1] = highNonce;
        data[2] = lowAmountUnderlying;
        data[3] = highAmountUnderlying;
        data[4] = lowAmountLpFees;
        data[5] = highAmountLpFees;
    }

    /**
     * @dev Checks if the provided L2 address is valid.
     * @param l2Address The L2 address to be validated.
     */
    function _checkValidL2Address(uint256 l2Address) internal pure {
        if (!_isValidL2Address(l2Address)) revert ErrorLib.InvalidL2Address();
    }

    /**
     * @dev Checks if the contract has enough underlying balance for a given amount.
     * @param amount The amount to be checked.
     */
    function _checkEnoughBalance(uint256 amount) internal view {
        bool isEnoughBalance = (amount <= _underlyingBalance);
        if (!isEnoughBalance) revert ErrorLib.InsufficientUnderlying();
    }

    /**
     * @dev Checks if the provided L2 address is valid within the FIELD_PRIME range.
     * @param l2Address The L2 address to be validated.
     * @return bool Whether the address is valid.
     */
    function _isValidL2Address(uint256 l2Address) internal pure returns (bool) {
        return (l2Address > 0 && l2Address < FIELD_PRIME);
    }

    /**
     * @dev Handles the bridge operation for transferring assets between L1 and L2.
     * Transfers assets from the contract to a user, processes fees.
     * @param user The address of the user receiving assets.
     * @param amount The amount of assets to be transferred.
     */
    function _handleBridge(
        address payable user,
        uint256 amount
    ) internal virtual {
        if (user == address(0)) revert ErrorLib.AddressNull();
        if (amount == 0) revert ErrorLib.AmountNull();
        _checkEnoughBalance(amount);
        _transfer_underlying(user, amount);
        unchecked {
            _dueAmount += int256(amount);
            _underlyingBalance -= amount;
        }
    }

    function _transfer_underlying(
        address payable user,
        uint256 amount
    ) internal virtual {}
}
