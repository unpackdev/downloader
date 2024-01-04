// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./Pausable.sol";

import "./XMust.sol";
import "./PoolManager.sol";

/**
 * @dev Tube allow users to supply liquidity in exchange of shares of the Tube.
 * Each xMust represents a share of the Tube. Each xMust generate a reward each
 * day that can be used to on external pool to mint tokens.
 */
contract Tube is AccessControl, Pausable, XMust, PoolManager {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(IERC20 _must) public XMust(_must) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Enter the msg sender in the Tube. An amount of must will be locked
     * on the Tube and an a quantity of shares (xMust) will be minted.
     *
     * @param amount Amount of must to transfer.
     *
     * Requirements:
     * - the Tube must be allowed on Must contract for the caller.
     */
    function enter(uint256 amount) external {
        _enter(msg.sender, amount);
    }

    /**
     * @dev Enter for a holder in the Tube by an operator. An amount of must
     * will be locked on the Tube and an a quantity of shares (xMust) will be
     * minted.
     *
     * @param holder Must holder.
     * @param amount Amount of must to transfer.
     *
     * Requirements:
     * - the caller must be allowed on Must contract for the holder.
     * - the Tube must be allowed on Must contract for the holder.
     */
    function enterFor(address holder, uint256 amount) external {
        _enter(holder, amount);
    }

    /**
     * @dev Withdraw the quantity of must associated to an amount shares.
     *
     * @param amount xMust amount.
     */
    function withdraw(uint256 amount) external {
        _withdraw(msg.sender, amount);
    }

    /**
     * @dev Add pool for reward.
     *
     * @param pool Pool address.
     */
    function addPool(address pool) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "Tube: must have manager role to change pool"
        );
        _addPool(pool);
    }

    /**
     * @dev Remove pool.
     *
     * @param pool Pool address.
     */
    function removePool(address pool) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "Tube: must have manager role to change pool"
        );
        _removePool(pool);
    }

    function pause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Tube: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Tube: must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @dev Quantity of must of an holder. This quantity is equal to the holder
     * shares multiplied by the total must amount and divided by the
     * total shares.
     *
     * @param holder xMust holder.
     */
    function mustOf(address holder) external view returns (uint256) {
        return _mustForShares(balanceOf(holder));
    }

    // _enter locks msg.sender `amount` must and creates shares of the Tube
    // for the given `amount` to `holder`.
    function _enter(address holder, uint256 amount) private {
        _beforeAction();
        _updateRewards(holder);
        uint256 mustSupply = must.balanceOf(address(this));
        uint256 xMustSupply = totalSupply();

        // by default we give 1 share per must
        uint256 shares = amount;
        if (mustSupply > 0 && xMustSupply > 0) {
            // in case there is already a supply compute the number of shares
            // for the given amount using a cross product. This can happen
            // because must can be transfered to the Tube without creating
            // shares. Similarly, users can withdraw their must.
            shares = amount.mul(xMustSupply).div(mustSupply);
        }

        _mint(holder, shares);
        must.transferFrom(msg.sender, address(this), amount);
    }

    // withdraw burns `holder`'s `shares`of the Tube and withdraw those `shares`
    // in must to `holder`. It requires that `holder` owns at least `shares`
    // of the Tube and `amount` is greater than 0.
    function _withdraw(address holder, uint256 shares) private {
        _beforeAction();
        _updateRewards(holder);
        uint256 _must = _mustForShares(shares);

        _burn(holder, shares);
        must.transfer(holder, _must);
    }

    function _mustForShares(uint256 shares) private view returns (uint256) {
        uint256 xMustSupply = totalSupply();
        if (xMustSupply == 0) {
            return 0;
        }

        uint256 mustSupply = must.balanceOf(address(this));
        return shares.mul(mustSupply).div(xMustSupply);
    }

    function _beforeAction() internal override {
        super._beforeAction();

        require(!paused(), "Tube: action blocked while paused");
    }
}
