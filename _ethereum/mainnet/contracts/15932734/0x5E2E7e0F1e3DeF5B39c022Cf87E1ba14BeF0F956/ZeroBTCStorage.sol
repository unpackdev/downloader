// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ERC4626Storage.sol";
import "./GovernableStorage.sol";
import "./ModuleStateCoder.sol";
import "./GlobalStateCoder.sol";
import "./LoanRecordCoder.sol";

contract ZeroBTCStorage is ERC4626Storage, GovernableStorage {
  GlobalState internal _state;

  mapping(address => ModuleState) internal _moduleFees;

  // Maps loanId => LoanRecord
  mapping(uint256 => LoanRecord) internal _outstandingLoans;

  // maps wallets => whether they can call earn
  mapping(address => bool) internal _isHarvester;
}
