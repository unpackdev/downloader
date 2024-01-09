// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";

contract FlyBoyNFT is ERC721Enumerable, Ownable, ERC721Burnable{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;
    bool public META_REVEAL = false;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 1013;
    string public sampleTokenURI;

    uint256 public constant MAX_ELEMENTS = 1013;
  
    uint256 public presaleprice1 = 0.04 ether;
    uint256 public presaleprice2 = 0.07 ether;
    uint256 public presaleprice3 = 0.1 ether;
    uint256 public presaleprice4 = 0.13 ether;
    uint256 public presaleprice5 = 0.15 ether;
    uint256 public publicsaleprice1 = 0.06 ether;
    uint256 public publicsaleprice2 = 0.1 ether;
    uint256 public publicsaleprice3 = 0.16 ether;
    uint256 public publicsaleprice4 = 0.2 ether;
    uint256 public publicsaleprice5 = 0.26 ether;
    uint256 public constant PRESALE_MAX_PER_USER = 5;
    uint256 public constant PRESALE_MAX_SUPPLY = 500;
    address public constant creatorAddress =
        0x50De0755FD715F8a3B1Dda35d6581A9C9a360549;

    string public baseTokenURI;
    bool private _pause;
    bool public presale = false;
    bool public publicsale = false;

    event JoinFace(uint256 indexed id);

    constructor(string memory baseURI) ERC721("FlyBoyNFT", "FBN") {
        setBaseURI(baseURI);
        pause(false);
    }

    modifier saleIsOpen() {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!_pause, "Pausable: paused");
        }
        _;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(
        bool _ispresale,
        uint256 _count,
        uint16 _balance
    ) public payable saleIsOpen {
        //presale minting
        require(publicsale || presale, "Sale has not yet started");
        uint256 total = _totalSupply();
        if (!publicsale && presale) {
            require(_ispresale);
            require(total + _count <= PRESALE_MAX_SUPPLY, "Presale Max Limit");
            require(total <= PRESALE_MAX_SUPPLY, "Sale end");
            require(_count <= PRESALE_MAX_PER_USER, "Exceeds number");
            require(_count <= PRESALE_MAX_PER_USER - _balance);
            if(_count == 1){require(msg.value >= presaleprice1);}
            else if(_count ==2 ){require(msg.value >= presaleprice2);}
            else if (_count == 3){require(msg.value >= presaleprice3);}  
            else if (_count == 4){require(msg.value >= presaleprice4);}  
            else if (_count == 5){require(msg.value >= presaleprice5);}  
             for (uint256 i = 0; i < _count; i++) {
                _mintAnElement(msg.sender, total + i);
            }         
        }
        
        else if (publicsale && !presale) {
            require(total + _count <= MAX_ELEMENTS, "Max limit");
            require(total <= MAX_ELEMENTS, "Sale end");
            if(_count == 1){require(msg.value >= publicsaleprice1);}
            else if(_count ==2 ){require(msg.value >= publicsaleprice2);}
            else if (_count == 3){require(msg.value >= publicsaleprice3);}  
            else if (_count == 4){require(msg.value >= publicsaleprice4);}  
            else if (_count == 5){require(msg.value >= publicsaleprice5);}          
            for (uint256 i = 0; i < _count; i++) {
                _mintAnElement(msg.sender, total + i);
            }
        }
    }

    function _mintAnElement(address _to, uint256 _tokenId) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId + 1);
        emit JoinFace(_tokenId + 1);
    }

    function togglePresale() public onlyOwner {
        presale = !presale;
    }
    function togglePublicsale() public onlyOwner {
        publicsale = !publicsale;
    }
    function getStatus() public view returns (bool) {
        if(presale) return true;
        else return false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    function setSampleURI(string memory sampleURI) public onlyOwner {
        sampleTokenURI = sampleURI;
    }
     function setMetaReveal(bool _reveal, uint256 _from, uint256 _to) public onlyOwner{
        META_REVEAL = _reveal;
        HIDE_FROM = _from;
        HIDE_TO = _to;
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!META_REVEAL && tokenId >= HIDE_FROM && tokenId <= HIDE_TO)
            return sampleTokenURI;

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(),".json"))
                : "";
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

    function pause(bool val) public onlyOwner {
        _pause = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(!presale);
        require(balance > 0);
        _widthdraw(creatorAdress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function reserve(uint256 _count) public onlyOwner {
        uint256 total = _totalSupply();
        require(total + _count <= 100, "Exceeded");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender(), total + i);
        }
    }
}
