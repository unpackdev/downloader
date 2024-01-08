// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract GolToken is ERC721Enumerable, Ownable {

    uint256 private _currentTokenId = 0;

    constructor() ERC721("Life Pattern", "CGOL") { }

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked("https://catagolue.hatsya.com/autogen/nfts/", Strings.toString(_tokenId), ".json"));
    }

    function mintTo(address _to) public onlyOwner {
        uint256 newTokenId = getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function getNextTokenId() public view returns (uint256) {
        return _currentTokenId + 1;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(address(0xa5409ec958C83C3f309868babACA7c86DCB077c1));
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

}
