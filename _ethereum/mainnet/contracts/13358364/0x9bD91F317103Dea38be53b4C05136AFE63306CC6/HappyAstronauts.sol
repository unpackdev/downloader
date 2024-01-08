// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract HappyAstronauts is
    ERC721Enumerable,
    Ownable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 10101;
    uint256 public constant PRICE = .06 ether;
    uint256 public constant MAX_BY_MINT = 10000;
    address public constant creatorAddress =
        0xE26EB6dA3050fb4E8E8792d75E7A0c87ccc783Fb;
    string public baseTokenURI;

    event CreateAstronaut(uint256 indexed id);

    constructor(string memory baseURI) ERC721("HappyAstronauts", "HATS") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen() {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        _;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function bulkDrop(address[] memory addresses, uint256[] memory ids) public onlyOwner{
        require(addresses.length == ids.length, "Count doet not match");
        address operator = _msgSender();
        for(uint256 i = 0; i < addresses.length; i++){
            safeTransferFrom(operator, addresses[i], ids[i]);
        }
        
    }

    function _mintAnElement(address _to) private {
        uint256 id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateAstronaut(id);
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

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
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
}
