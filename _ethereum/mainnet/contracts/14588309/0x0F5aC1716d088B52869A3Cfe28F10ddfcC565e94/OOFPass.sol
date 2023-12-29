// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract OOFCollective is ERC721A, Ownable {
    uint256 MAX_MINTS = 2;
    uint256 MAX_SUPPLY = 1000;
    uint256 public MINT_PRICE = 0.0169 ether;
    
    bool public whitelist = true;
    bool public saleIsActive = false;

    mapping(address => uint8) private _freeAllowList;
    mapping(address => uint8) private _mintAllowList;

    mapping(address => uint) public addressMintedBalance;

    string public baseURI = "https://oofcollective.xyz/assets/oof/metadata/";

    constructor() ERC721A("OOF Collective", "OOF") {}

    function mintPass(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(!whitelist || quantity <= _mintAllowList[msg.sender], "Exceeded max available to purchase");
        require(saleIsActive, "Sale must be active to mint");
        require(quantity > 0 && quantity <= MAX_MINTS, "Max per transaction reached");

        require(addressMintedBalance[msg.sender] + quantity <= MAX_MINTS, "Max mint limit reached");

        require(msg.value >= MINT_PRICE * quantity, "Not enough ETH for transaction");

        addressMintedBalance[msg.sender] += quantity; //tracking minted 
        _mintAllowList[msg.sender] += quantity; //tracking minted
        _safeMint(msg.sender, quantity);
    }

    function mintFree(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(quantity <= _freeAllowList[msg.sender], "Exceeded max available to purchase");
        require(saleIsActive, "Sale must be active to mint");
        require(quantity > 0 && quantity <= MAX_MINTS, "Max per transaction reached");

        require(addressMintedBalance[msg.sender] + quantity <= MAX_MINTS, "Max mint limit reached");

        addressMintedBalance[msg.sender] += quantity; //tracking minted 
        _freeAllowList[msg.sender] += quantity; //tracking minted
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address[] calldata addresses, uint256 quantity) external onlyOwner
    {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantity, "");
        }
    }

    function setFreeAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freeAllowList[addresses[i]] = numAllowedToMint;
        }
    }

    function setMintAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _mintAllowList[addresses[i]] = numAllowedToMint;
        }
    }

    function setPassPrice(uint256 price) external onlyOwner 
    {
        MINT_PRICE = price;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistingState() external onlyOwner
    {
        whitelist = !whitelist;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}