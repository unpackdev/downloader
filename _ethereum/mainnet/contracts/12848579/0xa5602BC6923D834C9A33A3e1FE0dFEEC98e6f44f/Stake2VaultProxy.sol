// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IStake2VaultProxy.sol";
import "./Stake2VaultStorage.sol";
import "./ProxyBase.sol";

/// @title Proxy for StakeVault
/// @notice
contract Stake2VaultProxy is Stake2VaultStorage, ProxyBase, IStake2VaultProxy {
    event Upgraded(address indexed implementation);

    /// @dev constructor of StakeVaultProxy
    /// @param impl the logic address of StakeVaultProxy
    constructor(address impl) {
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );

        require(impl != address(0), "Stake2VaultProxy: logic is zero");

        _setImplementation(impl);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, address(this));
    }

    /// @notice Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external override onlyOwner {
        pauseProxy = _pause;
    }

    /// @notice Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) external override onlyOwner {
        require(impl != address(0), "Stake2VaultProxy: input is zero");
        require(_implementation() != impl, "Stake2VaultProxy: same");
        _setImplementation(impl);
        emit Upgraded(impl);
    }

    /// @dev returns the implementation
    function implementation() public view override returns (address) {
        return _implementation();
    }

    /// @dev receive ether
    receive() external payable {
        revert("cannot receive Ether");
    }

    /// @dev fallback function , execute on undefined function call
    fallback() external payable {
        _fallback();
    }

    /// @dev fallback function , execute on undefined function call
    function _fallback() internal {
        address _impl = _implementation();
        require(
            _impl != address(0) && !pauseProxy,
            "Stake2VaultProxy: impl OR proxy is false"
        );

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /// @dev set initial storage
    /// @param _tos  TOS token address
    /// @param _stakefactory the factory address to create stakeContract
    /// @param _stakeType  Type of staking contract, 0 TON staking, 1 basic ERC20 staking, 2 UniswapV3  staking
    /// @param _cap  Maximum amount of rewards issued, allocated reward amount.
    /// @param _rewardPerBlock  the reward per block
    function initialize(
        address _tos,
        address _stakefactory,
        uint256 _stakeType,
        uint256 _cap,
        uint256 _rewardPerBlock,
        string memory _name
    ) external override onlyOwner {
        require(tos == address(0), "Stake2VaultProxy: already initialized");

        require(
            _tos != address(0) && _stakefactory != address(0),
            "Stake2VaultProxy: input is zero"
        );
        require(_cap > 0, "Stake1Vault: _cap is zero");

        tos = _tos;
        cap = _cap;
        stakeType = _stakeType;
        rewardPerBlock = _rewardPerBlock;
        name = _name;
        grantRole(ADMIN_ROLE, _stakefactory);
    }
}
