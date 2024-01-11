// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./dsmath.sol";

contract Helpers is DSMath {
    /// @dev Contract address is different on Kovan: 0x0EAE7BAdEF8f95De91fDDb74a89A786cF891Eb0e
    NotionalInterface internal constant notional = NotionalInterface(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);
}
