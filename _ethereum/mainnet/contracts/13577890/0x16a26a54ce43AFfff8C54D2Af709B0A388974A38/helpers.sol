pragma solidity ^0.7.0;

import "./math.sol";
import "./stores-polygon.sol";
import "./interfaces.sol";

abstract contract Helpers is DSMath, Stores {
    /**
     * @dev Aave referal code
     */
    uint16 constant internal referalCode = 3228;

    /**
     * @dev Aave Provider
     */
    AaveLendingPoolProviderInterface constant internal aaveProvider = AaveLendingPoolProviderInterface(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);

    /**
     * @dev Aave Data Provider
     */
    AaveDataProviderInterface constant internal aaveData = AaveDataProviderInterface(0x7551b5D2763519d4e37e8B81929D336De671d46d);

    function getIsColl(address token, address user) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
    }
}