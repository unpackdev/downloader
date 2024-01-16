// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./console.sol";
import "./ProxyERC721.sol";
import "./MinimalProxy.sol";
import "./Ownable.sol";

contract ProxyERC721Factory is Ownable, MinimalProxy {
    address[] public tokens;

    function createThing(string calldata _name, string calldata _symbol, string calldata _baseuri) public {
        address proxyerc721 = 0x82548e439328C74D75d320D84b95ce155F4F65c7; //ProxyERC721のコントラクトアドレス
        address clone = createClone(proxyerc721);
        ProxyERC721(clone).initialize(msg.sender, _name, _symbol, _baseuri);
        tokens.push(clone);
    }

    function tokenOf(uint256 tokenId) public view returns (address) {
        return tokens[tokenId];
    }
}
