// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
contract SkullPunksLogic is Ownable{

  mapping(address=>uint256) mintAllowance;
  mapping(address=>bool) mintAllowanceSatus;
 
  address payable public _wallet;
  uint256 public price;
  bool isFlashSale;
  address[] OGs = [ //whitelist of ogs that deserve free mints
    0xb0a80D27de9EDeFC59652Dc7aca7Fd6d08E5D80E,
    0x3E36d5cC57890b3400E245750A4c641f252cC685,
    0x238e9a9D6da8CFf2cDE7102269F33dd9a26D0079,
    0x0837BDb03c1184299f932B15cdd657E8f061071e,
    0x9e21Ebf0A5Fc6f1DA0ea7995F90fcB2bb483c617,
    0xD4ac716385924ed7449d50887FC6FE4fbf9CF81E,
    0xA06ff0CE9b22F7BcAaCf9f552af5A0f68324113e,
    0xBa6E38219Ac69Cd42E2b40EAe1f91c7bd0762449,
    0x5F267731EB92d24a82aC50E2BD6484116a719895,
    0xCbE803159b58A626Bb9f64a6CB6C127847264fc0,
    0xE17c2136E81B3F49D7F5745AB0029b41942e7CBA,
    0xeBc02e2a9d30A55cf3fa4D3279fD0ED23D5D0b60,
    0x2045510535FE63a694fd7BbdFc212e45E7439E6D,
    0x4D24Ec75AE7BD121BCfb455cF6e9971B75E7A222,
    0x7f8f28a9c18e3dD08032324Ac3C675fac9a4F29c,
    0xbF9aAc14272DE06BfDc2692A77cd0cB899dbF5AB,
    0x738a89598d07Dfd6db83a8DD43Af5eF7cb81a130,
    0x6DcF068797523410a63e23DEca425882203D1732,
    0x94AA50fE3c1ad32b0419004eeE4f278ca3908876,
    0xE17c2136E81B3F49D7F5745AB0029b41942e7CBA,
    0x9e079641C9C33bA1eBBAE41d9D59f8C781120967,
    0x381B91B155fe50b6B55608A27c664CbF4108219b,
    0x4D24Ec75AE7BD121BCfb455cF6e9971B75E7A222,
    0x238e9a9D6da8CFf2cDE7102269F33dd9a26D0079,
    0xb5571485E650bFD025397e0a220d7EbFBc6c831a,
    0xa4D4FeA9799cd5015955f248994D445C6bEB9436,
    0x91B6132cA348fbc5B884c9887F89f2eAC76E475e,
    0x6DcF068797523410a63e23DEca425882203D1732,
    0x901c20dfe0e6bef2d51d2B15111bbE1335171aD1,
    0xe09007f5451e567d4ebb34Fc38711A3B469758F3,
    0x28e3D831cB9939A98FFC8f29F9B6d1afbB410aF6,
    0x5F267731EB92d24a82aC50E2BD6484116a719895,
    0x379D77E2B1Ff14180B8E710d4A1a2DDd15a0eE63
  ];


  constructor() Ownable(){


  }

  //mint called everytime signin successful in the dapp
  function initialMintAllowance(address _add,uint256 _allow) internal returns (bool){
    uint256 allowance   = mintAllowance[_add];
    mintAllowance[_add] = _allow + allowance;
    mintAllowanceSatus[_add] = true;
    return true;
  }
  //
  function addMintAllowance(address _add,uint256 _allow) public onlyOwner returns (bool){
    uint256 allowance   = mintAllowance[_add];
    mintAllowance[_add] =  allowance + _allow;
    return true;
  }
  function subMintAllowance(address _add,uint256 _allow) public onlyOwner returns (bool){
    uint256 allowance     = mintAllowance[_add];
    if(allowance > 0){
      mintAllowance[_add] = allowance - _allow;
    }
    return true;
  }
  function isInitialMint(address _add) public view returns (bool){
    return mintAllowanceSatus[_add];
  }
  //mint allance updated everytime mint is done
  function reduceMintAllowance(address _add) internal returns (bool){
    uint256 allowance = getMintAllowance(_add);
    if(allowance > 0){
      mintAllowance[_add] = allowance - 1;
    }
    return true;
  }

  //show allowace of address
  function getMintAllowance(address _add) public view returns (uint256){
    return mintAllowance[_add];
  }
   
  //forward to wallet
  function forwardEth() internal  returns (bool){
    _wallet.transfer(msg.value);
    return true;
  }

  //update price
  function updatePrice(uint256 _price) public  onlyOwner  returns (bool){
    price = _price ;
    return true;
  }
  //get price
  function getPrice() public view  returns (uint256){
    return price;
  }
  //update wallet
  function updateWallet(address payable wallet) public onlyOwner  returns (bool){
    _wallet = wallet;
    return true;
  }

 

}
