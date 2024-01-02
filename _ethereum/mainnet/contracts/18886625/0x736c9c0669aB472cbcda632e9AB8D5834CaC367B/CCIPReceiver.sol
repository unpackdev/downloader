// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAny2EVMMessageReceiver.sol";
import "./Client.sol";
import "./IERC165.sol";

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
/// @author Dinari (https://github.com/dinaricrypto/usdplus-contracts/blob/main/src/bridge/CCIPReceiver.sol)
/// @author Modified from Chainlink (https://github.com/smartcontractkit/ccip/blob/ccip-develop/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol)
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
    /// ------------------ Types ------------------

    event RouterSet(address indexed router);

    error InvalidRouter(address router);

    /// ------------------ Storage ------------------

    struct CCIPReceiverStorage {
        address _router;
    }

    // keccak256(abi.encode(uint256(keccak256("dinaricrypto.storage.CCIPReceiver")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CCIPRECEIVER_STORAGE_LOCATION =
        0xedc444dd658271ef4a9c3fff333a6ab7abefccb2b01babad968042805dd76d00;

    function _getCCIPReceiverStorage() private pure returns (CCIPReceiverStorage storage $) {
        assembly {
            $.slot := CCIPRECEIVER_STORAGE_LOCATION
        }
    }

    /// ------------------ Initialization ------------------

    // slither-disable-next-line naming-convention
    function __CCIPReceiver_init(address router) internal {
        CCIPReceiverStorage storage $ = _getCCIPReceiverStorage();
        $._router = router;
    }

    function _setRouter(address router) internal {
        if (router == address(0)) revert InvalidRouter(address(0));
        CCIPReceiverStorage storage $ = _getCCIPReceiverStorage();
        $._router = router;
        emit RouterSet(router);
    }

    /// @notice IERC165 supports an interfaceId
    /// @param interfaceId The interfaceId to check
    /// @return true if the interfaceId is supported
    /// @dev Should indicate whether the contract implements IAny2EVMMessageReceiver
    /// e.g. return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId
    /// This allows CCIP to check if ccipReceive is available before calling it.
    /// If this returns false or reverts, only tokens are transferred to the receiver.
    /// If this returns true, tokens are transferred and ccipReceive is called atomically.
    /// Additionally, if the receiver address does not have code associated with
    /// it at the time of execution (EXTCODESIZE returns 0), only tokens will be transferred.
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IAny2EVMMessageReceiver
    function ccipReceive(Client.Any2EVMMessage calldata message) external virtual override onlyRouter {
        _ccipReceive(message);
    }

    /// @notice Override this function in your implementation.
    /// @param message Any2EVMMessage
    function _ccipReceive(Client.Any2EVMMessage calldata message) internal virtual;

    /////////////////////////////////////////////////////////////////////
    // Plumbing
    /////////////////////////////////////////////////////////////////////

    /// @notice Return the current router
    /// @return i_router address
    function getRouter() public view returns (address) {
        CCIPReceiverStorage storage $ = _getCCIPReceiverStorage();
        return $._router;
    }

    /// @dev only calls from the set router are accepted.
    modifier onlyRouter() {
        if (msg.sender != getRouter()) revert InvalidRouter(msg.sender);
        _;
    }
}
