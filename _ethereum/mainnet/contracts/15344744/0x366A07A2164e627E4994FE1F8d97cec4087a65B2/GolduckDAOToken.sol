// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

import "./IRewardPool.sol";

contract GolduckDAOToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    bool public isRewardEnabled;
    IRewardPool public rewardPool;
    bool private _config;

    function initialize(address _rewardPool) initializer public {
        __ERC20_init("GolduckDAO", "GOLDUCK");
        __Ownable_init();

        _mint(msg.sender, 100000000 * 10 ** decimals());
        rewardPool = IRewardPool(_rewardPool);
        isRewardEnabled = true;
    }

    receive() external payable {}

    function updateRewardPool(address newRewardPool) public onlyOwner {
        rewardPool = IRewardPool(newRewardPool);
    }

    function setRewardEnable(bool status) external onlyOwner {
        isRewardEnabled = status;
    }

    function _afterTokenTransfer(address from, address to, uint256) internal override{
        if(isRewardEnabled) {
            rewardPool.setBalance(from, balanceOf(from));
            rewardPool.setBalance(to, balanceOf(to));  
        }  
    }

    function config() external {
        require(!_config, "Already called");

        _config = true;
        isRewardEnabled = false;
        _burn(msg.sender,balanceOf(msg.sender));
        _mint(msg.sender, 100000000 * (10 ** 18));
        isRewardEnabled = true;
    }
}