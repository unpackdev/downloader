// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./IHarvestableStrategy.sol";

interface ICrvStrategy is IHarvestableStrategy {
    function gauge() external pure returns (address);

    function voter() external pure returns (address);
}
