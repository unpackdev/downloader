// contracts/QFZ.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract QatarFootballZoo is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // bool
    bool public _isMintingLive = false;
    bool public _isAllowlistRequired = true;

    // addresses
    address _owner;

    // integers
    uint256 public totalPublicSupply;
    uint256 public totalGiftSupply;

    uint256 public MAX_GIFT_SUPPLY = 16;
    uint256 public MAX_PUBLIC_SUPPLY = 816;

    // bytes
    bytes32 merkleRoot;

    string private _tokenBaseURI = "ipfs://bafybeid3xwwdjg4vj3r5t6d4bvce75djgklekozkmrn7cmgbhljiwoq2tm/metadata/";

    constructor(bytes32 _merkleRoot) ERC721A("QatarFootballZoo", "QFZ") {
        _owner = msg.sender;
        merkleRoot = _merkleRoot;
    }

    function setMintingLive() external onlyOwner {
        _isMintingLive = !_isMintingLive;
    }

    function setAllowlistRequired() external onlyOwner {
        _isAllowlistRequired = !_isAllowlistRequired;
    }

    function setBaseUri(string memory tokenBaseUri) external onlyOwner {
        _tokenBaseURI = tokenBaseUri;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    /*
    MINTING FUNCTIONS
    */

    /**
     * @dev Public mint function
     */
    function mint(uint256 amount, bytes32[] calldata proof) nonReentrant payable external {
        require(msg.sender == tx.origin);
        require(_isMintingLive, "Minting is not live");
        require(
            totalPublicSupply + amount <= MAX_PUBLIC_SUPPLY,
            "Tokens have all been minted"
        );

        uint256 numAccountMinted = _numberMinted(msg.sender);
        require(numAccountMinted < 2, "This address already minted");
        require(
            (numAccountMinted == 0 && amount == 1) ||
            (numAccountMinted == 0 && amount == 2 && msg.value >= .03 ether) ||
            (numAccountMinted == 1 && amount == 1 && msg.value >= .03 ether)            
            , "Donation amount is insufficient"
        );
        
        // check allowlists
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(!_isAllowlistRequired || _isAllowlistRequired && MerkleProof.verify(proof, merkleRoot, leaf), "Proof is invalid");

        totalPublicSupply += amount;
        _safeMint(msg.sender, amount);
    }

    /**
     * @dev Mint gift tokens for the contract owner
     */
    function mintGifts(uint256 _times) external onlyOwner {
        require(
            totalGiftSupply + _times <= MAX_GIFT_SUPPLY,
            "Must mint fewer than the maximum number of gifted tokens"
        );

        for(uint256 i=0; i<_times; i++) {
            totalGiftSupply += 1;
            _safeMint(msg.sender, 1);
        }
    }

    // Read functions
    function numMinted(address _address) public view returns (uint256) {
        return _numberMinted(_address);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json"));
    }

    function addressIsAllowed(address _address, bytes32[] calldata proof) public view returns (bool isAllowlisted) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        isAllowlisted = MerkleProof.verify(proof, merkleRoot, leaf);
        return isAllowlisted;
    }

    /**
     * @dev Withdraw ETH to owner
     */
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
}