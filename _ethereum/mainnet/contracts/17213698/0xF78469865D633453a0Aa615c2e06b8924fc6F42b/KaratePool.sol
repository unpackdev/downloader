//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC20PresetMinterPauser.sol";
import "./ERC20Snapshot.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IAccessControl.sol";
import "./Signatures.sol";

contract KaratePool {

   bool private allowanceSet;
   IERC20 private token;
   Ownable private storageContract;

   constructor(address tokenAddress, address storageContractAddress) {
       token = IERC20(tokenAddress);
       storageContract = Ownable(storageContractAddress);
   }

   function daoContract() internal view returns (address owner) {
       return storageContract.owner();
   }

   function createAllowance(address claimContract) external {
       require(msg.sender == daoContract(), 'Only active DAO contract can call');
       require(!allowanceSet, "Allowance already set");
       token.approve(claimContract, token.balanceOf(address(this)));
       allowanceSet = true;
   }
}

