// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Clones.sol";
import "./NFTBase.sol";
import "./OwnableUpgradeable.sol";
import "./INFTBaseDeployer.sol";

contract NFTBaseDeployer is INFTBaseDeployer, OwnableUpgradeable {
  address public immutable NFTBASE_IMPL;

  constructor() {
    __Ownable_init(msg.sender);
    NFTBASE_IMPL = address(new NFTBase());
  }

  function deployNFTBase(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _timelock,
    address _erc721
  ) public override onlyOwner returns (address) {
    address clone = Clones.clone(NFTBASE_IMPL);

    NFTBase(clone).initialize(_name, _symbol, _bURI, _timelock, _erc721);
    return clone;
  }
}
