// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "IERC20.sol";
import "SafeERC20.sol";

/// @title Cobie-escrowed LUNA betting contract.
///        Bet who wins. Do Kwon v.s. Sensei Algod.
/// @notice refs:
///         - https://twitter.com/AlgodTrading/status/1503103705939423234
///         - https://twitter.com/GiganticRebirth/status/1503335929976664065
/// @notice The contract is unaudited. Use at your own risk.
contract LunaBet {
  using SafeERC20 for IERC20;
  enum Side {
    NONE,
    DO,
    ALGOD
  }

  address public constant cobie = 0x4Cbe68d825d21cB4978F56815613eeD06Cf30152; // escrow-Cobie
  IERC20 public constant usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  // Assume bet starts when both parties successfully transferred 1M USDT to Cobie's wallet
  // (https://etherscan.io/tx/0x7c5df6922b4711dba00e3ffe7ad3d27b4003410b437681cc67a9d8c190d104f6)
  uint public betStartTimestamp = 1647243834;
  uint public betEndTimestamp; // initialized to be 7 days after contract deployment

  mapping(address => uint) public doAmts; // mapping from user to bet amounts on Do's side
  mapping(address => uint) public algodAmts; // mapping from user to bet amounts on Algod's side
  uint public doTotalAmt; // Total bet amount on Do's side
  uint public algodTotalAmt; // Total bet amount on Algod's side
  bool public isVoid; // whether the bet is void.
  Side public winner = Side.NONE; // The bet winner.
  uint public winningMultiplier; // in 1e18.

  constructor() {
    betEndTimestamp = block.timestamp + 7 days; // 7 days after deployment
  }

  /// @dev Bet on Do's side.
  /// @param _amt The amount of USDT to bet.
  /// @notice Must be called before the betting ends.
  function betDo(uint _amt) external {
    require(block.timestamp <= betEndTimestamp, 'bet already ended');
    require(_amt > 0, '!_amt');
    usdt.safeTransferFrom(msg.sender, address(this), _amt);
    doAmts[msg.sender] += _amt;
    doTotalAmt += _amt;
  }

  /// @dev Bet on Algod's side.
  /// @param _amt The amount of USDT to bet.
  /// @notice Must be called before the betting ends.
  function betAlgod(uint _amt) external {
    require(block.timestamp <= betEndTimestamp, 'bet already ended');
    require(_amt > 0, '!_amt');
    usdt.safeTransferFrom(msg.sender, address(this), _amt);
    algodAmts[msg.sender] += _amt;
    algodTotalAmt += _amt;
  }

  /// @dev Announce the winning side.
  /// @notice Can only be called by Cobie.
  /// @param _winner The winning side.
  function announceWinner(Side _winner) external {
    require(msg.sender == cobie, '!cobie');
    require(block.timestamp > betStartTimestamp + 365 days, 'not yet');
    require(!isVoid, 'voided');
    winner = _winner == Side.DO ? Side.DO : Side.ALGOD;
    uint totalAmts = doTotalAmt + algodTotalAmt;
    if (_winner == Side.DO) {
      winningMultiplier = doTotalAmt > 0 ? (totalAmts * 1e18) / doTotalAmt : 0;
    } else {
      winningMultiplier = algodTotalAmt > 0 ? (totalAmts * 1e18) / algodTotalAmt : 0;
    }
  }

  /// @dev Claim the winning bet.
  /// @notice Can only be called after the resolve (365 days after the bet start timestamp)
  ///         and after the winner is announced to the contract by Cobie.
  function claimWinningBet() external {
    Side _winner = winner; // gas saving
    require(block.timestamp > betStartTimestamp + 365 days, 'not yet');
    require(_winner != Side.NONE, 'winner unannounced');

    uint depositAmt;
    if (_winner == Side.DO) {
      depositAmt = doAmts[msg.sender];
      doAmts[msg.sender] = 0;
    } else {
      depositAmt = algodAmts[msg.sender];
      algodAmts[msg.sender] = 0;
    }

    uint claimAmt = (depositAmt * winningMultiplier) / 1e18;
    usdt.safeTransfer(msg.sender, claimAmt);
  }

  /// @dev Void the bet, in unforeseen circumstances. Use with care.
  /// @notice Can only be called by Cobie.
  function voidBet() external {
    require(msg.sender == cobie, '!cobie');
    require(winner == Side.NONE, 'winner already announced');
    isVoid = true;
  }

  /// @dev Withdraw voided bet.
  /// @notice Can only be called if the bet is voided.
  function withdrawVoidedBet() external {
    require(isVoid, 'bet still ongoing');
    uint withdrawAmt = algodAmts[msg.sender] + doAmts[msg.sender];
    require(withdrawAmt > 0, '!withdrawAmt');
    algodAmts[msg.sender] = 0;
    doAmts[msg.sender] = 0;
    usdt.safeTransfer(msg.sender, withdrawAmt);
  }

  /// @dev Rug. Transfer all USDT from this contract to Cobie.
  /// @notice Can only be called by Cobie.
  /// @notice Use with care.
  function rug(uint _amt) external {
    require(msg.sender == cobie, '!cobie');
    usdt.safeTransfer(cobie, _amt);
  }
}
