// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract CoolColorCollective is ERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _reservedClaimedTracker;
    bool private _paused;

    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant MAX_RESERVED = 200;
    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant MAX_BY_MINT = 5;
    address public constant withdrawalAddress = 0xeEbAb1F35d53CbEC899cf3CcAe03ff470678adb7;
    string public baseTokenURI;

    event CreateColor(uint256 indexed id);
    constructor(string memory baseURI) ERC721("CoolColorCollective", "CCC") {
        setBaseURI(baseURI);
        pause(true);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "All tokens have been sold");
        if (_msgSender() != owner()) {
            require(!_paused, "Paused");
        }
        _;
    }
    
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    function totalMinted() public view returns (uint256) {
        return _totalSupply();
    }
    function reservedClaimed() public view returns (uint256) {
        return _reservedClaimedTracker.current();
    }
    function paused() public view returns (bool) {
        return _paused;
    }

    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        uint256 total = _totalSupply();
        uint256 reserved = reservedClaimed();
        require(reserved < MAX_RESERVED, "Already have claimed all reserved elements");
        require(reserved + amount <= MAX_RESERVED, "Minting would exceed max reserved elements");
        require(recipient != address(0), "Cannot claim for null address");
        require(total < MAX_ELEMENTS, "All tokens have been minted");
        require(total + amount <= MAX_ELEMENTS, "Minting amount requested will exceed overall max");
        require(amount > 0, "Must mint at least one element");

        for (uint256 i = 0; i < amount; i++) {
            _mintAnElement(recipient);
            _reservedClaimedTracker.increment();
        }
    }

    function mint(address _to, uint256 amount) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total < MAX_ELEMENTS, "All tokens have been minted");
        require(total + amount <= MAX_ELEMENTS, "Minting amount requested will exceed overall max");
        require(amount <= MAX_BY_MINT, "Amount requested exceeds per-mint max");
        require(msg.value >= price(amount), "Value below price to mint amount");
        require(amount > 0, "Must mint at least one element");

        for (uint256 i = 0; i < amount; i++) {
            _mintAnElement(_to);
        }
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateColor(id);
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
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
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(withdrawalAddress, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Withdrawal transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}