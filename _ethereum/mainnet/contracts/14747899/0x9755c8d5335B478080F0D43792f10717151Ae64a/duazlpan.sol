// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

/* 

    ██████╗ ██╗   ██╗ █████╗ ███████╗██╗     ██████╗  █████╗ ███╗   ██╗
    ██╔══██╗██║   ██║██╔══██╗╚══███╔╝██║     ██╔══██╗██╔══██╗████╗  ██║
    ██║  ██║██║   ██║███████║  ███╔╝ ██║     ██████╔╝███████║██╔██╗ ██║
    ██║  ██║██║   ██║██╔══██║ ███╔╝  ██║     ██╔═══╝ ██╔══██║██║╚██╗██║
    ██████╔╝╚██████╔╝██║  ██║███████╗███████╗██║     ██║  ██║██║ ╚████║
    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝

*/

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

/**
 * @title Duazlpan contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract DUAZLPAN is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    // Constant variables
    string public uriPrefix = '';
    string public uriSuffix = '.json';
    string public hiddenMetadataUri;
  
    uint256 constant public whiteListPrice = 0.068 ether;
    uint256 constant public publicPrice = 0.088 ether;
    uint256 constant public maxSupply = 2048;
    uint256 constant public maxWhitelistMint = 3;
    uint256 constant public maxPublicMint = 5;

    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;

    bool public publicMintEnabled = false;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;
 
    // Merkle Root Hash
    bytes32 public merkleRoot;

    // check if publict was turned on
    bool public hasContractChanged = false;
    bool public finishedWhitelistEnabled = false;

    event IsContractChanged(bool _ischanged);

    constructor() ERC721A("DUAZLPAN", "DPN") {
        setHiddenMetadataUri("ipfs://QmcfGhS9uSBdoC3tUCdXc4w9h3DjdWwd8LbjtfsTfzHH5M/hidden.json");
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    modifier mintWhiteListPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= whiteListPrice * _mintAmount, "Insufficient funds");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= publicPrice * _mintAmount, "Insufficient funds");
        _;
    }

    modifier onlyWhitelistSale() {
        require(whitelistMintEnabled, "Whitelist sale is not active");
        _;
    }

    modifier onlyPublicSale() {
        require(publicMintEnabled, "Public sale is not active");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable 
        mintCompliance(_mintAmount) 
        mintWhiteListPriceCompliance(_mintAmount)
        onlyWhitelistSale {

        require(_mintAmount > 0 && whitelistMinted[_msgSender()] + _mintAmount <= maxWhitelistMint, 'Amount Limit');

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Not Whitelist');

        _safeMint(_msgSender(), _mintAmount);
        whitelistMinted[_msgSender()] += _mintAmount;
    }

    function mint(uint256 _mintAmount) public payable 
        mintCompliance(_mintAmount) 
        mintPriceCompliance(_mintAmount) 
        onlyPublicSale {

        require(_mintAmount > 0 && publicMinted[_msgSender()] + _mintAmount <= maxPublicMint, 'Amount Limit');
   
        _safeMint(_msgSender(), _mintAmount);
        publicMinted[_msgSender()] += _mintAmount;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // only owner
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPublicMintEnabled(bool _state) public onlyOwner {
        if(publicMintEnabled == true && _state == false) {
            hasContractChanged = true;
        }
        publicMintEnabled = _state;
        emit IsContractChanged(true);
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        if(whitelistMintEnabled == true && _state == false) {
            finishedWhitelistEnabled = true;
        }
        
        whitelistMintEnabled = _state;
        emit IsContractChanged(true);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}