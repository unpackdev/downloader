// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC20.sol";
import "./ILToken.sol";
import "./ERC20.sol";
import "./UnsignedSafeMath.sol";

/**
 * @title Deri Protocol liquidity provider token implementation
 */
contract LToken is IERC20, ILToken, ERC20 {

    using UnsignedSafeMath for uint256;

    // Pool address this LToken associated with
    address private _pool;

    modifier _pool_() {
        require(msg.sender == _pool, "LToken: called by non-associative pool, probably the original pool has been migrated");
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token
     */
    constructor(string memory name_, string memory symbol_, address pool_) ERC20(name_, symbol_) {
        require(pool_ != address(0), "LToken: construct with 0 address pool");
        _pool = pool_;
    }

    /**
     * @dev See {ILToken}.{setPool}
     */
    function setPool(address newPool) public override {
        require(newPool != address(0), "LToken: setPool to 0 address");
        require(msg.sender == _pool, "LToken: setPool caller is not current pool");
        _pool = newPool;
    }

    /**
     * @dev See {ILToken}.{pool}
     */
    function pool() public view override returns (address) {
        return _pool;
    }

    /**
     * @dev See {ILToken}.{mint}
     */
    function mint(address account, uint256 amount) public override _pool_ {
        require(account != address(0), "LToken: mint to 0 address");

        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev See {ILToken}.{burn}
     */
    function burn(address account, uint256 amount) public override _pool_ {
        require(account != address(0), "LToken: burn from 0 address");
        require(_balances[account] >= amount, "LToken: burn amount exceeds balance");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

}
