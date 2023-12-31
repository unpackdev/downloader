// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import "./Ownable.sol";
import "./ITokenDescriptor.sol";
import "./base64.sol";

contract TokenDescriptor is ITokenDescriptor, Ownable {

    /**
     * @notice Create the ERC721 token URI for a token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory json =  Base64.encode(bytes(string(
                abi.encodePacked(
                    bytes('{"name":"The Doomed DAO"'),
                    bytes(',"image":"ipfs://QmSBGK8zWyNfS8sU3Nd4ixoJtkYaeANHHdNjriHNaDdgYc"'),
                    bytes('}')
                )
        )));

        return string(abi.encodePacked('data:application/json;base64,', json));

    }
}
