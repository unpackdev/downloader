// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./IEGMC.sol";
import "./IWETH.sol";
import "./IEGMCRewardsDistributor.sol";

contract EGMCMine is Ownable {
    using Address for address payable;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IEGMC public immutable token;
    IWETH public immutable WETH;

    uint private constant REWARD_FACTOR_ACCURACY = 1_000_000_000_000 ether;
    uint private constant PERCENTAGE_DENOMINATOR = 10 ** 3;

    address public rewardsDistributor;
    address public shareholderDistributor;
    uint public allTimeGoldRewards;
    uint public allTimeGoldRewardsClaimed;
    uint public allTimeSilverRewards;
    uint public allTimeSilverRewardsClaimed;
    uint public totalMiningPower;
    uint public currentGoldRewardFactor;
    uint public currentSilverRewardFactor;
    bool public isDepositingEnabled;

    uint public currentEpoch;
    uint public mineShare = 400;

    struct Tool {
        bool enabled;
        uint miningPower;
        uint cost;
    }

    struct User {
        uint goldRewardFactor;
        uint goldHeldRewards;
        uint silverRewardFactor;
        uint silverHeldRewards;
        uint miningPower;
    }

    mapping(uint => Tool) public tools;
    mapping(address => User) private _users;
    mapping(address => bool) private _whitelisted;

    event DepositingEnabled();
    event DepositingDisabled();
    event Purchased(address user, uint amount);
    event Claimed(address user, uint goldRewards, uint silverRewards);
    event Distributed(uint goldRewards, uint silverRewards, uint totalMiningPower);
    event NewEpoch(uint oldEpoch, uint newEpoch);

    constructor (
        address _token
    ) {
        token = IEGMC(_token);
        WETH = IWETH(token.WETH());

        _setTool(0, true, 5, 184.80 ether);
        _setTool(1, true, 10, 351.12 ether);
        _setTool(2, true, 50, 1663.20 ether);

        _whitelisted[_msgSender()] = true;
    }

    /** VIEW FUNCTIONS */

    function getAmounts() external view returns (uint goldAmount, uint silverAmount) {
        (goldAmount, silverAmount) = IEGMCRewardsDistributor(rewardsDistributor).getAmounts();
    }

    function getMiningPower(address _user) external view returns (uint) {
        return _users[_user].miningPower;
    }

    function getReward(address _user) external view returns (uint goldReward, uint silverReward) {
        goldReward = _getGoldHeldRewards(_user) + _getGoldCalculatedRewards(_user);
        silverReward = _getSilverHeldRewards(_user) + _getSilverCalculatedRewards(_user);
    }

    function _getGoldHeldRewards(address _user) private view returns (uint) {
        return _users[_user].goldHeldRewards;
    }

    function _getSilverHeldRewards(address _user) private view returns (uint) {
        return _users[_user].silverHeldRewards;
    }

    function _getGoldCalculatedRewards(address _user) private view returns (uint) {
        uint balance = _users[_user].miningPower;
        return balance * (currentGoldRewardFactor - _users[_user].goldRewardFactor) / REWARD_FACTOR_ACCURACY;
    }

    function _getSilverCalculatedRewards(address _user) private view returns (uint) {
        uint balance = _users[_user].miningPower;
        return balance * (currentSilverRewardFactor - _users[_user].silverRewardFactor) / REWARD_FACTOR_ACCURACY;
    }

    function _mergeRewards(address _account) private {
        _holdCalculatedRewards(_account);
        _users[_account].goldRewardFactor = currentGoldRewardFactor;
        _users[_account].silverRewardFactor = currentSilverRewardFactor;
    }

    function _holdCalculatedRewards(address _account) private {
        uint calculatedGoldReward = _getGoldCalculatedRewards(_account);
        if (calculatedGoldReward > 0) {
            _users[_account].goldHeldRewards += calculatedGoldReward;
        }

        uint calculatedSilverReward = _getSilverCalculatedRewards(_account);
        if (calculatedSilverReward > 0) {
            _users[_account].silverHeldRewards += calculatedSilverReward;
        }
    }

    /** INTERNAL FUNCTIONS */

    function _distribute() internal {
        if (totalMiningPower > 0) {
            (uint goldAmount, uint silverAmount) = IEGMCRewardsDistributor(rewardsDistributor).distribute();

            if (goldAmount > 0) {
                allTimeGoldRewards += goldAmount;
                currentGoldRewardFactor += REWARD_FACTOR_ACCURACY * goldAmount / totalMiningPower;
            }

            if (silverAmount > 0) {
                allTimeSilverRewards += silverAmount;
                currentSilverRewardFactor += REWARD_FACTOR_ACCURACY * silverAmount / totalMiningPower;
            }

            emit Distributed(goldAmount, silverAmount, totalMiningPower);
        }
    }

    function _updateUser(address _user, uint _miningPower) internal {
        _mergeRewards(_user);
        _users[_user].miningPower += _miningPower;
        totalMiningPower += _miningPower;
    }

    function _setEpoch() internal {
        uint newEpoch = uint(block.timestamp / 1 hours);
        emit NewEpoch(currentEpoch, newEpoch);
        currentEpoch = newEpoch;
    }

    function _setTool(uint _id, bool _enabled, uint _miningPower, uint _cost) internal {
        tools[_id] = Tool(_enabled, _miningPower, _cost);
    }

    /** EXTERNAL FUNCTIONS */

    function purchase(uint _id, uint _quantity) external checkIfNewEpoch {
        require(isDepositingEnabled, "Depositing is not allowed at this time");
        require(tools[_id].enabled, "This tool is not enabled");

        uint miningPower = tools[_id].miningPower * _quantity;
        _updateUser(_msgSender(), miningPower);

        uint totalCost = tools[_id].cost * _quantity;
        IERC20(address(token)).safeTransferFrom(_msgSender(), address(this), totalCost);

        uint mineAmount = totalCost * mineShare / PERCENTAGE_DENOMINATOR;
        IERC20(address(token)).safeTransfer(rewardsDistributor, mineAmount);
        IERC20(address(token)).safeTransfer(shareholderDistributor, totalCost - mineAmount);

        emit Purchased(_msgSender(), miningPower);
    }

    function claim() external checkIfNewEpoch {
        _mergeRewards(_msgSender());

        uint goldHeldRewards = _users[_msgSender()].goldHeldRewards;
        if (goldHeldRewards > 0) {
            _users[_msgSender()].goldHeldRewards = 0;
            allTimeGoldRewardsClaimed += goldHeldRewards;

            uint balanceBefore = address(this).balance;
            WETH.withdraw(goldHeldRewards);
            payable(_msgSender()).sendValue(address(this).balance - balanceBefore);
        }

        uint silverHeldRewards = _users[_msgSender()].silverHeldRewards;
        if (silverHeldRewards > 0) {
            _users[_msgSender()].silverHeldRewards = 0;
            allTimeSilverRewardsClaimed += silverHeldRewards;
            IERC20(token).safeTransfer(_msgSender(), silverHeldRewards);
        }

        emit Claimed(_msgSender(), goldHeldRewards, silverHeldRewards);
    }

    /** RESTRICTED FUNCTIONS */

    function distribute() external {
        require(_whitelisted[_msgSender()], "Caller is not whitelisted!");
        _distribute();
        _setEpoch();
    }

    function enableDepositing() external onlyOwner {
        require(!isDepositingEnabled, "Depositing is already enabled");
        isDepositingEnabled = true;
        _setEpoch();
        emit DepositingEnabled();
    }

    function disableDepositing() external onlyOwner {
        require(isDepositingEnabled, "Depositing is already disabled");
        isDepositingEnabled = false;
        emit DepositingDisabled();
    }

    function setRewardsDistributor(address _distributor) external onlyOwner {
        rewardsDistributor = _distributor;
    }

    function setShareholderDistributor(address _distributor) external onlyOwner {
        shareholderDistributor = _distributor;
    }

    function setTool(uint id, bool enabled, uint miningPower, uint cost) external onlyOwner {
        _setTool(id, enabled, miningPower, cost);
    }

    function setWhitelist(address _account, bool _enabled) external onlyOwner {
        _whitelisted[_account] = _enabled;
    }

    function recover(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function recover() external onlyOwner {
        payable(owner()).sendValue(address(this).balance);
    }

    /** MODIFIERS */

    modifier checkIfNewEpoch() {
        if (uint(block.timestamp / 1 hours) > currentEpoch) {
            _distribute();
            _setEpoch();
        }

        _;
    }

    receive() external payable {}
}