// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract RoadToParadise is ERC721URIStorage, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("RoadToPardise", "RTP") {

    }

    function mint() public payable{
        require(_tokenIds.current() < 555);
        require(msg.value == 0.03 ether);


        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);

        _setTokenURI(newItemId, string(abi.encodePacked('https://opnsource.io/wp-json/wc/v2/media?rtp=RTP', Strings.toString(newItemId))));
    }


    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
  }
}
