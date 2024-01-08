import "./IERC721Enumerable.sol";

// interface ICreature is IERC721Enumerable {
interface ICards is IERC721Enumerable{
  function isMintedBeforeReveal(uint256 index) external view returns (bool);
  function mintedTimestamp(uint256 index) external view returns (uint256);
}
