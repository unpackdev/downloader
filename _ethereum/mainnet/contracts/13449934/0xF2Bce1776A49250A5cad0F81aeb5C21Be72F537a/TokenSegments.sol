// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

/*
 * Manage different baseURIs per tokenSegments.
 * A segment is defined by a starting and and ending index.
 * The last added segment that fits a passed ID wins over previous ones.
 * A segment can be changed back to an empty string.
 * A segment can be determined by passing a tokenId
 * */

contract TokenSegments{
    string[] segmentBaseURIs;
    uint256[] tokenSegmentsStartingIndex;
    uint256[] tokenSegmentsEndingIndex;

    function _setSegmentBaseTokenURIs(uint256 startingIndex, uint256 endingIndex, string memory _URI) internal{
        tokenSegmentsStartingIndex.push(startingIndex);
        tokenSegmentsEndingIndex.push(endingIndex);
        segmentBaseURIs.push(_URI);
    }

    function getSegmentId(uint256 pointer) public view returns(int256){
        // go backwards, so that segments can be overwritten by adding them
        if (tokenSegmentsStartingIndex.length == 0) {
            return -1;
        }
        for (int256 i = int256(tokenSegmentsStartingIndex.length - 1); i >= 0; i--) {
            if ((tokenSegmentsStartingIndex[uint256(i)] <= pointer) && (tokenSegmentsEndingIndex[uint256(i)] >= pointer)) {
                return i;
            }
        }
        return -1;
    }

    function getSegmentBaseURI(uint256 tokenId) public view returns(string memory){
        int256 segmentId = getSegmentId(tokenId);
        if (segmentId == -1) {
            return "";
        }
        return segmentBaseURIs[uint256(segmentId)];
    }

    function getBaseURIBySegmentId(int256 pointer) public view returns(string memory){
        return segmentBaseURIs[uint256(pointer)];
    }

    function _setBaseURIBySegmentId(int256 pointer, string memory _URI) internal{
        segmentBaseURIs[uint256(pointer)] = _URI;
    }
}