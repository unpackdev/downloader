// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./Initializable.sol";
import "./TaggrFactoryBase.sol";
import "./TaggrLazy721.sol";

contract TaggrFactoryLazy721 is Initializable, TaggrFactoryBase {
  bool internal _init;
  function initialize(address initiator) public initializer {
    _nftTemplate = address(new TaggrLazy721());
    _initialize(initiator);
    _init = true;
  }
}
