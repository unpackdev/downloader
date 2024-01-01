// SPDX-License-Identifier: MIT

/* solhint-disable no-empty-blocks */
pragma solidity 0.8.19;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./IERC20.sol";
import "./Ownable.sol";
import "./FeeManager.sol";

contract SpcFeeManager is FeeManager, Ownable {
    /// @notice address of wrapped ETH
    address public wETH;

    /// @notice address of LP mint
    address public lpMint;

    /// @notice uniswap V2 pair address
    IUniswapV2Pair public uniswapPair;
    /// @notice uniswap V2 router
    IUniswapV2Router02 public uniswapRouter;

    /// @notice min amount of tokens to trigger sync
    uint256 public minTokens;

    /// @notice fee distribution
    uint256 public burnFeeAlloc = 0;
    uint256 public lpFeeAlloc = 100;
    uint256 public totalFeeAlloc = burnFeeAlloc + lpFeeAlloc;

    address public taxReceiverAddress;

    constructor(address _token, address _wETH, address _taxReceiverAddress) FeeManager(_token) {
        require(_wETH != address(0), "_wETH address cannot be 0");
        wETH = _wETH;
        minTokens = 100 * 10**18;
        taxReceiverAddress = _taxReceiverAddress; 
    }

    function setUniswap(address _uniswapPair, address _uniswapRouter) external onlyOwner {
        require(_uniswapPair != address(0), "_uniswapPair address cannot be 0");
        require(_uniswapRouter != address(0), "_uniswapRouter address cannot be 0");
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);

        IERC20(token).approve(address(uniswapRouter), 0);
        IERC20(token).approve(address(uniswapRouter), type(uint256).max);
        IERC20(wETH).approve(address(uniswapRouter), 0);
        IERC20(wETH).approve(address(uniswapRouter), type(uint256).max);
    }

    function canSyncFee(address, address recipient) external view override returns (bool shouldSyncFee) {
            shouldSyncFee = true; // when swap token > ETH
    }

    function _syncFee() internal override {
        uint256 totalAmount = IERC20(token).balanceOf(address(this));
        uint256 burnAmount;

        if (totalAmount >= minTokens && totalFeeAlloc > 0) {
            burnAmount = (totalAmount * burnFeeAlloc) / totalFeeAlloc;

            if (burnAmount > 0) {
                IERC20(token).burn(burnAmount);
            }

            uint256 swapAmount = totalAmount - burnAmount;
            _swapTokens(swapAmount);

        }
    }

    function _swapTokens(uint256 amount) private {
        address[] memory path = new address[](2);

        path[0] = token;
        path[1] = wETH;

        try
            uniswapRouter.swapExactTokensForTokens(
                amount,
                0,
                path,
                address(taxReceiverAddress),
                block.timestamp // solhint-disable-line not-rely-on-time
            )
        {
            //
        } catch {
            //
        }
    }

    function _addTokensToLiquidity(uint256 tokenAmount, uint256 wETHAmount) private {
        if (tokenAmount != 0 && wETHAmount != 0) {
            address destination = (lpMint != address(0)) ? lpMint : address(this);

            try
                uniswapRouter.addLiquidity(
                    token,
                    wETH,
                    tokenAmount,
                    wETHAmount,
                    0,
                    0,
                    destination,
                    block.timestamp // solhint-disable-line not-rely-on-time
                )
            {
                //
            } catch {
                //
            }
        }
    }

    function setLpMint(address _lpMint) public onlyOwner {
        lpMint = _lpMint;
    }

    function setMinTokens(uint256 _minTokens) public onlyOwner {
        require(_minTokens >= 100, "not less then 100");
        minTokens = _minTokens;
    }

    function setFeeAlloc(uint256 _burnFeeAlloc, uint256 _lpFeeAlloc) public onlyOwner {
        require(_burnFeeAlloc >= 0 && _burnFeeAlloc <= 100, "_burnFeeAlloc is outside of range 0-100");
        require(_lpFeeAlloc >= 0 && _lpFeeAlloc <= 100, "_lpFeeAlloc is outside of range 0-100");
        burnFeeAlloc = _burnFeeAlloc;
        lpFeeAlloc = _lpFeeAlloc;
        totalFeeAlloc = burnFeeAlloc + lpFeeAlloc;
    }

    function recoverETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function recoverErc20(address _token) external onlyOwner {
        uint256 amt = IERC20(_token).balanceOf(address(this));
        require(amt > 0, "nothing to recover");
        IBadErc20(_token).transfer(owner, amt);
    }

    function updateTaxAddress(address _address) external onlyOwner {
        require(_address != address(0), "zero address");
        taxReceiverAddress = _address;
    }

    receive() external payable {} // not necessary
}

interface IBadErc20 {
    function transfer(address _recipient, uint256 _amount) external;
}