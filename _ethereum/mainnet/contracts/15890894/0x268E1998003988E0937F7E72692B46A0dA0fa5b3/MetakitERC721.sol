// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract MetaERC721 is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public adminAddress;
    address public owner;

    constructor(
        string memory _name,
        string memory _symbol,
        address _adminAddress
    ) ERC721(_name, _symbol) {
        owner = msg.sender;
        adminAddress = _adminAddress;
    }

    function exportItem(
        address playerAddress,
        string calldata tokenURI,
        int256 _tokenId
    ) public onlyMetakit returns (uint256) {
        if (_tokenId > -1 && this.ownerOf(uint256(_tokenId)) == address(this)) {
            super._transfer(address(this), playerAddress, uint256(_tokenId));
            return uint256(_tokenId);
        } else {
            uint256 newItemId = _tokenIds.current();
            _mint(playerAddress, newItemId);
            _setTokenURI(newItemId, tokenURI);
            _tokenIds.increment();
            return newItemId;
        }
    }

    function importItem(
        address playerAddress,
        address targetAddress,
        uint256 tokenId
    ) public onlyMetakit returns (bool) {
        super._transfer(playerAddress, targetAddress, tokenId);
        return true;
    }

    //
    // Unused in MVP
    //
    // function burnItem(
    //     address nftAddress,
    //     string memory playerID,
    //     uint256 tokenid,
    //     string memory sessionID,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) public returns (bool) {
    //     Verifier verifier = Verifier(verifierAddress);
    //     bytes32 msgHash = keccak256(
    //         abi.encodePacked(nftAddress, playerID, sessionID, 'IMPORT')
    //     );
    //     msgHash = keccak256(
    //         abi.encodePacked('\x19Ethereum Signed Message:\n32', msgHash)
    //     );
    //     require(
    //         verifier.isSigned(owner, msgHash, v, r, s),
    //         'Metakit::  Invalid signature'
    //     );

    //     //require((msg.sender == adminAddress), "Metakit:: Only the Admin can unlock to burn tokens");

    //     super._burn(tokenid);

    //     return true;
    // }

    modifier onlyMetakit() {
        require(msg.sender == adminAddress, 'Only MetaKit Service can call.');
        _; // Otherwise, it continues.
    }

    function changeAdmin(address newAdmin) public {
        require(
            (msg.sender == owner),
            'Only Owner can change this address'
        );
        adminAddress = newAdmin;
    }

    
}
