// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CigPass is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    // the passz's url
    string[] public cigPassz;
    // the whitelist mapping(address,address)
    mapping(address => address) public whiteLists;
    // all the whitelist address
    address[] private whiteListAddressList ;

    string private _pass_img_url = "https://cigdao.xyz/web3/static/pass_static.png";

    Counters.Counter private _tokenIdCounter;
    // Total amount from pass sales
    uint256 public balanceReceived;
    // the bagage
    uint256[] public badgeExchangePassz;

    uint256 private allowTotalSupply = 50000;

    uint256 private _airDropTotalSupply;

    uint256 private allowAirDropTotalSupply = 77;

    uint256 private _whitelistTotalSupply;

    uint256 private allowWhitelistTotalSupply = 300;


    struct Item {
        uint256 id;
        address owner;
        string uri; //metadata url
    }

    mapping(uint256 => Item) public Items; //id => Item

    constructor() ERC721("CigPass", "CPass") {}

    function airDropTotalSupply() public view  returns (uint256) {
        return _airDropTotalSupply;
    }

    function whitelistTotalSupply() public view  returns (uint256) {
        return _whitelistTotalSupply;
    }

    function checkAirDropTotalSupply() view internal {
            uint256 will_num = airDropTotalSupply() + 1;
            require(will_num > 0 && will_num < allowAirDropTotalSupply, "Exceeds airdrop supply");
     }

    function checkWhitelistTotalSupply() view internal {
            uint256 will_num = whitelistTotalSupply() + 1;
            require(will_num > 0 && will_num < allowWhitelistTotalSupply, "Exceeds whitelist supply");
     } 


    function checkTotalSupply() view internal {
            uint256 will_num = totalSupply() + 1;
            require(will_num > 0 && will_num < allowTotalSupply, "Exceeds token supply");
     }


/**
    Members on the whitelist can buy the pass at the whitelist price
 */

    function addWhiteList(address[] memory addresses) public onlyOwner {

       for(uint256 i = 0 ; i < addresses.length; i++){
            address to = addresses[i];
            whiteLists[to] = to;
            whiteListAddressList.push(to);
       }
    }

/**
  *   Those on the whitelist can buy the pass at 0.1 eth
 */

    function getWhiteList() public view returns (address[] memory){
       return whiteListAddressList;
    }

/**
 *     The admin can give someone a pass for free
 */
    function mintAirDropBatch(address[] memory addresses) public onlyOwner {
        checkAirDropTotalSupply();
        for(uint256 i = 0 ; i < addresses.length; i++){
            address to = addresses[i];
            _mint(to);    
        }
        
    }


/**
*  Exchange 100 regular badges for 1 pass or for members with the Professional badge, Honour badge or 50 Contribution badges, they can exchange for 1 pass
 */
    function badgeExchangePass(address to) public onlyOwner returns (uint256){
        checkTotalSupply();
        uint256 tokenId = _mint(to);
        badgeExchangePassz.push(tokenId);
        return tokenId;

    }

/**
 *  Buy the pass with whitelist price of 0.1 eth
 */

    function mintWithWhiteList(address to)
        public
        payable
        returns (uint256)
    {
        checkWhitelistTotalSupply();
        require(whiteLists[to] != address(0),"the address does not exist in the  whitelist");
        require(msg.value == .1 ether, "Not enough ETH sent: check price.");
        balanceReceived += msg.value;
        uint256 tokenId = _mint(to);
        return tokenId;
    }

/**
    Buy the pass with the public sale price of 0.2 eth
 */

    function mintPublic(address to)
        public
        payable
        returns (uint256)
    {
        checkTotalSupply();
        require(msg.value == .2 ether, "Not enough ETH sent: check price.");
        balanceReceived += msg.value;
        uint256 tokenId = _mint(to);
        return tokenId;
    }

    function getNftTotal(address addr)public view returns (uint256){
         uint256 token_total = _tokenIdCounter.current();
         uint256 total = 0;
         for(uint256 i = 1 ; i <= token_total; i++){
             address t_add  = Items[i].owner;
             if(t_add == addr){
                total = total + 1;
             }
         }
         return total;
    }

    function _mint(address to) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _pass_img_url);
        cigPassz.push(_pass_img_url);
        Items[tokenId] = Item({id: tokenId, owner: to, uri: _pass_img_url});
        return tokenId;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
    *  The admin can withdraw the balance
    */

    function withdrawMoney() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
