// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC165.sol";

interface IERC721BO is IERC165, IERC721Enumerable, IERC721Metadata{

    error NonexistentToken();
    error InvalidAddress();
    error CallerIsNotOwnerNorApproved();
    error CallerIsNotOwnerNorApprovedForAll();
    error IndexOutOfRange();
    error TransferToNonERC721ReceiverImplementer();
    error ExceededMaxOfMint();
    error TokenAlreadyMinted();
    error TransferFromIncorrectOwner();
    error ApproveToCaller();
}
