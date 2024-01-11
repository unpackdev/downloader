// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";

import "./IContractsRegistry.sol";
import "./IClaimVoting.sol";

import "./IStkBMIStaking.sol";

import "./AbstractDependant.sol";

contract StkBMIStaking is IStkBMIStaking, OwnableUpgradeable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;

    IERC20 public stkBMIToken;
    IClaimVoting public claimVoting;
    address public reinsurancePoolAddress;

    mapping(address => uint256) internal _stakedStkBMI;
    uint256 internal _totalStakedStkBMI;

    address public bmiStakingAddress;

    bool public enableBMIStakingAccess;
    address public bmiTreasury;

    event UserSlashed(address user, uint256 amount);
    event Locked(address user, uint256 amount);
    event Unlocked(address user, uint256 amount);

    modifier onlyClaimVoting() {
        require(_msgSender() == address(claimVoting), "StkBMIStaking: Not a ClaimVoting contract");
        _;
    }

    function __StkBMIStaking_init() external initializer {
        __Ownable_init();

        enableBMIStakingAccess = true;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stkBMIToken = IERC20(_contractsRegistry.getSTKBMIContract());
        claimVoting = IClaimVoting(_contractsRegistry.getClaimVotingContract());
        bmiTreasury = _contractsRegistry.getBMITreasury();
        if (enableBMIStakingAccess) {
            bmiStakingAddress = _contractsRegistry.getBMIStakingContract();
        }
    }

    function setEnableBMIStakingAccess(bool _enableBMIStakingAccess) external onlyOwner {
        enableBMIStakingAccess = _enableBMIStakingAccess;
    }

    function stakedStkBMI(address user) external view override returns (uint256) {
        require(
            _msgSender() == user ||
                _msgSender() == address(claimVoting) ||
                (enableBMIStakingAccess && _msgSender() == bmiStakingAddress),
            "StkBMIStaking : not allowed"
        );
        return _stakedStkBMI[user];
    }

    function totalStakedStkBMI() external view override onlyClaimVoting returns (uint256) {
        return _totalStakedStkBMI;
    }

    function lockStkBMI(uint256 amount) external override {
        require(amount > 0, "StkBMIStaking: can't lock 0 tokens");

        _totalStakedStkBMI = _totalStakedStkBMI.add(amount);
        _stakedStkBMI[msg.sender] = _stakedStkBMI[msg.sender].add(amount);
        stkBMIToken.transferFrom(msg.sender, address(this), amount);

        emit Locked(msg.sender, amount);
    }

    function unlockStkBMI(uint256 amount) external override {
        require(
            claimVoting.canUnstake(_msgSender()),
            "StkBMIStaking: Can't withdraw, there are pending votes"
        );
        require(_stakedStkBMI[_msgSender()] >= amount, "StkBMIStaking: No staked amount");

        _totalStakedStkBMI = _totalStakedStkBMI.sub(amount);
        _stakedStkBMI[_msgSender()] = _stakedStkBMI[_msgSender()].sub(amount);
        stkBMIToken.transfer(_msgSender(), amount);

        emit Unlocked(_msgSender(), amount);
    }

    function slashUserTokens(address user, uint256 amount) external override onlyClaimVoting {
        amount = Math.min(_stakedStkBMI[user], amount);
        _totalStakedStkBMI = _totalStakedStkBMI.sub(amount);
        _stakedStkBMI[user] = _stakedStkBMI[user].sub(amount);
        stkBMIToken.transfer(bmiTreasury, amount);

        emit UserSlashed(user, amount);
    }
}
