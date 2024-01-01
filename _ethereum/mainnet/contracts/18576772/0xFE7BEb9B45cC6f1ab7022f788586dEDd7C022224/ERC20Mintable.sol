// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";

abstract contract ERC20Mintable is ERC20 {
    mapping(address => bool) public isMinter;

    error InvalidMinter();
    error OnlyMinter();
    error ExceedsMaxSupply();

    event MinterSet(address indexed minter, bool isMinter);

    modifier onlyMinter() {
        if (!isMinter[msg.sender]) revert OnlyMinter();
        _;
    }

    function _setMinter(address _minter, bool _isMinter) internal {
        if (_minter == address(0) || isMinter[_minter] == _isMinter) revert InvalidMinter();

        isMinter[_minter] = _isMinter;
        emit MinterSet(_minter, _isMinter);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }
}
