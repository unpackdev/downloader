// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC1155Multinetwork.sol";

/// @notice defines the interface for the bridge contract. This contract implements a decentralized
/// bridge for an erc1155 token which enables users to transfer erc1155 tokens between supported networks.
/// users request a transfer in one network, which registers the transfer in the bridge contract, and generates
/// an event. This event is seen by a validator, who validates the transfer by calling the validate method on
/// the target network. Once a majority of validators have validated the transfer, the transfer is executed on the
/// target network by minting the approriate token type and burning the appropriate amount of the source token,
/// which is held in custody by the bridge contract until the transaction is confirmed. In order to participate,
/// validators must register with the bridge contract and put up a deposit as collateral.  The deposit is returned
/// to the validator when the validator self-removes from the validator set. If the validator acts in a way that
/// violates the rules of the bridge contract - namely the validator fails to validate a number of transfers,
/// or the validator posts some number of transfers which remain unconfirmed, then the validator is removed from the
/// validator set and their bond is distributed to other validators. The validator will then need to re-bond and
/// re-register. Repeated violations of the rules of the bridge contract will result in the validator being removed
/// from the validator set permanently via a ban.
interface IERC1155Bridge is IERC1155Multinetwork {

    /// @notice the network transfer status
    /// pending = on its way to the target network
    /// confirmed = target network received the transfer
    enum NetworkTransferStatus {
        Started,
        Confirmed,
        Failed
    }

    /// @notice the network transfer request structure. contains all the expected params of a transfer plus one addition nwtwork id param
    struct NetworkTransferRequest {
        uint256 id;
        address from;
        address to;
        uint32 network;
        uint256 token;
        uint256 amount;
        bytes data;
        NetworkTransferStatus status;
    }

    /// @notice emitted when a transfer is started
    event NetworkTransferStarted(
        uint256 indexed id,
        NetworkTransferRequest data
    );

    /// @notice emitted when a transfer is confirmed
    event NetworkTransferConfirmed(
        uint256 indexed id,
        NetworkTransferRequest data
    );

    /// @notice emitted when a transfer is cancelled
    event NetworkTransferCancelled(
        uint256 indexed id,
        NetworkTransferRequest data
    );

    /// @notice the token this bridge works with
    function token() external view returns (address);

    /// @notice start the network transfer
    function transfer(
        uint256 id,
        NetworkTransferRequest memory request
    ) external;

    /// @notice confirm the transfer. called by the target-side bridge
    /// @param id the id of the transfer
    function confirm(uint256 id) external;

    /// @notice fail  the transfer. called by the target-side bridge
    /// @param id the id of the transfer
    function cancel(uint256 id) external;

    /// @notice get the transfer request struct
    /// @param id the id of the transfer
    /// @return the transfer request struct
    function get(uint256 id)
    external view returns (NetworkTransferRequest memory);


}
