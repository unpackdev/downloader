// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./Ownable.sol";
import "./ERC20.sol";

contract PolkaPrivate is ERC20, Ownable {
    constructor() ERC20('PolkaPrivate', 'PPRIV') {
        _mint(msg.sender, 1_000_000_000 ether);
    }

    // @notice Transfer stuck tokens
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function transferStuckERC20(IERC20 _token, address _to, uint256 _amount) external onlyOwner {
        require(_token.transfer(_to, _amount), "[E-56] - Transfer failed.");
    }
}