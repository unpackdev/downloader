// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

interface IStaker {
  function addDeveloper ( address _developerAddress, uint256 _share ) external;
  function addPool ( address _token, uint256 _tokenStrength, uint256 _pointStrength ) external;
  function approvePointSpender ( address _spender, bool _approval ) external;
  function updateDeveloper ( address _newDeveloperAddress, uint256 _newShare ) external;
  function lockDevelopers (  ) external;
  function lockPointEmissions (  ) external;
  function lockTokenEmissions (  ) external;
  function setEmissions ( bytes[] calldata _tokenSchedule, bytes[] calldata _pointSchedule ) external;

  function deposit ( address _token, uint256 _amount ) external;
  function withdraw ( address _token, uint256 _amount ) external;

  function approvedPointSpenders ( address ) external view returns ( bool );
  function canAlterDevelopers (  ) external view returns ( bool );
  function canAlterPointEmissionSchedule (  ) external view returns ( bool );
  function canAlterTokenEmissionSchedule (  ) external view returns ( bool );
  function developerAddresses ( uint256 ) external view returns ( address );
  function developerShares ( address ) external view returns ( uint256 );

  function getAvailablePoints ( address _user ) external view returns ( uint256 );
  function getDeveloperCount (  ) external view returns ( uint256 );
  function getPendingPoints ( address _token, address _user ) external view returns ( uint256 );
  function getPendingTokens ( address _token, address _user ) external view returns ( uint256 );
  function getPoolCount (  ) external view returns ( uint256 );
  function getRemainingToken (  ) external view returns ( uint256 );
  function getSpentPoints ( address _user ) external view returns ( uint256 );
  function getTotalEmittedPoints ( uint256 _fromBlock, uint256 _toBlock ) external view returns ( uint256 );
  function getTotalEmittedTokens ( uint256 _fromBlock, uint256 _toBlock ) external view returns ( uint256 );
  function getTotalPoints ( address _user ) external view returns ( uint256 );
  function tokenEmissionBlockCount (  ) external view returns ( uint256 );
  function tokenEmissionBlocks ( uint256 ) external view returns ( uint256 blockNumber, uint256 rate );
  function totalPointStrength (  ) external view returns ( uint256 );
  function totalTokenDeposited (  ) external view returns ( uint256 );
  function totalTokenDisbursed (  ) external view returns ( uint256 );
  function totalTokenStrength (  ) external view returns ( uint256 );
  function pointEmissionBlockCount (  ) external view returns ( uint256 );
  function pointEmissionBlocks ( uint256 ) external view returns ( uint256 blockNumber, uint256 rate );
  function poolInfo ( address ) external view returns ( address _token, uint256 tokenStrength, uint256 tokensPerShare, uint256 pointStrength, uint256 pointsPerShare, uint256 lastRewardBlock );
  function poolTokens ( uint256 ) external view returns ( address );
  function userInfo ( address, address ) external view returns ( uint256 amount, uint256 tokenPaid, uint256 pointPaid );
  function userPoints ( address ) external view returns ( uint256 );
  function userSpentPoints ( address ) external view returns ( uint256 );
  function token (  ) external view returns ( address );

  function renounceOwnership (  ) external;
  function transferOwnership ( address newOwner ) external;
  function sweep ( address _token ) external;

  function spendPoints ( address _user, uint256 _amount ) external;
}
