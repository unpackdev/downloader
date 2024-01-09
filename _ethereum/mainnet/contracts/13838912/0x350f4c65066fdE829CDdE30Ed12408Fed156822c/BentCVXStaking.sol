// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Errors.sol";
import "./IBentCVXRewarder.sol";

contract BentCVXStaking is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event AddRewarder(address indexed rewarder);
    event RemoveRewarder(address indexed rewarder);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimAll(address indexed user);
    event Claim(address indexed user, uint256[][] indexes);
    event OnReward();

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    IERC20Upgradeable public bentCVX;
    IBentCVXRewarder[] public rewarders;
    mapping(address => bool) public isRewarder;

    function initialize(address _bentCVX) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        bentCVX = IERC20Upgradeable(_bentCVX);
    }

    function addRewarder(address _rewarder) external onlyOwner {
        require(isRewarder[_rewarder] == false, Errors.INVALID_REQUEST);

        rewarders.push(IBentCVXRewarder(_rewarder));
        isRewarder[_rewarder] = true;

        emit AddRewarder(_rewarder);
    }

    function removeRewarder(uint256 _index) external onlyOwner {
        require(_index < rewarders.length && isRewarder[address(rewarders[_index])], Errors.INVALID_INDEX);

        emit RemoveRewarder(address(rewarders[_index]));

        isRewarder[address(rewarders[_index])] = false;
        rewarders[_index] = IBentCVXRewarder(address(0));
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount != 0, Errors.ZERO_AMOUNT);

        bentCVX.safeTransferFrom(msg.sender, address(this), _amount);

        _mint(msg.sender, _amount);

        for (uint256 i = 0; i < rewarders.length; i++) {
            if (address(rewarders[i]) == address(0)) {
                continue;
            }

            rewarders[i].deposit(msg.sender, _amount);
        }

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(
            balanceOf[msg.sender] >= _amount && _amount != 0,
            Errors.INVALID_AMOUNT
        );

        for (uint256 i = 0; i < rewarders.length; i++) {
            if (address(rewarders[i]) == address(0)) {
                continue;
            }

            rewarders[i].withdraw(msg.sender, _amount);
        }

        _burn(msg.sender, _amount);

        // transfer to msg.sender
        bentCVX.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    function claimAll() external virtual nonReentrant {
        bool claimed = false;

        for (uint256 i = 0; i < rewarders.length; i++) {
            if (address(rewarders[i]) == address(0)) {
                continue;
            }

            if (rewarders[i].claimAll(msg.sender)) {
                claimed = true;
            }
        }

        require(claimed, Errors.NO_PENDING_REWARD);

        emit ClaimAll(msg.sender);
    }

    function claim(uint256[][] memory _indexes) external nonReentrant {
        require(_indexes.length == rewarders.length, Errors.INVALID_INDEX);

        bool claimed = false;
        for (uint256 i = 0; i < _indexes.length; i++) {
            if (address(rewarders[i]) == address(0)) {
                continue;
            }

            if (rewarders[i].claim(msg.sender, _indexes[i])) {
                claimed = true;
            }
        }
        require(claimed, Errors.NO_PENDING_REWARD);

        emit Claim(msg.sender, _indexes);
    }

    function _mint(address _user, uint256 _amount) internal {
        balanceOf[_user] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _user, uint256 _amount) internal {
        balanceOf[_user] -= _amount;
        totalSupply -= _amount;
    }
}
