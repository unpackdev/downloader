// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Ownable.sol";
import "./ERC721AQueryable.sol";

contract CPig is ERC721AQueryable, Ownable {
    string public baseTokenURI;
    uint256 public maxSupply = 2000;
    uint256 public maxCollection = 100;
    uint256 public maxAmountPerTx = 10;
    uint256 public autoPauseCount = 500;

    uint256 public maxAirdropSupply = 2000;
    uint256 public airdropSupply;
    uint256 public price1 = 0.2 ether;
    uint256 public count1 = 250;
    uint256 public price2 = 0.4 ether;

    bool public paused = false;
    bool public autoPauseOnce = false;

    modifier onlyNotPaused() {
        require(!paused, "1");
        _;
    }

    constructor() ERC721A("Capitalist Pig", "CPIG") {
    }

    function price(uint256 _count) public view returns (uint256) {
        if (totalSupply() + _count < count1) {
            return price1 * _count;
        } else if (totalSupply() + 1 >= count1) {
            return price2 * _count;
        } else {
            uint256 diff = totalSupply() + _count - count1;  
            return diff*price2 + (_count - diff)*price1;
        }
    }

    function setMaxAmountPerTx(uint256 _maxAmountPerTx) public onlyOwner {
        maxAmountPerTx = _maxAmountPerTx;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), "/", _toString(tokenId),".json") ) ;    
    }

    function mint(uint256 _count) public payable onlyNotPaused {
        require(totalSupply() + _count <= maxSupply, "5");
        require(msg.value >= price(_count) , "6");
        require(maxAmountPerTx >= _count, "7");
        _safeMint(msg.sender, _count);
        if (totalSupply() >= autoPauseCount && !autoPauseOnce) {
            paused = true;
            autoPauseOnce = true;
        }
    }

    function airDrop(address[] memory addresses)
        external
        onlyOwner
        onlyNotPaused
    {
        uint256 supply = totalSupply();
        require(
            airdropSupply + addresses.length <= maxAirdropSupply,
            "This transaction would exceed airdrop max supply"
        );
        require(
            supply + addresses.length <= maxSupply,
            "This transaction would exceed max supply"
        );
        for (uint8 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
            airdropSupply += 1;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function numberMinted(address add) public view returns (uint256) {
        return _numberMinted(add);
    }

    function setPrice1(uint256 _price) public onlyOwner {
        price1 = _price;
    }

    function setPrice2(uint256 _price) public onlyOwner {
        price2 = _price;
    }

    function setCount1(uint256 _count) public onlyOwner {
        count1 = _count;
    }

    function setAutoPauseCount(uint256 _count) public onlyOwner {
        autoPauseCount = _count;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
