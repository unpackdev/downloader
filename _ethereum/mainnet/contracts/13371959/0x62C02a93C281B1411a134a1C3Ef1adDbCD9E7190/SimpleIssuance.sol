// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify // it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IXPN.sol";

// @title Simple round-based fund raising contract for Exponent Vault issuance
contract SimpleIssuance is ReentrancyGuard, AccessControl, Pausable {
    using SafeERC20 for IERC20;
    bytes32 public constant ISSUANCE_MANAGER = keccak256("ISSUANCE_MANAGER");

    // @dev uninitialized value is always index 0, we make Started index 1 to prevent
    // client seeing an uninitialized round with the Started stage
    enum Stages {
        Null,
        Started,
        GoalMet,
        End
    }

    // @dev uninitialized zero value for ticket should have exists set to false
    struct Ticket {
        uint256 amount;
        bool redeemed;
        bool exists;
    }

    struct RoundData {
        Stages stage;
        uint256 goal;
        uint256 totalShares;
        uint256 totalDeposit;
    }

    event PurchaseTicket(address indexed from, uint256 amount);
    event SellTicket(address indexed from, uint256 amount);
    event RedeemTicket(address indexed from, uint256 amount);

    // @dev roundID => wallet => ticket
    mapping(uint256 => mapping(address => Ticket)) public userTicket;
    mapping(uint256 => RoundData) public roundData;
    uint256 public currentRoundId;
    address public vault;
    IERC20 public vaultToken;
    IERC20 public denomAsset;

    constructor(
        address _issuanceManager,
        uint256 _startGoal,
        address _denomAsset,
        address _vaultToken,
        address _vault
    ) {
        currentRoundId = 1;
        roundData[currentRoundId] = initRound(_startGoal);
        denomAsset = IERC20(_denomAsset);
        vaultToken = IERC20(_vaultToken);
        vault = _vault;
        _setupRole(ISSUANCE_MANAGER, _issuanceManager);
    }

    modifier onlyStage(Stages _stage, uint256 _roundId) {
        require(_roundId <= currentRoundId, "issuance: round does not exist");
        require(
            roundData[_roundId].stage == _stage,
            "issuance: incorrect stage"
        );
        _;
    }

    modifier notStage(Stages _stage, uint256 _roundId) {
        require(_roundId <= currentRoundId, "issuance: round does not exist");
        require(
            roundData[_roundId].stage != _stage,
            "issuance: incorrect stage"
        );
        _;
    }

    function initRound(uint256 _goal) private returns (RoundData memory) {
        return
            RoundData({
                stage: Stages.Started,
                goal: _goal,
                totalShares: 0,
                totalDeposit: 0
            });
    }

    // @dev stage transition function
    function _toNextRound() private {
        // use the same goal from the previous round
        uint256 goal = roundData[currentRoundId].goal;
        currentRoundId += 1;
        roundData[currentRoundId] = initRound(goal);
    }

    // @dev set current round to stage
    function _setCurrentRoundStage(Stages _stage) private {
        roundData[currentRoundId].stage = _stage;
    }

    /////////////////////////
    // external functions
    /////////////////////////

    function pause() external onlyRole(ISSUANCE_MANAGER) {
        _pause();
    }

    function unpause() external onlyRole(ISSUANCE_MANAGER) {
        _unpause();
    }

    // @notice sets current round goal amount
    // @dev the current deposit must be less than or equal to goal
    // @dev only issuance manager role can call this function
    // @param _newGoal the new goal amount to set the current round to
    function setCurrentRoundGoal(uint256 _newGoal)
        external
        nonReentrant
        onlyRole(ISSUANCE_MANAGER)
        onlyStage(Stages.Started, currentRoundId)
    {
        uint256 totalDeposit = roundData[currentRoundId].totalDeposit;
        require(
            totalDeposit <= _newGoal,
            "issuance: total deposit must be <= goal"
        );
        roundData[currentRoundId].goal = _newGoal;
        if (totalDeposit == _newGoal) {
            _setCurrentRoundStage(Stages.GoalMet);
        }
    }

    // @notice purchase a ticket of an amount in denominated asset into current round
    // @dev user should only have one ticket per round
    // @dev the contract must not be paused
    // @dev only once round has started and goal has not been met
    function purchaseTicket(uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        onlyStage(Stages.Started, currentRoundId)
    {
        require(_amount > 0, "issuance: amount can't be zero");
        denomAsset.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _totalDeposit = roundData[currentRoundId].totalDeposit +
            _amount;
        uint256 goal = roundData[currentRoundId].goal;
        uint256 realAmount = _amount;
        if (_totalDeposit > goal) {
            uint256 change = _totalDeposit - goal;
            realAmount -= change;
            roundData[currentRoundId].totalDeposit += realAmount;
            _setCurrentRoundStage(Stages.GoalMet);
            // send the excess amount back to caller
            denomAsset.transfer(msg.sender, change);
        }
        if (_totalDeposit == goal) {
            roundData[currentRoundId].totalDeposit += realAmount;
            _setCurrentRoundStage(Stages.GoalMet);
        }
        if (_totalDeposit < goal) {
            roundData[currentRoundId].totalDeposit += realAmount;
        }
        // create user ticket
        if (!userTicket[currentRoundId][msg.sender].exists) {
            userTicket[currentRoundId][msg.sender] = Ticket({
                amount: realAmount,
                redeemed: false,
                exists: true
            });
        } else {
            // or increment user ticket's amount
            userTicket[currentRoundId][msg.sender].amount += realAmount;
        }
        emit PurchaseTicket(msg.sender, realAmount);
    }

    // @notice sell unredeemed ticket of the current round for denominated asset
    // @param _amount amount of denominated asset to withdraw
    // @dev can be called at any stage except after vault tokens have been issued
    function sellTicket(uint256 _amount)
        external
        nonReentrant
        notStage(Stages.End, currentRoundId)
    {
        // does user have a ticket in the current round ID
        Ticket memory ticket = userTicket[currentRoundId][msg.sender];
        require(ticket.exists, "issuance: ticket for user does not exist");
        // we won't check if ticket has been redeemed, because the contract will transition
        // into the next round hence current round ticket.redeemed will always be false
        require(
            _amount <= ticket.amount,
            "issuance: can't sell more than current ticket amount"
        );
        // if the total amount is the total amount in the ticket, delete the ticket
        if (_amount == ticket.amount) {
            // decrement ticket amount from totalDeposit
            roundData[currentRoundId].totalDeposit -= _amount;
            // delete user ticket struct, save gas
            delete userTicket[currentRoundId][msg.sender];
        }
        if (_amount < ticket.amount) {
            // decrement ticket amount from totalDeposit
            roundData[currentRoundId].totalDeposit -= _amount;
            userTicket[currentRoundId][msg.sender].amount -= _amount;
        }
        // if the total deposits is now less than goal for current round, change stage back
        uint256 totalDeposit = roundData[currentRoundId].totalDeposit;
        uint256 goal = roundData[currentRoundId].goal;
        if (totalDeposit < goal) {
            _setCurrentRoundStage(Stages.Started);
        }
        // transfer ticket balance to user
        denomAsset.safeTransfer(msg.sender, _amount);
        emit SellTicket(msg.sender, _amount);
    }

    // @notice use the round's deposited assets to issue new vault tokens
    // @dev only callable from issuance manager
    // @dev can only issue for current round and after the goal is met
    function issue()
        external
        nonReentrant
        onlyRole(ISSUANCE_MANAGER)
        onlyStage(Stages.GoalMet, currentRoundId)
    {
        // approve vault and deposit
        uint256 amount = roundData[currentRoundId].totalDeposit;
        denomAsset.safeApprove(vault, amount);
        uint256 mintedVaultTokens = IXPN(vault).deposit(amount);
        // update the round with the current totalShares returned from deposit
        roundData[currentRoundId].totalShares = mintedVaultTokens;
        // ensure the new shares balance has been incremented correctly
        _setCurrentRoundStage(Stages.End);
        _toNextRound();
    }

    // @notice redeem the round ticket for vault tokens
    // @param _roundId the identifier of the round
    // @dev the round must have ended and vault tokens are issued
    function redeemTicket(uint256 _roundId)
        external
        nonReentrant
        onlyStage(Stages.End, _roundId)
    {
        // ensure the user ticket exists in the round specified
        Ticket memory ticket = userTicket[_roundId][msg.sender];
        RoundData memory round = roundData[_roundId];
        require(ticket.exists, "issuance: user ticket does not exist");
        require(
            !ticket.redeemed,
            "issuance: user vault tokens have been redeemed"
        );
        // calculate the shares of user to the current round shares using the proportion of their deposit
        uint256 claimable = ((round.totalShares * ticket.amount) /
            round.totalDeposit);
        // transfer the share of vault tokens to end user.
        userTicket[_roundId][msg.sender].redeemed = true;
        vaultToken.safeTransfer(msg.sender, claimable);
        emit RedeemTicket(msg.sender, claimable);
    }
}
