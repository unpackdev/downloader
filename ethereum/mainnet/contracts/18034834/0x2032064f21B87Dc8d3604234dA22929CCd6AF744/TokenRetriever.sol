// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ITokenRetriever.sol";

/// @title TokenRetriever
/// @dev Allows tokens to be retrieved from a contract preventing them from being locked forever
/// @author HFB - <frank@cryptopia.com>
abstract contract TokenRetriever is ITokenRetriever {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Extracts tokens from the contract
    /// @param tokenContract The address of ERC20 compatible token
    function retrieveTokens(IERC20Upgradeable tokenContract) 
        override virtual public 
    {
        tokenContract.safeTransfer(
            msg.sender, tokenContract.balanceOf(address(this)));
    }
}