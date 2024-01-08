// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";


contract Ingot is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Ingot", "ING", _proxyRegistryAddress)
    {}

    function burn(uint256 tokenId) public onlyOwner {
        //solhint-disable-next-line max-line-length
        _burn(tokenId);
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://ggy0vyi8rk.execute-api.us-east-1.amazonaws.com/final/ingot/";
    }
}
