pragma solidity ^0.6.0;

interface IMultiplier {
  function getTotalValueForUser(
    address _vault,
    address _user,
    uint256 _epoch,
    uint256 _pid
  ) external view returns (uint256);

  function isSpendableTokenInContract(address _vault, address _token) external view returns (bool);

  function getTotalLevel(
    address _vault,
    address _user,
    uint256 _epoch,
    uint256 _pid
  ) external view returns (uint256);

  function getLastTokenLevelForUser(
    address _vault,
    address _user,
    address _token,
    uint256 _epoch,
    uint256 _pid
  ) external view returns (uint256);

  function getSpendableCostPerTokenForUser(
    address _vault,
    address _user,
    address _token,
    uint256 _level,
    uint256 _epoch,
    uint256 _pid
  ) external view returns (uint256);

  function purchase(
    address _vault,
    address _user,
    address _token,
    uint256 _newLevel,
    uint256 _epoch,
    uint256 _pid
  ) external;

  function getTokensSpentPerContract(
    address _vault,
    address _token,
    address _user,
    uint256 _epoch,
    uint256 _pid
  ) external view returns (uint256);
}
