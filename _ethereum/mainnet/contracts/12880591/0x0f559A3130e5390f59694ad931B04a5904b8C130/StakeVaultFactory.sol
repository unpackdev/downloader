// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IStakeVaultFactory.sol";
import "./StakeVaultProxy.sol";
import "./Stake2VaultProxy.sol";
import "./AccessibleCommon.sol";

//import "./console.sol";

/// @title A factory that creates a vault that hold reward
contract StakeVaultFactory is AccessibleCommon, IStakeVaultFactory {
    mapping(uint256 => address) public vaultLogics;

    modifier nonZero(address _addr) {
        require(_addr != address(0), "StakeVaultFactory: zero");
        _;
    }

    /// @dev constructor of StakeVaultFactory
    /// @param _stakeVaultLogic the logic address used in StakeVault
    constructor(address _stakeVaultLogic) {
        require(
            _stakeVaultLogic != address(0),
            "StakeVaultFactory: logic zero"
        );
        vaultLogics[1] = _stakeVaultLogic;

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Set stakeVaultLogic address by _phase
    /// @param _phase the stake type
    /// @param _logic the vault logic address
    function setVaultLogicByPhase(uint256 _phase, address _logic)
        external
        override
        onlyOwner
        nonZero(_logic)
    {
        vaultLogics[_phase] = _logic;
    }

    /// @dev Create a vault that hold reward, _cap is allocated reward amount.
    /// @param _phase phase number
    /// @param _addr the array of [token, paytoken, _stakefactory, defiAddr]
    /// @param _intInfo array of [_stakeType, _cap, _saleStartBlock, _stakeStartBlock]
    /// @param owner the owner adderess
    /// @return a vault address
    function create(
        uint256 _phase,
        address[4] calldata _addr,
        uint256[4] calldata _intInfo,
        address owner
    ) external override returns (address) {
        require(
            vaultLogics[_phase] != address(0),
            "StakeVaultFactory: zero vault logic "
        );
        address _tos = _addr[0];
        address _paytoken = _addr[1];
        address _stakefactory = _addr[2];
        address _defiAddr = _addr[3];
        uint256 _stakeType = _intInfo[0];
        uint256 _cap = _intInfo[1];
        uint256 _saleStartBlock = _intInfo[2];
        uint256 _stakeStartBlock = _intInfo[3];

        StakeVaultProxy proxy = new StakeVaultProxy(vaultLogics[_phase]);
        require(address(proxy) != address(0), "StakeVaultFactory: proxy zero");

        proxy.initialize(
            _tos,
            _paytoken,
            _cap,
            _saleStartBlock,
            _stakeStartBlock,
            _stakefactory,
            _stakeType,
            _defiAddr
        );

        proxy.grantRole(ADMIN_ROLE, owner);
        proxy.revokeRole(ADMIN_ROLE, address(this));

        return address(proxy);
    }

    /// @dev Create a vault that hold reward, _cap is allocated reward amount.
    /// @param _phase phase number
    /// @param _addr the array of [tos, _stakefactory]
    /// @param _intInfo array of [_stakeType, _cap, _rewardPerBlock ]
    /// @param owner the owner adderess
    /// @return a vault address
    function create2(
        uint256 _phase,
        address[2] calldata _addr,
        uint256[3] calldata _intInfo,
        string memory _name,
        address owner
    ) external override returns (address) {
        require(
            vaultLogics[_phase] != address(0),
            "StakeVaultFactory: zero vault2 logic "
        );
        address _tos = _addr[0];
        address _stakefactory = _addr[1];
        uint256 _stakeType = _intInfo[0];
        uint256 _cap = _intInfo[1];
        uint256 _rewardPerBlock = _intInfo[2];

        //console.log("create2 %s", vaultLogics[_phase] );

        Stake2VaultProxy proxy = new Stake2VaultProxy(vaultLogics[_phase]);
        require(
            address(proxy) != address(0),
            "StakeVaultFactory: Stake2VaultProxy zero"
        );

        proxy.initialize(
            _tos,
            _stakefactory,
            _stakeType,
            _cap,
            _rewardPerBlock,
            _name
        );

        proxy.grantRole(ADMIN_ROLE, owner);
        proxy.revokeRole(ADMIN_ROLE, address(this));

        return address(proxy);
    }
}
