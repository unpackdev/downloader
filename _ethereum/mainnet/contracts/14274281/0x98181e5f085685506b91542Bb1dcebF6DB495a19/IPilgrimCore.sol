//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPilgrimCore {
    function list(
        address _nftAddress,
        uint256 _tokenId,
        uint128 _initPrice,
        address _baseToken,
        string[] calldata _tags,
        bytes32 _descriptionHash
    ) external;

    function getMetaNftId(address _nftAddress, uint256 _tokenId) external view returns (uint256 _metaNftId);
}
