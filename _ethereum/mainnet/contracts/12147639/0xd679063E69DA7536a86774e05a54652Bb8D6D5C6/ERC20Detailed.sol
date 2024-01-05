pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./Initializable.sol";
import "./Context.sol";


abstract contract ERC20DetailedUpgradeSafe is Initializable, ContextUpgradeSafe, IERC20{

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function __ERC20Detailed_init(string memory name, string memory symbol) internal initializer{
        __Context_init();
        __ERC20Detailed_init_unchained(name, symbol);
    }

    function __ERC20Detailed_init_unchained(string memory name, string memory symbol) internal initializer {

        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }

    /**
     * @dev Returns the name of the token. 
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[44] private __gap;
}