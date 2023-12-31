// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./IERC165.sol";

contract Callbacks is ERC721Holder, ERC1155Holder {
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }
}
