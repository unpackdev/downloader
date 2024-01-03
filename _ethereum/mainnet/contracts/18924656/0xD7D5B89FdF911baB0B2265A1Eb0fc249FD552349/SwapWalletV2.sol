// SPDX-License-Identifier: UNLICENSED
import "./SwapWallet.sol";

contract SwapWalletV2 is SwapWallet {
    function version() external view returns (uint256) {
        return 6;
    }
}
