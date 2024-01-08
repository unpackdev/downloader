//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStake1Logic {
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
    ) external;

    /// @dev Set factory address by StakeType

    /// @param _stakeType the stake type , 0:TON, 1: Simple, 2: UniswapV3LP
    /// @param _factory the factory address
    function setFactoryByStakeType(uint256 _stakeType, address _factory)
        external;

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
    ) external;

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
    ) external;

    /// @dev create stake contract in vault
    /// @param _phase phase of TOS platform
    /// @param _vaultName vault's name's hash
    /// @param _vault vault's address
    function addVault(
        uint256 _phase,
        bytes32 _vaultName,
        address _vault
    ) external;

    /// @dev end to staking by user
    /// @param _vault vault's address
    function closeSale(address _vault) external;

    /// @dev list of stakeContracts in vault
    /// @param _vault vault's address
    function stakeContractsOfVault(address _vault)
        external
        view
        returns (address[] memory);

    /// @dev list of vaults in _phase
    /// @param _phase the phase number
    function vaultsOfPhase(uint256 _phase)
        external
        view
        returns (address[] memory);

    /// @dev stake in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(
        address _stakeContract,
        address _layer2,
        uint256 stakeAmount
    ) external;

    /// @dev Requests unstaking in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    /// @param amount the amount of unstaking
    function tokamakRequestUnStaking(
        address _stakeContract,
        address _layer2,
        uint256 amount
    ) external;

    /// @dev Requests unstaking the amount of all  in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    function tokamakRequestUnStakingAll(address _stakeContract, address _layer2)
        external;

    /// @dev Processes unstaking the requested unstaking amount in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    function tokamakProcessUnStaking(address _stakeContract, address _layer2)
        external;

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
    ) external returns (uint256 amountOut);
}
