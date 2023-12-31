// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20SnapshotUpgradeable.sol";
import "./IAlloyxVaultToken.sol";
import "./AdminUpgradeable.sol";

/**
 * @title AlloyxVaultToken
 * @notice Alloyx Vault Token
 * @author AlloyX
 */
contract AlloyxVaultToken is ERC20SnapshotUpgradeable, AdminUpgradeable {
  /**
   * @notice Initialize the contract
   * @param _name the name of the vault token
   * @param _symbol the symbol of the vault token
   */
  function initialize(string calldata _name, string calldata _symbol) external initializer {
    __AdminUpgradeable_init(msg.sender);
    __ERC20_init(_name, _symbol);
    __ERC20Snapshot_init();
  }

  /**
   * @notice Mint Dura
   * @param _tokenToMint Number of dura to mint
   * @param _address The address to mint to
   */

  function mint(uint256 _tokenToMint, address _address) external onlyAdmin {
    _mint(_address, _tokenToMint);
  }

  /**
   * @notice Burn Dura
   * @param _tokenBurn Number of dura to burn
   * @param _address The address to burn from
   */
  function burn(uint256 _tokenBurn, address _address) external onlyAdmin {
    _burn(_address, _tokenBurn);
  }

  function snapshot() external onlyAdmin returns (uint256) {
    return _snapshot();
  }

  /**
   * @dev Being non transferrable, the vault token does not implement any of the
   * standard ERC20 functions for transfer.
   **/
  function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
    _recipient;
    _amount;
    revert("TRANSFER_NOT_SUPPORTED");
  }

  function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual override returns (bool) {
    _sender;
    _recipient;
    _amount;
    revert("TRANSFER_NOT_SUPPORTED");
  }
}
