// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IFilteredMinterV0.sol";

/// @title Art Blocks MultiMint
/// @author @arkaydeus - SquiggleDAO
/// @notice MultiMinter to allow for bulk minting of Art Blocks projects

contract MultiMint {
  event MultiMintEvent(
    uint256 mints,
    uint256 mintPrice,
    address indexed contractAddress,
    uint256 projectId
  );

  function multiMint(
    uint256 _mints,
    uint256 _mintPrice,
    address _contractAddress,
    uint256 _projectId
  ) public payable {
    for (uint256 i = 0; i < _mints; i++) {
      IFilteredMinterV0(_contractAddress).purchaseTo{value: _mintPrice}(
        msg.sender,
        _projectId
      );
    }

    emit MultiMintEvent(_mints, _mintPrice, _contractAddress, _projectId);
  }
}
