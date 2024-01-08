//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";

// SendGasSaveAs - a place where anyone can create a new type of token,
//   and anyone can mint as many as they want of any of them.
// Authored by sina.eth
// Inspired by impostor.eth
contract SendGasSaveAs is ERC1155("") {
    event NewId(uint256 id, string uri);

    string public constant INVALID_ID = "Got invalid token ID";

    string[] public uris;

    // Instantiate an ID of this token with a URI.
    function instantiateId(string calldata newUri)
        public
        returns (uint256 newId)
    {
        newId = uris.length;
        uris.push(newUri);
        emit NewId(newId, newUri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(id < uris.length, INVALID_ID);
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < uris.length, INVALID_ID);
        }
        _mintBatch(to, ids, amounts, data);
    }

    // Each token ID has a distinct URI.
    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return uris[id];
    }
}
