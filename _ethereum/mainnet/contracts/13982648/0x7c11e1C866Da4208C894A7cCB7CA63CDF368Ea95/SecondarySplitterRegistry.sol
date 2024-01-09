// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AdminControl.sol";
import "./RemixClubSecondarySplitter.sol";
import "./Clones.sol";

contract SecondarySplitterRegistry is AdminControl {
  address payable public immutable SPLITTER_IMPLEMENTATION_ADDRESS;

  mapping(address => address) public splitters;

  event SplitterRegistered (
    address splitterAddress,
    address tokenAddress,
    address[] recipients,
    uint256[] shares
  );

  constructor(
    address payable _SPLITTER_IMPLEMENTATION_ADDRESS
  ) {
    SPLITTER_IMPLEMENTATION_ADDRESS = _SPLITTER_IMPLEMENTATION_ADDRESS;
  }

  function cloneSplitter (
    address _tokenAddress,
    address[] calldata _recipients,
    uint256[] calldata _shares
  ) public onlyAdmin returns (address splitterAddress) {
      splitterAddress = Clones.clone(SPLITTER_IMPLEMENTATION_ADDRESS);
      IRemixClubSecondarySplitter(splitterAddress).initialize(_recipients, _shares);
      splitters[_tokenAddress] = splitterAddress;

      emit SplitterRegistered(splitterAddress, _tokenAddress, _recipients, _shares);
  }

  function registerExistingSplitter (
    address _tokenAddress,
    address _splitterAddress,
    address[] calldata _recipients,
    uint256[] calldata _shares
  ) public onlyAdmin {
    splitters[_tokenAddress] = _splitterAddress;

    emit SplitterRegistered(_splitterAddress, _tokenAddress, _recipients, _shares);
  }
}
