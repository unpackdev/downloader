// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                          
import "./GameToken.sol";

contract IGWhitelist is IERC721Receiver {
    GameToken immutable private _gameToken;
    
    constructor(address gametoken) {
        _gameToken = GameToken(gametoken);
    }
    
    function whitelistMint(bytes32 hash, bytes memory signature, string memory list, uint256 timestamp) external payable {
        _gameToken.whitelistMint{value: msg.value}(hash, signature, string(abi.encode(msg.sender)), list, timestamp);
        _gameToken.transferFrom(address(this), msg.sender, _gameToken.totalSupply());
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}