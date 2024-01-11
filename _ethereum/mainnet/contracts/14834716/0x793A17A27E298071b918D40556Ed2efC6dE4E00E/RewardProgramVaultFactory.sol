//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./VaultFactory.sol";

import "./RewardProgramVaultProxy.sol";
import "./IEventLog.sol";
import "./IRewardProgramVaultFactory.sol";
// import "./console.sol";

/// @title A factory that creates a Vault
contract RewardProgramVaultFactory is VaultFactory, IRewardProgramVaultFactory{

    address public staker;
    uint256 public waitStartSeconds;

    /// @inheritdoc IRewardProgramVaultFactory
    function setWaitStartSeconds(
        uint256 _waitStartSeconds
    )
        external override
        nonZero(_waitStartSeconds)
        onlyOwner
    {
        require(waitStartSeconds != _waitStartSeconds, "same waitStartSeconds");
        waitStartSeconds = _waitStartSeconds;
    }

    /// @inheritdoc IRewardProgramVaultFactory
    function setStaker(
        address _staker
    )
        external override
        nonZeroAddress(_staker)
        onlyOwner
    {
        require(staker != _staker, "same staker");
        staker = _staker;
    }


    /// @inheritdoc IRewardProgramVaultFactory
    function create(
        string calldata _name,
        address pool,
        address rewardToken,
        address _admin
    )
        external override
        nonZeroAddress(upgradeAdmin)
        nonZeroAddress(vaultLogic)
        nonZeroAddress(logEventAddress)
        nonZero(waitStartSeconds)
        returns (address)
    {
        require(bytes(_name).length > 0,"name is empty");

        RewardProgramVaultProxy _proxy = new RewardProgramVaultProxy();

        require(
            address(_proxy) != address(0),
            "RewardProgramVaultProxy zero"
        );

        string memory _name1 = _name;

        _proxy.addProxyAdmin(upgradeAdmin);
        _proxy.addAdmin(upgradeAdmin);
        _proxy.setImplementation2(vaultLogic, 0, true);
        _proxy.setLogEventAddress(logEventAddress, true);

        _proxy.setBaseInfoProxy(
            _name,
            pool,
            rewardToken,
            staker,
            _admin,
            waitStartSeconds
        );

        _proxy.removeAdmin();
        // _proxy.removeProxyAdmin();

        createdContracts[totalCreatedContracts] = ContractInfo(address(_proxy), _name);
        totalCreatedContracts++;

        IEventLog(logEventAddress).logEvent(
            keccak256("RewardProgramVaultFactory"),
            keccak256("CreatedRewardProgramVault"),
            address(this),
            abi.encode(address(_proxy), _name1));

        emit CreatedRewardProgramVault(address(_proxy), _name1);
        return address(_proxy);
    }


}