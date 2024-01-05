// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;
/** OpenZeppelin Dependencies Upgradeable */
// import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";
/** OpenZepplin non-upgradeable Swap Token (hex3t) */
import "./IERC20.sol";
/** Local Interfaces */
import "./NativeSwap.sol";

contract NativeSwapRestorable is NativeSwap {
    /* Setter methods for contract migration */
    function setStart(uint256 _start) external onlyMigrator {
        start = _start;
    }
}
