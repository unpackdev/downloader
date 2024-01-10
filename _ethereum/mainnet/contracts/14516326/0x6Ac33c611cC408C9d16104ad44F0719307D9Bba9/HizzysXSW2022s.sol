// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract HizzysXSW2022s is Ownable, PaymentSplitter, ERC721A {

    uint public transactionLimit = 5;
    uint public mintLimit = 267;
    uint public collectionLimit = 332;
    uint public price = 0.314 ether;
    bool public saleIsActive = false;
    bool public collectionFrozen = false;
    string public contractURI;
    string public baseURI;
    string public constant baseExtension = ".json";
    address[] private _addressList = [
        0x10e1885E07e51B8eED720f874a4Ca947FaDe0E5A, // dev
        0x821A51cD60d4dBaE3Ae1cc911160A690C14a65eb // hizzy
    ];
    uint[] private _shareList = [
        75,
        925
    ];

    constructor() 
        ERC721A("HizzysXSW2022s", "HIZZY")
        PaymentSplitter(_addressList, _shareList) { }

    function mint(uint256 quantity) external payable {
        require(saleIsActive, "Sale is not active yet");
        require(price * quantity <= msg.value, "Not enought ether");
        require(quantity <= transactionLimit, "Over transaction limit");
        require(totalSupply() + quantity <= mintLimit, "Exceeds available supply");
        require(totalSupply() + quantity <= collectionLimit, "Exceeds available supply");
        require(!collectionFrozen, "Collection is frozen");
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity, address addr) external onlyOwner {
        require(totalSupply() + quantity <= collectionLimit, "Exceeds available supply");
        require(!collectionFrozen, "Collection is frozen");
        _safeMint(addr, quantity);
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function freezeCollection() external onlyOwner {
        collectionFrozen = true;
        collectionLimit = totalSupply();
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint price_) external onlyOwner {
        price = price_;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }
}