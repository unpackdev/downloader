interface INFTLight {
    function burn(uint256 _tokenId) external returns (bool);

    function exists(uint256 _tokenId) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}
