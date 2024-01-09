// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC721Pausable.sol";


contract AppleHeads is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
     using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant PRICE = 5 * 10**16;
    uint256 public constant PRESALE_PRICE = 4.2 * 10**16;
    uint256 public constant CRUSADER_PRICE = 3.5 * 10**16;
    uint256 public constant MAX_BY_MINT = 20;
    uint256 public preSaleAddressLimit = 20;
    string public baseTokenURI;
    string public notRevealedURI;
    bool public revealed = false;
    bool public onlyPresale = true;
    address public constant creatorAddress = 0x69710051470E9d65f7A0B004c9cD298FA2a2AE4c;
    address[] public whitelistedAddresses;
    address[] public crusaderAddresses;
    address[] public PPP1Addresses;
    address[] public PPP2Addresses;
    mapping(address => uint256) public addressMintedBalance;

    event CreateAppleHead(uint256 indexed id);
    constructor(string memory baseURI, string memory _initNotRevealedURI) ERC721("AppleHeads", "AH") {
        setBaseURI(baseURI);
        setNotRevealedURI(_initNotRevealedURI);
        pause(true);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
            require(!onlyPresale, "Public Sale Not Open");
        }
        _;
    }
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    function mint(uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        if (_msgSender() != owner()) {
            require(msg.value >= price(_count), "Value below price");
        }
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement();
        }
    }

        function crusaderMint(uint256 _count) public payable {
        require(onlyPresale, "Presale is closed");
        require(isCrusader(msg.sender), "user is not a crusader");
        require(msg.value >= crusaderPrice(_count), "Value below price");
        presaleMint(_count);
        }

        function whitelistMint(uint256 _count) public payable {
        require(onlyPresale, "Presale is closed");
        require(isWhitelisted(msg.sender), "user is not whitelisted");
        require(msg.value >= whitelistPrice(_count), "Value below price");
        presaleMint(_count);
        }

        function PPP1Mint(uint256 _count) public payable {
        require(onlyPresale, "Presale is closed");
        require(isPPP1(msg.sender), "user is not PPP1");
        require(msg.value >= whitelistPrice(_count), "Value below price");
        presaleMint(_count);
        }

        function PPP2Mint(uint256 _count) public payable {
        require(onlyPresale, "Presale is closed");
        require(isPPP2(msg.sender), "user is not PPP2");
        require(msg.value >= whitelistPrice(_count), "Value below price");
        presaleMint(_count);
        }

        function presaleMint(uint256 _count) private {
        uint256 total = _totalSupply();
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _count <= preSaleAddressLimit, "max NFT per address exceeded");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement();
        }
    }




    function _mintAnElement() private {
        uint id = _totalSupply() + 1;
        _tokenIdTracker.increment();
        _safeMint(msg.sender, id);
        addressMintedBalance[msg.sender]++;
        emit CreateAppleHead(id);
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }
    function crusaderPrice(uint256 _count) public pure returns (uint256) {
        return CRUSADER_PRICE.mul(_count);
    }
        function whitelistPrice(uint256 _count) public pure returns (uint256) {
        return PRESALE_PRICE.mul(_count);
    }

     function setPreSalePerAddressLimit(uint256 _limit) public onlyOwner {
    preSaleAddressLimit = _limit;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    
      function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

      function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

    function isCrusader(address _user) public view returns (bool) {
    for (uint i = 0; i < crusaderAddresses.length; i++) {
      if (crusaderAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

      function isPPP1(address _user) public view returns (bool) {
    for (uint i = 0; i < PPP1Addresses.length; i++) {
      if (PPP1Addresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

        function isPPP2(address _user) public view returns (bool) {
    for (uint i = 0; i < PPP2Addresses.length; i++) {
      if (PPP2Addresses[i] == _user) {
          return true;
      }
    }
    return false;
  }
    
    function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

    function crusaderUsers(address[] calldata _users) public onlyOwner {
    delete crusaderAddresses;
    crusaderAddresses = _users;
  }

    function PPP1Users(address[] calldata _users) public onlyOwner {
    delete PPP1Addresses;
    PPP1Addresses = _users;
  }

    function PPP2Users(address[] calldata _users) public onlyOwner {
    delete PPP2Addresses;
    PPP2Addresses = _users;
  }


     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) { 
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false){
            return notRevealedURI;
        }
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
     }


    function reveal() public onlyOwner {
        revealed = true;    
    }
    
    
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function setOnlyPresale(bool _state) public onlyOwner {
    onlyPresale = _state;
  }


    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}



