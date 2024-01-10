// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
@author: dotyigit - twitter.com/dotyigit
$$$$$$$$\ $$$$$$$\  $$$$$$$\
$$  _____|$$  __$$\ $$  __$$\
$$ |      $$ |  $$ |$$ |  $$ |
$$$$$\    $$$$$$$  |$$$$$$$\ |
$$  __|   $$  ____/ $$  __$$\
$$ |      $$ |      $$ |  $$ |
$$ |      $$ |      $$$$$$$  |
\__|      \__|      \_______/
*/

import "./Ownable.sol";
import "./Strings.sol";

import "./IMetadataProvider.sol";

contract MetadataProvider is IMetadataProvider, Ownable {
    using Strings for uint256;

    string public baseURI =
        "https://polarbearsnft.mypinata.cloud/ipfs/QmTn7HTq9Tt9HwJADRAXNcqwJ7qdn7DNc2oQJbuakU2n12/";

    function getMetadata(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }
}
