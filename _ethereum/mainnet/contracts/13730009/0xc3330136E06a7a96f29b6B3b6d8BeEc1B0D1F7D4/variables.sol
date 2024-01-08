pragma solidity ^0.8.6;

import "./interfaces.sol";

contract Variables {
    struct TokenInfo {
        address sourceToken;
        address targetToken;
        uint256 amount;
    }
    
    struct Position {
        TokenInfo[] supply;
        TokenInfo[] withdraw;
    }

    // Structs
    struct AaveDataRaw {
        address targetDsa;
        uint256[] supplyAmts;
        uint256[] variableBorrowAmts;
        uint256[] stableBorrowAmts;
        address[] supplyTokens;
        address[] borrowTokens;
    }

    struct AaveData {
        address targetDsa;
        uint256[] supplyAmts;
        uint256[] borrowAmts;
        address[] supplyTokens;
        address[] borrowTokens;
    }

    // Constant Addresses //

    /**
    * @dev Aave referal code
    */
    uint16 constant internal referralCode = 3228;
    address public constant nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    /**
     * @dev Aave Provider
     */
    AaveLendingPoolProviderInterface public immutable aaveLendingPoolAddressesProvider;

    /**
     * @dev Aave Data Provider
     */
    AaveDataProviderInterface public immutable aaveProtocolDataProvider;

    /**
     * @dev Aave Price Oracle
     */
    // AaveOracleInterface public aaveOracle = AaveOracleInterface(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);

    /**
     * @dev InstaIndex Address.
     */
    IndexInterface public immutable instaIndex;
    address public immutable wnativeToken;

    constructor (
        address _aaveLendingPoolAddressesProvider,
        address _aaveProtocolDataProvider,
        address _instaIndex,
        address _wnativeToken
    ) {
        aaveLendingPoolAddressesProvider = AaveLendingPoolProviderInterface(_aaveLendingPoolAddressesProvider);
        aaveProtocolDataProvider = AaveDataProviderInterface(_aaveProtocolDataProvider);
        instaIndex = IndexInterface(_instaIndex);
        wnativeToken = _wnativeToken;
    }
}