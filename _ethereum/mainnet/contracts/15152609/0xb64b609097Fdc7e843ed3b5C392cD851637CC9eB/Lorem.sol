// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";

contract ERC721NFT is ERC721AQueryable, Ownable {
    uint256 public tokenPrice;
    uint256 public maxcollectionSize = 10000;
    uint8 public maxPerAddress = 1;
    uint256 public quantityForMint = 9900;
    uint8 public salesStage = 0;

    mapping(address => uint256) public alMinted;
    mapping(address => uint256) public publicMinted;
    mapping(uint256 => mapping(address => uint256)) public authorizedMinteds;

    string public _baseTokenURI;
    address public _adminSigner;

    constructor() ERC721A("ERC721NFT", "ERC721NFT") {}

    function publicMint(uint256 quantity) public payable callerIsUser {
        require(salesStage == 9, "Mint not active");
        require(publicMinted[msg.sender] + quantity <= maxPerAddress, "Wallet Max Reached");
        require(totalSupply() + quantity <= quantityForMint, "Minted Out");
        require(tokenPrice * quantity <= msg.value, "Insufficient Eth");

        _minttokens(msg.sender, quantity);
        publicMinted[msg.sender] += quantity;
    }

    function _minttokens(address _to, uint256 _quantity) internal {
        _safeMint(_to, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setQuantityForMint(uint256 newquantityForMint) public onlyOwner {
        require(newquantityForMint <= maxcollectionSize, "Exceed");
        quantityForMint = newquantityForMint;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    function setMaxPerAddress(uint8 newmaxPerAddress) public onlyOwner {
        maxPerAddress = newmaxPerAddress;
    }

    function setSigner(address newSigner) external onlyOwner {
        _adminSigner = newSigner;
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;
    }

    function setSalesStage(uint8 newSalesStage) public onlyOwner {
        salesStage = newSalesStage;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}
