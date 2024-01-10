//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IStrainLike.sol";

interface IStrain is IStrainLike {
    function genesisSupply() external returns (uint256);

    function maxGenesisSupply() external returns (uint256);
}
