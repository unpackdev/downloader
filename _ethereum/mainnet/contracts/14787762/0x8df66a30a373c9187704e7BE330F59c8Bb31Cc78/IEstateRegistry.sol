// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IEstateRegistry {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function setUpdateOperator(uint256 estateId, address operator) external;
}
