// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./TokenListenerInterface.sol";
import "./ControlledTokenInterface.sol";

interface PrizePoolInterface {

  function depositTo(
    address to,
    uint256 amount,
    address controlledToken,
    address referrer
  )
    external;

  function withdrawInstantlyFrom(
    address from,
    uint256 amount,
    address controlledToken,
    uint256 maximumExitFee
  ) external returns (uint256);

  function withdrawWithTimelockFrom(
    address from,
    uint256 amount,
    address controlledToken
  ) external returns (uint256);

  function withdrawReserve(address to) external returns (uint256);
  function awardBalance() external view returns (uint256);
  function captureAwardBalance() external returns (uint256);

  function award(
    address to,
    uint256 amount,
    address controlledToken
  )
    external;

  function transferExternalERC20(
    address to,
    address externalToken,
    uint256 amount
  )
    external;

  function awardExternalERC20(
    address to,
    address externalToken,
    uint256 amount
  )
    external;

  function awardExternalERC721(
    address to,
    address externalToken,
    uint256[] calldata tokenIds
  )
    external;

  function sweepTimelockBalances(
    address[] calldata users
  )
    external
    returns (uint256);

  function calculateTimelockDuration(
    address from,
    address controlledToken,
    uint256 amount
  )
    external
    returns (
      uint256 durationSeconds,
      uint256 burnedCredit
    );

  function calculateEarlyExitFee(
    address from,
    address controlledToken,
    uint256 amount
  )
    external
    returns (
      uint256 exitFee,
      uint256 burnedCredit
    );

  function estimateCreditAccrualTime(
    address _controlledToken,
    uint256 _principal,
    uint256 _interest
  )
    external
    view
    returns (uint256 durationSeconds);

  function balanceOfCredit(address user, address controlledToken) external returns (uint256);

  function setCreditPlanOf(
    address _controlledToken,
    uint128 _creditRateMantissa,
    uint128 _creditLimitMantissa
  )
    external;

   function creditPlanOf(
    address controlledToken
  )
    external
    view
    returns (
      uint128 creditLimitMantissa,
      uint128 creditRateMantissa
    );

  function setLiquidityCap(uint256 _liquidityCap) external;
  function setPrizeStrategy(TokenListenerInterface _prizeStrategy) external;
  function token() external view returns (address);
  function tokens() external view returns (address[] memory);
  function timelockBalanceAvailableAt(address user) external view returns (uint256);
  function timelockBalanceOf(address user) external view returns (uint256);
  function accountedBalance() external view returns (uint256);
}
