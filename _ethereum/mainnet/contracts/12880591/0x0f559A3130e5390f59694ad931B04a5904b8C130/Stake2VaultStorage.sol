//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

//import "./IStake2VaultStorage.sol";
import "./AccessibleCommon.sol";

/// @title the storage of StakeVaultStorage
contract Stake2VaultStorage is AccessibleCommon {
    /// @dev reward token : TOS
    address public tos;

    /// @dev name
    string public name;

    /// @dev allocated amount of tos
    uint256 public cap;

    /// @dev reward amount per block
    uint256 public rewardPerBlock;

    /// @dev Operation type of staking amount
    uint256 public stakeType;

    /// @dev a stakeContract maintained by the vault
    address public stakeAddress;

    uint256 private _lock;

    /// @dev flag for pause proxy
    bool public pauseProxy;

    ///@dev for migrate L2
    bool public migratedL2;

    modifier lock() {
        require(_lock == 0, "Stake2VaultStorage: LOCKED");
        _lock = 1;
        _;
        _lock = 0;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Stake2VaultStorage: zero address");
        _;
    }
    modifier nonZero(uint256 _value) {
        require(_value > 0, "Stake2VaultStorage: zero value");
        _;
    }
}
