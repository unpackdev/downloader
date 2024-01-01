// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

import "./PresaleMintable.sol";
import "./IPresaleMintableMulti.sol";

abstract contract PresaleMintableMulti is PresaleMintable, IPresaleMintableMulti {
  function presaleMint(uint256 _id, address _receiver, uint256 _amount) external payable virtual override onlySecondaryMinter {}
}