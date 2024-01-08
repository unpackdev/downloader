pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./TornVault.sol";
import "./Governance.sol";

/// @title Version 2 Governance contract of the tornado.cash governance
contract GovernanceV2 is Governance {
    // vault which stores user TORN
    TornVault public userVault;

    // information on whether someone's tokens are still in governance
    mapping(address => bool) public isBalanceMigrated;

    // call Governance v1 constructor
    constructor() public Governance() {}

    /// @notice Deploys the vault to hold user tokens
    /// @return Boolean, if true, deployment succeeded
    function deployVault() external returns (bool) {
        require(address(userVault) == address(0), "vault already deployed");
        userVault = new TornVault();
        assert(address(userVault) != address(0));
        torn.approve(address(userVault), type(uint256).max);
        return true;
    }

    /// @notice Withdraws TORN from governance if conditions permit
    /// @param amount the amount of TORN to withdraw
    function unlock(uint256 amount) external override {
        if (!isBalanceMigrated[msg.sender]) {
            if (lockedBalance[msg.sender] == 0) {
                isBalanceMigrated[msg.sender] = true;
            } else {
                migrateTORN();
            }
        }
        require(
            getBlockTimestamp() > canWithdrawAfter[msg.sender],
            "Governance: tokens are locked"
        );
        lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(
            amount,
            "Governance: insufficient balance"
        );
        require(userVault.withdrawTorn(amount), "withdrawTorn failed");
        require(torn.transfer(msg.sender, amount), "TORN: transfer failed");
    }

    /// @notice checker for success on deployment
    /// @return returns precise version of governance
    function version() external pure virtual returns (string memory) {
        return "2.vault-migration";
    }

    /// @notice transfers tokens from the contract to the vault, withdrawals are unlock()
    /// @param owner account/contract which (this) spender will send to the user vault
    /// @param amount amount which spender will send to the user vault
    function _transferTokens(address owner, uint256 amount) internal override {
        if (!isBalanceMigrated[msg.sender]) {
            if (lockedBalance[msg.sender] == 0) {
                isBalanceMigrated[msg.sender] = true;
            } else {
                migrateTORN();
            }
        }
        require(
            torn.transferFrom(owner, address(userVault), amount),
            "TORN: transferFrom failed"
        );
        lockedBalance[owner] = lockedBalance[owner].add(amount);
    }

    /// @notice migrates TORN for both unlock() and _transferTokens (which is part of 2 lock functions)
    function migrateTORN() internal {
        require(!isBalanceMigrated[msg.sender], "cannot migrate twice");
        require(
            torn.transfer(address(userVault), lockedBalance[msg.sender]),
            "TORN: transfer failed"
        );
        isBalanceMigrated[msg.sender] = true;
    }
}
