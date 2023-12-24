// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "./IERC20Upgradeable.sol";

/// @title TokenRetriever
/// @dev Allows tokens to be retrieved from a contract preventing them from being locked forever
/// @author HFB - <frank@cryptopia.com>
interface ITokenRetriever {

    /// @dev Extracts tokens from the contract
    /// @param tokenContract The address of ERC20 compatible token
    function retrieveTokens(IERC20Upgradeable tokenContract) external;
}