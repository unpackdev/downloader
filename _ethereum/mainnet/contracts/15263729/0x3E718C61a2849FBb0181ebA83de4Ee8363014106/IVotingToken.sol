// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import "./ERC20Votes.sol";

/// @title Interface for voting tokens (see https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Votes).
interface IVotingToken is IERC20, IERC20Permit, IVotes {

}
