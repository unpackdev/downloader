// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

/*
Twitter: https://twitter.com/ClumsyPeteNFT
Website: https://clumsypetenft.com
*/


contract ClumsyPete is ERC721A, Ownable {
    uint256 public constant cost = 0.066 ether;
    uint256 public constant availableNFTs = 600;
    uint256 public constant maxTokens = 2;
    uint256 public constant startTokenId = 1;

    bytes32 private _merkleRoot;
    string private _baseUri;

    /// @dev Inactive = 0; Sale = 1;
    uint256 private _saleFlag = 1;
    bool private _metadataLocked = false;

    mapping(address => uint256) private _amountMintedPerUser;
    mapping(address => bool) private _freeMintAddr;

    constructor(
        string memory base,
        bytes32 merkleRoot,
        address[] memory freeMinterAddresses
    ) ERC721A("Clumsy Pete", "CLUMSY") {
        _baseUri = base;
        _merkleRoot = merkleRoot;
        for (uint i = 0; i < freeMinterAddresses.length; i++) {
            _freeMintAddr[freeMinterAddresses[i]] = true;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return startTokenId;
    }

    function setFreeMinter(address minter) public onlyOwner {
        _freeMintAddr[minter] = true;
    }

    function isFreeMinter(address minter) public view returns (bool) {
        return _freeMintAddr[minter] == true;
    }

    function getCurrentIndex() external view returns (uint256) {
        return _currentIndex;
    }

    function remainingTokens() public view returns (uint256) {
        return availableNFTs + startTokenId - _currentIndex;
    }

    function lockMetadata() external onlyOwner {
        _metadataLocked = true;
    }

    function setFlag(uint256 newFlag) external onlyOwner onlyUnlocked {
        _saleFlag = newFlag;
    }

    function setMerkleRoot(bytes32 newRoot) external onlyOwner onlyUnlocked {
        _merkleRoot = newRoot;
    }

    function setBaseURI(string memory base) external onlyOwner onlyUnlocked {
        _baseUri = base;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    modifier onlyUnlocked() {
        require(!_metadataLocked, "METADATA_LOCKED");
        _;
    }

    modifier onlyWhitelist(bytes32[] calldata merkleProof) {
        require(MerkleProof.verify(
            merkleProof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "INVALID_MERKLE_PROOF");
        _;
    }

    function mintWhitelist(bytes32[] calldata merkleProof, uint256 quantity) external payable onlyWhitelist(merkleProof) {
        require(_saleFlag == 1, "MINTING_PAUSED");
        uint256 supply = this.totalSupply();
        require(supply + quantity <= availableNFTs, "EXCEEDS_TOTAL_SUPPLY");
        if (_freeMintAddr[msg.sender] == true) {
            require(msg.value == 0, "INVALID_FREE_MINT_VALUE");
        } else {
            require(msg.value == cost * quantity, "INVALID_VALUE");
        }
        require(quantity <= maxTokens, "QUANTITY_TOO_HIGH");
        require(_amountMintedPerUser[msg.sender] + quantity <= maxTokens, "EXCEEDS_MINT_LIMIT");

        _safeMint(msg.sender, quantity);
        _amountMintedPerUser[msg.sender] += quantity;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}