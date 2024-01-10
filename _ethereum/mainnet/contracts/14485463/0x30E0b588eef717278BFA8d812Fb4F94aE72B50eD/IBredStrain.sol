//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IStrainLike.sol";

interface IBredStrain is IStrainLike {
    function bredSupply() external returns (uint256);

    function breedMint(
        address account,
        uint256 seedId,
        CoreTraits memory traits
    ) external;
}
