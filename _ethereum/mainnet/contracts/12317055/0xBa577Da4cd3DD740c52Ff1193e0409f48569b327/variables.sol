pragma solidity ^0.7.0;

import "./interfaces.sol";

contract Variables {

    // Structs
    struct AaveDataRaw {
        address targetDsa;
        uint[] supplyAmts;
        uint[] variableBorrowAmts;
        uint[] stableBorrowAmts;
        address[] supplyTokens;
        address[] borrowTokens;
    }

    struct AaveData {
        address targetDsa;
        uint[] supplyAmts;
        uint[] borrowAmts;
        address[] supplyTokens;
        address[] borrowTokens;
    }

    // Constant Addresses //

    /**
    * @dev Aave referal code
    */
    uint16 constant internal referralCode = 3228;
    
    /**
    * @dev Polygon Receiver contract
    */
    address constant internal polygonReceiver = 0x4A090897f47993C2504144419751D6A91D79AbF4;
    
    /**
    * @dev Flashloan contract
    */
    FlashloanInterface constant internal flashloanContract = FlashloanInterface(0xd7e8E6f5deCc5642B77a5dD0e445965B128a585D);
    
    /**
    * @dev ERC20 Predicate address
    */
    address constant internal erc20Predicate = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

    /**
     * @dev Aave Provider
     */
    AaveLendingPoolProviderInterface constant internal aaveProvider = AaveLendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    /**
     * @dev Aave Data Provider
     */
    AaveDataProviderInterface constant internal aaveData = AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    /**
     * @dev Aave Price Oracle
     */
    AaveOracleInterface constant internal aaveOracle = AaveOracleInterface(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);

    /**
     * @dev Polygon State Sync Contract
     */
    StateSenderInterface constant internal stateSender = StateSenderInterface(0x28e4F3a7f651294B9564800b2D01f35189A5bFbE);

    /**
     * @dev InstaIndex Address.
     */
    IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

    /**
     * @dev Polygon deposit bridge
     */
    RootChainManagerInterface public constant rootChainManager = RootChainManagerInterface(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
    
    
    // Storage variables //
    
    /**
    * @dev This will be used to have debt/collateral ratio always 20% less than liquidation
    */
    uint public safeRatioGap = 800000000000000000; // 80%

    /**
    * @dev fee on collateral
    */
    uint public fee = 998000000000000000; // 0.2% (99.8%) on collateral

    /**
    * @dev Mapping of supported token
    */
    mapping(address => bool) public isSupportedToken;

    /**
    * @dev Array of supported token
    */
    address[] public supportedTokens; // don't add ethAddr. Only add wethAddr

}