// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./IStrikeBoostFarm.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract VStrikeToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    // staking address
    address public stakingAddress;
    // pool id
    uint256 public poolId;

    constructor(string memory _name, string memory _symbol)
        public
        ERC20(_name, _symbol)
        Ownable()
    {}

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        IStrikeBoostFarm(stakingAddress).move(poolId, _msgSender(), recipient, amount);
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        // _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        uint256 decreasedAllowance = allowance(sender, _msgSender()).sub(
            amount,
            "ERC20: transfer amount exceeds allowance"
        );

        _approve(sender, _msgSender(), decreasedAllowance);
        IStrikeBoostFarm(stakingAddress).move(poolId, sender, recipient, amount);
        return true;
    }

    /**
        ------------------------------------------------------------------------
        Burnable functionality
        This has been taken out of the:
        @openzeppelin/contracts/token/ERC20/ERC20Burnable (v3.2.0)
        This functionality has been removed from the Burnable contract and added
        directly here in order to prevent an inheritance clash. 
        For more information on this inheritance clash please see the README
        ------------------------------------------------------------------------
    */

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
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
            amount,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    /**
        ------------------------------------------------------------------------
        Mintable functionality
        This functionality has been taken from the OpenZeppelin library v2.5.0:
        @openzeppelin/contracts/token/ERC20/ERC20Mintable (v2.5.0)
        
        This was done to provide an audited mint functionality (as there is no
        equivalent in OZ v3.x). The access control has been updated from the
        Mintable Role to the Ownable role in order to reduce the amount of code
        taken from the older library. 
        For more information on this change please see the README
        ------------------------------------------------------------------------
    */

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {Ownable} role.
     */
    function mint(address account, uint256 amount)
        public
        onlyOwner()
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    // Set staking address and pool id
    function setStakingInfo(address _address, uint256 _pid) external onlyOwner() {
        stakingAddress = _address;
        poolId = _pid;
    }
}