// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @dev XMust contract is a wrapper around the Must token. It is a ERC20 token
 * that does not allow trading. The balance of xMust represents the share of
 * the Tube an address own. Minting xMust means creating shares of the Tube.
 * Burning xMust means removing shares of the Tube.
 */
contract XMust {
    using SafeMath for uint256;

    IERC20 public must;

    mapping(address => uint256) private _shares;
    uint256 private _totalSupply;

    constructor(IERC20 _must) public {
        must = _must;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _shares[account];
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    // mint creates `amount` shares for `holder`
    function _mint(address holder, uint256 amount) internal {
        require(holder != address(0), "xMust: mint to the zero address");
        _shares[holder] = _shares[holder].add(amount);
        _totalSupply = _totalSupply.add(amount);
    }

    // burn removes `amount` shares from `holder`.
    // It requires that `holder` owns at least `amount` xMust.
    function _burn(address holder, uint256 amount) internal {
        require(amount > 0, "xMust: cannot burn zero");
        require(holder != address(0), "xMust: burn from the zero address");
        require(
            _shares[holder] >= amount,
            "xMust: burn amount exceeds balance"
        );

        _shares[holder] = _shares[holder].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
    }
}
