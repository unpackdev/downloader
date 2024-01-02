// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

// 💬 ABOUT
// Forge Std's default Script.

// 🧩 MODULES
import "./console.sol";
import "./console2.sol";
import "./safeconsole.sol";
import "./StdChains.sol";
import "./StdCheats.sol";
import "./StdJson.sol";
import "./StdMath.sol";
import "./StdStorage.sol";
import "./StdStyle.sol";
import "./StdUtils.sol";
import "./Vm.sol";

// 📦 BOILERPLATE
import "./Base.sol";

// ⭐️ SCRIPT
abstract contract Script is ScriptBase, StdChains, StdCheatsSafe, StdUtils {
    // Note: IS_SCRIPT() must return true.
    bool public IS_SCRIPT = true;
}
