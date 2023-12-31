// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Governor.sol";
import "./ERC20Votes.sol";
import "./Math.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotes is Governor {
    ERC20Votes public immutable token;

    constructor(ERC20Votes tokenAddress) {
        token = tokenAddress;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {IGovernor-getVotes}).
     */
    function getVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return token.getPastVotes(account, blockNumber);
    }
}
