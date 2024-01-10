// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";

library LibGetters {
    function _getMetaNftId(address _nftAddress, uint256 _tokenId) internal view returns (uint256 _metaNftId) {
        uint256[] storage pairVersions = LibAppStorage._diamondStorage().metaNftIds[_nftAddress][_tokenId];
        require(pairVersions.length > 0, "Pilgrim: Pair Not Found");
        _metaNftId = pairVersions[pairVersions.length - 1];
    }

    function _getMetaNftId(address _nftAddress, uint256 _tokenId, uint32 _version) internal view returns (uint256 _metaNftId) {
        uint256[] storage pairVersions = LibAppStorage._diamondStorage().metaNftIds[_nftAddress][_tokenId];
        require(pairVersions.length > 0, "Pilgrim: Pair Not Found");
        require(_version < pairVersions.length, "Pilgrim: Invalid Pair Version");
        _metaNftId = pairVersions[_version];
    }

    function _getPairInfo(uint256 _metaNftId) internal view returns (PairInfo storage _pairInfo) {
        _pairInfo = LibAppStorage._diamondStorage().pairs[_metaNftId];
    }

    function _getPairReserves(
        uint256 _metaNftId
    ) internal view returns (
        uint128 _baseReserve,
        uint128 _roundReserve
    ) {
        PairInfo storage pairInfo = _getPairInfo(_metaNftId);
        _baseReserve = pairInfo.actualBaseReserve + pairInfo.initBaseReserve + pairInfo.mintBaseReserve;
        _roundReserve = INITIAL_ROUNDS;
    }

    function _getBaseToken(uint256 _metaNftId) internal view returns (address _baseToken) {
        _baseToken = _getPairInfo(_metaNftId).baseToken;
    }

    function _getActualBaseReserve(uint256 _metaNftId) internal view returns (uint128 _actualBaseReserve) {
        _actualBaseReserve = _getPairInfo(_metaNftId).actualBaseReserve;
    }

    function _getUniV3ExtraRewardParam(address _tokenA, address _tokenB) internal view returns (uint32 _value) {
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        _value = LibAppStorage._diamondStorage().uniV3ExtraRewardParams[token0][token1];
    }
}
