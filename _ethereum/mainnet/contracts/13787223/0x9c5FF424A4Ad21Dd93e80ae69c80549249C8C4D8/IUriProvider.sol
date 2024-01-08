interface IUriProvider {
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function writeLogo(uint256 tokenId, string memory data) external returns (address logo);
}