//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Pausable.sol";



abstract contract PrometheusPassPausable is Ownable, ERC721Pausable {

  function pause() public virtual onlyOwner {
    _pause();
  }

  function unpause() public virtual onlyOwner {
    _unpause();
  }

}
