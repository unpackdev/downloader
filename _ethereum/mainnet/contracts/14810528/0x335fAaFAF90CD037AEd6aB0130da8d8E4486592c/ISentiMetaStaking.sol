// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ISentiMetaStaking {
    struct TokenStake {
        uint48 timestamp;
        uint96 tokenId;
    }

    function stake(uint96 tokenId_, address projectAddress_) external;

    function unstake(uint96 tokenId_) external;

    function stakeMultiple(uint96[] calldata tokenIds_, address[] calldata projectAddresss_) external;

    function unstakeMultiple(uint96[] calldata tokenIds_) external;

    function getCountByProjectAddress(address projectAddress_) external view returns (uint256);

    function getTokenIdByProjectAddressAndIndex(address projectAddress_, uint96 index_) external view returns (uint256);

    function getProjectAddressByTokenId(uint96 tokenId_) external view returns (address);

    function getProjectAddressesByTokenIds(uint96[] calldata tokenIds_) external view returns (address[] memory);

    function checkTokenIdsStaked(uint96[] calldata tokenIds_) external view returns (bool[] memory);

    function getStakedTokenIdsOfOwner(address owner_) external view returns (uint256[] memory);

    /* CONTRACT HELPER METHODS */
    function checkTokenIdStakedToProject(uint96 tokenId_, address projectAddress_) external view returns (bool);

    function getStakedTokenById(uint96 tokenId_) external view returns (TokenStake memory);
}