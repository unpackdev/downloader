// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./IcCRV.sol";
import "./IRewards.sol";

contract cvxCRVDepositor is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public cvxCRV;
    IcCRV public cCRV;
    IRewards public rewards;

    address public operator;

    bool public limitedToGranted;
    mapping(address => uint) public granted;

    event Deposit(address indexed user, uint amount);

    function initialize(IERC20 _cvxCRV, IcCRV _cCRV, IRewards _cvxCRVRewards) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        cvxCRV = _cvxCRV;
        cCRV = _cCRV;
        rewards = _cvxCRVRewards;

        limitedToGranted = true;

        setApprove();
    }

    function setApprove() public {
        cvxCRV.approve(address(rewards), type(uint).max);
    }

    function setOperator(address op_) external onlyOwner {
        operator = op_;
    }

    function setLimitedToGranted(bool limit) external onlyOwner {
        limitedToGranted = limit;
    }

    function updateGranted(address[] calldata accounts, uint[] calldata grants) external onlyOwner {
        require(accounts.length == grants.length, "Invalid data");
        for(uint i; i < accounts.length; i++) {
            granted[accounts[i]] = grants[i];
        }
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!authorized");
        _;
    }

    // Deposits will temporarily only be permitted from authorized addresses
    function deposit(uint amount) external {
        require(!limitedToGranted || granted[msg.sender] != 0, "!authorized");

        _depositCvxCRV(amount);
        cCRV.mint(msg.sender, amount);
    }

    // cvxCRV backing will continue to accumulate from donations
    function donate(uint amount) external {
        _depositCvxCRV(amount);
    }

    function _depositCvxCRV(uint amount) internal {
        cvxCRV.safeTransferFrom(msg.sender, address(this), amount);
        rewards.stake(amount);
    }

    // We have to keep this method in case of convex upgrades
    function withdrawFromConvex(uint amount, bool claim) external onlyOwner {
        rewards.withdraw(amount, claim);
    }

    // Rewards will be distributed by RewardDistributor contract
    function getRewardFromConvex(address[] calldata tokens, address[] calldata receivers) external onlyOperator {
        rewards.getReward();
        _withdrawToken(tokens, receivers);
    }

    function _withdrawToken(address[] calldata tokens, address[] calldata receivers) internal {
        require(tokens.length == receivers.length, "_withdrawToken: invalid data");
        for (uint i; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(receivers[i], IERC20(tokens[i]).balanceOf(address(this)));
        }
    }

    function withdrawToken(address[] calldata tokens, address[] calldata receivers) external onlyOwner {
        _withdrawToken(tokens, receivers);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
    }
}
