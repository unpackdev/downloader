// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";

contract RetroViz is ERC721, Ownable {
    bytes32 public immutable merkleRoot;

    constructor(bytes32 merkleRoot_, string memory baseURI_)
        ERC721("RetroViz", "RTV")
    {
        merkleRoot = merkleRoot_;
        customBaseURI = baseURI_;
    }

    /** ACTIVATING THE AIRDROP **/

    bool public isActive = false;

    function setIsActive(bool isActive_) public onlyOwner {
        isActive = isActive_;
    }

    /** CLAIMING **/

    // This is roughly adapted from (GPL-3.0) https://github.com/Uniswap/merkle-distributor

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(uint256[] calldata tokenIds, bytes32[] calldata merkleProof)
        public
    {
        require(
            isActive || msg.sender == owner(),
            "RetroViz: Drop not started"
        );

        // We use the first tokenId to check if the drop has been claimed.
        // We can do this since it's not possible to partially claim a drop.
        require(!isClaimed(tokenIds[0]), "RetroViz: Drop already claimed");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, tokenIds));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "RetroViz: Invalid proof"
        );

        _setClaimed(tokenIds[0]);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(msg.sender, tokenIds[i]);
        }
    }

    /** URI HANDLING **/

    string private customBaseURI;

    function setBaseURI(string memory baseURI) external onlyOwner {
        customBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }
}
