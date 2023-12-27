/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.0;

/// @title IHashflowMessenger
/// @author Victor Ionescu
/**
 * @notice This interface should be implemented by any contract
 * that is to be used for X-Chain Message passing.
 */
interface IHashflowXChainMessenger {
    struct XChainQuote {
        uint16 srcChainId;
        uint16 dstChainId;
        address srcPool;
        bytes32 dstPool;
        address srcExternalAccount;
        bytes32 dstExternalAccount;
        address trader;
        bytes32 dstTrader;
        address baseToken;
        bytes32 quoteToken;
        uint256 baseTokenAmount;
        uint256 quoteTokenAmount;
        bytes32 txid;
    }

    struct XChainTradePayload {
        uint16 dstChainId;
        bytes32 txid;
        bytes32 srcPool;
        bytes32 dstPool;
        bytes32 dstExternalAccount;
        bytes32 quoteToken;
        bytes32 dstTrader;
        uint256 quoteTokenAmount;
        bytes32 permissionedRelayer;
        bytes32 srcCaller;
        bytes32 dstContract;
        bytes dstContractCalldata;
    }

    /// @notice Emitted when an associated IHashflowMessenger on a source chain changes.
    /// @param chainId The Hashflow Chain ID.
    /// @param remoteAddress The address of the remote, pre-padded to 32 bytes.
    event UpdateXChainRemoteAddress(uint16 chainId, bytes remoteAddress);

    /// @notice The Hashflow Chain ID for this chain.
    function hChainId() external view returns (uint16);

    /// @notice Returns the Hashflow Router.
    function router() external view returns (address);

    /// @notice Returns the registered remote for a Hashflow Chain ID.
    /// @param hChainId The foreign Hashflow Chain ID.
    function xChainRemotes(uint16 hChainId)
        external
        view
        returns (bytes memory);

    /// @notice Send X-Chain trade fill message.
    /// @param xChainQuote Quote object.
    /// @param caller The caller of the X-Chain trade.
    /// @param dstContract The contract to call on the destination chain.
    /// @param dstCalldata The calldata to pass to the contract.
    function tradeXChain(
        XChainQuote memory xChainQuote,
        address caller,
        bytes32 dstContract,
        bytes memory dstCalldata
    ) external payable;

    /// @notice Updates the associated IHashflowMessenger address on a different chain.
    /// @param hChainId The Hashflow Chain ID of the peer chain.
    /// @param remoteAddress The address of the IHashflowMessenger on the peer chain.
    function updateXChainRemoteAddress(
        uint16 hChainId,
        bytes calldata remoteAddress
    ) external;

    /// @notice Withdraws excess fees to the owner.
    function withdrawFunds() external;
}
