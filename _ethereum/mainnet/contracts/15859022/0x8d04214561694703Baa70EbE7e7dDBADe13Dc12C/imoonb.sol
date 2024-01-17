// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract imoonb is ERC721A, Ownable {
    bytes32 private merkleRoot;
    mapping(address => uint256) public walletMintedCount;
    string public baseURI = '';
    bool public mintEnabled = false;
    uint256 constant public price = 0.004 ether;
    uint256 constant public maxMintPerWallet = 10;
    uint256 constant public supply = 4444;
    uint256 constant public whitelistFreePerWallet = 1;

    constructor() ERC721A("Invert Moonbirds", "imoonb") {}

    function devMint(address _to, uint256 _mintAmount) external onlyOwner {
		require(_totalMinted() + _mintAmount <= supply, "Sold out!");
		_safeMint(_to, _mintAmount);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(mintEnabled, 'Mint is not enabled!'); 
        require(_totalMinted() + _mintAmount <= supply, "Sold out!");
        require(walletMintedCount[msg.sender] + _mintAmount <= maxMintPerWallet, "You minted max!");
        _;
    }

    function publicMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {  
        require(msg.value >= (price * _mintAmount), "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);
        walletMintedCount[msg.sender] += _mintAmount;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) {
        require(walletWhitelist(msg.sender, _merkleProof), "You are not in whitelist");
        require(walletMintedCount[msg.sender] < 1, "Use public!");
        uint256 payForCount = _mintAmount;
        if(_mintAmount > whitelistFreePerWallet) {
            payForCount = _mintAmount - whitelistFreePerWallet;
        }
        else {
            payForCount = 0;
        }
        require(msg.value >= (price * payForCount), "Insufficient funds!");
        _safeMint(_msgSender(), _mintAmount);
        walletMintedCount[msg.sender] += _mintAmount;
  }

    function walletWhitelist(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        return MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function mintedCount(address owner) external view returns (uint256) {
        return walletMintedCount[owner];
    }

    function setMintEnabled(bool _state) external onlyOwner {
        mintEnabled = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}