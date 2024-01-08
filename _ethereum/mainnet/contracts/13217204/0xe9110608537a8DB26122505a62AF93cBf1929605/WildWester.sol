// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract WildWester is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 2 * 10**16;
    uint256 public constant MAX_BY_MINT = 20;
    address public constant devAddress = 0x3cC7DcE0981C59251BfEd2648dB3D5543DA175Ef;
    string public baseTokenURI;

    event CreateWildWester(uint256 indexed id);
    constructor(string memory baseURI) ERC721("WildWester", "WWR") {
        setBaseURI(baseURI);
        pause(true);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_SUPPLY, "Max supply reached.");
        if (_msgSender() != owner()) {
            require(!paused(), "Contract is paused.");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdCounter.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_SUPPLY, "Mint amount exceeds max supply.");
        require(total <= MAX_SUPPLY, "Max supply reached.");
        require(_count <= MAX_BY_MINT, "Mint amount exceeds max allowed.");
        require(msg.value >= price(_count), "Insufficient funds.");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdCounter.increment();
        _safeMint(_to, id);
        emit CreateWildWester(id);
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
        if (val == true){
            _pause();
        } else {
            _unpause();
        }
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}