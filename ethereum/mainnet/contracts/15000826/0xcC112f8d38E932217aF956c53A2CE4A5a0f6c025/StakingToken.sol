// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";
import "./Staking.sol";

contract StakingToken is ERC20 {
    Staking public stakingPool;

    constructor(
        string memory _name,
        string memory _symbol,
        address _stakingPool
    ) ERC20(_name, _symbol) {
        stakingPool = Staking(_stakingPool);
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 len = stakingPool.getDepositsOfLength(account);
        Staking.Deposit[] memory deposits = stakingPool.getDepositsOf(
            account,
            0,
            len
        );
        uint256 balance;
        for (uint256 i = 0; i < len; i++) {
            balance = balance + deposits[i].amount;
        }
        return balance * 2;
    }

    function totalSupply() public view override returns (uint256) {
        return stakingPool.totalStaked() * 2;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        revert("non-transferable");
    }
}
