// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./AccessControl.sol";
import "./GovernanceToken.sol";

contract CarveToken is GovernanceToken, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");

    uint256 public constant CAP = 100 * (10 ** 3) * (10 ** 18);
    uint256 public burnedSupply;
    uint256 public fee;
    address public rewardPoolAddress;

    constructor(uint256 fee_)
        ERC20("Carve", "CARVE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(GOV_ROLE, msg.sender);
        fee = fee_;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not an admin");
        _;
    }

    modifier onlyMinters() {
        require(hasRole(MINTER_ROLE, msg.sender), "caller is not a minter");
        _;
    }

    modifier onlyGov() {
        require(hasRole(GOV_ROLE, msg.sender), "caller is not governor");
        _;
    }

    /**
     * @notice Helper function to return fee for amount
     * @param amount amount to calculate fee on
     */
    function feeForAmount(uint256 amount) public view returns (uint256) {
        return amount.mul(fee).div(1000);
    }

    /**
     * @notice Sets reward pool
     * @param rewardPoolAddress_ address where rewards are sent
     */
    function setRewardPool(address rewardPoolAddress_) external onlyAdmin {
        rewardPoolAddress = rewardPoolAddress_;
    }

    /**
     * @notice Sets the transaction fee percentage. Maximum of 5%.
     * @param fee_ percentage using decimal base of 1000 ie: 10% = 100
     */
    function setFee(uint256 fee_) external onlyGov {
        require(fee_ <= 50, "invalid fee value");
        fee = fee_;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function mint(address to, uint256 amount) external onlyMinters {
        _mint(to, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferWithFee(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transferWithFee(sender, recipient, amount);
        _approve(sender, msg.sender, allowance(sender, msg.sender).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
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
    function burnFrom(address account, uint256 amount) external {
        uint256 decreasedAllowance = allowance(account, msg.sender).sub(amount, "ERC20: burn amount exceeds allowance");
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient` and takes a fee.
     */
    function _transferWithFee(address sender, address recipient, uint256 amount) internal {
        uint256 amount_fee = feeForAmount(amount);
        uint256 amount_send = amount.sub(amount_fee);
        require(amount == amount_send + amount_fee, "Fee value invalid");

        if (amount_fee > 0 && rewardPoolAddress != address(0)) {
            uint256 amount_reward = amount_fee.div(2);
            amount_fee = amount_fee.sub(amount_reward);
            if (amount_reward > 0) {
                _transfer(sender, rewardPoolAddress, amount_reward);
            }
        }

        if (amount_fee > 0) {
            _burn(sender, amount_fee);
        }

        _transfer(sender, recipient, amount_send);
    }

    /**
     * @dev Destroys `amount` tokens from the `account`.
     *
     * See {ERC20-_burn}.
     */
    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        burnedSupply = burnedSupply.add(amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= CAP, "cap exceeded");
        }
        _moveDelegates(_delegates[from], _delegates[to], amount);
    }
}