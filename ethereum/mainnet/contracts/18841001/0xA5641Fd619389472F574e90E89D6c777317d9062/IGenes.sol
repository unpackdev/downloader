// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;


    
interface IGenes {
    struct Entity {
        uint256 genes;
        uint256 bornAt;
    }

    event RebirthEvent(uint256 indexed _tokenId, address indexed _owner, uint256 _genes);
    event UpgradeEvent(uint256 indexed _tokenId, uint256 _genes);
    event RetiredEvent(uint256 indexed _tokenId);
    

    function verifyTokenId(uint256 _tokenId, bytes calldata _sig)
        external
        view
        returns (bool success, address signer);
}
