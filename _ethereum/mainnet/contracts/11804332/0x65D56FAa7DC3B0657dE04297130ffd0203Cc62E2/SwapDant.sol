pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

contract SwapDant is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public usdtToken;
    ERC20 public dantToken;

    event Swap(
        address indexed user,
        uint amountIn,
        uint amountOut,
        bool receiveDant
    );

    constructor(
        ERC20 _usdtToken,
        ERC20 _dantToken
    ) public {
        usdtToken = _usdtToken;
        dantToken = _dantToken;
    }

    function buytDant(uint256 _amountIn) external{
        uint256 amountOut = _amountIn.mul(1e12);
        usdtToken.safeTransferFrom(msg.sender, address(this), _amountIn);
        dantToken.safeTransfer(msg.sender, amountOut);
        emit Swap(msg.sender, _amountIn, amountOut, true);
    }

    function sellDant(uint256 _amountIn) external{
        uint256 amountOut = _amountIn.div(1e12);
        dantToken.safeTransferFrom(msg.sender, address(this), _amountIn);
        usdtToken.safeTransfer(msg.sender, amountOut);
        emit Swap(msg.sender, _amountIn, amountOut, false);
    }

     function withdrawUSDT(uint256 amount) external onlyOwner{
        usdtToken.safeTransfer(msg.sender, amount);
    }

    function withdrawDant(uint256 amount) external onlyOwner{
        dantToken.safeTransfer(msg.sender, amount);
    }
}