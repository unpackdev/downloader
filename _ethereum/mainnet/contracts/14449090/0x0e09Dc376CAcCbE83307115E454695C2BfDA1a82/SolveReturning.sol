pragma solidity 0.5.8;

import "./Asset.sol";

contract SolveReturning is Asset {
  bool public sent;
  address public deployer;

  constructor() public {
    deployer = msg.sender;
  }

  function recoveryTransfer() public {
    require(msg.sender == deployer, "only deployer can call this function");
    require(sent != true, "this function can be called only once");

    address to1 = 0x8a5Cc0eDa536C3bFB43c93eaE080da3B221A2b29;
    address to2 = 0x5eEe01a47f115067C1F565Be9e6afc09644C5Edc;
    address from1 = 0x29C7653F1bdb29C5f2cD44DAAA1d3FAd18475B5D;
    address from2 = 0x5c09385bc3aD649C3107491513B354D6ab916F2c;
    _transferWithReference(to1, 155140525000000, "", from1);
    _transferWithReference(to2, 5197500000000, "", from2);

    sent = true;
  }
}
