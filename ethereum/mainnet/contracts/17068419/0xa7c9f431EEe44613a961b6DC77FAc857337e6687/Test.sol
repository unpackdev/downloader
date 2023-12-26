// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

// 💬 ABOUT
// Standard Library's default Test

// 🧩 MODULES
import "./console.sol";
import "./console2.sol";
import "./StdAssertions.sol";
import "./StdChains.sol";
import "./StdCheats.sol";
import "./StdError.sol";
import "./StdInvariant.sol";
import "./StdJson.sol";
import "./StdMath.sol";
import "./StdStorage.sol";
import "./StdUtils.sol";
import "./Vm.sol";

// 📦 BOILERPLATE
import "./Base.sol";
import "./test.sol";

// ⭐️ TEST
abstract contract Test is DSTest, StdAssertions, StdChains, StdCheats, StdInvariant, StdUtils, TestBase {
// Note: IS_TEST() must return true.
// Note: Must have failure system, https://github.com/dapphub/ds-test/blob/cd98eff28324bfac652e63a239a60632a761790b/src/test.sol#L39-L76.
}
