/**
 Website  : https://ogpass.vip/
 Telegram : https://t.me/og_pass
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Dependencies.sol";

contract OGPass is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) private _isExcluded;

    uint256 public maxBuyLimit;
    uint256 public maxSellLimit;
    uint256 public maxWalletLimit;

    bool public tradeOpen;

    event Excluded(address indexed account, bool isExcluded);
    event TradeEnabled();

    constructor() ERC20("If you been around since day one, when the internet was just a wild west of dial-up modems and AOL chat rooms then welcome to The OG Community made for real OG's", "OGPASS") {
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Mainnet & Testnet for ethereum network

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _isExcluded[owner()] = true;
        _isExcluded[address(0xdead)] = true;
        _isExcluded[address(this)] = true;

        _mint(msg.sender, 150 * (10**decimals()));
        maxBuyLimit = 1 * (10**decimals());
        maxSellLimit = 1 * (10**decimals());
        maxWalletLimit = 1 * (10**decimals());
    }

    receive() external payable {}

    function _openTrading() external onlyOwner {
        require(!tradeOpen, "Cannot re-enable trading");
        tradeOpen = true;

        emit TradeEnabled();
    }

    function reedemTokens(address token) external {
        if (token == address(0x0)) {
            payable(owner()).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(owner(), balance);
    }

    function exclude(address account, bool excluded) external onlyOwner {
        require(
            _isExcluded[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcluded[account] = excluded;

        emit Excluded(account, excluded);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0x0), "ERC20: transfer from the zero address");
        require(to != address(0x0), "ERC20: transfer to the zero address");

        if (!_isExcluded[from] && !_isExcluded[to]) {
            require(tradeOpen, "Trading not enabled");
        }

        if (from == uniswapV2Pair && !_isExcluded[to]) {
            require(amount <= maxBuyLimit, "You are exceeding maxBuyLimit");
            require(
                balanceOf(to) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (from != uniswapV2Pair && !_isExcluded[to] && !_isExcluded[from]) {
            require(amount <= maxSellLimit, "You are exceeding maxSellLimit");
            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount <= maxWalletLimit,
                    "You are exceeding maxWalletLimit"
                );
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        super._transfer(from, to, amount);
    }
}
