pragma solidity 0.7.6;

import "./MinterPauserClaimableERC20.sol";
import "./IFuture.sol";
import "./ILiquidityGauge.sol";

/**
 * @title APWine interest bearing token
 * @notice Interest bearing token for the futures liquidity provided
 * @dev the value of an APWine IBT is equivalent to a fixed amount of underlying tokens of the future IBT
 */
contract APWineIBT is MinterPauserClaimableERC20 {
    using SafeMathUpgradeable for uint256;

    IFuture public future;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * future
     *
     * See {ERC20-constructor}.
     */

    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address futureAddress
    ) public initializer {
        super.initialize(name, symbol);
        _setupRole(DEFAULT_ADMIN_ROLE, futureAddress);
        _setupRole(MINTER_ROLE, futureAddress);
        _setupRole(PAUSER_ROLE, futureAddress);
        future = IFuture(futureAddress);
        _setupDecimals(decimals);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        // sender and receiver state update
        if (from != address(future) && to != address(future) && from != address(0x0) && to != address(0x0)) {
            // update apwIBT and FYT balances befores executing the transfer
            if (future.hasClaimableFYT(from)) {
                future.claimFYT(from);
            }
            if (future.hasClaimableFYT(to)) {
                future.claimFYT(to);
            }
            if (future.hasNoRecord(to)) {
                future.createRecord(to);
            }
        }
    }

    /**
     * @notice transfer a defined amount of apwIBT from one user to another
     * @param sender sender's address
     * @param recipient recipient'saddress
     * @param amount amount of apwIBT to be transferred
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        if (recipient != address(future)) {
            _approve(
                sender,
                _msgSender(),
                allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance")
            );
        }
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
    function burnFrom(address account, uint256 amount) public override {
        if (msg.sender != address(future)) {
            super.burnFrom(account, amount);
        } else {
            _burn(account, amount);
        }
    }

    /**
     * @notice returns the current balance of one user including the apwIBT that were not claimed yet
     * @param account the address of the account to check the balance of
     * @return the total apwIBT balance of one address
     */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account).add(future.getClaimableAPWIBT(account));
    }

    uint256[50] private __gap;
}
