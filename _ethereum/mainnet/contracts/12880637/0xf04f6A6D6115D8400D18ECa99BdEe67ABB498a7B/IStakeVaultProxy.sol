//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeVaultProxy {
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
    /// @param _paytoken  Tokens staked by users, can be used as ERC20 tokens.
    //                     (In case of ETH, input address(0))
    /// @param _cap  Maximum amount of rewards issued, allocated reward amount.
    /// @param _saleStartBlock  the sale start block
    /// @param _stakeStartBlock  the staking start block
    /// @param _stakefactory the factory address to create stakeContract
    /// @param _stakeType  Type of staking contract, 0 TON staking, 1 basic ERC20 staking, 2 Defi linked staking
    /// @param _defiAddr Used when an external address is required. default: address(0)
    function initialize(
        address _tos,
        address _paytoken,
        uint256 _cap,
        uint256 _saleStartBlock,
        uint256 _stakeStartBlock,
        address _stakefactory,
        uint256 _stakeType,
        address _defiAddr
    ) external;
}
