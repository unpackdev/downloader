// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./IERC721.sol";
import "./IMerkleMinter.sol";
import "./BalanceController.sol";

/**
 * @dev Allows a whitelist of accounts to mint a token for a particular price.
 * The whitelist is formed into a Merkle tree and claims require a valid
 * inclusion proof in order to mint the related token.
 */
contract MerkleMinter is IMerkleMinter, BalanceController {
    /**
     * @dev The address of the token claimants will mint.
     **/
    address public immutable override mintableToken;

    /**
     * @dev The address of the token claimants will pay with.
     **/
    address public immutable override paymentToken;

    /**
     * @dev The number of claims in the tree.
    **/
    uint32 public immutable numClaims;

    /**
     * @dev The root of the tree of claims.
    **/
    bytes32 public immutable override merkleRoot;

    /**
     * @dev A packed array of booleans that tracks which leaves of the tree are
     * claimed.
     */
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address MintingToken_, address PaymentToken_, uint32 numClaims_, bytes32 merkleRoot_) {
        mintableToken = MintingToken_;
        paymentToken = PaymentToken_;
        numClaims = numClaims_;
        merkleRoot = merkleRoot_;
    }

    /**
     * @dev Returns whether the leaf with the given index has been claimed.
    **/
    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @dev Returns an array of booleans indicated if each index is claimed.
     */
    function claimedList() public view override returns (bool[] memory) {
        bool[] memory list = new bool[](numClaims);
        for (uint i = 0; i < numClaims; i++) {
            list[i] = isClaimed(i);
        }
        return list;
    }

    /**
     * @dev Marks the leaf with the given index as claimed in the packed array.
    **/
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
    /**
     * @dev Validates that the given information is a claim in the tree and then
     * issues the mint.
    **/
    function claim(uint256 index, address account, uint256 tokenId, uint256 price, bytes32[] calldata merkleProof) external override {
        // Check that this index is unclaimed
        require(!isClaimed(index), 'MerkleMinter: Token already claimed.');

        // Check that the merkle proof is valid
        require(MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(index, account, tokenId, price))),
            'MerkleMinter: Invalid proof.');

        // Perform the mint
        _mintClaim(index, account, tokenId, price);
    }

    /**
     * @dev Performs the payment transfer and the token mint. It marks the leaf
     * as claimed causing all future calls to `claim` for the same leaf to fail.
    **/
    function _mintClaim(uint256 index, address account, uint256 tokenId, uint256 price) internal {
        // Transfer the funds
        require(IERC20(paymentToken).transferFrom(account, address(this), price), 'MerkleMinter: Token transfer failed.');

        // Mark index as claimed
        _setClaimed(index);

        // Mint the token
        IERC721(mintableToken).mint(account, tokenId);

        // Send an event for logging
        emit Claimed(index, account, tokenId, price);
    }
}
