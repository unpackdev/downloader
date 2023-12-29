//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

//import "./IStakeVaultStorage.sol";
import "./LibTokenStake1.sol";
import "./AccessibleCommon.sol";

/// @title the storage of StakeVaultStorage
contract StakeVaultStorage is AccessibleCommon {
    /// @dev reward token : TOS
    address public tos;

    /// @dev paytoken is the token that the user stakes.
    address public paytoken;

    /// @dev allocated amount of tos
    uint256 public cap;

    /// @dev the start block for sale.
    uint256 public saleStartBlock;

    /// @dev the staking start block
    uint256 public stakeStartBlock;

    /// @dev the staking end block.
    uint256 public stakeEndBlock;

    /// @dev the staking real end block.
    uint256 public realEndBlock;

    /// @dev reward amount per block
    uint256 public blockTotalReward;

    /// @dev sale closed flag
    bool public saleClosed;

    /// @dev Operation type of staking amount
    uint256 public stakeType;

    /// @dev External contract address used when operating the staking amount
    address public defiAddr;

    /// @dev a list of stakeContracts maintained by the vault
    address[] public stakeAddresses;

    /// @dev the information of the stake contract
    mapping(address => LibTokenStake1.StakeInfo) public stakeInfos;

    /// @dev the end blocks of the stake contracts, which must be in ascending order
    uint256[] public orderedEndBlocks;

    /// @dev the total staked amount stored at orderedEndBlock’s end block time
    mapping(uint256 => uint256) public stakeEndBlockTotal;

    uint256 private _lock;

    /// @dev flag for pause proxy
    bool public pauseProxy;

    ///@dev for migrate L2
    bool public migratedL2;

    modifier lock() {
        require(_lock == 0, "Stake1Vault: LOCKED");
        _lock = 1;
        _;
        _lock = 0;
    }
}
