// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC165.sol";

/// @title HEX Minter Receiver
/// @author Sam Presnal - Staker
/// @dev Receives shares and hearts earned from the ShareMinter
abstract contract MinterReceiver is ERC165 {
    /// @notice ERC165 ensures the minter receiver supports the interface
    /// @param interfaceId The MinterReceiver interface id
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(MinterReceiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Receives newly started stake properties
    /// @param stakeId The HEX stakeId
    /// @param supplier The reimbursement address for the supplier
    /// @param stakedHearts Hearts staked
    /// @param stakeShares Shares available
    function onSharesMinted(
        uint40 stakeId,
        address supplier,
        uint72 stakedHearts,
        uint72 stakeShares
    ) external virtual;

    /// @notice Receives newly ended stake properties
    /// @param stakeId The HEX stakeId
    /// @param heartsEarned Hearts earned from the stake
    function onEarningsMinted(uint40 stakeId, uint72 heartsEarned) external virtual;
}
