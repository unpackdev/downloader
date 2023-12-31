// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IVotes.sol";

/**
 * @notice esMet interface
 */
interface IEsMet {
    function MET() external view returns (IVotes _met);
}
