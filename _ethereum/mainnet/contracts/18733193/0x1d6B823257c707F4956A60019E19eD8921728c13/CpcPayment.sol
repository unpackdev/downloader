// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract CpcPayment is AccessControl, Pausable, ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error ReceiverExist();
    error ReceiverNotExist();
    error SupportTokenExist();
    error SupportTokenNotExist();
    error NotEnoughAllowanceAmount();
    error NoReceiver();
    error MethodNotSupported();
    error TransferEthFailed();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event ReceiverAdded(address newReceiver, address addedBy);
    event ReceiverRemoved(address removedReceiver, address removedBy);
    event SupportTokenAdded(address newSupportToken, address addedBy);
    event SupportTokenRemoved(address removedSupportToken, address removedBy);
    event TokenPaymentMade(
        address indexed token,
        address indexed owner,
        address indexed receiver,
        uint256 amount,
        string paymentId
    );
    event EthPaymentMade(
        address indexed owner,
        address indexed receiver,
        uint256 amount,
        string paymentId
    );

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------
    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    EnumerableSet.AddressSet internal _receivers;
    EnumerableSet.AddressSet internal _supportTokens;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        super._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// -----------------------------------------------------------------------
    /// Modifier
    /// -----------------------------------------------------------------------
    /// -----------------------------------------------------------------------
    /// View Functions
    /// -----------------------------------------------------------------------

    function getReceivers() external view returns (address[] memory) {
        return _receivers.values();
    }

    function getSupportTokens() external view returns (address[] memory) {
        return _supportTokens.values();
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._unpause();
    }

    function addReceiver(
        address newReceiver
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_receivers.contains(newReceiver)) revert ReceiverExist();
        _receivers.add(newReceiver);
        emit ReceiverAdded(newReceiver, msg.sender);
    }

    function removeReceiver(
        address removedReceiver
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_receivers.contains(removedReceiver)) revert ReceiverNotExist();
        _receivers.remove(removedReceiver);
        emit ReceiverRemoved(removedReceiver, msg.sender);
    }

    function addSupportToken(
        address newSupportToken
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_supportTokens.contains(newSupportToken))
            revert SupportTokenExist();
        _supportTokens.add(newSupportToken);
        emit SupportTokenAdded(newSupportToken, msg.sender);
    }

    function removeSupportToken(
        address removedSupportToken
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_supportTokens.contains(removedSupportToken))
            revert SupportTokenNotExist();
        _supportTokens.remove(removedSupportToken);
        emit SupportTokenRemoved(removedSupportToken, msg.sender);
    }

    function makePaymentByToken(
        address token,
        uint256 amount,
        string memory paymentId
    ) external whenNotPaused nonReentrant {
        if (IERC20(token).allowance(msg.sender, address(this)) < amount)
            revert NotEnoughAllowanceAmount();
        uint256 numberOfReceiver = _receivers.length();
        if (numberOfReceiver == 0) revert NoReceiver();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 nextReceiverIndex = block.timestamp % _receivers.length();
        address nextReceiver = _receivers.at(nextReceiverIndex);
        IERC20(token).safeTransfer(nextReceiver, amount);

        emit TokenPaymentMade(
            token,
            msg.sender,
            nextReceiver,
            amount,
            paymentId
        );
    }

    function makePaymentByEth(
        string memory paymentId
    ) external payable whenNotPaused nonReentrant {
        uint256 amount = msg.value;
        uint256 numberOfReceiver = _receivers.length();
        if (numberOfReceiver == 0) revert NoReceiver();

        uint256 nextReceiverIndex = block.timestamp % _receivers.length();
        address nextReceiver = _receivers.at(nextReceiverIndex);
        _safeTransferEth(nextReceiver, amount);

        emit EthPaymentMade(msg.sender, nextReceiver, amount, paymentId);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        revert MethodNotSupported();
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        revert MethodNotSupported();
    }

    /// @dev _safeTransferEth transfer eth and throw on failure or exception
    function _safeTransferEth(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert TransferEthFailed();
    }
}
