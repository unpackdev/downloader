// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";

abstract contract ERC721BatchMinting is ERC721 {
    function _mintBatch(address to, uint256[] memory ids) internal virtual {
        if (to == address(0)) revert InvalidRecipient();

        for (uint256 id = 0; id < ids.length; ) {
            if (_ownerOf[ids[id]] != address(0)) revert AlreadyMinted();
            _ownerOf[ids[id]] = to;
            emit Transfer(address(0), to, ids[id]);
            unchecked {
                id++;
            }
        }

        // Will probably never be more than uin256.max so may as well save some gas.
        unchecked {
            _balances[to] += ids.length;
        }
    }

    function _safeMintBatch(address to, uint256[] memory ids) internal virtual {
        _mintBatch(to, ids);

        for (uint256 id = 0; id < ids.length; ) {
            require(
                to.code.length == 0 ||
                    ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
            unchecked {
                id++;
            }
        }
    }

    function _safeMintBatch(
        address to,
        uint256[] memory ids,
        bytes memory data
    ) internal virtual {
        _mintBatch(to, ids);

        for (uint256 id = 0; id < ids.length; ) {
            require(
                to.code.length == 0 ||
                    ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
            unchecked {
                id++;
            }
        }
    }
}
