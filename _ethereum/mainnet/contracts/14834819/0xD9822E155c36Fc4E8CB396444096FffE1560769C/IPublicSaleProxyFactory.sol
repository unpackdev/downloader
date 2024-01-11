//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IPublicSaleProxyFactory {

    /// @dev Create a PublicSaleProxyFactory
    /// @param name name
    /// @param _owner proxyOwner address
    /// @param saleAddresses  [saleTokenAddress,getTokenOwner,liquidityVaultAddress]
    /// @param _index liquidityVault index
    /// @return proxy contract address
    function create(
        string calldata name,
        address _owner,
        address[3] calldata saleAddresses,
        uint256 _index
    )
        external
        returns (address);

    /// @dev setting the basicAddress
    /// @param _basicAddress [tonAddress, wtonAddress, sTOSAddress, tosAddres, uniRouterAddress, publicLogic]
    function basicSet(
        address[6] calldata _basicAddress
    )
        external;

    /// @dev setting the address, value
    /// @param _addr [upgradeAdmin, initailVault, eventLog]
    /// @param _value [minTOS, maxTOS, sTOSTier1, sTOSTier2, sTOSTier3, sTOSTier4, delayTime]
    function allSet(
        address[3] calldata _addr,
        uint256[7] calldata _value
    ) 
        external;

    /// @dev setting the admin
    /// @param addr ontherProxyManagerMasterAddress
    function setUpgradeAdmin(
        address addr
    )   
        external;

    /// @dev setting the min, max
    /// @param _min ton -> tos min percents
    /// @param _max ton -> tos max percents
    function setMaxMin(
        uint256 _min,
        uint256 _max
    )
        external;

    /// @dev setting the initialLiquidityFactoryAddress
    /// @param _vaultFactory factoryAddress
    function setVault(
        address _vaultFactory
    )
        external;

    /// @dev setting the eventLog
    /// @param _addr logContract addr
    function setEventLog(
        address _addr
    )
        external;

    /// @dev set the sTOSstandard
    /// @param _tier1 tier1 STOS
    /// @param _tier2 tier1 STOS
    /// @param _tier3 tier1 STOS
    /// @param _tier4 tier1 STOS
    function setSTOS(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    ) 
        external;

    /// @dev set the delayTime
    /// @param _delay tier1 STOS
    function setDelay(
        uint256 _delay
    )
        external;

    /// @dev Last generated contract information
    function lastestCreated() external view returns (address contractAddress, string memory name);

    /// @dev Contract information stored in the index
    function getContracts(uint256 _index) external view returns (address contractAddress, string memory name);


}
