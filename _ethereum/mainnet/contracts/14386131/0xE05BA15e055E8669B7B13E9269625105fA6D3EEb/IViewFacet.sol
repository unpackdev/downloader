// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IViewFacet {
    function getMetaNftId(address _nftAddress, uint256 _tokenId) external view returns (uint256 _metaNftId);
    function getMetaNftId(address _nftAddress, uint256 _tokenId, uint32 _version) external view returns (uint256 _metaNftId);
    function getPairInfo(uint256 _metaNftId) external view returns (
        address _nftAddress,
        uint256 _tokenId,
        uint32 _version,
        bytes32 _descriptionHash
    );
    function getCumulativeFees(address _baseToken) external view returns (uint256 _amount);
    function getBidTimeout() external view returns (uint32 _bidTimeout);
    function getUniV3ExtraRewardParam(address _tokenA, address _tokenB) external view returns (uint32 _uniExtraRewardParam);
    function getBaseFee() external view returns (uint32 _baseFeeNumerator);
    function getRoundFee() external view returns (uint32 _roundFeeNumerator);
    function getNftFee() external view returns (uint32 _nftFeeNumerator);
}
