// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract KhamzatInu is ERC20 {
    uint256 public constant TAX = 5;
    address private immutable taxman;

    constructor(address _taxman) ERC20("Khamzat Inu", "KZAT") {
        taxman = _taxman;
        _mint(taxman, 100_000_000 * 10**decimals());
    }

    /**
     * @dev Adds tax.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 _tax = amount * TAX / 100;

        super._transfer(from, taxman, _tax);
        super._transfer(from, to, (amount - _tax));
    }
}
