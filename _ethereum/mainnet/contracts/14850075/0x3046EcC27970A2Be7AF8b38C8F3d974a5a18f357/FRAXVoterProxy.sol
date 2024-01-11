// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: research@pitch.foundation

import "./IYieldDistro.sol";
import "./IVoting.sol";
import "./IVoteEscrow.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract FraxVoterProxy is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // State Variables
    address public depositor;
    address public FXS;
    address public veFXS;
    address public gaugeController;

    /* ========== INITIALIZER FUNCTION ========== */ 
    function initialize(address _FXS, address _veFXS, address _gaugeController) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        FXS = _FXS;
        veFXS = _veFXS;
        gaugeController = _gaugeController;
    }

    /* ========== FUNCTION MODIFIERS ========== */
    modifier onlyDepositor() {
        require(msg.sender == depositor, "FraxVoterProxy : Depositor-only access!");
        _;
    }

    modifier depositorOrOwner() {
        require(
            msg.sender == depositor || msg.sender == owner(), 
            "FraxVoterProxy : Depositor- or Owner-only access!"
        );
        _;
    }
    /* ========== END FUNCTION MODIFIERS ========== */

    /* ========== OWNER FUNCTIONS ========== */
    // --- Update Addresses --- //
    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
    }

    function setFXS(address _FXS) external onlyOwner {
        FXS = _FXS;
    }

    function setVeFXS(address _veFXS) external onlyOwner {
        veFXS = _veFXS;
    }

    function setGaugeController(address _gaugeController) external onlyOwner {
        gaugeController = _gaugeController;
    }
    // --- End Update Addresses --- //

    function voteGaugeWeight(address _gauge, uint256 _weight) external onlyOwner returns(bool){
        //vote
        IVoting(gaugeController).vote_for_gauge_weights(_gauge, _weight);
        emit VotedOnGaugeWeight(_gauge, _weight);
        return true;
    }

    function claimFees(address _distroContract, address _token, address _claimTo) external onlyOwner returns (uint256){
        IYieldDistro(_distroContract).getYield();
        uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this)); //_token = FXS

        emit FeesClaimed(_claimTo, _balance);

        IERC20Upgradeable(_token).safeTransfer(_claimTo, _balance);
        return _balance;
    }

    // this lets the contract execute arbitrary code and send arbitrary data... something to be very careful about
    function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }

    // used to manage upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}
    /* ========== END OWNER FUNCTIONS ========== */

    /* ========== DEPOSITOR FUNCTIONS ========== */
    function createLock(uint256 _value, uint256 _unlockTime) external onlyDepositor returns (bool) {
        IERC20Upgradeable(FXS).safeApprove(veFXS, 0);
        IERC20Upgradeable(FXS).safeApprove(veFXS, _value);
        IVoteEscrow(veFXS).create_lock(_value, _unlockTime);

        emit LockCreated(msg.sender, _value, _unlockTime);
        return true;
    }

    function increaseAmount(uint256 _value) external onlyDepositor returns (bool) {
        IERC20Upgradeable(FXS).safeApprove(veFXS, 0);
        IERC20Upgradeable(FXS).safeApprove(veFXS, _value);
        IVoteEscrow(veFXS).increase_amount(_value);
        return true;
    }

    function increaseTime(uint256 _value) external onlyDepositor returns (bool) {
        IVoteEscrow(veFXS).increase_unlock_time(_value);
        return true;
    }

    function release(address _recipient) external onlyDepositor returns (bool) {
        IVoteEscrow(veFXS).withdraw();
        uint256 balance = IERC20Upgradeable(FXS).balanceOf(address(this));

		IERC20Upgradeable(FXS).safeTransfer(_recipient, balance);
		emit Released(_recipient, balance);
        return true;
    }

    function checkpointFeeRewards(address _distroContract) external depositorOrOwner {
        IYieldDistro(_distroContract).checkpoint();
    }
    /* ========== END DEPOSITOR FUNCTIONS ========== */

    /* ========== EVENTS ========== */
	event LockCreated(address indexed user, uint256 value, uint256 duration);
	event FeesClaimed(address indexed user, uint256 value);
	event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
    event Released(address indexed user, uint256 value);
}