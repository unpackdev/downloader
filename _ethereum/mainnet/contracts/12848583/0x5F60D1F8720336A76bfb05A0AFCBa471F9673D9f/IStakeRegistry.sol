//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeRegistry {
    /// @dev Set addresses for Tokamak integration
    /// @param _ton TON address
    /// @param _wton WTON address
    /// @param _depositManager DepositManager address
    /// @param _seigManager SeigManager address
    /// @param _swapProxy Proxy address that can swap TON and WTON
    function setTokamak(
        address _ton,
        address _wton,
        address _depositManager,
        address _seigManager,
        address _swapProxy
    ) external;

    /// @dev Add information related to Defi
    /// @param _name name . ex) UNISWAP_V3
    /// @param _router entry point of defi
    /// @param _ex1  additional variable . ex) positionManagerAddress in Uniswap V3
    /// @param _ex2  additional variable . ex) WETH Address in Uniswap V3
    /// @param _fee  fee
    /// @param _routerV2 In case of uniswap, router address of uniswapV2
    function addDefiInfo(
        string calldata _name,
        address _router,
        address _ex1,
        address _ex2,
        uint256 _fee,
        address _routerV2
    ) external;

    /// @dev Add Vault
    /// @dev It is excuted by proxy
    /// @param _vault vault address
    /// @param _phase phase ex) 1,2,3
    /// @param _vaultName  hash of vault's name
    function addVault(
        address _vault,
        uint256 _phase,
        bytes32 _vaultName
    ) external;

    /// @dev Add StakeContract in vault
    /// @dev It is excuted by proxy
    /// @param _vault vault address
    /// @param _stakeContract  StakeContract address
    function addStakeContract(address _vault, address _stakeContract) external;

    /// @dev Get addresses for Tokamak interface
    /// @return (ton, wton, depositManager, seigManager)
    function getTokamak()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );

    /// @dev Get indos for UNISWAP_V3 interface
    /// @return (uniswapRouter, npm, wethAddress, fee)
    function getUniswap()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            address
        );

    /// @dev Checks if a vault is withing the given phase
    /// @param _phase the phase number
    /// @param _vault the vault's address
    /// @return valid true or false
    function validVault(uint256 _phase, address _vault)
        external
        view
        returns (bool valid);

    function phasesAll(uint256 _index) external view returns (address[] memory);

    function stakeContractsOfVaultAll(address _vault)
        external
        view
        returns (address[] memory);

    /// @dev view defi info
    /// @param _name  hash name : keccak256(abi.encodePacked(_name));
    /// @return name  _name ex) UNISWAP_V3, UNISWAP_V3_token0_token1
    /// @return router entry point of defi
    /// @return ext1  additional variable . ex) positionManagerAddress in Uniswap V3
    /// @return ext2  additional variable . ex) WETH Address in Uniswap V3
    /// @return fee  fee
    /// @return routerV2 In case of uniswap, router address of uniswapV2

    function defiInfo(bytes32 _name)
        external
        returns (
            string calldata name,
            address router,
            address ext1,
            address ext2,
            uint256 fee,
            address routerV2
        );
}
