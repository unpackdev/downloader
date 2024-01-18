// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ICurve.sol";
import "./ILSSVMPair.sol";
import "./IERC721Enumerable.sol";

interface ICollectionswap is IERC721, IERC721Enumerable {
    struct LPTokenParams721ETH {
        address nftAddress;
        address bondingCurveAddress;
        address payable poolAddress;
        uint96 fee;
        uint128 delta;
        uint128 initialSpotPrice;
        uint256 initialPoolBalance;
        uint256 initialNFTIDsLength;
    }

    /**
     * @notice Create a sudoswap pair and issue an LP token for this pair to 
     * `tx.origin`.
     * 
     * @param _nft The NFT collection which the pair will interact with
     * @param _bondingCurve The bonding curve which the pair will use to 
     * calculate prices
     * @param _delta The delta of the curve
     * @param _fee  The fee of the curve
     * @param _spotPrice The spot price of the curve
     * @param _initialNFTIDs The tokenIds of the NFTs to add to the pair
     * 
     * @return newPair The sudoswap pair created
     * @return newTokenId The tokenId of the newly issued LP token
     */
    function createDirectPairETH(
        address _user,
        IERC721 _nft,
        ICurve _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs        
    ) external payable returns (ILSSVMPairETH newPair, uint256 newTokenId);

    function setCanSpecifySender(address user, bool canSet) external;

    function useLPTokenToDestroyDirectPairETH(address user, uint256 _lpTokenId) external;

    /**
     * @return poolParams the parameters of the pool matching `tokenId`.
     */
    function viewPoolParams(uint256 tokenId)
        external
        view
        returns (LPTokenParams721ETH memory poolParams);

    /**
     * @param tokenId The tokenId of the pool to validate
     * @param nftAddress The address of the NFT collection which the pool 
     * should accept
     * @param bondingCurveAddress The address of the bonding curve the pool
     * should be using
     * @param fee The maximum fee the pool should have
     * @param delta The maximum delta the pool should have
     * 
     * @return true iff the pool specified by `tokenId` has the correct
     * NFT address, bonding curve address, and has fee and delta == `fee` and
     * `delta`, respectively
     */
    function validatePoolParamsLte(
        uint256 tokenId,
        address nftAddress,
        address bondingCurveAddress,
        uint96 fee,
        uint128 delta
    )
        external
        view
        returns (bool);

    /**
     * @param tokenId The tokenId of the pool to validate
     * @param nftAddress The address of the NFT collection which the pool 
     * should accept
     * @param bondingCurveAddress The address of the bonding curve the pool
     * should be using
     * @param fee The fee the pool should have
     * @param delta The delta the pool should have
     * 
     * @return true iff the pool specified by `tokenId` has the correct
     * NFT address, bonding curve address, and has fee and delta <= `fee` and
     * `delta`, respectively
     */
    function validatePoolParamsEq(
        uint256 tokenId,
        address nftAddress,
        address bondingCurveAddress,
        uint96 fee,
        uint128 delta
    )
        external
        view
        returns (bool);
}
