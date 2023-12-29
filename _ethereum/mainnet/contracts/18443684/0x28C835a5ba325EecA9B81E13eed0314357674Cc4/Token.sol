// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;


import "./ERC20.sol";


interface IUniSwapV2Router {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}


contract EBOT is ERC20 {
    IUniSwapV2Router public constant UNISWAP_ROUTER = IUniSwapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniFactory public constant UNISWAP_FACTORY = IUniFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address payable public constant FEE_RECEIVER = payable(0x4968A5DC556672bfDD91fFb545f94e56B8208F52);

    address uniswapPoolAddress = address(0x0);
    address immutable owner;
    mapping(address => bool) public noFeeSellers;

    error NotAnOwner(address sender, address owner);

    constructor(uint256 initialSupply) ERC20("Essentially the Best Of Tweets", "EBOT") {
        owner = msg.sender;
        noFeeSellers[owner] = true;
        noFeeSellers[address(this)] = true;
        _mint(msg.sender, initialSupply);
        _approve(address(this), address(UNISWAP_ROUTER), type(uint256).max);
    }

    function setNoFeeSeller(address seller) external {
        if (msg.sender != owner) {
            revert NotAnOwner(msg.sender, owner);
        }
        noFeeSellers[seller] = true;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount == 0) { return; }
        // Update Cache
        if (uniswapPoolAddress == address(0x0) && msg.sender == address(UNISWAP_ROUTER)) {
            uniswapPoolAddress = UNISWAP_FACTORY.getPair(UNISWAP_ROUTER.WETH(), address(this));
        }
        
        bool isSell = (uniswapPoolAddress == to);
        if (isSell) {
            uint256 fees = amount * 7 / 200;
            if (fees > 0 && !noFeeSellers[from]) {
                super._update(from, address(this), fees);
                swapTokensForEth(fees);
                amount -= fees;
            }
        }
        super._update(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            FEE_RECEIVER,
            block.timestamp
        );
    }
}
