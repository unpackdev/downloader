// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import "./EIP165.sol";
import "./OnlyStrategy.sol";
import "./IWithRewards.sol";
import "./IAdapter.sol";

/// @notice Abstract base for adapters that have rewards
contract WithRewards is EIP165, OnlyStrategy {
    function rewardTokens() external view virtual returns (address[] memory) {}

    function claim() public virtual onlyStrategy returns (bool) {}

    /*//////////////////////////////////////////////////////////////
                      EIP-165 LOGIC
  //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IWithRewards).interfaceId ||
            interfaceId == type(IAdapter).interfaceId;
    }
}
