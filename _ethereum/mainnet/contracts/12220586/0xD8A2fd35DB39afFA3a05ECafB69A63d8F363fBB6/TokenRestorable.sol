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
import "./Token.sol";

contract TokenRestorable is Token {
    /* Setter methods for contract migration */
    function setNormalVariables(uint256 _swapTokenBalance)
        external
        onlyMigrator
    {
        swapTokenBalance = _swapTokenBalance;
    }

    function bulkMint(
        address[] calldata userAddresses,
        uint256[] calldata amounts
    ) external onlyMigrator {
        for (uint256 idx = 0; idx < userAddresses.length; idx = idx + 1) {
            _mint(userAddresses[idx], amounts[idx]);
        }
    }
}
