//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICollectionMint {
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external;
}
