pragma solidity ^0.7.0;

import "./math.sol";
import "./stores.sol";
import "./interfaces.sol";

abstract contract Helpers is DSMath, Stores {
    /**
     * @dev Aave referal code
     */
    uint16 constant internal referalCode = 3228;

    /**
     * @dev Minimum borrowable amount in Aave v1
     */
    uint constant internal minBorrowAmt = 5000000; // 5e6

    /**
     * @dev Aave Provider
     */
    AaveProviderInterface constant internal aaveProvider = AaveProviderInterface(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    function getIsColl(AaveInterface aave, address token) internal view returns (bool isCol) {
        (, , , , , , , , , isCol) = aave.getUserReserveData(token, address(this));
    }

    function getPaybackBalance(AaveInterface aave, address token, address user) internal view returns (uint amt) {
        (, uint bal, , , , , uint fee, , , ) = aave.getUserReserveData(token, user);
        amt = add(bal, fee);
    }
}