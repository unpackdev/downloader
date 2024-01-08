// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract Dopewaby is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public Reserved_Count = 200;
    
    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant PRICE = 50 * 10**15; // 0.05
    uint256 public constant MAX_BUY_MINT = 20;
    
    address public constant creatorAddress = 
    0xdF1194163154f1608cB2FD876e0F47e8E4DBcaa1;
    address public constant devAddress = 
    0x40AbdeCD3BB963Ccc74925E801294d88d53B9DcC;
    
    uint256 public devTotalFee = 0;
    string public baseTokenURI;

    event CreateDOPEWABY(uint256 indexed id, address to);
    
    constructor(string memory baseURI) ERC721("DOPE WABY", "WABY") {
        setBaseURI(baseURI);
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
    function maxLastMint() public view returns (uint256) {
        return MAX_ELEMENTS - Reserved_Count - totalMint();
    }

    function reservedMint(uint256 _count) public payable onlyOwner {
        require(_count <= Reserved_Count, "Max Reserved limit");

        for (uint256 i = 0; i < _count; i++) {
            Reserved_Count--;
            _mintAnElement(msg.sender);
        }
    }
    
    function mintBy(uint256 id, address _to) public onlyOwner {
        _safeMint(_to, id);
        emit CreateDOPEWABY(id, _to);
    }
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BUY_MINT, "Exceeds number");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        uint256 totalPrice = price(_count);
        require(msg.value >= totalPrice, "Value below price");
        
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
            if (totalMint() > 700) {
                // Developer Fee Percent
                devTotalFee += PRICE.mul(13).div(100);
            }
        }
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateDOPEWABY(id, _to);
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
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAllToCreater() public payable onlyOwner {
        _withdrawAllToDeveloper();
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0.");
        _widthdraw(creatorAddress, address(this).balance);
    }
    function withdrawAllToDeveloper() public payable {
        require(devAddress == _msgSender(), "Developer: caller is not the developer");
        require(devTotalFee > 0, "Developer: fee is 0.");
        _withdrawAllToDeveloper();
    }
    function _withdrawAllToDeveloper() private {
        _widthdraw(devAddress, devTotalFee);
        devTotalFee = 0;
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