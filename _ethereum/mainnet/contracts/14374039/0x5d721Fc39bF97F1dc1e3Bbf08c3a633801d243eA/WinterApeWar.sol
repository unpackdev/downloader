// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC721A.sol";

pragma solidity ^0.8.4;
contract WinterApeWar is ERC721A, Ownable{
  // Token mint values
    uint256 public constant MAX_SUPPLY = 6970;
    uint256 public nextTokenIndex  = 1;

  //public sale
    uint256 public constant PUBLIC_SALE_MAX_PER_TRANSACTION = 21;
    uint256 public publicPrice = 0.042 ether;

  //Presale
    uint256 public constant PRE_SALE_MAX_PER_TRANSACTION = 11;
    uint256 public presalePrice = 0 ether;
  
    string public baseTokenURI;

  //sale state status
    enum EPublicMintStatus {
        CLOSED,
        PRIVATE_MINT,
        OPEN
    }

    EPublicMintStatus public publicMintStatus;

    constructor() ERC721A("WinterApeWar", "WINTER"){
    }

      modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        uint256 _nextTokenIndex = nextTokenIndex;
        
        require(publicMintStatus == EPublicMintStatus.OPEN, 'Sale is not live.');
        require((_nextTokenIndex + quantity) < MAX_SUPPLY, 'Exceeds available supply');

        if (_nextTokenIndex < 1301){
            require(quantity < PRE_SALE_MAX_PER_TRANSACTION, 'Can only mint max of 5 per transaction');
            require(msg.value == (presalePrice * quantity), 'Not enough ETH to cover costs.');
        }
        else{
            require(quantity < PUBLIC_SALE_MAX_PER_TRANSACTION, 'Can only mint max of 20 per transaction');
            require(msg.value == (publicPrice * quantity), 'Not enough ETH to cover costs.');

        }

        _nextTokenIndex += quantity;
        _safeMint(msg.sender, quantity);
        nextTokenIndex = _nextTokenIndex;
    }

    function privateMint(uint256 quantity) external payable onlyOwner{
        uint256 _nextTokenIndex = nextTokenIndex;
        require(publicMintStatus == EPublicMintStatus.PRIVATE_MINT, 'Private mint is not live.');
        require((_nextTokenIndex += quantity) < MAX_SUPPLY, 'Exceeds Supply');

        _nextTokenIndex += quantity;
        _safeMint(msg.sender, quantity);
        nextTokenIndex = _nextTokenIndex;
    }

    function setPublicMintStatus(uint256 status) external onlyOwner {
        require(status < 3, "Mint Status Out of bounds");

        publicMintStatus = EPublicMintStatus(status);
    }

    // In wei - 10 ** 18
    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    // In wei - 10 ** 18
    function setPresalePrice(uint256 newPrice) external onlyOwner {
        presalePrice = newPrice;
    }

  // baseURI URI of the image server
    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

  // string Uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}