//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

//pragma abicoder v2;
//import "./LibTokenStake1.sol";

interface IStake2Vault {
    /// @dev Sets TOS address
    /// @param _tos  TOS address
    function setTOS(address _tos) external;

    /// @dev Change cap of the vault
    /// @param _cap  allocated reward amount
    function changeCap(uint256 _cap) external;

    /// @dev change name
    /// @param _name   name
    function changeName(string memory _name) external;

    /// @dev set stake address
    /// @param _stakeAddress  stake address
    function setStakeAddress(address _stakeAddress) external;

    /// @dev set mining start time
    /// @param _miningStartTime  mining start time
    function setMiningStartTime(uint256 _miningStartTime) external;

    /// @dev set mining end time
    /// @param _miningEndTime  mining end time
    function setMiningEndTime(uint256 _miningEndTime) external;

    /// @dev set mining amount per second
    /// @param _miningPerSecond  a mining amount per second
    function setMiningAmountPerSecond(uint256 _miningPerSecond) external;

    /// @dev If the vault has more money than the reward to give, the owner can withdraw the remaining amount.
    /// @param to to address
    /// @param _amount the amount of withdrawal
    function withdraw(address to, uint256 _amount) external;

    /// @dev claim function.
    /// @dev sender is a staking contract.
    /// @dev A function that pays the amount(_amount) to _to by the staking contract.
    /// @dev A function that _to claim the amount(_amount) from the staking contract and gets the TOS in the vault.
    /// @param _to a user that received reward
    /// @param _amount the receiving amount
    /// @return true
    function claim(address _to, uint256 _amount) external returns (bool);

    /// @dev  a according to request from(staking contract)  the amount of mining is paid to to.
    /// @param to the address that will receive the reward
    /// @param minableAmount minable amount
    /// @param miningAmount amount mined
    /// @param nonMiningAmount Amount not mined
    function claimMining(
        address to,
        uint256 minableAmount,
        uint256 miningAmount,
        uint256 nonMiningAmount
    ) external returns (bool);

    /// @dev Give the infomation of this vault
    /// @return return1 [tos, stakeAddress]
    /// @return return2 cap
    /// @return return3 stakeType
    /// @return return4 rewardPerBlock
    /// @return return5 name
    function infos()
        external
        view
        returns (
            address[2] memory,
            uint256,
            uint256,
            uint256,
            string memory
        );

    /// @dev Returns Give the TOS balance stored in the vault
    /// @return the balance of TOS in this vault.
    function balanceTOSAvailableAmount() external view returns (uint256);

    /// @dev Give all stakeContracts's addresses in this vault
    /// @return all stakeContracts's addresses
    function stakeAddressesAll() external view returns (address[] memory);
}
