//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeVaultFactory {
    /// @dev Create a vault that hold reward, _cap is allocated reward amount.
    /// @param _phase phase number
    /// @param _addr the array of [token, paytoken, vault, defiAddr]
    /// @param _intInfo array of [_stakeType, _cap, _saleStartBlock, _stakeStartBlock]
    /// @param owner the owner adderess
    /// @return a vault address
    function create(
        uint256 _phase,
        address[4] calldata _addr,
        uint256[4] calldata _intInfo,
        address owner
    ) external returns (address);

    /// @dev Create a vault that hold reward, _cap is allocated reward amount.
    /// @param _phase phase number
    /// @param _addr the array of [tos, _stakefactory]
    /// @param _intInfo array of [_stakeType, _cap, _rewardPerBlock ]
    /// @param _name the name of stake contract
    /// @param owner the owner adderess
    /// @return a vault address
    function create2(
        uint256 _phase,
        address[2] calldata _addr,
        uint256[3] calldata _intInfo,
        string memory _name,
        address owner
    ) external returns (address);

    /// @dev Set stakeVaultLogic address by _phase
    /// @param _phase the stake type
    /// @param _logic the vault logic address
    function setVaultLogicByPhase(uint256 _phase, address _logic) external;
}
