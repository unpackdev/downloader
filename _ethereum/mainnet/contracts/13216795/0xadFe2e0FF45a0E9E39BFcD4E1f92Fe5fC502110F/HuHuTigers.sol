// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./Counters.sol";



contract HuHuTigers is Ownable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {

    using SafeMath for uint256;
    using Strings for uint256;
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant PRICE = 7 * 10**16;
    uint256 public constant MAX_BY_MINT = 20;
    
    address internal ceo = 0x3B81f61116B4fA30EA030e54ab2dC2889F3dF50B;
    address internal cfo = 0xF6006784aA0E1AF230a8b6796A2A323F9d625da0;

    string public baseURI = "https://ipfs.io/ipfs/QmStW9q5NHrnGm7zsdFNWQKSm7fkchTbsHYUV26DGQ3GRx/";

    event CreateTiger(uint256 indexed id);

    constructor() ERC721("HuHuTigers", "HHT") {
        pause(true);
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

    function totalMint() public view returns (uint256) {
        return _totalSupply();
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
        _mint(_to, id);
        emit CreateTiger(id);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(string(abi.encodePacked(baseURI, tokenId.toString())), ".json")) : "";
        //return string(abi.encodePacked(baseURI, tokenId.toString()));
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

    function withdrawAll() public {
        uint256 balance = address(this).balance;
        require(balance > 0);
        require(msg.sender == ceo || msg.sender == cfo, "only CEO or CFO send");
        _widthdraw(ceo, balance.mul(60).div(100));
        _widthdraw(cfo, address(this).balance);
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
