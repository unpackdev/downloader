// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Owned.sol";
import "./LinearVRGDA.sol";
import "./SafeTransferLib.sol";
import "./SignedWadMath.sol";

import "./Metadata.sol";

/// @title Purplecheck - Your JPEGs deserve to feel special.
/// @notice Mint an ERC721 token associated with an IPFS content ID.
/// Mint price is calculated by a linear VRGDA targeting 6.9 purplechecks
/// per day at a price of 0.00420 ETH.
/// @author horsefacts <horsefacts@terminally.online>
contract Purplecheck is ERC721, LinearVRGDA, Owned {
    /// @notice Total number of Purplecheck tokens.
    uint256 public totalSupply;

    /// @notice Mint start time. Used in VRGDA price calculations.
    uint256 public immutable startTime = block.timestamp;

    /// @notice tokenId => IPFS CIDv1
    mapping(uint256 => string) public cid;

    constructor(address owner)
        ERC721("Purplecheck", unicode"🟪️✅")
        // Target rate 6.9 per day @ 0.00420 ETH
        LinearVRGDA(0.0042e18, 0.31e18, 6.9e18)
        Owned(owner)
    {}

    /// @notice Get the contract URI for this contract, encoded as a data URI.
    /// @return Contract metadata URI.
    function contractURI() external pure returns (string memory) {
        return Metadata.contractURI();
    }

    /// @notice Get the metadata URI for the given token ID, encoded as a data URI.
    /// @param tokenId uint256 token ID.
    /// @return Metadata URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return Metadata.tokenURI(tokenId, imageURI(tokenId));
    }

    /// @notice Get the IPFS image URI for the given token ID.
    /// @param tokenId uint256 token ID.
    /// @return URI of given token ID.
    function imageURI(uint256 tokenId) public view returns (string memory) {
        return Metadata.toImageURI(cid[tokenId]);
    }

    /// @notice Current mint price of a Purplecheck token, based on block.timestamp.
    /// @return uint256 mint price in wei.
    function price() public view returns (uint256) {
        return getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), totalSupply);
    }

    /// @notice Mint a Purplecheck token.
    /// @param _cid IPFS CIDv1 of the associated image.
    /// @return tokenId uint256 token ID.
    function mint(string calldata _cid) external payable returns (uint256 tokenId) {
        unchecked {
            // Get current VRGDA price
            uint256 _price = price();

            // Revert if caller has underpaid
            require(msg.value >= _price, "UNDERPAID");

            // Increment total supply and store image CID
            cid[tokenId = ++totalSupply] = _cid;

            // Mint token to caller
            _mint(msg.sender, tokenId);

            // Refund excess payment to caller
            if (msg.value != _price) SafeTransferLib.safeTransferETH(msg.sender, msg.value - _price);
        }
    }

    /// @notice Burn a Purplecheck token. Must be owner or approved.
    /// @param tokenId uint256 token ID.
    function burn(uint256 tokenId) external {
        address owner = _ownerOf[tokenId];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender] || msg.sender == getApproved[tokenId],
            "NOT_AUTHORIZED"
        );
        _burn(tokenId);
    }

    /// @notice Revert on attempted transfer.
    function transferFrom(address, address, uint256) public pure override {
        revert("TRANSFERS_DISABLED");
    }

    /// @notice Withdraw full balance to given recipient address.
    function withdrawBalance(address to) external onlyOwner {
        SafeTransferLib.safeTransferETH(to, address(this).balance);
    }
}
