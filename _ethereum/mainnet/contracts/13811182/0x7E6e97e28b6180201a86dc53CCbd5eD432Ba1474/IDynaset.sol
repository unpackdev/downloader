import "./IERC20.sol";

interface IDynaset is IERC20{
  function joinDynaset(uint256 _amount) external;
  function exitDynaset(uint256 _amount) external;
  function calcTokensForAmount(uint256 _amount) external view returns (address[] memory tokens, uint256[] memory amounts);
}