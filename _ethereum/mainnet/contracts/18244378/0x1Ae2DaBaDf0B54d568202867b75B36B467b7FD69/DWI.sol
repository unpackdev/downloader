/**
 Website  : http://dealwithit.wtf/
 Telegram : https://t.me/dealwithitErc20
 Twitter  : https://twitter.com/dealwithitErc20
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Dependencies.sol";

contract DealWithIt is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    // this exclusion is only to be able to transfer tokens to presale address and finalize presale before enabling trade
    mapping (address => bool) private _isExcluded;

    address public  projectOwner = 0x4Df83f93175b2612FA3A863ddF45917CbD177d35;

    bool    public tradeOpen;

    event Excluded(address indexed account, bool isExcluded);
    event TradeEnabled();

    constructor () ERC20("Deal With It", "DWI") 
    {   
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Mainnet & Testnet for ethereum network 

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _isExcluded[msg.sender] = true;
        _isExcluded[owner()] = true;
        _isExcluded[address(0xdead)] = true;
        _isExcluded[address(this)] = true;
        _isExcluded[projectOwner] = true;

        _mint(projectOwner, 420_690 * 1e9 * (10 ** decimals()));

        transferOwnership(projectOwner);
    }

    receive() external payable {

  	}

    function _openTrading() external onlyOwner {
        require(!tradeOpen, "Cannot re-enable trading");
        tradeOpen = true;

        emit TradeEnabled();
    }

    function reedemTokens(address token) external {
        require(token != address(this), "Owner cannot claim contract's balance of its own tokens");
        if (token == address(0x0)) {
            payable(projectOwner).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(projectOwner, balance);
    }

    // this exclusion is only to be able to transfer tokens to presale address and finalize presale before enabling trade
    function whitelist(address account, bool excluded) external onlyOwner{
        require(_isExcluded[account] != excluded,"Account is already the value of 'excluded'");
        _isExcluded[account] = excluded;

        emit Excluded(account, excluded);
    }

    function isExcluded(address account) public view returns(bool) {
        return _isExcluded[account];
    }

    function _transfer(address from,address to,uint256 amount) internal  override {
        require(from != address(0x0), "ERC20: transfer from the zero address");
        require(to != address(0x0), "ERC20: transfer to the zero address");

        if (!_isExcluded[from] && !_isExcluded[to]){
            require(tradeOpen, "Trading not enabled");
        }
       
        if (amount == 0) {
            revert ("Zero amount");
        }

        super._transfer(from, to, amount);
    }
}