// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./IAjnaDripper.sol";
import "./IAjnaRedeemer.sol";

/* @inheritdoc IAjnaDripper */
contract AjnaDripper is IAjnaDripper, AccessControl {
    mapping(uint256 => bool) public weeklyDrip;
    uint256 constant MAX_WEEKLY_AMOUNT = 2_000_000 * 10 ** 18;
    address public immutable beneficiary;
    uint256 public immutable dripperDeploymentWeek;
    IERC20 public immutable ajnaToken;
    IAjnaRedeemer public redeemer;
    uint256 public weeklyAmount;
    uint256 public lastUpdate;

    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    event Dripped(uint256 indexed week, uint256 amount);
    event RedeemerChanged(uint256 indexed week, address oldRedeemer, address indexed newRedeemer);
    event WeeklyAmountChanged(uint256 indexed week, uint256 oldAmount, uint256 indexed newAmount);

    constructor(IERC20 _ajnaToken, address _multisig) {
        require(address(_ajnaToken) != address(0), "drip/invalid-ajna-token");
        require(_multisig != address(0), "drip/invalid-multisig");
        ajnaToken = _ajnaToken;
        beneficiary = _multisig;
        dripperDeploymentWeek = getCurrentWeek();
        _setupRole(DEFAULT_ADMIN_ROLE, _multisig);
    }

    /* @inheritdoc IAjnaDripper */
    function getCurrentWeek() public view returns (uint256) {
        return block.timestamp / 1 weeks;
    }

    /* @inheritdoc IAjnaDripper */
    function drip(uint256 week) external onlyRole(REDEEMER_ROLE) returns (bool status) {
        require(weeklyDrip[week] == false, "drip/already-dripped");
        require(week >= dripperDeploymentWeek && week <= getCurrentWeek(), "drip/invalid-week");
        weeklyDrip[week] = true;
        status = ajnaToken.transfer(address(redeemer), weeklyAmount);
        require(status, "drip/transfer-from-failed");
        emit Dripped(week, weeklyAmount);
    }

    function validateWeeklyAmount(uint256 _weeklyAmount) private view {
        require(_weeklyAmount <= MAX_WEEKLY_AMOUNT, "drip/amount-exceeds-max");
        require(
            (_weeklyAmount >= (90 * weeklyAmount) / 100 &&
                _weeklyAmount <= (110 * weeklyAmount) / 100) || weeklyAmount == 0,
            "drip/invalid-amount"
        );
    }

    /* @inheritdoc IAjnaDripper */
    function setup(
        IAjnaRedeemer _redeemer,
        uint256 _weeklyAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(redeemer) == address(0), "drip/redeemer-already-set");
        changeRedeemerInternal(_redeemer);

        require(weeklyAmount == 0, "drip/weekly-amount-already-set");
        changeWeeklyAmountInternal(_weeklyAmount);
    }

    /* @inheritdoc IAjnaDripper */
    function changeRedeemer(IAjnaRedeemer _redeemer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(redeemer) != address(0), "drip/redeemer-not-set");
        changeRedeemerInternal(_redeemer);
    }

    /* @inheritdoc IAjnaDripper */
    function changeWeeklyAmount(uint256 _weeklyAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(lastUpdate + 4 weeks < block.timestamp, "drip/invalid-timestamp");
        changeWeeklyAmountInternal(_weeklyAmount);
    }

    /* @inheritdoc IAjnaDripper */
    function emergencyWithdraw(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(ajnaToken.balanceOf(address(this)) >= amount, "drip/insufficient-balance");
        require(ajnaToken.transfer(beneficiary, amount), "drip/transfer-failed");
    }

    function changeRedeemerInternal(IAjnaRedeemer _redeemer) internal {
        require(address(_redeemer) != address(0), "drip/invalid-redeemer");
        revokeRole(REDEEMER_ROLE, address(redeemer));
        grantRole(REDEEMER_ROLE, address(_redeemer));
        redeemer = _redeemer;
        emit RedeemerChanged(getCurrentWeek(), address(redeemer), address(_redeemer));
    }

    function changeWeeklyAmountInternal(uint256 _weeklyAmount) internal {
        validateWeeklyAmount(_weeklyAmount);
        weeklyAmount = _weeklyAmount;
        lastUpdate = block.timestamp;
        emit WeeklyAmountChanged(getCurrentWeek(), weeklyAmount, _weeklyAmount);
    }
}
