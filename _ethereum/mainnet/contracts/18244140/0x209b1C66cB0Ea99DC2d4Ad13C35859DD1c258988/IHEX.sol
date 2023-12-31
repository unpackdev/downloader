// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IUnderlyingStakeable.sol";

interface IHEX is IERC20, IERC20Metadata, IUnderlyingStakeable {
  /*  XfLobbyEnter      (auto-generated event)

      uint40            timestamp       -->  data0 [ 39:  0]
      address  indexed  memberAddr
      uint256  indexed  entryId
      uint96            rawAmount       -->  data0 [135: 40]
      address  indexed  referrerAddr
  */
  event XfLobbyEnter(
    uint256 data0,
    address indexed memberAddr,
    uint256 indexed entryId,
    address indexed referrerAddr
  );

  /*  XfLobbyExit       (auto-generated event)

      uint40            timestamp       -->  data0 [ 39:  0]
      address  indexed  memberAddr
      uint256  indexed  entryId
      uint72            xfAmount        -->  data0 [111: 40]
      address  indexed  referrerAddr
  */
  event XfLobbyExit(
    uint256 data0,
    address indexed memberAddr,
    uint256 indexed entryId,
    address indexed referrerAddr
  );

  /*  DailyDataUpdate   (auto-generated event)

      uint40            timestamp       -->  data0 [ 39:  0]
      uint16            beginDay        -->  data0 [ 55: 40]
      uint16            endDay          -->  data0 [ 71: 56]
      bool              isAutoUpdate    -->  data0 [ 79: 72]
      address  indexed  updaterAddr
  */
  event DailyDataUpdate(
      uint256 data0,
      address indexed updaterAddr
  );

  /*  Claim             (auto-generated event)

      uint40            timestamp       -->  data0 [ 39:  0]
      bytes20  indexed  btcAddr
      uint56            rawSatoshis     -->  data0 [ 95: 40]
      uint56            adjSatoshis     -->  data0 [151: 96]
      address  indexed  claimToAddr
      uint8             claimFlags      -->  data0 [159:152]
      uint72            claimedHearts   -->  data0 [231:160]
      address  indexed  referrerAddr
      address           senderAddr      -->  data1 [159:  0]
  */
  event Claim(
    uint256 data0,
    uint256 data1,
    bytes20 indexed btcAddr,
    address indexed claimToAddr,
    address indexed referrerAddr
  );

  /*  ClaimAssist       (auto-generated event)

      uint40            timestamp       -->  data0 [ 39:  0]
      bytes20           btcAddr         -->  data0 [199: 40]
      uint56            rawSatoshis     -->  data0 [255:200]
      uint56            adjSatoshis     -->  data1 [ 55:  0]
      address           claimToAddr     -->  data1 [215: 56]
      uint8             claimFlags      -->  data1 [223:216]
      uint72            claimedHearts   -->  data2 [ 71:  0]
      address           referrerAddr    -->  data2 [231: 72]
      address  indexed  senderAddr
  */
  event ClaimAssist(
    uint256 data0,
    uint256 data1,
    uint256 data2,
    address indexed senderAddr
  );

  /*  StakeStart        (auto-generated event)

      uint40            timestamp       -->  data0 [ 39:  0]
      address  indexed  stakerAddr
      uint40   indexed  stakeId
      uint72            stakedHearts    -->  data0 [111: 40]
      uint72            stakeShares     -->  data0 [183:112]
      uint16            stakedDays      -->  data0 [199:184]
      bool              isAutoStake     -->  data0 [207:200]
  */
  event StakeStart(
    uint256 data0,
    address indexed stakerAddr,
    uint40 indexed stakeId
  );

  /*  StakeGoodAccounting(auto-generated event)

      uint40            timestamp       -->  data0 [ 39:  0]
      address  indexed  stakerAddr
      uint40   indexed  stakeId
      uint72            stakedHearts    -->  data0 [111: 40]
      uint72            stakeShares     -->  data0 [183:112]
      uint72            payout          -->  data0 [255:184]
      uint72            penalty         -->  data1 [ 71:  0]
      address  indexed  senderAddr
  */
  event StakeGoodAccounting(
    uint256 data0,
    uint256 data1,
    address indexed stakerAddr,
    uint40 indexed stakeId,
    address indexed senderAddr
  );

  /*  StakeEnd          (auto-generated event)

      uint40            timestamp       -->  data0 [ 39:  0]
      address  indexed  stakerAddr
      uint40   indexed  stakeId
      uint72            stakedHearts    -->  data0 [111: 40]
      uint72            stakeShares     -->  data0 [183:112]
      uint72            payout          -->  data0 [255:184]
      uint72            penalty         -->  data1 [ 71:  0]
      uint16            servedDays      -->  data1 [ 87: 72]
      bool              prevUnlocked    -->  data1 [ 95: 88]
  */
  event StakeEnd(
    uint256 data0,
    uint256 data1,
    address indexed stakerAddr,
    uint40 indexed stakeId
  );

  /*  ShareRateChange   (auto-generated event)

      uint40            timestamp       -->  data0 [ 39:  0]
      uint40            shareRate       -->  data0 [ 79: 40]
      uint40   indexed  stakeId
  */
  event ShareRateChange(
    uint256 data0,
    uint40 indexed stakeId
  );
  function stakeLists(address staker, uint256 index) view external returns(StakeStore memory);
  function currentDay() external view returns (uint256);
  function globalInfo() external view returns(uint256[13] memory);

  function dailyData(uint256 day) external view returns(
    uint72 dayPayoutTotal,
    uint72 dayStakeSharesTotal,
    uint56 dayUnclaimedSatoshisTotal
  );
  function dailyDataRange(uint256 beginDay, uint256 endDay)
    external
    view
    returns (uint256[] memory list);
}
