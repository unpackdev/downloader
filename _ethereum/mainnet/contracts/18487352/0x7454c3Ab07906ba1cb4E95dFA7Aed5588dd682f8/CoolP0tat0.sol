// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import {ERC721} from "ERC721.sol";

/// @title ERC721 NFT Cool P0tat0 to commemorate the transfer of the hot potato to 0x3E2dA (1723)
/// @author 1723
contract CoolP0tat0 is ERC721 {

    // Hot Potato Previous Owner
    address private chickenjalfrezi = 0x4e672fC6C49EA1666F302664F55c8eef236144A2;

    // Hot Potato Future Owner
    address private seventeen = 0x3E2dAba02b8b09879ed9b517bF4603a3DD9C410F;
    
    // Hot Potato Contract
    address private hotpotato = 0xF0d74e3D564614cAf257b748cD824cce2891bA41;

    // Hot Potato tokenId
    uint256 private hotpotatotokenid = 1;

    // Token metadata URIs
    string private token1URI = "ipfs://bafybeiclgfdn7z7wpx4csysjchmsxy5ghfz2bqxyzggz7basg6zbndi7ny";

    constructor() ERC721("Cool P0tat0", "COOLP0TAT0") {}

    function freeCoolP0tat0() public {
        address hotPotatoOwner = ERC721(hotpotato).ownerOf(hotpotatotokenid);
        require(hotPotatoOwner == seventeen, "Hot Potato is not owned by the right address!");
        _mint(chickenjalfrezi, 1);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId == 1 && ownerOf(tokenId) != address(0), "Token does not exist!");
        return token1URI;
    }
}
