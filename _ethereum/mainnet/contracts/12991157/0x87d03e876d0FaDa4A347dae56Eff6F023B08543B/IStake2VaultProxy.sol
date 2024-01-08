//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStake2VaultProxy {
    /// @dev Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external;

    /// @dev Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) external;

    /// @dev view implementation address
    /// @return the logic address
    function implementation() external view returns (address);

    /// @dev set initial storage
    /// @param _tos  TOS token address
    /// @param _stakefactory the factory address to create stakeContract
    /// @param _stakeType  Type of staking contract, 0 TON staking, 1 basic ERC20 staking, 2 UniswapV3  staking
    /// @param _cap  Maximum amount of rewards issued, allocated reward amount.
    /// @param _rewardPerBlock  the reward per block
    /// @param _name  the name of stake contratc
    function initialize(
        address _tos,
        address _stakefactory,
        uint256 _stakeType,
        uint256 _cap,
        uint256 _rewardPerBlock,
        string memory _name
    ) external;
}
