// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC2771Context.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract UniswapGasless is ERC2771Context {
    uint256 private BASE_FEE = 0.001 ether;
    uint256 private MAX_ALLOWANCE = 999999999999999999999999999;
    address private feeCollector;
    address public owner;
    uint8 public fixedPercentageFee = 1; // 1%
    bool public isFixedPercentageFeeMode = true;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Router02 private router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address trustedForwarder, uint256 _baseFee, address _feeCollector, address _owner) ERC2771Context(trustedForwarder) {
        feeCollector = _feeCollector;
        BASE_FEE = _baseFee;
        _transferOwnership(_owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function changeFeeMode(bool _isFixedPercentageFee) external onlyOwner {
        isFixedPercentageFeeMode = _isFixedPercentageFee;
    }

    function setPercentageFee(uint8 _fixedPercentageFee) external onlyOwner {
        require(_fixedPercentageFee > 0, "FixedFeeCantBeZero");
        fixedPercentageFee = _fixedPercentageFee;
    }

    function swapTokenForToken(
        address[] memory path,
        uint256 amountOutDesired,
        uint256 amountIn,
        uint256 estimatedGas,
        uint256 priceQuote,
        bool reverseQuote
    ) external returns (uint amountOut) {
        require(path.length > 0, "UniswapV2/InvalidPath");

        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        if (IERC20(path[0]).allowance(address(this), address(router)) == 0) {
            IERC20(path[0]).approve(address(router), MAX_ALLOWANCE);
        }

        (uint256 tokenCharge,) = calculateCharge(estimatedGas, priceQuote, amountIn, path[0], reverseQuote);
        require(tokenCharge < amountIn, "UniswapV2/NotEnoughToCoverFee");

        uint256 remainTokenIn = amountIn - tokenCharge;
        uint256 amountOutDesiredCalculated = remainTokenIn * amountOutDesired / amountIn;

        if (tokenCharge > 0)  {
            IERC20(path[0]).transferFrom(address(this), feeCollector, tokenCharge);
        }

        // do the real swap
        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOutDesiredCalculated,
            remainTokenIn,
            path,
            _msgSender(),
            block.timestamp + 1800
        );

        return amounts[1];
    }

    function swapExactTokensForETH(
        address[] memory path,
        uint256 amountOutDesired,
        uint256 amountIn,
        uint256 estimatedGas,
        uint256 priceQuote,
        bool reverseQuote
    ) external returns (uint amountOut) {
        require(path.length > 1 && path[path.length - 1] == WETH, "UniswapV2/InvalidPath");

        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        if (IERC20(path[0]).allowance(address(this), address(router)) == 0) {
            IERC20(path[0]).approve(address(router), MAX_ALLOWANCE);
        }

        (uint256 tokenCharge,) = calculateCharge(estimatedGas, priceQuote, amountIn, path[0], reverseQuote);
        require(tokenCharge < amountIn, "UniswapV2/NotEnoughToCoverFee");

        uint256 remainTokenIn = amountIn - tokenCharge;
        uint256 amountOutDesiredCalculated = remainTokenIn * amountOutDesired / amountIn;

        if (tokenCharge > 0)  {
            IERC20(path[0]).transferFrom(address(this), feeCollector, tokenCharge);
        }

        // do the real swap
        uint[] memory amounts = router.swapExactTokensForETH(
            remainTokenIn,
            amountOutDesiredCalculated,
            path,
            _msgSender(),
            block.timestamp + 1800
        );

        return amounts[1];
    }

    function swapETHForToken(
        address[] memory path,
        uint256 amountOutDesired,
        uint256 estimatedGas
    ) external payable returns (uint amountOut) {
        require(path.length > 0 && path[0] == WETH, "UniswapV2/InvalidPath");
        require(msg.value > 0, "UniswapV2/Insufficient");

        (, uint256 ethCharge) = calculateCharge(estimatedGas, 0, msg.value, path[0],  false);
        require(ethCharge < msg.value, "UniswapV2/NotEnoughToCoverFee");

        uint256 remainTokenIn = msg.value - ethCharge;
        uint256 amountOutDesiredCalculated = remainTokenIn * amountOutDesired / msg.value;

        if (ethCharge > 0) {
            payable(feeCollector).transfer(ethCharge);
        }

        // do the real swap
        uint[] memory amounts = router.swapExactETHForTokens{value: msg.value}(
            amountOutDesiredCalculated,
            path,
            _msgSender(),
            block.timestamp + 1800
        );

        return amounts[1];
    }

    function calculateCharge(
        uint256 gasUsed,
        uint256 priceQuote,
        uint256 amountIn,
        address token,
        bool reverseQuote
    ) public view
    returns (uint256 tokenCharge, uint256 ethCharge) {
        if (tx.gasprice != 0) {
            ethCharge = BASE_FEE + gasUsed * tx.gasprice;
        } else {
            ethCharge = BASE_FEE + gasUsed * 20000000000; // 20 Gwei
        }

        if (isFixedPercentageFeeMode) {
            return (amountIn * fixedPercentageFee / 100, ethCharge);
        }
        
        if (priceQuote != 0) {
            if (reverseQuote) {
                return (ethCharge * priceQuote/(1 ether), ethCharge);
            }
            
            uint8 decimals = IERC20(token).decimals()*2;
            return (ethCharge * (10**decimals) / priceQuote/(1 ether), ethCharge);
        }
    }

    function withdrawEther(uint256 amount, address to) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient contract balance");

        // Transfer Ether to the owner
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Ether transfer failed");
    }

    function recoverTokens(address token, uint256 amount, address to) external onlyOwner {
        require(IERC20(token).transfer(to, amount), "Transfer failed");
    }

    function revokeAllowance(address token, address spender) external onlyOwner {
        IERC20(token).approve(spender, 0);
    }

    error OwnableUnauthorizedAccount(address account);
}

