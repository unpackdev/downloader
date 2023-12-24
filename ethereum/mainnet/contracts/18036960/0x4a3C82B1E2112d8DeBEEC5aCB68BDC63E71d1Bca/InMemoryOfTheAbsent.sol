// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./IERC721.sol";
import "./IMetadataResolver.sol";

//   _____ _____
//  |     |   | |
//  |-   -| | | |
//  |_____|_|___|_____ _____ _____ __ __
//  |     |   __|     |     | __  |  |  |
//  | | | |   __| | | |  |  |    -|_   _|
//  |_|_|_|_____|_|_|_|_____|__|__| |_|
//  |     |   __|
//  |  |  |   __|
//  |_____|__|__ _____
//  |_   _|  |  |   __|
//    | | |     |   __|
//   _|_|_|__|__|_____|_____ _____ _____
//  |  _  | __  |   __|   __|   | |_   _|
//  |     | __ -|__   |   __| | | | | |
//  |__|__|_____|_____|_____|_|___| |_|
//
//  @creator: Pak
//  @author: NFT Studios | Powered by Buildtree

contract InMemoryOfTheAbsent is IMetadataResolver {
    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        try IERC721(msg.sender).ownerOf(_tokenId) {
            return "In memory of the absent.";
        } catch {
            return "404";
        }
    }
}
