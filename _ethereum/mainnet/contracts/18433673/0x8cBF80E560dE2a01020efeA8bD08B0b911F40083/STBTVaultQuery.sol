// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IERC20.sol";
import "SafeERC20.sol";
import "Operator.sol";
import "Address.sol";
import "ISTBTVault.sol";

contract STBTVaultQuery is Operator {

    struct AccountInfo {
        uint256 fee;
        uint256 feeTo;
        uint256 gasthreshold;
        uint256 minimumRequest;
        uint256 withdrawLockupEpochs;
        uint256 epoch;
        uint256 period;
        uint256 nextEpochPoint;
        uint256 total_supply_staked;
        uint256 total_supply_wait;
        uint256 total_supply_withdraw;

        uint256 balanceOfUSDC;
        int256 balance_reward;
        uint256 balance_staked;
        uint256 balance_wait;
        uint256 balance_withdraw;
        bool canWithdraw;
        int256 earned;
        uint256 approvedAmount;
        uint256 stake_request_epoch;
        uint256 withdraw_request_amount;
        uint256 withdraw_request_epoch;
    }

    struct VaultInfo {
        uint256 fee;
        uint256 feeTo;
        uint256 gasthreshold;
        uint256 minimumRequest;
        uint256 withdrawLockupEpochs;
        uint256 epoch;
        uint256 period;
        uint256 nextEpochPoint;
        uint256 total_supply_staked;
        uint256 total_supply_wait;
        uint256 total_supply_withdraw;
    }

    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    using SafeERC20 for IERC20;

    function queryAccountData(address vault, address user) external view returns (AccountInfo memory accountInfo) {
        accountInfo.fee = ISTBTVault(vault).fee();
        accountInfo.feeTo = ISTBTVault(vault).feeTo();
        accountInfo.gasthreshold = ISTBTVault(vault).gasthreshold();
        accountInfo.minimumRequest = ISTBTVault(vault).minimumRequest();
        accountInfo.withdrawLockupEpochs = ISTBTVault(vault).withdrawLockupEpochs();
        accountInfo.total_supply_staked = ISTBTVault(vault).total_supply_staked();
        accountInfo.total_supply_wait = ISTBTVault(vault).total_supply_wait();
        accountInfo.total_supply_withdraw = ISTBTVault(vault).total_supply_withdraw();
        accountInfo.epoch = ISTBTVault(vault).epoch();
        accountInfo.period = ISTBTVault(vault).period();
        accountInfo.nextEpochPoint = ISTBTVault(vault).nextEpochPoint();

        accountInfo.balanceOfUSDC = IERC20(usdc).balanceOf(user);
        accountInfo.balance_reward = ISTBTVault(vault).balance_reward(user);
        accountInfo.balance_staked = ISTBTVault(vault).balance_staked(user);
        accountInfo.balance_wait = ISTBTVault(vault).balance_wait(user);
        accountInfo.balance_withdraw = ISTBTVault(vault).balance_withdraw(user);
        accountInfo.canWithdraw = ISTBTVault(vault).canWithdraw(user);
        accountInfo.earned = ISTBTVault(vault).earned(user);
        accountInfo.approvedAmount = IERC20(usdc).allowance(user, vault);

        
        ISTBTVault.StakeInfo memory stakeInfo = ISTBTVault(vault).stakeRequest(user);
        ISTBTVault.WithdrawInfo memory withdrawInfo = ISTBTVault(vault).withdrawRequest(user);

        accountInfo.stake_request_epoch = stakeInfo.requestEpoch;
        accountInfo.withdraw_request_epoch = withdrawInfo.requestEpoch;
        accountInfo.withdraw_request_amount = withdrawInfo.amount;
        
    }

    function queryVaultData(address vault) external view returns (VaultInfo memory vaultInfo) {
        vaultInfo.fee = ISTBTVault(vault).fee();
        vaultInfo.feeTo = ISTBTVault(vault).feeTo();
        vaultInfo.gasthreshold = ISTBTVault(vault).gasthreshold();
        vaultInfo.minimumRequest = ISTBTVault(vault).minimumRequest();
        vaultInfo.withdrawLockupEpochs = ISTBTVault(vault).withdrawLockupEpochs();
        vaultInfo.total_supply_staked = ISTBTVault(vault).total_supply_staked();
        vaultInfo.total_supply_wait = ISTBTVault(vault).total_supply_wait();
        vaultInfo.total_supply_withdraw = ISTBTVault(vault).total_supply_withdraw();
        vaultInfo.epoch = ISTBTVault(vault).epoch();
        vaultInfo.period = ISTBTVault(vault).period();
        vaultInfo.nextEpochPoint = ISTBTVault(vault).nextEpochPoint();
    }

    // to help users who accidentally send their tokens to this contract
    function governanceWithdrawFunds(address _token, uint256 amount, address to) external onlyOperator {
        require(to != address(0), "to address can not be zero address");
        IERC20(_token).safeTransfer(to, amount);
    }

    function governanceWithdrawFundsETH(uint256 amount, address to) external onlyOperator {
        require(to != address(0), "to address can not be zero address");
        Address.sendValue(payable(to), amount);
    }
}