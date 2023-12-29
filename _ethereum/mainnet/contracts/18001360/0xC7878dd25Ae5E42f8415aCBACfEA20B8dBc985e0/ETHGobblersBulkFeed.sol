// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Owned.sol";
import "./ECDSA.sol";

contract ETHGobblersBulkFeed is Owned {
    using ECDSA for bytes32;
    // Off chain signer address
    address public signer;
    // Event emited when a feed is made
    event Feed(bytes tokenIds, bytes amounts);

    constructor(
        address _signer,
        address _owner
    ) Owned(_owner){
        signer = _signer;
    }

    /// @notice Function to feed multiple gobblers at once.
    /// @param tokenIds The tokenIds of the gobblers to feed
    /// @param amounts The amounts to feed each gobbler
    /// @param expiryBlock The block number after which the feed is no longer valid
    /// @param messageHash The hash of the feed function data
    /// @param signature The signature of the messageHash
    function bulkFeed(
        uint[] calldata tokenIds,
        uint[] calldata amounts,
        uint expiryBlock,
        bytes32 messageHash,
        bytes calldata signature
    ) external payable {
        require(block.number < expiryBlock, "Expired bundle.");
        require(hashBulkFeed(tokenIds, amounts, msg.value, expiryBlock) == messageHash, "Invalid message hash.");
        require(verifyAddressSigner(messageHash, signature), "Invalid signature.");
        bytes memory encodedIDs = abi.encode(tokenIds);
        bytes memory encodedAmounts = abi.encode(amounts);
        emit Feed(encodedIDs, encodedAmounts);
    }

    /// @notice Verifies the signature of the messageHash matches the signer address
    /// @param messageHash The hash of the feed function data
    /// @param signature The signature of the messageHash
    /// @return bool True if the signature is valid
    function verifyAddressSigner(
        bytes32 messageHash,
        bytes calldata signature
    ) private view returns (bool) {
        address recovery = messageHash.toEthSignedMessageHash().recover(signature);
        return signer == recovery;
    }

    /// @notice Hashes the feed funtction data.
    /// @param tokenIds The tokenIds of the gobblers to feed
    /// @param amounts The amounts to feed each gobbler
    /// @param etherSent The amount of ether sent with the feed
    /// @param expiryBlock The block number after which the feed is no longer valid
    function hashBulkFeed(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint etherSent,
        uint expiryBlock
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenIds, amounts, etherSent, expiryBlock));
    }

    /// @notice Owner function to set the signer address
    /// @param _signer The address of the signer
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /// @notice Owner function to withdraw ether from the contract to the owners address
    function withdrawEther() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
