// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "./IERC20.sol";

import "./ITrancheToken.sol";
import "./OndoLibrary.sol";

interface IRollover {
  // ========== EVENTS ==========

  event CreatedRollover(
    uint256 indexed rolloverId,
    address indexed creator,
    address indexed strategist,
    address seniorAsset,
    address juniorAsset,
    address seniorToken,
    address juniorToken
  );

  event AddedVault(uint256 indexed rolloverId, uint256 indexed vaultId);

  event MigratedRollover(
    uint256 indexed rolloverId,
    uint256 indexed newVault,
    uint256 seniorDeposited,
    uint256 juniorDeposited
  );

  event Withdrew(
    address indexed user,
    uint256 indexed rolloverId,
    uint256 indexed trancheId,
    uint256 equivalentInvested,
    uint256 withdrawnShares,
    uint256 totalShares,
    uint256 excess
  );

  event Deposited(
    address indexed user,
    uint256 indexed rolloverId,
    uint256 indexed trancheId,
    uint256 depositAmount,
    uint256 excess,
    uint256 sharesMinted
  );

  event Claimed(
    address indexed user,
    uint256 indexed rolloverId,
    uint256 indexed trancheId,
    uint256 tokens,
    uint256 excess
  );
  event DepositedLP(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 amount,
    uint256 seniorTrancheMintedAmount,
    uint256 juniorTrancheMintedAmount
  );

  event WithdrewLP(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 amount,
    uint256 seniorTrancheBurnedAmount,
    uint256 juniorTrancheBurnedAmount
  );
  // ========== STRUCTS ==========

  struct TrancheRoundView {
    uint256 deposited;
    uint256 invested; // Total, if any, actually invested
    uint256 redeemed; // After Vault is done, total tokens redeemed for LP
    uint256 shares;
    uint256 newDeposited;
    uint256 newInvested;
  }

  struct RoundView {
    uint256 vaultId;
    TrancheRoundView[] tranches;
  }

  struct RolloverView {
    address creator;
    address strategist;
    IERC20[] assets;
    ITrancheToken[] rolloverTokens;
    uint256 thisRound;
  }

  struct TrancheRound {
    uint256 deposited;
    uint256 invested; // Total, if any, actually invested
    uint256 redeemed; // After Vault is done, total tokens redeemed for LP
    uint256 shares;
    uint256 newDeposited;
    uint256 newInvested;
    mapping(address => OLib.Investor) investors;
  }

  struct Round {
    uint256 vaultId;
    mapping(OLib.Tranche => TrancheRound) tranches;
  }

  struct Rollover {
    address creator;
    address strategist;
    mapping(uint256 => Round) rounds;
    mapping(OLib.Tranche => IERC20) assets;
    mapping(OLib.Tranche => ITrancheToken) rolloverTokens;
    mapping(OLib.Tranche => mapping(address => uint256)) investorLastUpdates;
    uint256 thisRound;
    bool dead;
  }

  struct SlippageSettings {
    uint256 seniorMinInvest;
    uint256 seniorMinRedeem;
    uint256 juniorMinInvest;
    uint256 juniorMinRedeem;
  }

  // ========== FUNCTIONS ==========

  function getRollover(uint256 rolloverId)
    external
    view
    returns (RolloverView memory);

  function getRound(uint256 _rolloverId, uint256 _roundIndex)
    external
    view
    returns (RoundView memory);

  function getNextVault(uint256 rolloverId) external view returns (uint256);

  function deposit(
    uint256 _rolloverId,
    OLib.Tranche _tranche,
    uint256 _amount
  ) external;

  function withdraw(
    uint256 _rolloverId,
    OLib.Tranche _tranche,
    uint256 shares
  ) external;
}
