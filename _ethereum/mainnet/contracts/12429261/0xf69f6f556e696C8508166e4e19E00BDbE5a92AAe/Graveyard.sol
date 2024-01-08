// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";

contract Graveyard is IERC721Receiver {

    event Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data,
        uint256 _gas
    );

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns (bytes4) {
        emit Received(operator, from, tokenId, data, gasleft());
        return IERC721Receiver(address(this)).onERC721Received.selector;
    }

}