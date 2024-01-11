//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IChameleon.sol";

interface ISvgGenerator {
    function generateTokenUri(uint256 tokenId, IChameleon.Chameleon memory)
        external
        view
        returns (string memory);
}
