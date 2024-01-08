pragma solidity >=0.5.17 <=0.8.0;


import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2.sol";

contract SwapInUniswapV2 {
    using SafeERC20 for IERC20;
    address private uniswapV2Address = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function swap(
        address fromToken,
        uint256 _amount,
        uint256 _minReturn,
        address[] memory _path,
        address recipient,
        uint256 _timeout
    ) public returns (uint256[] memory) {
        require(_amount > 0, '_amount>0');
        require(_minReturn >= 0, '_minReturn>=0');
        IERC20(fromToken).safeApprove(uniswapV2Address, 0);
        IERC20(fromToken).safeApprove(uniswapV2Address, _amount);

       try IUniswapV2(uniswapV2Address).swapExactTokensForTokens(
            _amount,
            _minReturn,
            _path,
            recipient,
            block.timestamp + _timeout
        ) returns (uint256[] memory amounts){
           return amounts;
       }catch{

       }
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0;
        amounts[1] = 0;
        return amounts;
    }
}
