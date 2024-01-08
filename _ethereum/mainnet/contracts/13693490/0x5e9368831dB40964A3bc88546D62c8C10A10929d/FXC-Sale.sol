// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/****************************************
 * @author: @antontheswan1                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./FXC.sol";
import "./Delegated.sol";
import "./genesis.sol";
import "./token-types.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

contract FXCSale is Delegated, PaymentSplitter {
  using Strings for uint;

  FXC public tokenContract;

  struct ContractBalance {
    address addr;
    uint balance;
  }

  uint public MAX_ORDER  = 20;
  uint public MAX_SUPPLY = 6000;
  uint public PRICE      = 0.06 ether;

  bool public isActive   = false;
  uint public amountSold = 0;

  address[2] public sourceContracts;

  address[] private payees = [
    0x172c418b3bDA2Ad1226287376051f5749567d568,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];

  mapping (address => uint[2]) public balanceMap;

  uint[] private splits = [
    90,
    10
  ];

  constructor(address[2] memory _contracts) PaymentSplitter( payees, splits ) {
        sourceContracts = _contracts;
  }

  //external payable
  fallback() external payable {}

  function mint( uint[2] calldata quantityList ) external payable {
    require( isActive,                      "Sale is not active"        );

    ContractBalance[3] memory holdings = checkHoldings(msg.sender);

    if (quantityList[0] > 0) {
      uint balanceAfterSale = quantityList[0] + balanceMap[msg.sender][0];
      require(
        balanceAfterSale <= holdings[0].balance &&
        balanceAfterSale <= holdings[1].balance,
        "This wallet does not hold enough Pixel and Genesis Foxxies to mint the requested amount of FXC tokens."
      );
    } else if (quantityList[1] > 0) {
      uint balanceAfterSale = quantityList[1] + balanceMap[msg.sender][1];
      require(
        balanceAfterSale <= holdings[0].balance + holdings[1].balance,
        "This wallet does not hold enough Pixel or Genesis Foxxies to mint the requested amount of FXC tokens."
      );
    } else {
      revert("The selected token type is not valid.");
    }

    uint totalQuantity = quantityList[0] + quantityList[1];

    require( totalQuantity <= MAX_ORDER,         "Order too big"             );
    require( msg.value >= PRICE * totalQuantity, "Ether sent is not correct" );
    require( amountSold + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i = 0; i < quantityList[0]; i++) {
      tokenContract.mint(msg.sender, TOKEN_TYPES.GOLD);
      balanceMap[msg.sender][0]++;
    }
    
    for(uint i = 0; i < quantityList[1]; i++) {
      tokenContract.mint(msg.sender, TOKEN_TYPES.SILVER);
      balanceMap[msg.sender][1]++;
    }
  }

  //onlyDelegates
  function mintTo(uint[] calldata quantity, address[] calldata recipient, TOKEN_TYPES _tokenType) external payable onlyDelegates {
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity = 0;
    for(uint i = 0; i < quantity.length; i++){
      totalQuantity += quantity[i];
    }
    require( amountSold + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    delete totalQuantity;

    for(uint i = 0; i < recipient.length; i++) {
      for(uint j = 0; j < quantity[i]; j++) {
        tokenContract.mint(recipient[i], _tokenType);
      }
    }
  }

  function setActive(bool isActive_) external onlyDelegates {
    require( isActive != isActive_, "New value matches old" );
    isActive = isActive_;
  }

  function setMaxOrder(uint maxOrder) external onlyDelegates {
    require( MAX_ORDER != maxOrder, "New value matches old" );
    MAX_ORDER = maxOrder;
  }

  function setPrice(uint price) external onlyDelegates {
    require( PRICE != price, "New value matches old" );
    PRICE = price;
  }

  //onlyOwner
  function setMaxSupply(uint maxSupply) external onlyOwner {
    require( MAX_SUPPLY != maxSupply, "New value matches old" );
    require( maxSupply >= amountSold, "Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }

  function setTokenContract(FXC _tokenContract) external onlyOwner {
      tokenContract = _tokenContract;
  }

  //public
  function checkHoldings(address _addr) public view returns(ContractBalance[3] memory) {
      ContractBalance[3] memory results;
      for (uint i = 0; i < 2; i++) {
        FOXXIES callee = FOXXIES(sourceContracts[i]);
        results[i] = ContractBalance(
          sourceContracts[i],
          callee.balanceOf(_addr)
        );
      }
      results[2] = ContractBalance(
          address(tokenContract),
          tokenContract.balanceOf(_addr)
        );
      return results;
  }
}