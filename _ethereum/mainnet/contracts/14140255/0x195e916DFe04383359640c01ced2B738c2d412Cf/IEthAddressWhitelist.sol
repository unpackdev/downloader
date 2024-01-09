//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IEthAddressWhitelist {
  event WhitelistStatusSet(address indexed whitelistAddress, bool indexed status);

  function initialize(
    address _owner,
    address[] memory _whitelisters
  ) external;

  function setWhitelistStatus(
    address _address,
    bool _status
  ) external;

  function isWhitelisted(address _address) external view returns(bool);
}