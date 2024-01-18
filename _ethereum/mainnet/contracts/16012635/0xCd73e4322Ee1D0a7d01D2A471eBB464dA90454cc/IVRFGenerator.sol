// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

uint256 constant FOEVER = type(uint256).max;
address constant ZERO = 0x0000000000000000000000000000000000000000;

interface IVRFGenerator {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint32 numWords)
        external
        returns (uint256 requestId);

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords);

    function shuffle(uint256 size, uint256 entropy)
        external
        pure
        returns (uint256[] memory);

    function shuffle16(uint16 size, uint256 entropy)
        external
        pure
        returns (uint16[] memory);
}
