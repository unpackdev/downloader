// contracts/cNft.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract cNft is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 constant public cost = 0.5 ether;

    constructor() public ERC721("CHRONSTATE INO", "cINO") {}

    function mintNft(string memory tokenURI) public payable returns (uint256) {
        require(msg.value == cost);

        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(msg.sender, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);

        return newNftTokenId;
    }

    function withdrawEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}
