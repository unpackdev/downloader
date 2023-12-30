pragma solidity 0.5.11;

import "./ERC20.sol";
import "./InitializableERC20Detailed.sol";

contract InitializableToken is ERC20, InitializableERC20Detailed {
    /**
     * @dev Initialization function for implementing contract
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function _initialize(string memory _nameArg, string memory _symbolArg)
        internal
    {
        InitializableERC20Detailed._initialize(_nameArg, _symbolArg, 18);
    }
}
