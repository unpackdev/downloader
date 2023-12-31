// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBotVault.sol";
import "./VaultBase.sol";
import "./Strings.sol";
import "./IRoboFiGame.sol";


struct RegularVaultData {
    mapping(uint => RegularVaultOption) option;
}

contract RegularVault is VaultBase, IBotVaultEvent {

    using SafeERC20 for IERC20;

    bytes32 constant VAULT_DATA_POSITION = keccak256('data.regular.vault');

    uint constant PRECISION = 1e18;

    modifier nonRestricted(uint vID) {
        require(!vaultData().option[vID].restricted, Errors.RV_VAULT_IS_RESTRICTED);
        _;
    }

    function vaultData() internal pure returns(RegularVaultData storage ds) {
        bytes32 position = VAULT_DATA_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setVaultOption(uint vID, bytes calldata data) external ownedBotOnly(vID) { 
        vaultData().option[vID] = abi.decode(data, (RegularVaultOption));
    }

    function getVaultOption(uint vID) external view returns(bytes memory result) {
        result = abi.encode(vaultData().option[vID]);
    }

    function getVaultInfo(uint vID, address account) external view returns(VaultInfo memory result) {
        Vault storage vault = _vaultOf(vID);
        result.data = vault.data;
        result.user = vault.users[account];
        result.totalDeposit = vault.totalDeposit;
        result.accRewardPerShare = vault.accRewardPerShare;
        result.lastRewardTime = vault.lastRewardTime;
        result.pendingReward = _pendingReward(vault, account);
        result.option = abi.encode(vaultData().option[vID]);
    }

    function pendingReward(uint vID, address account) public view returns(uint) {
        Vault storage vault = _vaultOf(vID);
        return _pendingReward(vault, account);
    }

    function deposit(uint vID, uint amount) external _validVault(vID) nonRestricted(vID) {
        _deposit(vID, _msgSender(), _msgSender(), amount, 0);
    }

    function delegateDeposit(uint vID, address payor, address account, uint amount, uint lock) external _validVault(vID) ownedBotOnly(vID) botOnly {
        _deposit(vID, payor, account, amount, lock);
    }

    function withdraw(uint vID, uint amount) external _validVault(vID) {
        _withdraw(vID, _msgSender(), amount);
    }

    function delegateWithdraw(uint vID, address account, uint amount) external _validVault(vID) ownedBotOnly(vID) botOnly {
        _withdraw(vID, account, amount);
    }

    function updateReward(uint vID, uint assetAmount) external _validVault(vID) botOnly {
        Vault storage vault = _vaultOf(vID);
        if (vault.totalDeposit > 0)
            vault.accRewardPerShare += assetAmount * PRECISION / vault.totalDeposit;
        else
            vault.accRewardPerShare = 0;

        vault.lastRewardTime = block.timestamp;
        emit RewardAdded(vID, assetAmount);
    }

    function claimReward(uint vID, address account) external _validVault(vID) {
        Vault storage vault = _vaultOf(vID);
        UserInfo storage user = vault.users[account];
        _claimReward(vID, vault, account);
        user.debt = user.deposit * vault.accRewardPerShare / PRECISION;
    }

    function snapshot(uint vID) external _validVault(vID) botOnly {
        _snapshot(vID);
    }

    function _snapshot(uint vID) private {
        Vault storage vault = _vaultOf(vID);
        vault.currentSnapshotId = block.number;
        emit Snapshot(vID, block.number);
    }

    function _pendingReward(Vault storage vault, address account) internal view returns(uint) {
        if (vault.data.botToken == address(0))
            return 0;
        UserInfo storage user = vault.users[account];
        uint reward = vault.accRewardPerShare * user.deposit / PRECISION;
        if (reward < user.debt)
            return 0;
        return reward - user.debt; 
    }

    function _claimReward(uint vID, Vault storage vault, address account) internal {
        uint reward = _pendingReward(vault, account);
        if (reward == 0)
            return; 
        IERC20(vault.data.asset).safeTransfer(account, reward);
        emit RewardClaimed(vID, account, reward);
    }

    function _deposit(uint vID, address payor, address account, uint amount, uint lock) internal {

        _snapshot(vID);

        Vault storage vault = _vaultOf(vID);
        UserInfo storage user = vault.users[account];

        _claimReward(vID, vault, account);

        if (amount != 0) {    
            if (payor != address(0))
                IERC20(vault.data.botToken).safeTransferFrom(payor, address(this), amount);
            _updateDepositSnapshot(vault, account, user.deposit);

            user.lockPeriod = lock;
            user.deposit += amount;
            vault.totalDeposit += amount;
            _generateTicket(vault, account, amount);
        }
        user.debt = user.deposit * vault.accRewardPerShare / PRECISION;
        user.lastDepositTime = block.timestamp; 

        emit Deposit(vID, payor, account, amount);
    }

    function _withdraw(uint vID, address account, uint amount) internal {
        Vault storage vault = _vaultOf(vID);
        UserInfo storage user = vault.users[account];

        require(block.timestamp >= user.lastDepositTime + user.lockPeriod, Errors.RV_DEPOSIT_LOCKED);

        _snapshot(vID);

        _claimReward(vID, vault, account);

        if (amount > 0) {
            require(amount <= user.deposit, Errors.RV_WITHDRAWL_AMOUNT_EXCEED_DEPOSIT);
            _updateDepositSnapshot(vault, account, user.deposit);
            
            user.deposit -= amount;
            vault.totalDeposit -= amount;
            _deleteTicket(vault, account, amount);
        }
        user.debt = user.deposit * vault.accRewardPerShare / PRECISION;
        IERC20(vault.data.botToken).safeTransfer(account, amount);
        emit Widthdraw(vID, account, amount);
    }

    function _updateDepositSnapshot(Vault storage vault, address account, uint currentValue) internal {
        DepositSnapshots storage shot = vault.userDepositSnapshots[account];
        if (shot.ids.length > 0 && 
            shot.ids[shot.ids.length - 1] == vault.currentSnapshotId)
            return;
        shot.ids.push(vault.currentSnapshotId);
        shot.values.push(currentValue);
    }

    function _generateTicket(Vault storage vault, address account, uint amount) private {
        VaultManagerData storage vaultManagerData = data();
        IConfigurator configurator = vaultManagerData.botManager.configurator();
        IRoboFiGame roboFiGame = IRoboFiGame(configurator.addressOf(AddressBook.ADDR_ROBOFI_GAME));
        roboFiGame.generateTicket(vault.data.bot, account, vault.data.botToken, uint112(amount));
    }

    function _deleteTicket(Vault storage vault, address account, uint amount) private {
        VaultManagerData storage vaultManagerData = data();
        IConfigurator configurator = vaultManagerData.botManager.configurator();
        IRoboFiGame roboFiGame = IRoboFiGame(configurator.addressOf(AddressBook.ADDR_ROBOFI_GAME));
        roboFiGame.deleteTicket(vault.data.bot, account, vault.data.botToken, uint112(amount));
    }
}
