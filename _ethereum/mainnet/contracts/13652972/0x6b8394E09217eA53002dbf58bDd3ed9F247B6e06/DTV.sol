pragma solidity ^0.6.0;

import "./Detailed.sol";
import "./Capped.sol";

contract DTV is ERC20Detailed, ERC20Capped {

    string constant private NAME = "DelnorteToken";
    string constant private SYMBOL = "DTV";
    uint8 constant private DECIMALS = 18;
    uint256 constant private CAP = 1000000000 * (10 ** uint256(DECIMALS));

    constructor() public
        ERC20Detailed(NAME, SYMBOL, DECIMALS)
        ERC20Capped(CAP) {
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount) public virtual onlyMinter returns (bool) {
        ERC20Capped._beforeTokenTransfer(address(0), to, amount);
        ERC20._mint(to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override(ERC20, IERC20) returns (bool) {
        ERC20Pausable._beforeTokenTransfer(address(0), to, amount);

        ERC20._transfer(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20, IERC20) returns (bool) {
        ERC20Capped._beforeTokenTransfer(sender, recipient, amount);

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}
