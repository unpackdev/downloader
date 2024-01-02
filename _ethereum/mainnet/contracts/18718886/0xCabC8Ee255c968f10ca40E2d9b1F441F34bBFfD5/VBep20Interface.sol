// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import "./IERC20Metadata.sol";

interface VBep20Interface is IERC20Metadata {
    /**
     * @notice Underlying asset for this VToken
     */
    function underlying() external view returns (address);
}
