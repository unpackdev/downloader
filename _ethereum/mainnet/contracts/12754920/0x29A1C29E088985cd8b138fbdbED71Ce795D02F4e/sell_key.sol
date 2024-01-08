//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract KAKAKey is ERC721Enumerable {

    address public owner;
    address public superMinter;
    mapping(address => uint)public minters;
    string public myBaseURI;
    using SafeMath for uint;
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;

    modifier onlyOwner () {
        require(_msgSender() == owner, "not Owner's calling");
        _;
    }

    function setOwner(address newOwner_) public onlyOwner{
        owner = newOwner_;
    }

    function setMinter(address newMinter_, uint mint_limit) public onlyOwner {
        minters[newMinter_] = mint_limit;
    }
    constructor(address Owner_, string memory name_, string memory symbol_, string memory myBaseURI_) ERC721(name_, symbol_) {
        owner = Owner_;
        myBaseURI = myBaseURI_;
    }
    function mint(address player) public returns (uint256) {
        require(minters[msg.sender] > 0 || msg.sender == superMinter, "mint limit is 0");
        minters[msg.sender] = minters[msg.sender] - 1;

        _tokenIds.increment();
        uint tokenId = _tokenIds.current();
        _safeMint(player, tokenId, "");

        return tokenId;
    }

    function setMyBaseURI(string memory uri_) public onlyOwner {
        myBaseURI = uri_;
    }

    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC721: burn caller is not owner nor approved");

        _burn(tokenId_);
        return true;
    }

    function burnMulti(uint[] calldata tokenIds_) public returns (bool){
        for (uint i = 0; i < tokenIds_.length; ++i) {
            uint tokenId_ = tokenIds_[i];
            require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC721: burn caller is not owner nor approved");

            _burn(tokenId_);
        }
        return true;
    }

    function _baseURI() internal view override returns (string memory) {
        return myBaseURI;
    }
}


contract SellKey is KAKAKey {
    address public wallet;

    bool public isSale;
    uint public price;
    uint public inventory;
    IERC20 saleToken;
    using Counters for Counters.Counter;

    constructor (address owner_, address saleToken_, address wallet_, string memory name_, string memory symbol_, string memory myBaseURI_) KAKAKey(owner_, name_, symbol_, myBaseURI_) {
        wallet = wallet_;
        saleToken = IERC20(saleToken_);
    }

    function setIsSale(bool isSale_) public onlyOwner returns (bool){
        isSale = isSale_;
        return true;
    }

    function setPrice(uint price_) public onlyOwner returns (bool){
        price = price_;
        return true;
    }

    function setInventory(uint inventory_) public onlyOwner returns (bool){
        inventory = inventory_;
        return true;
    }

    function buy() public returns (uint) {
        require(isSale, "not start yet");
        require(price > 0, "sold out");
        require(inventory > 0, "sold out");
        require(saleToken.balanceOf(msg.sender) >= price, "not enough token");

        saleToken.transferFrom(msg.sender, address(wallet), price);
        inventory = inventory - 1;

        _tokenIds.increment();
        uint tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId, "");

        return tokenId;
    }

    function setWallet(address wallet_) public onlyOwner returns (bool){
        wallet = wallet_;
        return true;
    }
}

