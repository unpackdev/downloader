// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// Utils /////
import {ERC20Upgradeable} from
  "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

/// Interfaces /////
import "./IGovernanceModule.sol";

///@title  sTRSY
///@notice ERC20 contract for the staked TRSY token
///        This contract serves as a template for all sTRSY-asset tokens, which are implemented
///@dev    All sTRSY clone this contract and initialize with the corresponding name
///@dev    Governance Module has access to burn and mint
contract sTRSY is ERC20Upgradeable {
  /*//////////////////////////////////////////////////////////////
                              STORAGE
  //////////////////////////////////////////////////////////////*/

  ///@notice governanceModule which has deployed the contract
  IGovernanceModule immutable GOVERNANCE_MODULE;

  /*//////////////////////////////////////////////////////////////
                              STORAGE
  //////////////////////////////////////////////////////////////*/

  error Unauthorized();

  /*//////////////////////////////////////////////////////////////
                           INITIALIZATION
  //////////////////////////////////////////////////////////////*/

  ///@notice Constructor of the sTRSY template
  ///@param _governanceModule Address of the governance module
  constructor(address _governanceModule) {
    GOVERNANCE_MODULE = IGovernanceModule(_governanceModule);
  }

  ///@notice Initializer for state variables that are different for each clone
  ///@param  _name Name of the sTRSY token
  ///@param  _symbol Symbol of the sTRSY token
  function initialize(string memory _name, string memory _symbol) public initializer {
    __ERC20_init(_name, _symbol);
  }

  /*//////////////////////////////////////////////////////////////
                         AUTHORIZED EXTERNAL
    //////////////////////////////////////////////////////////////*/

  ///@notice Mint sTRSY token
  ///@param _to Recipient of the sTRSY
  ///@param _amount Amount to be minted
  function mint(address _to, uint256 _amount) external onlyGovernance {
    _mint(_to, _amount);
  }

  ///@notice Burn sTRSY token
  ///@param _from Address to burn token from
  ///@param _amount Amount to be burned
  function burn(address _from, uint256 _amount) external onlyGovernance {
    _burn(_from, _amount);
  }

  ///@dev Hook that makes sure any transfer of sTRSY triggers the transfer of underlying assets
  /// between
  ///     user proxies
  function _afterTokenTransfer(address _from, address _to, uint256) internal override {
    if (_from != address(0x0) && _to != address(0x0)) GOVERNANCE_MODULE.onStrsyTransfer(_from, _to);
  }

  /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

  modifier onlyGovernance() {
    if (msg.sender != address(GOVERNANCE_MODULE)) revert Unauthorized();
    _;
  }
}
