// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Clones.sol";
import "./Address.sol";

contract SuperVaultFactory {
  using Address for address;
  using Clones for address;

  event NewSuperVaultContract(address indexed owner, address superVaultContract);

  address public base;

  ///@param _base The address of the base contract to create clones from
  constructor(address _base) {
    require(address(_base) != address(0));

    base = _base;
  }

  ///@notice Clones a new supervault instance using the simple-clone pattern 
  ///@param _initdata The init params to call the initialize function on for the new clone 
  function clone(bytes calldata _initdata) public {
    address superVaultContract = base.clone();
    superVaultContract.functionCall(_initdata);
  
    emit NewSuperVaultContract(msg.sender, superVaultContract);
  }
}
