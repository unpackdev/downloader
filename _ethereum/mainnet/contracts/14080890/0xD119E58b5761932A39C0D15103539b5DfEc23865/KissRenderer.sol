// SPDX-License-Identifier: UNLICENSED
// Copyright 2022 Arran Schlosberg
pragma solidity >=0.8.0 <0.9.0;

import "./Kiss.sol";
import "./IKissRenderer.sol";
import "./DynamicBuffer.sol";
import "./IERC165.sol";
import "./Ownable.sol";

/**
@notice Implements the IKissRenderer interface, exposing the respective
functions from the Kiss library; the rendering library for the generative-art
collection, The Kiss Precise.
 */
contract KissRenderer is IKissRenderer, Ownable {
    using Kiss for bytes32;

    constructor() {}

    /**
    @notice Returns the SVG returned by draw(seed) from the Kiss library.
     */
    function draw(bytes32 seed) public pure returns (string memory svg_) {
        (bytes memory svg, , ) = seed.draw(seed.randomStyle());
        assembly {
            svg_ := svg
        }
    }

    /**
    @notice Returns draw(sha3(seed)).
     */
    function draw(string memory seed) external pure returns (string memory) {
        return draw(keccak256(abi.encodePacked(seed)));
    }

    /**
    @notice The address of the Kiss NFT contract, used to ensure that tokenURI
    isn't fraudulently called from another contract.
     */
    address public kiss;

    /**
    @notice Sets the address of the Kiss NFT contract.
     */
    function setKissAddress(address kiss_) external onlyOwner {
        kiss = kiss_;
    }

    /**
    @notice Returns tokenURI(seed) from the Kiss library.
     */
    function tokenURI(uint256 tokenId, bytes32 seed)
        external
        view
        returns (string memory)
    {
        require(kiss == address(0) || msg.sender == kiss, "Not Kiss contract");
        return Kiss.tokenURI(tokenId, seed);
    }

    /**
    @notice Returns true iff interfaceId is IERC165 or IKissRenderer.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IKissRenderer).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
