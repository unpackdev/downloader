interface IERC721Locker {
    function unlock(uint256 tokenId) external;

    function onERC721Locked(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    function onERC721Unlocked(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
