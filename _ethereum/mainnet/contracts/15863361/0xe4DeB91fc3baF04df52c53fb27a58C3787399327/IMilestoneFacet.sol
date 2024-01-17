// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io

**************************************/

/**************************************

    Milestone facet interface

**************************************/

interface IMilestoneFacet {
    function postponeMilestones(
        string memory _raiseId,
        uint256 delay
    ) external;
}
