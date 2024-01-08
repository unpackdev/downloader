// SPDX-License-Identifier: MIT
                                                                                
                                                                                
                                                                                
                                                                                
//                        %%%%%%%%%%%%%%%%%%%%                             
//                        @@@@@@@@@@@@@@@@@@@@                             
//                  .(((((@@@@@((((((((((@@@@@(((((                        
//                  *@@@@@@@@@@          @@@@@@@@@@                        
//                  *@@@@@@@@@@          @@@@@@@@@@                        
//              @@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@                   
//              @@@@@##########**********##########@@@@@                   
//              @@@@#          @@@@@@@@@@          @@@@@                   
//              @@@@#          @@@@@@@@@@          @@@@@                   
//        (@@@@@@@@@#          @@@@@@@@@@          @@@@@@@@@@              
//        (@@@@@@@@@#          @@@@@@@@@@          @@@@@@@@@@              
//        (@@@@@    *@@@@@@@@@@          @@@@@@@@@@     @@@@@              
//        (@@@@@    *@@@@@@@@@@          @@@@@@@@@@     @@@@@              
//   %@@@@(         *@@@@@@@@@@          @@@@@@@@@@          @@@@@*        
//   %@@@@(         *@@@@@@@@@@          @@@@@@@@@@          @@@@@*        
//   %@@@@@@@@@@@@@@#          @@@@@@@@@@          @@@@@@@@@@@@@@@*        
//   %@@@@@@@@@@@@@@#          @@@@@@@@@@          @@@@@@@@@@@@@@@*        
//   %@@@@@@@@@@@@@@#          @@@@@@@@@@          @@@@@@@@@@@@@@@*        
//   %@@@@@@@@@@@@@@#          @@@@@@@@@@          @@@@@@@@@@@@@@@*        
//        (@@@@@    *@@@@@@@@@@          @@@@@@@@@@     @@@@@              
//        (@@@@@    *@@@@@@@@@@          @@@@@@@@@@     @@@@@              
//              @@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@                   
//              @@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@                   
//                  *@@@@@     @@@@@@@@@@     @@@@@                        
//                  *@@@@@     @@@@@@@@@@     @@@@@                        
//              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

//Opensea whitelisting
contract OwnableDelegateProxy { }

//Opensea whitelisting
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Gotchis is ERC721Enumerable, Ownable {

    using Strings for uint256;

    address public proxyRegistryAddress;
    string _baseTokenURI;
    uint256 private _price = 0.05 ether;
    bool public _paused = true;
    bool public _giveawayPaused = true;
    bool public _finalGiveawayUnleashed = false;

    address t1 = 0xfB58F9bEe03d2981476D5901aE42D5A03A9D9E39;

    constructor(string memory baseURI, address _proxyRegistryAddress) ERC721("Gotchis NFT", "GOTCHIS")  {
        setBaseURI(baseURI);
        proxyRegistryAddress = _proxyRegistryAddress;

        _safeMint(t1, 0);
    }

  //Opensea whitelist
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }
    return ERC721.isApprovedForAll(_owner, _operator);
  }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(!_paused, "Sale paused");
        require(num < 21, "You can mint a maximum of 20 Gotchis at once");
        require(supply + num < 9501, "Exceeds maximum Gotchis available to purchase");
        require(msg.value >= _price * num, "Ether sent is not correct");

        for(uint256 i; i < num; i++){
            _safeMint(msg.sender, supply + i);
        }
    }

    function startingGiveaway() public {
        uint256 supply = totalSupply();
        require(!_giveawayPaused, "Giveaway paused");
        require(supply < 501, "Giveaway has finished!");
        require(balanceOf(msg.sender) < 1, "Only one per person during initial giveaway");

        _safeMint(msg.sender, supply);
    }

    function finalGiveaway() public {
        uint256 supply = totalSupply();
        require(!_paused, "Sale paused");
        require(supply > 9499, "The regular sale must finish before the post-sale giveaway begins");

        uint256 tokenCount = balanceOf(msg.sender);

        bool ownsRegularToken = false;
        for(uint256 i; i < tokenCount; i++){
            uint256 ownedToken = tokenOfOwnerByIndex(msg.sender, i);
            if(ownedToken > 501 && !ownsRegularToken) {
                ownsRegularToken = true;
            }
            require(ownedToken < 9500 || _finalGiveawayUnleashed, "Only one final giveaway Gotchi per person!");
        }
        require(ownsRegularToken, "This final giveaway is for those who have bought a Gotchi" );
        require(supply < 10000, "There's none left, giveaway finished!" );

        _safeMint(msg.sender, supply);
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function pauseGiveaway(bool val) public onlyOwner {
        _giveawayPaused = val;
    }

    //in case there aren't 500 unique buyers in regular sale
    function unleashFinalGiveaway(bool val) public onlyOwner {
        _finalGiveawayUnleashed = val;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(t1).send(address(this).balance));
    }
}