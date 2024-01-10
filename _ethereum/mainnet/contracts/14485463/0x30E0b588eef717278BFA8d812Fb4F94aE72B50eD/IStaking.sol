//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IStaking {
    function ownerOf(uint256 strainId, uint8 strainType)
        external
        view
        returns (address);

    function burn(address account, uint256 strainId) external;
}
