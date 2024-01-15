// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./Edwone.sol";

contract CloneableSanctuary {
  address private immutable controller;
  address internal immutable owner;
  Edwone internal immutable edwone;

  constructor(address _controller, address _owner, Edwone _edwone) {
    controller = _controller;
    owner = _owner;
    edwone = _edwone;
  }

  function init() public {
    edwone.setApprovalForAll(controller, true);
    edwone.setApprovalForAll(owner, true);
  }

  function onERC721Received(
      address operator,
      address,
      uint256,
      bytes calldata
  ) external view returns (bytes4) {
    require(operator == controller || operator != edwone.owner(), "Sanctuary: do not disturb The Worm.");
    return 0x150b7a02;
  }
}