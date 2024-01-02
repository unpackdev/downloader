// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./WhitelistUpgradeable.sol";
import "./IFarmToken.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

error NotWhitelisted();
error AlreadyWhitelisted();
error ZeroAddress();

contract FarmManagerUpgradable is Initializable, WhitelistUpgradeable, UUPSUpgradeable {
  IFarmToken token;

  function initialize() public virtual initializer {
    __UUPSUpgradeable_init();
    __AccessControl_init();
    _setupRole(ADMIN_ROLE, msg.sender);
  }

  function createInvestments(
    address[] calldata _investors,
    uint256[] calldata _amounts
  ) external payable onlyWhitelistAdmin {
    address tknAddr = address(token);
    _requireNonZero(tknAddr);
    uint length = _investors.length;
    for (uint i; i < length;) {
      if (!this.isWhitelisted(tknAddr, _investors[i]))
        revert NotWhitelisted();

      token.mint(_investors[i], _amounts[i]);
      unchecked { ++i; }
    }
  }

  function bulkWhitelist(
    address[] calldata _investors
  ) external payable onlyWhitelistAdmin {
    address tknAddr = address(token);
    _requireNonZero(tknAddr);
    uint length = _investors.length;
    for (uint i; i < length;) {
      if(this.isWhitelisted(tknAddr, _investors[i]))
        revert AlreadyWhitelisted();

      addToWhitelist(tknAddr, _investors[i]);
      unchecked { ++i; }
    }
  }

  function revokeInvestments(
    address[] calldata _investors,
    uint256[] calldata _amounts,
    bool _removeWhitelist
  ) external payable onlyWhitelistAdmin {
    address tknAddr = address(token);
    _requireNonZero(tknAddr);
    uint length = _investors.length;
    for (uint i; i < length;) {
      if (!this.isWhitelisted(tknAddr, _investors[i]))
        revert NotWhitelisted();

      if(_removeWhitelist) {
        removeFromWhitelist(tknAddr, _investors[i]);
      }
      uint256 investment = token.balanceOf(_investors[i]);
      if (investment > 0 && investment >= _amounts[i]) {
        token.burn(_investors[i], _amounts[i]); // burn investment of this user
      }
      unchecked { ++i; }
    }
  }

  function setFarmToken(address _token) external payable onlyAdmin {
    _requireNonZero(_token);
    token = IFarmToken(_token);
  }

  function withdrawEth() external payable onlyAdmin {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
  }

  function _requireNonZero(address _adr) internal pure {
    if(_adr == address(0))
      revert ZeroAddress();
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal virtual override onlyAdmin{}

  function _version() external view returns (string memory){
    return '0.0.1';
  }

}
