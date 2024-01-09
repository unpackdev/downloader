// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Clones.sol";
import "./FixedPrice.sol";
import "./OwnableUpgradeable.sol";
import "./IFixedPriceDeployer.sol";

contract FixedPriceDeployer is IFixedPriceDeployer, OwnableUpgradeable {
  address public immutable FIXEDPRICE_IMPL;

  constructor() {
    __Ownable_init(msg.sender);
    FIXEDPRICE_IMPL = address(new FixedPrice());
  }

  function deployFixedPrice(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _timelock,
    address _erc20,
    address payable _platform,
    address payable _receivingAddress,
    uint256 _rate,
    uint256 _maxSupply,
    uint256 _platformRate
  ) public override onlyOwner returns (address) {
    address clone = Clones.clone(FIXEDPRICE_IMPL);

    FixedPrice(clone).initialize(
      _name,
      _symbol,
      _bURI,
      _timelock,
      _erc20,
      _platform,
      _receivingAddress,
      _rate,
      _maxSupply,
      _platformRate
    );
    return clone;
  }
}
