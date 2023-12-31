// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract Discoin is ERC20, Ownable {
    address private treasury;

    uint256 public constant TOTAL_SUPPLY = 21_000_000_000;

    constructor() ERC20("Discoin", "DISCO") {
        _mint(msg.sender, TOTAL_SUPPLY * 10 ** decimals());

        treasury = msg.sender;
        _transferOwnership(msg.sender);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "Treasury cannot be zero address");

        treasury = _treasury;
    }

    function getTreasury() public view returns (address) {
        return treasury;
    }

    /**
     * @dev Overrides the internal transfer function to deduct a fee for the treasury.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 feeAmount = (amount * 10) / 100; // Calculate the 10% fee
        uint256 netAmount = amount - feeAmount;

        super._transfer(sender, recipient, netAmount); // Transfer the net amount

        // Transfer the fee to the treasury
        super._transfer(sender, treasury, feeAmount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}
