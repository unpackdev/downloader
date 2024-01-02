// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

interface IUniswapV2Router02 {
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint) external;

    function approve(address to, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function balanceOf(address owner) external view returns (uint);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

contract dipiFiRouter {
    address private owner;
    IUniswapV2Router02 private uniswapRouter;
    IWETH private weth;
    bool private locked;
    modifier noReentrancy() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // weth = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
        weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    function _safeTransferETH(address payable _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        address payable feeAddress,
        address payable referralAddress
    ) external payable noReentrancy {
        require(msg.value > 0, "No ETH sent");
        require(
            feeAddress != address(0) && referralAddress != address(0),
            "Invalid fee or referral address"
        );

        uint256 fee = msg.value / 100;
        require(fee > 0, "Fee calculates to zero");
        uint256 swapValue = msg.value - fee;
        require(swapValue > 0, "Insufficient value post-fee");

        _safeTransferETH(feeAddress, fee / 2);
        _safeTransferETH(referralAddress, fee / 2);

        weth.deposit{value: swapValue}();

        require(
            weth.approve(address(uniswapRouter), swapValue),
            "WETH approve failed"
        );

        uint256[] memory amounts = uniswapRouter.swapTokensForExactTokens(
            amountOut,
            swapValue,
            path,
            to,
            deadline
        );
        uint256 usedWeth = amounts[0];

        if (usedWeth < swapValue) {
            uint256 unusedWeth = swapValue - usedWeth;
            weth.withdraw(unusedWeth);
            _safeTransferETH(payable(msg.sender), unusedWeth);
        }
    }

    function swapETHForExactTokensWithBribe(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        address payable feeAddress,
        address payable referralAddress,
        uint256 bribeAmount
    ) external payable noReentrancy {
        require(msg.value > 0, "No ETH sent");
        require(
            feeAddress != address(0) && referralAddress != address(0),
            "Invalid fee or referral address"
        );
        require(msg.value > bribeAmount, "Insufficient ETH for bribe");

        uint256 remainingETHAfterBribe = msg.value - bribeAmount;
        uint256 fee = remainingETHAfterBribe / 100;
        require(fee > 0, "Fee calculates to zero");
        uint256 swapValue = remainingETHAfterBribe - fee;
        require(swapValue > 0, "Insufficient value post-fee");

        _safeTransferETH(feeAddress, fee / 2);
        _safeTransferETH(referralAddress, fee / 2);

        _safeTransferETH(payable(block.coinbase), bribeAmount);

        weth.deposit{value: swapValue}();

        require(
            weth.approve(address(uniswapRouter), swapValue),
            "WETH approve failed"
        );

        uint256[] memory amounts = uniswapRouter.swapTokensForExactTokens(
            amountOut,
            swapValue,
            path,
            to,
            deadline
        );
        uint256 usedWeth = amounts[0];

        if (usedWeth < swapValue) {
            uint256 unusedWeth = swapValue - usedWeth;
            weth.withdraw(unusedWeth);
            _safeTransferETH(payable(msg.sender), unusedWeth);
        }
    }

    receive() external payable {}

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        address payable feeAddress,
        address payable referralAddress
    ) external payable noReentrancy {
        require(
            feeAddress != address(0) && referralAddress != address(0),
            "Invalid address"
        );

        uint256 fee = msg.value / 100;
        uint256 swapValue = msg.value - fee;

        feeAddress.transfer(fee / 2);
        referralAddress.transfer(fee / 2);

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: swapValue
        }(amountOutMin, path, to, deadline);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address payable to,
        uint256 deadline,
        address payable feeAddress,
        address payable referralAddress
    ) external {
        require(
            feeAddress != address(0) && referralAddress != address(0),
            "Swap: Fee or referral address is zero"
        );

        IERC20 token = IERC20(path[0]);
        require(
            token.balanceOf(msg.sender) >= amountIn,
            "Swap: Insufficient token balance"
        );
        require(
            token.allowance(msg.sender, address(this)) >= amountIn,
            "Swap: Token allowance too low"
        );

        require(
            token.transferFrom(msg.sender, address(this), amountIn),
            "Swap: Transfer of tokens to contract failed"
        );

        require(
            token.approve(address(uniswapRouter), amountIn),
            "Swap: Token approval for router failed"
        );

        uint256 balanceBeforeSwap = address(this).balance;

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        uint256 amountETH = address(this).balance - balanceBeforeSwap;
        require(
            amountETH >= amountOutMin,
            "Swap: Swap did not yield enough ETH"
        );

        uint256 fee = amountETH / 100;
        uint256 feeHalf = fee / 2;

        (bool feeSuccess, ) = feeAddress.call{value: feeHalf}("");
        require(feeSuccess, "Swap: Fee transfer to fee address failed");

        (bool referralSuccess, ) = referralAddress.call{value: feeHalf}("");
        require(
            referralSuccess,
            "Swap: Fee transfer to referral address failed"
        );

        (bool toSuccess, ) = to.call{value: amountETH - fee}("");
        require(toSuccess, "Swap: ETH transfer to recipient failed");
    }

    function sendETH(address payable _to, uint _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient Balance");
        _to.transfer(_amount);
        emit Sent(_to, _amount);
    }

    event Sent(address, uint);

    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawTokens(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
}