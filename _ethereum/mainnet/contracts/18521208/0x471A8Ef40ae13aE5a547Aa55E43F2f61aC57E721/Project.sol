// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IMembership.sol";
import "./IProjectFactory.sol";
import "./ERC20.sol";

contract Project is Initializable, ERC20Upgradeable, OwnableUpgradeable {

    struct StakeInfo {
        uint256 depositedAmount;
        uint256 claimedValue;
        uint256 lastCalculateTimestamp;
        uint256 accumulatedReward;
        bool isStaked;
    }

    uint256 constant private MAX_BPS = 10000;

    IProjectFactory public factory;

    string public title;
    string public description;
    string public image;
    string public projectLink;
    uint256 public termOfInvestment;
    uint256 public apy;

    mapping(uint256 => StakeInfo) public stakeInfo;
    mapping(uint256 => uint256) public deposited;
    mapping(uint256 => bool) public allowedWithdraw;
    mapping(uint256 => bool) public allowedClaim;

    event Deposit(uint256 membershipId, uint256 amount);
    event Claim(uint256 membershipId, uint256 amount);
    event Withdraw(uint256 membershipId, uint256 amount);
    event AllowClaim(uint256 membershipId);
    event AllowWithdraw(uint256 membershipId);

    function initialize(string memory _title, string memory name, string memory symbol, string memory _description, string memory _image, string memory _projectLink, uint256 _termOfInvestment, uint256 _apy) external initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        factory = IProjectFactory(msg.sender);
        title = _title;
        apy = _apy;
        image = _image;
        description = _description;
        termOfInvestment = _termOfInvestment;
        projectLink = _projectLink;
    }

    function deposit(uint256 membershipId, uint256 amount) external {
        address sender = msg.sender;

        IERC20 cocc = factory.coccToken();
        IMembership membership = factory.membership();

        require(membership.ownerOf(membershipId) == sender, "[deposit]: invalid membership");

        _mint(address(this), amount);
        _approve(address(this), address(membership), amount);
        membership.deposit(membershipId, address(this), amount);
        membership.transferFromERC20(membershipId, address(cocc), address(this), amount);

        StakeInfo storage _stakeInfo = stakeInfo[membershipId];
        if (_stakeInfo.isStaked) {
            uint256 earned = _earned(_stakeInfo);
            _stakeInfo.accumulatedReward += earned;
        } else {
            _stakeInfo.isStaked = true;
        }

        _stakeInfo.depositedAmount += amount;
        _stakeInfo.lastCalculateTimestamp = block.timestamp;
        emit Deposit(membershipId, amount);
    }

    function allowWithdraw(uint256 membershipId) external {
        require(msg.sender == factory.owner(), "[allowWithdraw]: sender is not superadmin");
        allowedWithdraw[membershipId] = true;
        emit AllowWithdraw(membershipId);
    }

    function allowClaim(uint256 membershipId) external {
        require(msg.sender == factory.owner(), "[allowClaim]: sender is not superadmin");
        allowedClaim[membershipId] = true;
        emit AllowClaim(membershipId);
    }

    function claim(uint256 membershipId) public {
        ERC20 usdt = ERC20(address(factory.rewardToken()));
        IMembership membership = factory.membership();

        StakeInfo storage _stakeInfo = stakeInfo[membershipId];

        require(allowedClaim[membershipId], "[claim]: claim is not allowed");
        require(membership.ownerOf(membershipId) == msg.sender, "[claim]: invalid membership");
        uint256 earned = (_stakeInfo.accumulatedReward + _earned(_stakeInfo)) * 1000;
        uint256 decimalDifference = 10 ** (uint256(ERC20(address(factory.coccToken())).decimals()) - uint256(usdt.decimals()));
        usdt.approve(address(membership), earned / decimalDifference);
        membership.deposit(membershipId, address(usdt), earned / decimalDifference);

        _stakeInfo.lastCalculateTimestamp = block.timestamp;
        _stakeInfo.accumulatedReward = 0;
        _stakeInfo.claimedValue += earned;

        allowedClaim[membershipId] = false;

        emit Claim(membershipId, earned);
    }

    function withdraw(uint256 membershipId) external {
        IERC20 cocc = factory.coccToken();
        IMembership membership = factory.membership();

        require(membership.ownerOf(membershipId) == msg.sender, "[withdraw]: invalid membership");
        require(allowedWithdraw[membershipId], "[withdraw]: withdraw is not allowed");

        StakeInfo storage _stakeInfo = stakeInfo[membershipId];

        require(_stakeInfo.isStaked, "[withdraw]: not staked");

        uint256 earned = _earned(_stakeInfo);
        _stakeInfo.accumulatedReward += earned;

        cocc.approve(address(membership), _stakeInfo.depositedAmount);
        membership.deposit(membershipId, address(cocc), _stakeInfo.depositedAmount);
        membership.transferFromERC20(membershipId, address(this), address(this), _stakeInfo.depositedAmount);

        allowedWithdraw[membershipId] = false;

        emit Withdraw(membershipId, _stakeInfo.depositedAmount);

        _stakeInfo.depositedAmount = 0;
        _stakeInfo.isStaked = false;
        _stakeInfo.claimedValue = 0;
        _stakeInfo.lastCalculateTimestamp = 0;
    }

    function _earned(StakeInfo memory _stakeInfo) internal view returns (uint256) {
        uint256 passedTime = block.timestamp - _stakeInfo.lastCalculateTimestamp;
        return _stakeInfo.depositedAmount * apy / MAX_BPS / termOfInvestment * passedTime;
    }

    function estimateProfitPerTerm(uint256 membershipId) external view returns (uint256) {
        return stakeInfo[membershipId].depositedAmount * apy / MAX_BPS + stakeInfo[membershipId].accumulatedReward;
    }

}