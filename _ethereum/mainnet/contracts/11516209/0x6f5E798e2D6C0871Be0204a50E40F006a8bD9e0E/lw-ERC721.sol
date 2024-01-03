// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract LWArtToken is ERC721, Ownable {
     using Counters for Counters.Counter;
     Counters.Counter private _tokenIds;

    constructor() public ERC721("Lars Wander (Art)", "LWNA") {}


    function grant(address receiver, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(receiver, id);
        _setTokenURI(id, tokenURI);

        return id;
    }
}
