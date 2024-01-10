// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";

import "./ERC721A.sol";

contract MetaPunksClub is ERC721A, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32;
    using SafeMath for uint256;
    using Strings for uint256;

    string private _uri; 
    bool private _reveal;  
    uint256 public isActive;
    uint256 public MAX_MINT;
    uint256 public immutable MAX_NFT;
    uint256 public publicPrice;
    uint256 public whiteListPrice;
    uint256 public allowListPrice;
    bytes32 public root;

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory initURI
    ) ERC721A(_name, _symbol, 100) {
        _uri = initURI;
        isActive = 6;
        MAX_MINT = 20;
        MAX_NFT = 10001;
        publicPrice = 200000000000000000;
        whiteListPrice = 80000000000000000;
        allowListPrice = 250000000000000000;
    }

    function _baseURI() internal view  override(ERC721A) returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) public virtual onlyOwner{
        _uri = newuri;
    }

    function setIsActive(uint256 _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setMaxMint(uint256 _max_mint) external onlyOwner {
        MAX_MINT = _max_mint;
    }

    function setPrice(
        uint256 _publicPrice, 
        uint256 _whiteListPrice, 
        uint256 _allowListPrice
    ) external onlyOwner {
        publicPrice = _publicPrice;
        whiteListPrice = _whiteListPrice;
        allowListPrice = _allowListPrice;
    }

    function revealNow(bool _isreveal) external onlyOwner {
        _reveal = _isreveal;
    }

    // Set MerkleProof root for whitelist verify
    function setRoot(uint256 _root) public onlyOwner {
        root = bytes32(_root);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function mintTo(uint256 _quantity, address _to) public onlyOwner {
        require(totalSupply().add(_quantity) <= MAX_NFT, "MSG10001");
        _safeMint(_to, _quantity);
    }  

    function publicMint(uint256 _quantity) public payable {
        require(isActive == 9, 'MSG09');
        require(totalSupply().add(_quantity) <= MAX_NFT, "MSG10001");
        require(msg.value >= publicPrice.mul(_quantity), "MSG666");

        _safeMint(msg.sender, _quantity);
    }

    function allowListMint(uint256 _quantity) public payable {
        require(isActive == 7, 'MSG07');
        require(totalSupply().add(_quantity) <= MAX_NFT, "MSG10001");
        require(numberMinted(msg.sender).add(_quantity) <= MAX_MINT, 'MSG20');
        require(msg.value >= allowListPrice.mul(_quantity), "MSG666");

        _safeMint(msg.sender, _quantity);
    }

    function whiteListMint(uint256 _quantity, bytes32[] memory _proof) public payable {
        require(isActive < 9, 'MSG06');
        require(MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(msg.sender))) || !_reveal, "MSG008");
        require(totalSupply().add(_quantity) <= MAX_NFT, "MSG10001");
        require(numberMinted(msg.sender).add(_quantity) <= MAX_MINT, 'MSG20');
        require(msg.value >= whiteListPrice.mul(_quantity), "MSG666");

        _safeMint(msg.sender, _quantity);
    }

    function release() public virtual nonReentrant onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "MSG000");
        payable(address(0xc06d42a5B78aE6DdA23ba710D7FC538537e8322A)).transfer(amount);
    }
}