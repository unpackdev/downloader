// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "./AccessControl.sol";
import "./IERC721.sol";
import "./AccessControlInitializer.sol";
import "./ERC721Receiver.sol";
import "./ReturnIncorrectERC20.sol";
import "./ReturnIncorrectERC721.sol";


contract AdamCustodianERC721 is AccessControl, AccessControlInitializer, ERC721Receiver, ReturnIncorrectERC20, ReturnIncorrectERC721 {

    bytes32 public constant TRANSFER_CALLER_ROLE = keccak256("TRANSFER_CALLER_ROLE");

    event CallTransfer(address indexed operator, address indexed contract_, uint256 indexed tokenId, address from, address to);

    constructor (bytes32[] memory roles, address[] memory addresses) {
        _setupRoleBatch(roles, addresses);
    }

    function callERC721SafeTransferFrom(
        IERC721 erc721, address to, uint256 tokenId, bytes memory data
    ) external virtual onlyRole(TRANSFER_CALLER_ROLE) {
        erc721.safeTransferFrom(address(this), to, tokenId, data);
        emit CallTransfer(_msgSender(), address(erc721), tokenId, address(this), to);
    }
}
