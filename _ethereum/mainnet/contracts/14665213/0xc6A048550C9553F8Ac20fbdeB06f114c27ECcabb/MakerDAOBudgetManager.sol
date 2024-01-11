// SPDX-License-Identifier: MIT

/*

  Coded for MakerDAO and The Keep3r Network with ♥ by
  ██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
  ██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
  ██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
  ██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
  ██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
  ╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░
  https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import "./MakerDAOParameters.sol";
import "./Governable.sol";
import "./DustCollector.sol";

import "./IMakerDAOBudgetManager.sol";
import "./IKeep3rV2.sol";
import "./IDaiJoin.sol";
import "./IDssVest.sol";
import "./IERC20.sol";
import "./Math.sol";

contract MakerDAOBudgetManager is IMakerDAOBudgetManager, MakerDAOParameters, Governable, DustCollector {
  address public override keep3r = 0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC;
  address public override job = 0x5D469E1ef75507b0E0439667ae45e280b9D81B9C;
  address public override keeper;

  uint256 public override daiToClaim;
  uint256 public override invoiceNonce;
  mapping(uint256 => uint256) public override invoiceAmount;

  constructor(address _governor) Governable(_governor) {
    emit Keep3rJobSet(keep3r, job);
    IERC20(DAI).approve(DAI_JOIN, type(uint256).max);
  }

  // Views

  /// @inheritdoc IMakerDAOBudgetManager
  function credits() public view override returns (uint256 _daiCredits) {
    return IKeep3rV2(keep3r).jobTokenCredits(job, DAI);
  }

  // Methods

  /// @inheritdoc IMakerDAOBudgetManager
  function invoiceGas(
    uint256 _gasCostETH,
    uint256 _claimableDai,
    string memory _description
  ) external override onlyGovernor {
    daiToClaim += _claimableDai;
    invoiceAmount[++invoiceNonce] = _claimableDai;

    // emits event to be tracked in DuneAnalytics dashboard & contrast with txs
    emit InvoicedGas(invoiceNonce, _gasCostETH, _claimableDai, _description);
  }

  /// @inheritdoc IMakerDAOBudgetManager
  function deleteInvoice(uint256 _invoiceNonce) external override onlyGovernor {
    uint256 deleteAmount = invoiceAmount[_invoiceNonce];
    if (deleteAmount > daiToClaim) revert InvoiceClaimed();

    daiToClaim -= deleteAmount;
    delete invoiceAmount[_invoiceNonce];

    // emits event to filter out InvoicedGas events
    emit DeletedInvoice(_invoiceNonce);
  }

  /// @inheritdoc IMakerDAOBudgetManager
  function claimDai() external override onlyGovernor {
    _claimDai();
  }

  /// @inheritdoc IMakerDAOBudgetManager
  function claimDaiUpkeep() external override onlyKeeper {
    _claimDai();
  }

  /// @notice This function handles the flow of Vested DAI
  function _claimDai() internal {
    // claims DAI
    uint256 daiAmount = IERC20(DAI).balanceOf(address(this));
    IDssVest(DSS_VEST).vest(vestId);
    // removes previous balance from scope
    daiAmount = IERC20(DAI).balanceOf(address(this)) - daiAmount;

    if (daiAmount < minBuffer) revert MinBuffer();

    // returns any DAI above maxBuffer
    uint256 daiToReturn;
    if (daiAmount > maxBuffer) {
      daiToReturn = daiAmount - maxBuffer;
      daiAmount = maxBuffer;
    }

    // checks for DAI debt and reduces debt if applies
    uint256 claimableDai;
    if (daiToClaim > minBuffer) {
      claimableDai = Math.min(daiToClaim, daiAmount);

      // reduces debt accountance
      daiToClaim -= claimableDai;
      daiAmount -= claimableDai;
    }

    // checks for credits on Keep3rJob and refills up to maxBuffer if possible
    uint256 daiCredits = credits();
    uint256 creditsToRefill;
    if (daiCredits < minBuffer && daiAmount > 0) {
      // refill credits up to maxBuffer or available DAI
      creditsToRefill = Math.min(maxBuffer - daiCredits, daiAmount);

      // refill DAI credits on Keep3rJob
      IERC20(DAI).approve(keep3r, uint256(creditsToRefill));
      IKeep3rV2(keep3r).addTokenCreditsToJob(job, DAI, uint256(creditsToRefill));

      daiAmount -= creditsToRefill;
    }

    // returns any excess of DAI
    daiToReturn += daiAmount;
    if (daiToReturn > 0) {
      IDaiJoin(DAI_JOIN).join(VOW, daiToReturn);
    }

    // emits event to be tracked in DuneAnalytics dashboard & tracks DAI flow
    emit ClaimedDai(claimableDai, creditsToRefill, daiToReturn);
  }

  // Parameters

  /// @inheritdoc IMakerDAOBudgetManager
  function setKeep3rJob(address _keep3r, address _job) external override onlyGovernor {
    keep3r = _keep3r;
    job = _job;

    emit Keep3rJobSet(_keep3r, _job);
  }

  /// @inheritdoc IMakerDAOBudgetManager
  function setKeeper(address _keeper) external override onlyGovernor {
    keeper = _keeper;

    emit KeeperSet(_keeper);
  }

  // Modifiers

  modifier onlyKeeper() {
    if (msg.sender != keeper) revert OnlyKeeper();
    _;
  }
}
