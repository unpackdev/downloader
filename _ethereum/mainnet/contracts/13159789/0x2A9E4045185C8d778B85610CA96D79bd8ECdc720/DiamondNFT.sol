//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract TaschasDestroyedDiamond is ERC721URIStorage, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() public ERC721("TaschasDestroyedDiamond", "TDD") {}


    function mintNFT(address recipient, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        uint256 currentId = _tokenIds.current();
        require(currentId == 0, 'You cannot mint more than 1 diamond!');
        _tokenIds.increment(); // increment by 1 cuz we don't like #0

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);


        return newItemId;
    }
}
