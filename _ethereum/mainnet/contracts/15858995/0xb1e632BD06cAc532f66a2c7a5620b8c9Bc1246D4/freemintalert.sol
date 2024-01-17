// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract freemintalert is ERC721A, Ownable {
    bytes32 private merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => uint256) public walletMintedCount;
    
    string public metadata = '';

    bool public publicEnabled = false;
    bool public whitelistEnabled = false;
    
    uint256 public whitelistCost = 0.01 ether;
    uint256 public publicCost = 0.02 ether;

    uint256 constant public maxMintPerWallet = 3;
    uint256 constant public supply = 1000;

    constructor() ERC721A("Free Mint Alert", "FMA") {}

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    function devMint(address _to, uint256 _mintAmount) external onlyOwner {
		require(_totalMinted() + _mintAmount <= supply, "Sold out!");
		_safeMint(_to, _mintAmount);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_totalMinted() + _mintAmount <= supply, "Sold out!");
        require(_mintAmount > 0 && _mintAmount <= maxMintPerWallet, 'Invalid mint amount!');
        require(walletMintedCount[msg.sender] + _mintAmount <= maxMintPerWallet, "You minted max!");
        _;
    }

    function publicMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {  
        require(publicEnabled, 'Public mint is not enabled!'); 
        require(msg.value >= (publicCost * _mintAmount), "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);
        walletMintedCount[msg.sender] += _mintAmount;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) {
        require(whitelistEnabled, 'Whitelist mint is not enabled!');
        require(isInWhitelist(msg.sender, _merkleProof), "You are not in whitelist");
        require(!whitelistClaimed[msg.sender], "You have already claimed whitelist!");
        require(msg.value >= (whitelistCost * _mintAmount), "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);
        whitelistClaimed[msg.sender] = true;
        walletMintedCount[msg.sender] += _mintAmount;
    }

    function setWhitelistCost(uint256 _cost) external onlyOwner {
        whitelistCost = _cost;
    }

    function setPublicCost(uint256 _cost) external onlyOwner {
        publicCost = _cost;
    }

    function isInWhitelist(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        return MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function mintedCount(address owner) external view returns (uint256) {
        return walletMintedCount[owner];
    }

    function isWhitelistClaimed(address owner) external view returns (bool) {
        return whitelistClaimed[owner];
    }

    function setPublicEnabled(bool _state) external onlyOwner {
        publicEnabled = _state;
    }

    function setWhitelistEnabled(bool _state) external onlyOwner {
        whitelistEnabled = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return metadata;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        metadata = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return metadata;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}