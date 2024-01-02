// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IRstStakingPool.sol";

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract RstStakingPool is AccessControl {

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    using SafeERC20 for IERC20;

    uint256 public rewardRate;
    uint256 public minRewardStake;

    uint256 public maxBonus;
    uint256 public bonusDuration;
    uint256 public bonusRate;

    IERC20 public rstToken;
    IERC20 public rewardToken; 

    // Universal variables
    uint256 public totalSupply;

    IRstStakingPool.GeneralRewardVars public generalRewardVars;

    // account specific variables

    mapping(address => IRstStakingPool.AccountRewardVars) public accountRewardVars;
    mapping(address => IRstStakingPool.AccountVars) public accountVars;
    mapping(address => uint256) public staked;

    constructor(address _rstToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        rstToken = IERC20(_rstToken);
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "not owner"
        );
        _;
    }

    modifier onlyEditor() {
        require(
            hasRole(EDITOR_ROLE, _msgSender()),
            "not editor"
        );
        _;
    }









    function setRewardRate(uint256 _rewardRate) external onlyEditor {
        rewardRate = _rewardRate;
    }
    function setMinRewardStake(uint256 _minRewardStake) external onlyEditor {
        minRewardStake = _minRewardStake;
    }

    function setMaxBonus(uint256 _maxBonus) external onlyEditor {
        maxBonus = _maxBonus;
    }
    function setBonusDuration(uint256 _bonusDuration) external onlyEditor {
        bonusDuration = _bonusDuration;
    }
    function setBonusRate(uint256 _bonusRate) external onlyEditor {
        bonusRate = _bonusRate;
    }

    function setRewardToken(address _rewardTokenAddress) external onlyOwner {
        require (_rewardTokenAddress != address(rstToken), "bad addr");
        rewardToken = IERC20(_rewardTokenAddress);
    }

    function setGeneralRewardVars(IRstStakingPool.GeneralRewardVars memory _generalRewardVars) external onlyEditor {
        generalRewardVars = _generalRewardVars;
    }

    function setAccountRewardVars(address _user, IRstStakingPool.AccountRewardVars memory _accountRewardVars) external onlyEditor {
        accountRewardVars[_user] = _accountRewardVars;
    }

    function setAccountVars(address _user, IRstStakingPool.AccountVars memory _accountVars) external onlyEditor {
        accountVars[_user] = _accountVars;
    }

    function stakeTokens(address _user, uint256 _amount) external onlyEditor {
        rstToken.safeTransferFrom(_user, address(this), _amount);
        staked[_user] = staked[_user] + _amount;
        totalSupply = totalSupply + _amount;
    }

    function withdrawTokens(address _user, uint256 _amount) external onlyEditor {
        staked[_user] = staked[_user] - _amount;
        totalSupply = totalSupply - _amount;
        rstToken.safeTransfer(_user, _amount);
    }

    function withdrawRewardToken(address _user, uint256 _amount) external onlyEditor {        
        rewardToken.safeTransfer(_user, _amount);
    }
}
