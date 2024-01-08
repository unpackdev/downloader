// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
    __   __       __  ___  __        ___ ___       ___  __   ___       __   __    __   __        
    /  ` |__) \ / |__)  |  /  \ |\ | |__   |  |    |__  / _` |__  |\ | |  \ /__`  /  ` /  \  |\/| 
    \__, |  \  |  |     |  \__/ | \| |     |  |___ |___ \__> |___ | \| |__/ .__/ .\__, \__/  |  |                                                                                  

    https://cryptonftlegends.com

    Minting begins 6PM 06/09/21 UTC

*/

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";

contract CNFTLNFT is ERC721, ERC721Enumerable, PaymentSplitter, Ownable, Pausable {
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    string private _api_entry;
    uint256 private _itemPrice;
    bool public saleIsActive = true;
    uint public salesStart = 1630951200;
    uint256 public MAXNFT = 222;

    mapping(uint256 => uint256) private _totalSupply;
    Counters.Counter private _tokenIdCounter;

    address[] private _team = [
      0x6044C65E61d8C13fd16Dc6Ac6FDfa6A5570dCf58, //tony
      0x7adfea83291fcf100d906A0461A8251fB3E80423, //dan
      0x64011147621c84f71A0601d5fA926075641608a1, //artist
      0x5C89fcDbDbe9b5a95C3ef4214e394cF8512B6DbD, //dev
      0x3EAaF039f2BeDE9367c7979664b9BC64E01C936f //dev
    ];

    uint256[] private _team_shares = [60,10,10,10,10];

    constructor()
        PaymentSplitter(_team, _team_shares)
        ERC721("CryptoNftLegends.com", "CNFTL")
    {
	    _api_entry = "https://api.cryptonftlegends.com/meta/";
        setItemPrice(220000000000000000);
    }
    
    function contractURI() public pure returns (string memory) {
		return "https://api.cryptonftlegends.com/contract/";
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
        require(saleIsActive, "Sales must be active to mint");
        require(salesStart < block.timestamp, "Sales begin at 1630951200");
        require(msg.value == getItemPrice(), "insufficient ETH");
        require(_tokenIdCounter.current() <= MAXNFT, "Purchase would exceed max supply");
        master_mint();
    }

    function master_mint() private {
        _safeMint(msg.sender, _tokenIdCounter.current() + 1);
        _tokenIdCounter.increment();

    }

    function totalSupply() override public view virtual returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getTotalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return getTotalSupply(id) > 0;
    }

    function mintID(address to, uint256 id) public onlyOwner {
        require(_totalSupply[id] == 0, "this NFT is already owned by someone");
        _tokenIdCounter.increment();
        _mint(to, id);
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function getItemPrice() public view returns (uint256) {
        return _itemPrice;
    }

    function setItemPrice(uint256 _price) public onlyOwner {
        _itemPrice = _price;
    }

    function setSalesStart(uint256 _salesStart) public onlyOwner {
        salesStart = _salesStart;
    }

    function setMax(uint256 _max) public onlyOwner {
        MAXNFT = _max;
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

    function transferETH(address payable recipient, uint256 amount) external onlyOwner() {
        require(amount <= 1000000000000000000, "CNFTL:: 1 ETH Max");
        require(address(this).balance >= amount, "CNFTL:: Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "CNFTL:: Address: unable to send value, recipient may have reverted");
    }

    // Admin function to remove tokens mistakenly sent to this address
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint256 _amount) external onlyOwner() {
        require(_tokenAddr != address(this), "CNFTL:: Cant remove CNFTL");
        require(IERC20(_tokenAddr).transfer(_to, _amount), "CNFTL:: Transfer failed");
    }
}