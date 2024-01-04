// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./UniswapV2Library.sol";
import "./TransferHelper.sol";

contract NFTFund is Ownable {
    using SafeMath for uint256;

    event TokensForEthSwapped(uint256 tokenAmount, uint256 weiBalanceAfterSwap, address indexed from);
    event TokenWithdrawn(uint256 tokenAmount, address indexed token, address indexed to);
    event EthWithdrawn(uint256 weiAmount, address indexed to);

    IUniswapV2Router02 public router;

    IERC20 public token;

    constructor(IUniswapV2Router02 _router,  IERC20 _token) public {
        require(
            address(_router) != address(0) &&
            address(_token) != address(0),
            "NFTFund: router and token are zero addresses"
        );
        token = _token;
        router = _router;
    }

    receive() external payable {}

    function getTokenBalance() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function updateTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), "NFTFund: token is a zero address");

        token = IERC20(_token);
    }

    function swapTokensForETH() external {
        uint amountToSwap = getTokenBalance();
        _swapTokensForETH(amountToSwap);
    }

    function swapTokensForETH(uint256 amountToSwap) external {
        require(
            amountToSwap <= getTokenBalance(),
            "NFTFund: token amount exceeds balance"
        );

        _swapTokensForETH(amountToSwap);
    }

    function withdrawETH() external onlyOwner {
        uint256 weiAmount = address(this).balance;
        _withdrawETH(weiAmount, msg.sender);
    }

    function withdrawETH(uint256 weiAmount) external onlyOwner {
        _withdrawETH(weiAmount, msg.sender);
    }

    function withdrawTokens() external onlyOwner {
        uint256 tokenAmount = getTokenBalance();
        _withdrawTokens(tokenAmount, address(token), msg.sender);
    }

    function withdrawTokens(uint256 tokenAmount) external onlyOwner {
        _withdrawTokens(tokenAmount, address(token), msg.sender);
    }

    function _swapTokensForETH(uint _amountIn)
        internal
    {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = router.WETH();
        TransferHelper.safeApprove(address(token), address(router), _amountIn);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );

        emit TokensForEthSwapped(_amountIn, address(this).balance, msg.sender);
    }

    function _withdrawTokens(uint256 _tokenAmount, address _token, address _to) internal {
        require(_tokenAmount > 0, "NFTFund: HCORE amount should be > 0");
        require(
            _tokenAmount <= getTokenBalance(),
            "NFTFund: token amount exceeds balance"
        );

        IERC20(_token).transfer(_to, _tokenAmount);
        emit TokenWithdrawn(_tokenAmount, _token, _to);
    }

    function _withdrawETH(uint256 _weiAmount, address payable _to) internal {
        require(_weiAmount > 0, "NFTFund: ETH amount should be > 0");
        require(_weiAmount <= address(this).balance, "NFTFund: wei amount exceeds balance");

        _to.transfer(_weiAmount);
        emit EthWithdrawn(_weiAmount, _to);
    }
}