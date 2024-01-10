// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
contract SkullPunksLogic is Ownable{

  mapping(address=>uint256) mintAllowance;
  mapping(address=>bool) mintAllowanceSatus;
  mapping(uint256=>bool) editionLog;
  address payable public _wallet;
  uint256 public price;
  bool isFlashSale;
  constructor() Ownable(){
  }

  //mint called everytime signin successful in the dapp
  function initialMintAllowance(address _add,uint256 allowance) internal returns (bool){
    if(mintAllowanceSatus[_add] == false){
      mintAllowance[_add] += allowance;
      mintAllowanceSatus[_add] == true;
    }
    return true;
  }
  //mint allance updated everytime mint is done
  function updateMintAllowance(address _add) internal returns (bool){
    uint256 allowance = getFreeMint(_add);
    if(allowance > 0){
      mintAllowance[_add] -= 1;
    }
    return true;
  }

  //show allowace of address
  function getFreeMint(address _add) public view returns (uint256){
    return mintAllowance[_add];
  }
  //mint allance provision made by only admin for special cases and giveaways to the community
  function mintAllowanceProvision(address _add,uint256 allowance) public onlyOwner returns (bool){
    mintAllowance[_add] += allowance;
    return true;
  }

  //prevents multiple creation of one og edtion
  function updateEditionLog(uint256 edition) internal returns (bool){
    editionLog[edition]= true;
    return true;
  }

  //get status of og edtion
  function getEditionStatus(uint256 edition) public view  returns (bool){
    return editionLog[edition];
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

  //update wallet
  function updateFlashSale(uint256 status,uint256 _price) public onlyOwner  returns (bool){
    if(status == 0 ){
      isFlashSale=false;
    }else{
      isFlashSale=true;  
    }
    updatePrice(_price);
    return true;
  }

  function isFlash() public view returns(bool){
    return isFlashSale;
  }


}
