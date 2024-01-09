//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";

abstract contract ERC721Stakable is ERC721Upgradeable, OwnableUpgradeable {
  address public stakingAddress;

  function __ERC721Stakable_init(string memory name_, string memory symbol_)
    internal
    initializer
  {
    __ERC721_init(name_, symbol_);
    __Ownable_init_unchained();
  }

  function __ERC721Stakable_init_unchained() internal initializer {}

  function setStakingAddress(address _stakingAddress) external onlyOwner {
    stakingAddress = _stakingAddress;
  }

  /*
  OVERRIDE FUNCTIONS
  */

  /**
   * @dev allow staking contract to transfer on behalf of owner
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    address sender = _msgSender();
    require(
      _isApprovedOrOwner(sender, tokenId) || sender == stakingAddress,
      "ERC721: transfer caller is not owner nor approved"
    );

    _transfer(from, to, tokenId);
  }
}
