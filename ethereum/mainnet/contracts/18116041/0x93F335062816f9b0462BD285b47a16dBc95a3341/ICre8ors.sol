// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC721Drop.sol";
import "./ILockup.sol";
import "./IERC721A.sol";
import "./ICre8ing.sol";
import "./ISubscription.sol";

/**
 ██████╗██████╗ ███████╗ █████╗  ██████╗ ██████╗ ███████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔════╝
██║     ██████╔╝█████╗  ╚█████╔╝██║   ██║██████╔╝███████╗
██║     ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗╚════██║
╚██████╗██║  ██║███████╗╚█████╔╝╚██████╔╝██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝                                                       
*/
/// @notice Interface for Cre8ors Drops contract
interface ICre8ors is IERC721Drop, IERC721A {
    /// @notice Error emitted when trying to mint more than 4444.
    error Cre8ors_4444();

    function cre8ing() external view returns (ICre8ing);

    /// @notice Getter for last minted token ID (gets next token id and subtracts 1)
    function _lastMintedTokenId() external view returns (uint256);

    /// @dev Returns `true` if `account` has been granted `role`.
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function subscription() external view returns (address);

    function setSubscription(address newSubscription) external;

    function setCre8ing(ICre8ing _cre8ing) external;

    function MINTER_ROLE() external returns (bytes32);
}
