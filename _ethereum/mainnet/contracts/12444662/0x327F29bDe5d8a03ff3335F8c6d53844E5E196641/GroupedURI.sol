//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * This contract allows to group tokenIds
 * Each group has its own baseURI
 *
 * This will allow to decentralize the tokens in batches, uploading them on IPFS or arweave
 * in a directory, and then set the directory uri as baseURI for this group of tokens
 */
contract GroupedURI {
    event GroupURIBatchUpdate(uint256[] groupIds);
    event TokenGroupBatchUpdate(uint256[] tokenIds, uint256[] groupIds);

    uint256 public currentGroupId;
    mapping(uint256 => string) public tokenGroupsURIs;
    mapping(uint256 => uint256) public tokenIdToGroupId;

    function __GroupedURI_init(string memory firstGroupURI) internal {
        require(bytes(firstGroupURI).length > 0, 'Invalid URI');

        // init tokenGroupsURIs
        currentGroupId = 1;
        tokenGroupsURIs[1] = firstGroupURI;
    }

    /**
     * @dev Function to link id with currentGroupId
     */
    function _addIdToCurrentGroup(uint256 id) internal {
        tokenIdToGroupId[id] = currentGroupId;
    }

    /**
     * @dev Function to query the baseURI for a given id
     */
    function _getIdGroupURI(uint256 id) internal view returns (string memory) {
        return tokenGroupsURIs[tokenIdToGroupId[id]];
    }

    /**
     * @dev Function to increment group id and set current and next base URI
     */
    function _setNnextGroup(
        string memory currentGroupNewURI,
        string memory nextGroupBaseURI
    ) internal {
        require(bytes(nextGroupBaseURI).length > 0, 'Invalid URI');

        uint256 currentGroupId_ = currentGroupId;

        if (bytes(currentGroupNewURI).length > 0) {
            tokenGroupsURIs[currentGroupId_] = currentGroupNewURI;
        }

        // initiate new group
        currentGroupId_++;
        tokenGroupsURIs[currentGroupId_] = nextGroupBaseURI;

        // set new group id
        currentGroupId = currentGroupId_;
    }

    /**
     * @dev Function to change multiple tokenIds tokenGroupsURIs
     */
    function _setIdGroupIdBatch(uint256[] memory ids, uint256[] memory groupIds)
        internal
    {
        require(ids.length == groupIds.length, 'Length mismatch');
        for (uint256 i; i < ids.length; i++) {
            tokenIdToGroupId[ids[i]] = groupIds[i];
        }

        emit TokenGroupBatchUpdate(ids, groupIds);
    }

    /**
     * @dev Function to change multiple tokenGroupsURIs uris
     */
    function _setGroupURIBatch(uint256[] memory groupIds, string[] memory uris)
        internal
    {
        require(groupIds.length == uris.length, 'Length mismatch');
        for (uint256 i; i < groupIds.length; i++) {
            tokenGroupsURIs[groupIds[i]] = uris[i];
        }

        emit GroupURIBatchUpdate(groupIds);
    }
}
