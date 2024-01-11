pragma solidity 0.8.14;

import "./Initializable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 * @dev Vanilla upgradeable {ERC20} "WAXP" token:
 *
 */
contract WAXPERC20UpgradeSafe is Initializable, OwnableUpgradeable, ERC20BurnableUpgradeable {
    uint8 public constant DECIMALS = 8;                         // The number of decimals for display
    uint256 public constant INITIAL_SUPPLY = 386482894311326596;  // supply specified in base units

    /**
     * See {ERC20-constructor}.
     */

    function initialize(address escrow) public initializer {
        ERC20Upgradeable.__ERC20_init("WAXP Token", "WAXP");
        _mint(escrow, INITIAL_SUPPLY);
        __Ownable_init();
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Destroys `amount` tokens from the contract owner.
     *
     * See {ERC20-_burn}.
     * - only owner allow to call
     */
    function burn(uint256 amount) public override onlyOwner {
        super.burn(amount);
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
     * - only owner allow to call
     */
    function burnFrom(address account, uint256 amount) public override onlyOwner {
        super.burnFrom(account, amount);
    }
}
