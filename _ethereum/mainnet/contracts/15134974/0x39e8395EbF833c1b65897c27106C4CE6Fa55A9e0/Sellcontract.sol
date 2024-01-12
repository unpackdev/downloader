// SPDX-License-Identifier: NxtBloc and MIT 
pragma solidity ^0.8.3;

import "./CountersUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";


contract Sellcontract is Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
   using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter private _itemIds;
  CountersUpgradeable.Counter private _itemsSold;
  IERC20Upgradeable public tokenAccepted;
  uint256 tokenPrice ;
 
  address payable plateformfeeaddress;

   function initialize(address _token) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        tokenAccepted =IERC20Upgradeable(_token);
        tokenPrice= 0.001 ether;
      
    }

  function getPrice() public view returns (uint256) {
    return tokenPrice;
  }

  function changePrice(uint256 _newprice) public onlyOwner returns(bool result){
    tokenPrice=_newprice;
    return true;
  }

  function buyToken(
    
    uint256 _amounteth
   
  ) public payable nonReentrant {
    uint value=1;
    require(_amounteth >= (value/1000), "Quantity must be at least 0.001 ");
    //require(msg.value == tokenPrice*_qty,"insufficient funds");
    require(msg.value >= tokenPrice,"should be greater than 0.001");
    //payable(owner()).transfer(msg.value);
    
    IERC20Upgradeable(tokenAccepted).transfer(msg.sender, _amounteth * 10 ** 8);

  }

  function winthdrawEth (address payable _addr, uint256 _qty) public onlyOwner { 
    _addr.transfer(_qty);
  }

    function winthdrawNXTB (address payable _addr, uint256 _amount) public onlyOwner { 
    
          IERC20Upgradeable(tokenAccepted).transfer(_addr, _amount);
  }

      function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}


}