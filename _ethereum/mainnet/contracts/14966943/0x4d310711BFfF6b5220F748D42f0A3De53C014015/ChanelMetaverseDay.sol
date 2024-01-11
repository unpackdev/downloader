// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";


contract ChanelMetaverseDay is ERC1155, Ownable, ReentrancyGuard {

  using Strings for uint256;

  uint256 public constant CocoCoin = 1;

  address public dev = 0x072B4CeA4B1aC906a50621b7b7270B5AFc2d5E4C; 
  address public own = 0x7e1Ef58aB95105D529BDbF10e75e5D908fC242B1;

  uint cost = 0.1 ether;
  

  constructor() ERC1155("ipfs://QmVqg4ad9ZJbTrrBczAdt1GDezBKVaGPqmuPzFXgzNN2xy/Cococoin.json") {

    _mint(msg.sender, CocoCoin, 1,"");
    _transferOwnership(0x7e1Ef58aB95105D529BDbF10e75e5D908fC242B1); 
  }
 

   function changeOwn(address _own) public {
     require(_msgSender() == dev || _msgSender() == own );
     own = _own;
   }   

   function changeDev (address _dev) public {
     require(_msgSender() == dev || _msgSender() == own );
     dev = _dev;
   }

   function changeCost (uint _cost) public {
     require(_msgSender() == dev || _msgSender() == own );
     cost = _cost;
   }
    
    function setTokenUri( string memory _uri) public {
    require(_msgSender() == dev || _msgSender() == own );
        _setURI(_uri); 
    }
 

    function gift(address[] calldata addresses) public returns(bool)   {
            require(_msgSender() == dev || _msgSender() == own );
            require(addresses.length > 0, "Need to gift at least 1 NFT");
            for (uint256 i = 0; i < addresses.length; i++) {
              _mint(addresses[i], CocoCoin, 1, "");
            }

            return true;
        }

    function giftNFTs(address[] calldata addresses, uint[] memory amount ) public  returns(bool)   {
            require(_msgSender() == dev || _msgSender() == own );
            require(addresses.length > 0, " Need to gift at least 1 NFT");
            for (uint256 i = 0; i < addresses.length; i++) {
              _mint(addresses[i], CocoCoin, amount[i], "");
            }
              return true;
        }

    function burn(address[] calldata addresses, uint[] memory ids, uint[] memory amount ) public returns(bool)  {
          require(_msgSender() == dev || _msgSender() == own );
          for(uint i = 0; i < amount.length; i++){  
          
          uint[] memory supply = balanceOfBatch(addresses, ids);
          require(1 <= supply[i]);
          require(supply[i] >= amount[i]);

          _burn(addresses[i], 1, amount[i]);
          supply[i] -= amount[i];
        
        }
            return true;
        
      }


    function transfer(address[] calldata addresses, uint[] memory amount) public returns(bool)  {
              require(addresses.length > 0, "Need to gift at least 1 NFT");
              
              for (uint256 i = 0; i < addresses.length; i++) {        
                safeTransferFrom(msg.sender, addresses[i], 1, amount[i], "");
              }

              return true;
      }

    function send(address payable[] calldata receiver) public nonReentrant returns(bool){
    
     for (uint256 i = 0; i < receiver.length; i++) { 
          
          require(address(this).balance >= cost, "There is not enough matic in the smart contract");
          (receiver[i]).transfer(cost);
        }

        return true; 
    
  }

  function balanceOfCollection() public view returns(uint) {
    return address(this).balance;
  } 

  function deposit() payable public {}


}