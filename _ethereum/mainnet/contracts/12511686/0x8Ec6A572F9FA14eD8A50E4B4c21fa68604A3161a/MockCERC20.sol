// SPDX-License-Identifier: MIT
// Mock ERC20 token for testing

pragma solidity 0.7.6;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./ICERC20.sol";

contract MockCERC20Base is ICERC20, ERC20 {
    address public immutable token;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint private constant MULTIPLIER = 10**18;
    uint public exchangeRate;
    bool public returnError;
    constructor(
        address tokenAddr,
        string memory name_, string memory symbol_, uint8 decimals_)
    ERC20(name_, symbol_) {
        token = tokenAddr;
        exchangeRate = MULTIPLIER;
        returnError = false;
        _setupDecimals(decimals_);
    }

    function mint(uint amount) external override returns (uint) {
        if (returnError) return 1;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount.mul(MULTIPLIER).div(exchangeRate));
        return 0;
    }
    function redeem(uint amount) external override returns (uint) {
        if (returnError) return 1;
        IERC20(token).safeTransfer(
            msg.sender, amount.mul(exchangeRate).div(MULTIPLIER)
        );
        _burn(msg.sender, amount);
        return 0;
    }
    function redeemUnderlying(uint amount) external override returns (uint) {
        if (returnError) return 1;
        IERC20(token).safeTransfer(msg.sender, amount);
        _burn(
            msg.sender, amount.mul(MULTIPLIER).div(exchangeRate)
        );
        return 0;
    }
    function exchangeRateCurrent() external view override returns (uint) {
        return exchangeRate;
    }
    function supplyRatePerBlock() external pure override returns (uint) {
        return 0;
    }
    function balanceOf(address account) public override(ERC20, ICERC20) view returns (uint) {
        return ERC20.balanceOf(account);
    }
    function approve(address account, uint amount) public override(ERC20, ICERC20) returns (bool) {
        return ERC20.approve(account, amount);
    }
    function transfer(address dst, uint amount) public override(ERC20, ICERC20) returns (bool) {
        return ERC20.transfer(dst, amount);
    }

    function setExchangeRate(uint e) external {
        exchangeRate = e;
    }
    function setError(bool b) external {
        returnError = b;
    }
}

contract MockCERC20 is MockCERC20Base {
    constructor(address tokenAddr) MockCERC20Base(
        tokenAddr, "MockCERC20", "MCERC20", 18
    ) {
    }
}
