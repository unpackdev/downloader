// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";

contract LooneyBalloons is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 8888;
    uint256 public constant PRICE = 0.04 ether;
    uint256 public constant MAX_BY_MINT = 20;
    address public constant creatorAddress = 0x3D3753523e901E5e14Ab4ae7aDA9c85e9D1f0C61;
    string public baseTokenURI;
    string public hiddenURI;
    bool public isRevealed = false;

    event CreateBalloon(uint256 indexed id);
    constructor(string memory baseURI, string memory __hiddenURI) ERC721("LooneyBalloons", "LB") {
        setBaseURI(baseURI);
        setHiddenURI(__hiddenURI);
        _pause();
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateBalloon(id);
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }
    function mintUnique(address _to, uint256 id) public payable onlyOwner {
        _safeMint(_to, id);
        emit CreateBalloon(id);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _hiddenURI() public view virtual returns (string memory) {
        return hiddenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setHiddenURI(string memory __hiddenURI) public onlyOwner {
        hiddenURI = __hiddenURI;
    }

    function getHiddenURI() public view onlyOwner returns (string memory) {
        return hiddenURI;
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function hide() public onlyOwner {
        isRevealed = false;
    }

    function _isRevealed() public view returns(bool) {
        return isRevealed;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!_isRevealed()) {
            return _hiddenURI();
        }

        return bytes(_baseURI()).length > 0
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : "";
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function unpause(bool val) public onlyOwner {
        if (val == true) {
            _unpause();
            return;
        }
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getAddress() public view virtual returns(address) {
        return address(this);
    }
}
