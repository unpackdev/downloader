// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IMarchandDeGlace {
    function gelLockedByWhale(address whale_) external view returns (uint256);
}
