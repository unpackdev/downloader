/**
*
*                   ▄▄▄▄    ▒█████   ▄▄▄       ██▀███  
*                   ▓█████▄ ▒██▒  ██▒▒████▄    ▓██ ▒ ██▒
*                   ▒██▒ ▄██▒██░  ██▒▒██  ▀█▄  ▓██ ░▄█ ▒
*                   ▒██░█▀  ▒██   ██░░██▄▄▄▄██ ▒██▀▀█▄  
*                   ░▓█  ▀█▓░ ████▓▒░ ▓█   ▓██▒░██▓ ▒██▒
*                   ░▒▓███▀▒░ ▒░▒░▒░  ▒▒   ▓▒█░░ ▒▓ ░▒▓░
*                   ▒░▒   ░   ░ ▒ ▒░   ▒   ▒▒ ░  ░▒ ░ ▒░
*                   ░    ░ ░ ░ ░ ▒    ░   ▒     ░░   ░ 
*                   ░          ░ ░        ░  ░   ░     
*                       ░      
*                              boarjetclub.com
*
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract BoarJetClub is ERC721A, Ownable {

    using Strings for uint256;
    uint public maxMint;
    uint public porfit;
    uint public maxTotal;
    uint public price;
    uint public mintTime;
    bool public preMintOpen;
    bool public publicMintOpen;
    uint256 public immutable amountForDevs;
    address public withdrawAddress;
    string private _baseTokenURI;
    bytes32 public merkleRoot;
    
    constructor(
        string memory name, 
        string memory symbol, 
        uint _maxMint,
        uint _maxTotal, 
        uint _price, 
        uint _amountForDevs,
        string memory baseTokenURI_
    ) ERC721A(name, symbol, _maxMint, _maxTotal) {
        maxMint = _maxMint;
        maxTotal = _maxTotal;
        price = _price;
        amountForDevs = _amountForDevs;
        _baseTokenURI = baseTokenURI_;
        withdrawAddress = msg.sender;
    }

    function preMint(uint256 num, bytes32[] calldata proof_) public payable {
        require(verify(proof_), "Address is not on the whitelist");
        require(preMintOpen, "No mint time");
        require(num <= maxMint, "You can adopt a maximum of MAX_MINT");
        require(totalSupply() + num <= maxTotal, "Exceeds maximum supply");
        require(msg.value >= price * num, "Ether sent is not correct");
        require(block.timestamp >= mintTime, "No mint time");

        _safeMint(msg.sender, num);
    }

    function publicMint(uint256 num) public payable {
        require(publicMintOpen, "No mint time");
        require(num <= maxMint, "You can adopt a maximum of MAX_MINT");
        require(totalSupply() + num <= maxTotal, "Exceeds maximum supply");
        require(msg.value >= price * num, "Ether sent is not correct");
        require(block.timestamp >= mintTime, "No mint time");

        _safeMint(msg.sender, num);
    }

    function getAirDrop(uint16 _num, address recipient) public onlyOwner {
        require(totalSupply() + _num <= maxTotal,"Exceeds maximum supply");
        _safeMint(recipient, _num);
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setPreMintOpen() public onlyOwner {
        preMintOpen = !preMintOpen;
    }

    function setPublicMintOpen() public onlyOwner {
        publicMintOpen = !publicMintOpen;
    }

    function setMintTime(uint256 _mintTime) public onlyOwner {
        mintTime = _mintTime;
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawMoney() external onlyOwner {
        require(payable(withdrawAddress).send(address(this).balance),"Transfer failed.");
    }

    function verify(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function walletOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function getOwnershipData(uint256 tokenId)
      external
      view
      returns (TokenOwnership memory)
    {
      return ownershipOf(tokenId);
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= amountForDevs,
            "Too many already minted before dev mint");
        require(quantity % maxBatchSize == 0,
            "Can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }
}