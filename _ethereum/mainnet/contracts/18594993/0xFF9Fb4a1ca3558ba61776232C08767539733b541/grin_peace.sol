// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./ERC721Psi.sol";

contract grinpeace is ERC721Psi, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply = 2000;

    uint256 public al1Price = 0.007 ether;
    uint256 public al2Price = 0.008 ether;
    uint256 public publicPrice = 0.009 ether;
    uint256 public piePrice = 0.009 ether;

    bool public freeSaleStart = true;
    bool public al1SaleStart = true;
    bool public al2SaleStart = true;
    bool public pubSaleStart = true;
    bool public pieSaleStart = false;

    uint256 public al1MintLimit = 4;
    uint256 public al2MintLimit = 8;
    uint256 public publicMintLimit = 99;

    mapping(address => uint256) public freeClaimed;
    mapping(address => uint256) public al1Claimed;
    mapping(address => uint256) public al2Claimed;
    mapping(address => uint256) public publicClaimed;

    bytes32 public merkleRoot0 = 0x425590944b09b5c1744672da1d51519233ad8a3ac8e22ab59c3dc57d21d436d6;
    bytes32 public merkleRoot1 = 0x52abd3d3bc73f205ada4beeac1857e65c66ec772860ca47ee4a1441aa4bce177;
    bytes32 public merkleRoot2 = 0x82d3c2a681a6b15d7636e07d7d9c1932fc96ff2e4efc22ba470fd7cbba4dca27;
    
    bool public revealed = false;
    string private _hiddenURI = "https://arweave.net/wiRPTTBykF-1QFh0nxNskEA_ogzwJg3SDYbE_VHk1OM/hidden.json";
    string private _baseTokenURI;

    constructor() ERC721Psi("grin peace", "GP") {
        _safeMint(0xE962587325D6F8f682F93B335483789362917DCe, 1);
        _safeMint(0xBAa98fe972144EF1DE53b801045CEc5A291cB30E, 1);
        _safeMint(0xAD863559C9437205D6c8c68FF5f009A7767001ee, 1);
        _safeMint(0x5c0455464a07F7c715e0b4428EdfCa51DEF5594E, 1);

        _setDefaultRoyalty(address(0xc29b7EB1C7CBc39A06b7f42E9193683375960802), 1000);
    }

    // URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721Psi) returns (string memory) {
        if (revealed) {
            return
                string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
        } else {
            return _hiddenURI;
        }
    }

    // freeMint
    function freeMintCount(address _address, uint256 _count, bytes32[] memory _proof) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_address, _count));
        for (uint256 i = 0; i < _proof.length; i++) {
            _leaf = _leaf < _proof[i] ? keccak256(abi.encodePacked(_leaf, _proof[i])) : keccak256(abi.encodePacked(_proof[i], _leaf));
        }
        return _leaf == merkleRoot0;
    }

    function freeMint(uint256 _amount, uint256 _count, bytes32[] memory _proof) external virtual nonReentrant {
        require(freeSaleStart, "Free Mint is Paused");
        require(freeMintCount(msg.sender, _count, _proof), "Invalid count");
        require(_count > 0, "You have no FreeMint");
        require(_count >= _amount, "Over max FreeMint per wallet");
        require(_count >= freeClaimed[msg.sender] + _amount, "You have no FreeMint left");
        require((_amount + totalSupply()) <= (maxSupply), "No more NFTs");

        freeClaimed[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    // preMintAL1
    function checkMerkleProof1(bytes32[] calldata _merkleProof1) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof1, merkleRoot1, leaf);
    }

    function preMint1(uint256 _quantity, bytes32[] calldata _merkleProof1) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = al1Price * _quantity;
        require(al1SaleStart, "Before sale begin.");
        require(supply + _quantity <= maxSupply, "Max supply over");
        require(al1Claimed[msg.sender] + _quantity <= al1MintLimit,"Already claimed max");
        require(msg.value >= cost, "Not enough funds");
        require(checkMerkleProof1(_merkleProof1), "Invalid Merkle Proof");
        al1Claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // preMintAL2
    function checkMerkleProof2(bytes32[] calldata _merkleProof2) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof2, merkleRoot2, leaf);
    }

    function preMint2(uint256 _quantity, bytes32[] calldata _merkleProof2) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = al2Price * _quantity;
        require(al2SaleStart, "Before sale begin.");
        require(supply + _quantity <= maxSupply, "Max supply over");
        require(al2Claimed[msg.sender] + _quantity <= al2MintLimit,"Already claimed max");
        require(msg.value >= cost, "Not enough funds");
        require(checkMerkleProof2(_merkleProof2), "Invalid Merkle Proof");
        al2Claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // publicMint
    function publicMint(uint256 _quantity) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = publicPrice * _quantity;
        require(pubSaleStart, "Before sale begin.");
        require(supply + _quantity <= maxSupply, "Max supply over");
        require(msg.value >= cost, "Not enough funds");
        require(publicClaimed[msg.sender] + _quantity <= publicMintLimit,"Already claimed max");
        publicClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // piementMint
    function piementMint(address _receiver, uint256 _quantity) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = piePrice * _quantity;
        require(pieSaleStart, "Before sale begin.");
        require(supply + _quantity <= maxSupply, "Max supply over");
        require(msg.value >= cost, "Not enough funds");
        require(publicClaimed[_receiver] + _quantity <= publicMintLimit, "Already claimed max");
        publicClaimed[_receiver] += _quantity;
        _safeMint(_receiver, _quantity);
    }

    // ownerMint
    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _quantity <= maxSupply, "Max supply over");
        _safeMint(_address, _quantity);
    }

    // setURI
    function setBaseURI(string calldata _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setHiddenBaseURI(string memory uri_) public onlyOwner {
        _hiddenURI = uri_;
    }

    // reveal
    function reveal(bool bool_) public onlyOwner {
        revealed = bool_;
    }

    // setMerkleRoot
    function setFreeMintMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot0 = _merkleRoot;
    }

    function setAL1MerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot1 = _merkleRoot;
    }

    function setAL2MerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot2 = _merkleRoot;
    }

    // setSaleStart
    function setFreeSaleStart(bool _state) public onlyOwner {
        freeSaleStart = _state;
    }

    function setAL1SaleStart(bool _state) public onlyOwner {
        al1SaleStart = _state;
    }

    function setAL2SaleStart(bool _state) public onlyOwner {
        al2SaleStart = _state;
    }

    function setPubSaleStart(bool _state) public onlyOwner {
        pubSaleStart = _state;
    }

    function setPiementSaleStart(bool _state) public onlyOwner {
        pieSaleStart = _state;
    }

    // setLimit
    function setAl1MintLimit(uint256 _quantity) public onlyOwner {
        al1MintLimit = _quantity;
    }

    function setAl2MintLimit(uint256 _quantity) public onlyOwner {
        al2MintLimit = _quantity;
    }

    function setPublicMintLimit(uint256 _quantity) public onlyOwner {
        publicMintLimit = _quantity;
    }

    // setMaxSupply
    function setMaxSupply(uint256 _quantity) public onlyOwner {
        require(totalSupply() <= maxSupply, "Lower than _currentIndex.");
        maxSupply = _quantity;
    }

    // setPrice
    function setAl1Price(uint256 _price) public onlyOwner {
        al1Price = _price;
    }

    function setAl2Price(uint256 _price) public onlyOwner {
        al2Price = _price;
    }

    function setPublicPrice(uint256 _price) public onlyOwner {
        publicPrice = _price;
    }

    function setPiePrice(uint256 _price) public onlyOwner {
        piePrice = _price;
    }

    // royality
    function setRoyalty(address _royaltyAddress, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721Psi, ERC2981) returns (bool) {
        return
            ERC721Psi.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(0xE962587325D6F8f682F93B335483789362917DCe), ((balance * 250000) / 1000000));
        Address.sendValue(payable(0x5c0455464a07F7c715e0b4428EdfCa51DEF5594E), ((balance * 250000) / 1000000));
        Address.sendValue(payable(0xAD863559C9437205D6c8c68FF5f009A7767001ee), ((balance * 250000) / 1000000));
        Address.sendValue(payable(0xBAa98fe972144EF1DE53b801045CEc5A291cB30E), ((balance * 250000) / 1000000));
    }
}
// Code by lettuce908