// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./INFTGemFeeManager.sol";
import "./IERC20.sol";

contract NFTGemFeeManager is INFTGemFeeManager {
    address private operator;

    uint256 private constant MINIMUM_LIQUIDITY = 100;
    uint256 private constant FEE_DIVISOR = 1000;

    mapping(address => uint256) private feeDivisors;
    uint256 private _defaultFeeDivisor;

    mapping(address => uint256) private _liquidity;
    uint256 private _defaultLiquidity;

    /**
     * @dev constructor
     */
    constructor() {
        _defaultFeeDivisor = FEE_DIVISOR;
        _defaultLiquidity = MINIMUM_LIQUIDITY;
    }

    /**
     * @dev Set the address allowed to mint and burn
     */
    receive() external payable {
        //
    }

    /**
     * @dev Set the address allowed to mint and burn
     */
    function setOperator(address _operator) external {
        require(operator == address(0), "IMMUTABLE");
        operator = _operator;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function liquidity(address token) external view override returns (uint256) {
        return _liquidity[token] != 0 ? _liquidity[token] : _defaultLiquidity;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function defaultLiquidity() external view override returns (uint256 multiplier) {
        return _defaultLiquidity;
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setDefaultLiquidity(uint256 _liquidityMult) external override returns (uint256 oldLiquidity) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_liquidityMult != 0, "INVALID");
        oldLiquidity = _defaultLiquidity;
        _defaultLiquidity = _liquidityMult;
        emit LiquidityChanged(operator, oldLiquidity, _defaultLiquidity);
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function feeDivisor(address token) external view override returns (uint256 divisor) {
        divisor = feeDivisors[token];
        divisor = divisor == 0 ? FEE_DIVISOR : divisor;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function defaultFeeDivisor() external view override returns (uint256 multiplier) {
        return _defaultFeeDivisor;
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setDefaultFeeDivisor(uint256 _feeDivisor) external override returns (uint256 oldDivisor) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = _defaultFeeDivisor;
        _defaultFeeDivisor = _feeDivisor;
        emit DefaultFeeDivisorChanged(operator, oldDivisor, _defaultFeeDivisor);
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setFeeDivisor(address token, uint256 _feeDivisor) external override returns (uint256 oldDivisor) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = feeDivisors[token];
        feeDivisors[token] = _feeDivisor;
        emit FeeDivisorChanged(operator, token, oldDivisor, _feeDivisor);
    }

    /**
     * @dev get the ETH balance of this fee manager
     */
    function ethBalanceOf() external view override returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev get the token balance of this fee manager
     */
    function balanceOF(address token) external view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev transfer ETH from this contract to the to given recipient
     */
    function transferEth(address payable recipient, uint256 amount) external override {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");
        recipient.transfer(amount);
    }

    /**
     * @dev transfer tokens from this contract to the to given recipient
     */
    function transferToken(
        address token,
        address recipient,
        uint256 amount
    ) external override {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(IERC20(token).balanceOf(address(this)) >= amount, "INSUFFICIENT_BALANCE");
        IERC20(token).transfer(recipient, amount);
    }
}
