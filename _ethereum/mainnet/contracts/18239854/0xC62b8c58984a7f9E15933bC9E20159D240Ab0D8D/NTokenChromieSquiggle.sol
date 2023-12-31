// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./NToken.sol";
import "./IPool.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Errors.sol";
import "./IXTokenType.sol";
import "./ApeStakingLogic.sol";
import "./INTokenApeStaking.sol";
import "./ApeCoinStaking.sol";
import "./INToken.sol";
import "./IRewardController.sol";
import "./DataTypes.sol";

/**
 * @title NTokenChromieSquiggle
 *
 * @notice Implementation of the NTokenChromieSquiggle for the ParaSpace protocol
 */
contract NTokenChromieSquiggle is NToken {
    // there is no gas cheap way to dynamic query the max tokenId of Chromie Squiggles by Snowfro
    // and since Chromie Squiggles by Snowfro also announced pause minting forever
    // so we can use current max tokenId as the endTokenId allowed in our market.
    uint256 private immutable startTokenId;
    uint256 private immutable endTokenId;

    /**
     * @dev Constructor.
     * @param pool The address of the Pool contract
     */
    constructor(
        IPool pool,
        address delegateRegistry,
        uint256 _startTokenId,
        uint256 _endTokenId
    ) NToken(pool, false, delegateRegistry) {
        startTokenId = _startTokenId;
        endTokenId = _endTokenId;
    }

    /// @inheritdoc INToken
    function mint(
        address onBehalfOf,
        DataTypes.ERC721SupplyParams[] calldata tokenData
    ) external virtual override onlyPool nonReentrant returns (uint64, uint64) {
        for (uint256 index = 0; index < tokenData.length; index++) {
            uint256 tokenId = tokenData[index].tokenId;
            require(
                tokenId >= startTokenId && tokenId <= endTokenId,
                Errors.INVALID_TOKEN_ID
            );
        }
        return _mintMultiple(onBehalfOf, tokenData);
    }

    function getXTokenType() external pure override returns (XTokenType) {
        return XTokenType.NTokenChromieSquiggle;
    }
}
