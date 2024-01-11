// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TaxedToken is ERC20 {
    uint256 private _transferFeePercentage;
    address private _fundAddress;

    constructor(
        uint256 transferFeePercentage_,
        address fundAddress_
    ) ERC20("Taxed Token", "TTC") {
        _transferFeePercentage = transferFeePercentage_;
        _fundAddress = fundAddress_;
        _mint(msg.sender, 10000000 * 10**18);
    }

    function transferFeePercentage() public view returns (uint256) {
        return _transferFeePercentage;
    }

    function fundAddress() public view returns (address) {
        return _fundAddress;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        uint256 fee = (amount * _transferFeePercentage) / 100;
        uint256 taxedValue = amount - fee;
        uint256 funds = fee;

        address owner = _msgSender();
        _transfer(owner, recipient, taxedValue);
        _transfer(owner, _fundAddress, funds);

        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        uint256 fee = (amount * _transferFeePercentage) / 100;
        uint256 taxedValue = amount - fee;
        uint256 funds = fee;

        _transfer(from, to, taxedValue);
        _transfer(from, _fundAddress, funds);
        return true;
    }
}