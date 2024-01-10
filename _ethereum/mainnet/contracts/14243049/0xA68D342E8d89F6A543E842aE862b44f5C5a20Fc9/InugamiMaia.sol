// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// ██ ███    ██ ██    ██  ██████   █████  ███    ███ ██     ███    ███  █████  ██  █████  
// ██ ████   ██ ██    ██ ██       ██   ██ ████  ████ ██     ████  ████ ██   ██ ██ ██   ██ 
// ██ ██ ██  ██ ██    ██ ██   ███ ███████ ██ ████ ██ ██     ██ ████ ██ ███████ ██ ███████ 
// ██ ██  ██ ██ ██    ██ ██    ██ ██   ██ ██  ██  ██ ██     ██  ██  ██ ██   ██ ██ ██   ██ 
// ██ ██   ████  ██████   ██████  ██   ██ ██      ██ ██     ██      ██ ██   ██ ██ ██   ██ 
//     
// http://www.inugamigame.com/
// Contract - https://t.me/geimskip

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract InugamiMaia is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("InugamiMaia", "Maia") {
    }

    function mint() public payable returns (uint256 tokenId) {
        require(msg.value == 0.05 ether);

        _tokenIds.increment();
        tokenId = _tokenIds.current();

        _safeMint(msg.sender, tokenId);

        return tokenId;
    }

    function tokenURI(uint256 tokenId) public override pure returns (string memory) {
        string memory tokenIdStr = string(abi.encodePacked(uintToBytes(tokenId)));
        return string(abi.encodePacked("https://us-central1-inugamimaia.cloudfunctions.net/getMetadata?tokenId=", tokenIdStr));
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function uintToBytes(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}