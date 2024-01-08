/*
 __    __     ______     ______     ______     ______     ______     __
/\ "-./  \   /\  ___\   /\  ___\   /\  ___\   /\  __ \   /\  == \   /\ \
\ \ \-./\ \  \ \  __\   \ \___  \  \ \___  \  \ \  __ \  \ \  __<   \ \ \
 \ \_\ \ \_\  \ \_____\  \/\_____\  \/\_____\  \ \_\ \_\  \ \_\ \_\  \ \_\
  \/_/  \/_/   \/_____/   \/_____/   \/_____/   \/_/\/_/   \/_/ /_/   \/_/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Messari2022Theses is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() public ERC721("Messari 2022 Theses", "MAT22") {}

    function mintNFT(address recipient, string memory tokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function sweepEth() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(owner()).transfer(_balance);
    }
}
