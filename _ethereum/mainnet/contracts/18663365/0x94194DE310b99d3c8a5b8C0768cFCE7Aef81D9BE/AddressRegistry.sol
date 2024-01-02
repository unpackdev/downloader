// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// Utils
import "./Ownable.sol";

// Interfaces
import "./IOracle.sol";
import "./IGovernanceModule.sol";

///@title AddressRegistry contract
///@notice Handle state and logic for external authorized call (mainly keeper) and the oracle module
abstract contract AddressRegistry is Ownable {
  /*//////////////////////////////////////////////////////////////
                            STORAGE
  //////////////////////////////////////////////////////////////*/

  ///@notice Address of the oracle module
  IOracle public oracleModule;

  ///@notice Governance Registry contract address interface
  IGovernanceModule public immutable GOVERNANCE_MODULE;

  address public RELAYER;

  /*//////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/

  event OracleModuleUpdated(address indexed oracleModule);

  /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(address _govModule, address _relayer) {
    GOVERNANCE_MODULE = IGovernanceModule(_govModule);
    RELAYER = _relayer;
  }

  /*//////////////////////////////////////////////////////////////
                            ACCESS
  //////////////////////////////////////////////////////////////*/

  function setRelayer(address _relayer) external onlyOwner {
    RELAYER = _relayer;
  }

  ///@notice Set the oracle address
  function setOracleModule(address _oracle) public onlyOwner {
    oracleModule = IOracle(_oracle);
    emit OracleModuleUpdated(_oracle);
  }
}
