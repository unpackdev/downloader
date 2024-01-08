//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./ERC20PresetMinterPauser.sol";


contract Piece is ERC20PresetMinterPauser {
    uint256 constant private _CAP = 1000000 ether; // 1 mln tokens

    constructor() public ERC20PresetMinterPauser("PIECE", "PIECE") {
        // Silence
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _CAP;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "Piece: Cap exceeded");
        super._mint(account, amount);
    }
}