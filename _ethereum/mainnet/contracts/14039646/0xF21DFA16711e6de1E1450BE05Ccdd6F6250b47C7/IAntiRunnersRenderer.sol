// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAntiRunnersRenderer {
    struct TokenURIInput {
        uint256 tokenId;
        uint256 dna;
        bool isReunited;
    }

    function tokenURI(TokenURIInput memory input) external view returns (string memory);
    function tokenSVG(uint256 _dna, bool isReunited) external view returns (string memory);
}
