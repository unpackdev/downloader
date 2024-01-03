/**
 *Submitted for verification at Etherscan.io on 2020-06-29
 */

// File: localhost/contracts/Config.sol

pragma solidity ^0.7.0;

import "./HandlerBase.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract HERC20TokenIn is HandlerBase {
    using LibCache for bytes32[];
    using SafeERC20 for IERC20;

    function inject(address[] calldata tokens, uint256[] calldata amounts)
        external
        payable
    {
        require(
            tokens.length == amounts.length,
            "token and amount does not match"
        );
        address sender = cache.getSender();
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransferFrom(
                sender,
                address(this),
                amounts[i]
            );

            // Update involved token
            _updateToken(tokens[i]);
        }
    }
}
