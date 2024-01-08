// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IStake1Logic.sol";
import "./IProxy.sol";
import "./IStakeFactory.sol";
import "./IStakeRegistry.sol";
import "./IStake1Vault.sol";
import "./IStakeTONTokamak.sol";
import "./IStakeUniswapV3.sol";

import "./AccessibleCommon.sol";

import "./StakeProxyStorage.sol";

/// @title The logic of TOS Plaform
/// @notice Admin can createVault, createStakeContract.
/// User can excute the tokamak staking function of each contract through this logic.
contract Stake1Logic is StakeProxyStorage, AccessibleCommon, IStake1Logic {
    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Stake1Logic:zero address");
        _;
    }

    /*
    /// @dev event on create vault
    /// @param vault the vault address created
    /// @param paytoken the token used for staking by user
    /// @param cap  allocated reward amount
    event CreatedVault(address indexed vault, address paytoken, uint256 cap);

    /// @dev event on create stake contract in vault
    /// @param vault the vault address
    /// @param stakeContract the stake contract address created
    /// @param phase the phase of TOS platform
    event CreatedStakeContract(
        address indexed vault,
        address indexed stakeContract,
        uint256 phase
    );

    /// @dev event on sale-closed
    /// @param vault the vault address
    event ClosedSale(address indexed vault);

    /// @dev event on setting stake registry
    /// @param stakeRegistry the stakeRegistry address
    event SetStakeRegistry(address stakeRegistry);
*/

    constructor() {}

    /// @dev upgrade to the logic of _stakeProxy
    /// @param _stakeProxy the StakeProxy address, it is stakeContract address in vault.
    /// @param _implementation new logic address
    function upgradeStakeTo(address _stakeProxy, address _implementation)
        external
        onlyOwner
    {
        IProxy(_stakeProxy).upgradeTo(_implementation);
    }

    /// @dev grant the role to account in target
    /// @param target target address
    /// @param role  byte32 of role
    /// @param account account address
    function grantRole(
        address target,
        bytes32 role,
        address account
    ) external onlyOwner {
        AccessControl(target).grantRole(role, account);
    }

    /// @dev revoke the role to account in target
    /// @param target target address
    /// @param role  byte32 of role
    /// @param account account address
    function revokeRole(
        address target,
        bytes32 role,
        address account
    ) external onlyOwner {
        AccessControl(target).revokeRole(role, account);
    }

    /// @dev Sets TOS address
    /// @param _tos new TOS address
    function setTOS(address _tos) public onlyOwner nonZeroAddress(_tos) {
        tos = _tos;
    }

    /// @dev Sets Stake Registry address
    /// @param _stakeRegistry new StakeRegistry address
    function setStakeRegistry(address _stakeRegistry)
        public
        onlyOwner
        nonZeroAddress(_stakeRegistry)
    {
        stakeRegistry = IStakeRegistry(_stakeRegistry);
        emit SetStakeRegistry(_stakeRegistry);
    }

    /// @dev Sets StakeFactory address
    /// @param _stakeFactory new StakeFactory address
    function setStakeFactory(address _stakeFactory)
        public
        onlyOwner
        nonZeroAddress(_stakeFactory)
    {
        stakeFactory = IStakeFactory(_stakeFactory);
    }

    /// @dev Set factory address by StakeType
    /// @param _stakeType the stake type , 0:TON, 1: Simple, 2: UniswapV3LP
    /// @param _factory the factory address
    function setFactoryByStakeType(uint256 _stakeType, address _factory)
        external
        override
        onlyOwner
        nonZeroAddress(address(stakeFactory))
    {
        stakeFactory.setFactoryByStakeType(_stakeType, _factory);
    }

    /// @dev Sets StakeVaultFactory address
    /// @param _stakeVaultFactory new StakeVaultFactory address
    function setStakeVaultFactory(address _stakeVaultFactory)
        external
        onlyOwner
        nonZeroAddress(_stakeVaultFactory)
    {
        stakeVaultFactory = IStakeVaultFactory(_stakeVaultFactory);
    }

    /// Set initial variables
    /// @param _tos  TOS token address
    /// @param _stakeRegistry the registry address
    /// @param _stakeFactory the StakeFactory address
    /// @param _stakeVaultFactory the StakeVaultFactory address
    /// @param _ton  TON address in Tokamak
    /// @param _wton WTON address in Tokamak
    /// @param _depositManager DepositManager address in Tokamak
    /// @param _seigManager SeigManager address in Tokamak
    function setStore(
        address _tos,
        address _stakeRegistry,
        address _stakeFactory,
        address _stakeVaultFactory,
        address _ton,
        address _wton,
        address _depositManager,
        address _seigManager
    )
        external
        override
        onlyOwner
        nonZeroAddress(_stakeVaultFactory)
        nonZeroAddress(_ton)
        nonZeroAddress(_wton)
        nonZeroAddress(_depositManager)
    {
        setTOS(_tos);
        setStakeRegistry(_stakeRegistry);
        setStakeFactory(_stakeFactory);
        stakeVaultFactory = IStakeVaultFactory(_stakeVaultFactory);

        ton = _ton;
        wton = _wton;
        depositManager = _depositManager;
        seigManager = _seigManager;
    }

    /// @dev create vault
    /// @param _paytoken the token used for staking by user
    /// @param _cap  allocated reward amount
    /// @param _saleStartBlock  the start block that can stake by user
    /// @param _stakeStartBlock the start block that end staking by user and start that can claim reward by user
    /// @param _phase  phase of TOS platform
    /// @param _vaultName  vault's name's hash
    /// @param _stakeType  stakeContract's type, if 0, StakeTON, else if 1 , StakeSimple , else if 2, StakeDefi
    /// @param _defiAddr  extra defi address , default is zero address
    function createVault(
        address _paytoken,
        uint256 _cap,
        uint256 _saleStartBlock,
        uint256 _stakeStartBlock,
        uint256 _phase,
        bytes32 _vaultName,
        uint256 _stakeType,
        address _defiAddr
    ) external override onlyOwner nonZeroAddress(address(stakeVaultFactory)) {
        address vault =
            stakeVaultFactory.create(
                _phase,
                [tos, _paytoken, address(stakeFactory), _defiAddr],
                [_stakeType, _cap, _saleStartBlock, _stakeStartBlock],
                address(this)
            );
        require(vault != address(0), "Stake1Logic: vault is zero");
        stakeRegistry.addVault(vault, _phase, _vaultName);

        emit CreatedVault(vault, _paytoken, _cap);
    }

    /// @dev create stake contract in vault
    /// @param _phase the phase of TOS platform
    /// @param _vault  vault's address
    /// @param token  the reward token's address
    /// @param paytoken  the token used for staking by user
    /// @param periodBlock  the period that generate reward
    /// @param _name  the stake contract's name
    function createStakeContract(
        uint256 _phase,
        address _vault,
        address token,
        address paytoken,
        uint256 periodBlock,
        string memory _name
    ) external override onlyOwner {
        require(
            stakeRegistry.validVault(_phase, _vault),
            "Stake1Logic: unvalidVault"
        );

        IStake1Vault vault = IStake1Vault(_vault);

        (
            address[2] memory addrInfos,
            ,
            uint256 stakeType,
            uint256[3] memory iniInfo,
            ,

        ) = vault.infos();

        require(paytoken == addrInfos[0], "Stake1Logic: differrent paytoken");
        uint256 phase = _phase;
        address[4] memory _addr = [token, addrInfos[0], _vault, addrInfos[1]];

        // solhint-disable-next-line max-line-length
        address _contract =
            stakeFactory.create(
                stakeType,
                _addr,
                address(stakeRegistry),
                [iniInfo[0], iniInfo[1], periodBlock]
            );
        require(_contract != address(0), "Stake1Logic: deploy fail");

        IStake1Vault(_vault).addSubVaultOfStake(_name, _contract, periodBlock);
        stakeRegistry.addStakeContract(address(vault), _contract);

        emit CreatedStakeContract(address(vault), _contract, phase);
    }

    /// @dev create stake contract in vault
    /// @param _phase phase of TOS platform
    /// @param _vaultName vault's name's hash
    /// @param _vault vault's address
    function addVault(
        uint256 _phase,
        bytes32 _vaultName,
        address _vault
    ) external override onlyOwner {
        stakeRegistry.addVault(_vault, _phase, _vaultName);
    }

    /// @dev end to staking by user
    /// @param _vault vault's address
    function closeSale(address _vault) external override {
        IStake1Vault(_vault).closeSale();

        emit ClosedSale(_vault);
    }

    /// @dev list of stakeContracts in vault
    /// @param _vault vault's address
    function stakeContractsOfVault(address _vault)
        external
        view
        override
        nonZeroAddress(_vault)
        returns (address[] memory)
    {
        return IStake1Vault(_vault).stakeAddressesAll();
    }

    /// @dev list of vaults in _phase
    /// @param _phase the _phase number
    function vaultsOfPhase(uint256 _phase)
        external
        view
        override
        returns (address[] memory)
    {
        return stakeRegistry.phasesAll(_phase);
    }

    /// @dev stake in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(
        address _stakeContract,
        address _layer2,
        uint256 stakeAmount
    ) external override {
        IStakeTONTokamak(_stakeContract).tokamakStaking(_layer2, stakeAmount);
    }

    /// @dev Requests unstaking the amount WTON in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    /// @param amount the amount of unstaking
    function tokamakRequestUnStaking(
        address _stakeContract,
        address _layer2,
        uint256 amount
    ) external override {
        IStakeTONTokamak(_stakeContract).tokamakRequestUnStaking(
            _layer2,
            amount
        );
    }

    /// @dev Requests unstaking the amount of all  in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    function tokamakRequestUnStakingAll(address _stakeContract, address _layer2)
        external
        override
    {
        IStakeTONTokamak(_stakeContract).tokamakRequestUnStakingAll(_layer2);
    }

    /// @dev Processes unstaking the requested unstaking amount in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    function tokamakProcessUnStaking(address _stakeContract, address _layer2)
        external
        override
    {
        IStakeTONTokamak(_stakeContract).tokamakProcessUnStaking(_layer2);
    }

    /// @dev Swap TON to TOS using uniswap v3
    /// @dev this function used in StakeTON ( stakeType=0 )
    /// @param _stakeContract the stakeContract's address
    /// @param amountIn the input amount
    /// @param amountOutMinimum the minimun output amount
    /// @param deadline deadline
    /// @param sqrtPriceLimitX96 sqrtPriceLimitX96
    /// @param _type the function type, if 0, use exactInputSingle function, else if, use exactInput function
    function exchangeWTONtoTOS(
        address _stakeContract,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline,
        uint160 sqrtPriceLimitX96,
        uint256 _type
    ) external override returns (uint256 amountOut) {
        return
            IStakeTONTokamak(_stakeContract).exchangeWTONtoTOS(
                amountIn,
                amountOutMinimum,
                deadline,
                sqrtPriceLimitX96,
                _type
            );
    }
}
