// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./IViewFacet.sol";
import "./LibGetters.sol";

contract ViewFacet is IViewFacet {
    AppStorage internal s;

    /// @notice Get the MetaNFT ID of the PilgrimPair with the given NFT address & ID
    ///
    /// @param  _nftAddress     ERC-721 contract address
    /// @param  _tokenId        NFT ID
    /// @return _metaNftId      MetaNFT ID
    ///
    function getMetaNftId(address _nftAddress, uint256 _tokenId) external view override returns (uint256 _metaNftId) {
        _metaNftId = LibGetters._getMetaNftId(_nftAddress, _tokenId);
    }

    /// @notice Get the MetaNFT ID of the PilgrimPair with the given NFT address & ID & version
    ///
    /// @param  _nftAddress     ERC-721 contract address
    /// @param  _tokenId        NFT ID
    /// @param  _version        PilgrimPair version
    /// @return _metaNftId      MetaNFT ID
    ///
    function getMetaNftId(address _nftAddress, uint256 _tokenId, uint32 _version) external view override returns (uint256 _metaNftId) {
        _metaNftId = LibGetters._getMetaNftId(_nftAddress, _tokenId, _version);
    }

    /// @notice Get the PilgrimPair info
    ///
    /// @param  _metaNftId          MetaNFT ID
    /// @return _nftAddress         ERC-721 contract address
    /// @return _tokenId            NFT ID
    /// @return _version            PilgrimPair version
    /// @return _descriptionHash    Pair description IPFS hash
    ///
    function getPairInfo(uint256 _metaNftId) external view override returns (
        address _nftAddress,
        uint256 _tokenId,
        uint32 _version,
        bytes32 _descriptionHash
    ) {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        _nftAddress = pairInfo.nftAddress;
        _tokenId = pairInfo.tokenId;
        _version = pairInfo.version;
        _descriptionHash = pairInfo.descriptionHash;
    }

    /// @notice Get the amount of cumulative fees of the base token
    ///
    /// @param  _baseToken  Base token address
    /// @return _amount     The amount of fees
    ///
    function getCumulativeFees(address _baseToken) public view override returns (uint256 _amount) {
        _amount = s.cumulativeFees[_baseToken];
    }

    /// @notice Get the timeout of NFT/MetaNFT bid
    ///
    /// @return _bidTimeout     NFT/MetaNFT bid timeout in seconds
    ///
    function getBidTimeout() external view override returns (uint32 _bidTimeout) {
        _bidTimeout = s.bidTimeout;
    }

    /// @notice Get the extra reward paramter of UniV3Pos NFT
    ///
    /// @return _uniExtraRewardParam    UniV3Pos Extra reward parameter
    ///
    function getUniV3ExtraRewardParam(address _tokenA, address _tokenB) external view override returns (uint32 _uniExtraRewardParam) {
        _uniExtraRewardParam = LibGetters._getUniV3ExtraRewardParam(_tokenA, _tokenB);
    }

    /// @notice Get the base fee numerator
    ///
    /// @return _baseFeeNumerator   Base fee numerator
    ///
    function getBaseFee() external view override returns (uint32 _baseFeeNumerator) {
        _baseFeeNumerator = s.baseFeeNumerator;
    }

    /// @notice Get the round fee numerator
    ///
    /// @return _roundFeeNumerator   Round fee numerator
    ///
    function getRoundFee() external view override returns (uint32 _roundFeeNumerator) {
        _roundFeeNumerator = s.roundFeeNumerator;
    }

    /// @notice Get the NFT/metaNFT fee numerator
    ///
    /// @return _nftFeeNumerator   NFT/metaNFT fee numerator
    ///
    function getNftFee() external view override returns (uint32 _nftFeeNumerator) {
        _nftFeeNumerator = s.nftFeeNumerator;
    }
}
