//SPDX-License-Identifier: UNLICENSED

interface IERC721 {
    function approve(address to, uint256 tokenId) external ;
    function setApprovalForAll(address operator, bool _approved) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function isApprovedForAll(address owner, address operator)external returns(bool);
}