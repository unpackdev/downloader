// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";

contract GPUNKSNFT is ERC721, ERC721Enumerable, PaymentSplitter, Ownable, Pausable {
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    string private _api_entry;
    // bool private _mintIsRandom = false;
    uint256 private _itemPrice;
    uint256 private _maxNftAtOnce = 20;
    bool public saleIsActive = true;
    uint256 public MAXNFT = 10000;

    mapping(uint256 => uint256) private _totalSupply;
    Counters.Counter private _tokenIdCounter;

    address[] private _team = [
      0x4bCF0A70a20dFD45962d8ba28Ae9E643af970B8c, 
      0x38bc372f8112daEa40f8947e54f04B92EE3a2F0f
    ];

    uint256 public gpunksNeeded = 1446300000 * 10**9;
    address public constant gpunksAddress = 0xB25a6090b85681330Fc1E0B63085d637e194d859;

    uint256[] private _team_shares = [50,50];

    constructor()
        PaymentSplitter(_team, _team_shares)
        ERC721("Grumpy Doge Punks Offical", "GPUNKS")
    {
	    _api_entry = "https://api.grumpydogepunks.com/meta/";
        setItemPrice(600000000000000);
    }
    
    function contractURI() public pure returns (string memory) {
		return "https://api.grumpydogepunks.com/contract/";
	}

    function mineReserves(uint _amount) public onlyOwner {
        for(uint x = 0; x < _amount; x++){
	        master_mint();
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return _api_entry;
    }

    function setBaseURI (string memory _uri) public onlyOwner  {
        _api_entry = _uri;
    }

    function getOneNFT() public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(msg.value == getItemPrice(), "insufficient ETH");
        require(_tokenIdCounter.current() <= MAXNFT, "Purchase would exceed max supply");
        master_mint();
    }

    function getMultipleNFT(uint256 _howMany) public payable {
	require(saleIsActive, "Sale must be active to mint");
	require(_howMany <= _maxNftAtOnce, "to many NFT's at once");
	require(getItemPrice().mul(_howMany) == msg.value, "insufficient ETH");
	require(_tokenIdCounter.current().add(_howMany) <= MAXNFT, "Purchase would exceed max supply");
		for (uint256 i = 0; i < _howMany; i++) {
			master_mint();
		}
	}

    function master_mint() private {
        _safeMint(msg.sender, _tokenIdCounter.current() + 1);
        _tokenIdCounter.increment();
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getotalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return getotalSupply(id) > 0;
    }

    function setMax(uint256 _max) public onlyOwner {
        MAXNFT = _max;
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function getItemPrice() public view returns (uint256) {
        if(IERC20(gpunksAddress).balanceOf(msg.sender) > gpunksNeeded) {
            return _itemPrice.div(2);
        } else {
            return _itemPrice;
        }    
    }

    function setItemPrice(uint256 _price) public onlyOwner {
        _itemPrice = _price;
    }

    function getMaxNftAtOnce() public view returns (uint256) {
        return _maxNftAtOnce;
    }

    function setMaxNftAtOnce(uint256 _items) public onlyOwner {
        _maxNftAtOnce = _items;
    }
    
    function setGpunksNeeded(uint256 _needed) public onlyOwner {
        gpunksNeeded = _needed;
    }

    function withdrawParitial() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
     
    function withdrawAll() public onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}