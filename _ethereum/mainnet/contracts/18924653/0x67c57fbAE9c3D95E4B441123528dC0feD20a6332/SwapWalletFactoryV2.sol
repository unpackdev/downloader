// SPDX-License-Identifier: UNLICENSED
import "./SwapWalletFactory.sol";

contract SwapWalletFactoryV2 is SwapWalletFactory {
    function version() external view returns (uint256) {
        return 3;
    }
}
