import "./IERC721.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPerpetualFutures {
  struct Index {
    string name;
    uint256 dowOpenMin;
    uint256 dowOpenMax;
    uint256 hourOpenMin;
    uint256 hourOpenMax;
    bool isActive;
  }

  struct PositionLifecycle {
    uint256 openTime;
    uint256 openFees;
    uint256 closeTime;
    uint256 closeFees;
    uint256 settleCollPriceUSD; // For positions with alternate collateral, USD per collateral token extended to 18 decimals
    uint256 settleMainPriceUSD; // For positions with alternate collateral, USD per main token extended to 18 decimals
  }

  struct Position {
    PositionLifecycle lifecycle;
    uint256 indexIdx;
    address collateralToken;
    uint256 collateralAmount;
    bool isLong;
    uint16 leverage;
    uint256 indexPriceStart;
    uint256 indexPriceSettle;
    uint256 amountWon;
    uint256 amountLost;
    bool isSettled;
    uint256 mainCollateralSettledAmount;
  }

  struct ActionRequest {
    uint256 timestamp;
    address requester;
    uint256 indexIdx;
    uint256 tokenId;
    address owner;
    address collateralToken;
    uint256 collateralAmount;
    bool isLong;
    uint16 leverage;
    uint256 openSlippage;
    uint256 desiredIdxPriceStart;
  }

  function openFeeETH() external view returns (uint256);

  function mainCollateralToken() external view returns (address);

  function relays(address wallet) external view returns (bool);

  function perpsNft() external view returns (IERC721);

  function positions(uint256 tokenId) external view returns (Position memory);

  function openPositionRequest(
    address collateralToken,
    uint256 indexInd,
    uint256 desiredPrice,
    uint256 slippage,
    uint256 collateral,
    uint16 leverage,
    bool isLong,
    uint256 tokenId, // optional: if adding margin
    address owner // optional: if opening for another wallet
  ) external payable;

  function executeSettlement(
    uint256 tokenId,
    address to,
    uint256 amount
  ) external;
}
