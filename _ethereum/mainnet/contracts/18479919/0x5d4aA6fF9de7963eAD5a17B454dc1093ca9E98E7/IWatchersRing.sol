//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.18;

interface IWatchersRing {
    enum WatchersRingType {
        red,
        blue,
        yellow,
        green,
        brown,
        white,
        purple,
        prismatic
    }

    event WatchersRingMinted(
        address to,
        uint256 tokenId,
        IWatchersRing.WatchersRingType rtype
    );

    function mintTokenId(
        address recipient,
        uint256 tokenId,
        WatchersRingType rtype
    ) external;
}
