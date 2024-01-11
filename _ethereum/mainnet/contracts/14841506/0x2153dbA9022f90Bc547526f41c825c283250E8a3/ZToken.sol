//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

/**
 *@dev Contract module which helps to make some fund holded for certain time.
 * accounts added to _holderlist can't spend funds before release date.
 */

contract Holdable is Initializable {
    mapping(address => bool) internal _holdersList;

    /**
     *@dev stores the date of initial deployment of the contract.
     */
    uint256 public initialDate;

    /**
     *@dev stores the date to relaese holded tokens.
     */
    uint256 public releaseDate;
    bool private _released;

    /**
     * @dev Initializes the contract setting initial date and release date.
     * Constructor is removed since proxy is used.
     */

    function __Holdable_init() internal initializer {
        __Holdable_init_unchained();
    }

    function __Holdable_init_unchained() internal initializer {
        initialDate = block.timestamp;
        releaseDate = initialDate + 730 days;
        _released = false;
    }

    /**
     * @dev internal function to add an account to holders list.
     */
    function _addHolder(address _holder) internal virtual {
        _holdersList[_holder] = true;
        emit HolderAdded(_holder);
    }

    /**
     * @dev internal function to remove an account from holders list.
     */
    function _removeHolder(address _holder) internal virtual {
        _holdersList[_holder] = false;
        emit HolderRemoved(_holder);
    }

    /**
     * @dev function to check whether an account belongs to holders list.
     */
    function isHolder(address account) public view returns (bool) {
        return _holdersList[account];
    }

    /**
     * @dev function to check whether release time is reached.
     */
    function released() public virtual returns (bool) {
        uint256 currentBlockTime = block.timestamp;
        _released = currentBlockTime > releaseDate;
        return _released;
    }

    /**
     * @dev Emitted when new `address` added to holders list.
     */
    event HolderAdded(address indexed _account);

    /**
     * @dev Emitted when an `address` removed from holders list.
     */
    event HolderRemoved(address indexed _account);
}

contract ZToken_V1 is ERC20PausableUpgradeable, OwnableUpgradeable, Holdable {
    address private _governor;

    /**
     * @dev Throws if called by any account other than the owner or governer.
     */
    modifier onlyAdmin() {
        require(
            _msgSender() == owner() || _msgSender() == governor(),
            "Caller is not an admin"
        );
        _;
    }

    // prevent intialization of logic contract.
    //constructor() initializer {}

    /**
     * @dev initialize the token contract. Minting _totalSupply into owners account.
     * setting owner as _governer.
     * Note:initializer modifier is used to prevent initialize token twice.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) external initializer {
        __ERC20Pausable_init_unchained();
        __Pausable_init_unchained();
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
        __Ownable_init_unchained();
        __Holdable_init_unchained();
        _mint(_msgSender(), totalSupply_);
        _governor = _msgSender();
    }

    /**
     *@dev external function to set new governer. Function is limited to owner.
     */
    function setGovernor(address newGovernor) external virtual onlyOwner {
        _setGovernor(newGovernor);
    }

    function addHolder(address holder)
        external
        virtual
        onlyAdmin
        returns (bool)
    {
        _addHolder(holder);
        return true;
    }

    function removeHolder(address holder)
        external
        virtual
        onlyAdmin
        returns (bool)
    {
        _removeHolder(holder);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
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
    function burnFrom(address account, uint256 amount) external virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract.
     */
    function pause() external virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be owner of the contract.
     */
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    /**
     *@dev function which returns the governer address.
     * governer role is created to manage funding.
     */

    function governor() public view returns (address) {
        return _governor;
    }

    /**
     *@dev internal function to set new governer.
     */
    function _setGovernor(address newGovernor) internal virtual {
        _governor = newGovernor;
        emit GovernerAdded(newGovernor);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (isHolder(sender)) {
            require(released(), "Holders can't transfer before release Date ");
        }
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Emitted when new `address` added as governer.
     */
    event GovernerAdded(address indexed _account);
}
