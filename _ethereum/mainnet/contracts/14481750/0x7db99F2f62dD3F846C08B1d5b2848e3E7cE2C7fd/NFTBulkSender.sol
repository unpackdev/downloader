// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC721.sol";
import "./OwnableUpgradeable.sol";

contract NFTBulkSender is OwnableUpgradeable {
  function __NFTBulkSender_init() external initializer {
    __Ownable_init();
  }

  function fBulkTransfer(
    address _pNft,
    address _pTo,
    uint256[] memory _pIds
  ) external {
    require(_pIds.length > 0, "NFTBulkSender:01");

    for (uint i = 0; i < _pIds.length; i++) {
      IERC721(_pNft).transferFrom(_msgSender(), _pTo, _pIds[i]);
    }
  }
}
