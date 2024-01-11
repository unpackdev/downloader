// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";


contract boobBears is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using SafeMath for uint256;
    using Strings for uint256;

    string public baseURI;
    uint256 public mintPrice = 0.003 ether;
    uint256 public maxSupply = 10000;
    uint256 public devMaxMints = 69;
    uint256 public freeMintAmount = 2000;
    uint256 public maxMintFree = 3;
    uint256 public maxMint = 30;

    // Mint Trackers
    mapping(address => uint256) addressMinted;
    mapping(address => uint256) addressMintedFree;
    uint256 public devMints;
    bool public publicSaleLive;

    constructor() ERC721A("boobBears", "BB") {}

    function freeMint(uint256 amount) external payable nonReentrant {
        require(publicSaleLive, "Public mint is not live");
        require(totalSupply() + amount <= freeMintAmount, "Free Mint is Over");
        require(msg.value == 0, "Must provide exact required ETH");
        addressMintedFree[msg.sender] += amount;
        require(addressMintedFree[msg.sender] <= maxMintFree, "Max Free Mint per wallet reached");
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable nonReentrant {
        require(publicSaleLive, "Public mint is not live");
        require(amount > 0, "Amount to mint is 0");
        require(totalSupply()+ amount <= maxSupply, "Sold out!");
        require(msg.value == mintPrice.mul(amount), "Must provide exact required ETH");
        addressMinted[msg.sender] += amount;
        require(addressMinted[msg.sender] <= maxMint, "Max Mint per wallet reached");
        _safeMint(msg.sender, amount);
    }

    function changeMaxMint(uint56 _new) external onlyOwner {
        maxMint = _new;
    }

    function changeMaxFreeMint(uint56 _new) external onlyOwner {
        maxMintFree = _new;
    }

    function setPublicSale(bool _status) external onlyOwner {
        publicSaleLive = _status;
    }

    function setFreeMintAmount(uint256 _new) external onlyOwner {
        freeMintAmount = _new;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setbaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function devMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Sold out!");
        devMints += amount;
        require(devMints <= devMaxMints, "Team Max Mints Reached");
        _safeMint(msg.sender, amount);
    }
    
    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether");
    }

}