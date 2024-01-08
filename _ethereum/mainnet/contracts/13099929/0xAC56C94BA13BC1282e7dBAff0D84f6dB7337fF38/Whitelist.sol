pragma solidity ^0.6.12;


import "./Ownable.sol";
import "./AccessControl.sol";


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, AccessControl {
  bytes32 public constant ROLE_WHITELISTED = keccak256("WHITELIST");

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    require(hasRole(ROLE_WHITELISTED, _operator));
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   */
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    grantRole(ROLE_WHITELISTED, _operator);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(ROLE_WHITELISTED, _operator);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   */
  function addAddressesToWhitelist(address[] memory _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   */
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    revokeRole(ROLE_WHITELISTED, _operator);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   */
  function removeAddressesFromWhitelist(address[] memory _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}
