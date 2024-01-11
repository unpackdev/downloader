// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./IERC721.sol";

interface FadeAwayBunnyNFT is IERC721 {
    function bunnies(uint256 _id)
        external
        view
        returns (
            bytes32,
            uint64,
            uint32,
            uint32,
            uint16
        );

    function createFadeAwayBunny(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        bytes32 _genes,
        address _owner
    ) external returns (uint256);
}
