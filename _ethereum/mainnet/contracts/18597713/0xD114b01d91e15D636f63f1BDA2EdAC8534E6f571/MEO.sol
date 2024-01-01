// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./ERC20.sol";


interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
        function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}



contract MEO is Ownable, ERC20 {
    mapping(address => bool) public blacklists;
    mapping (address => bool) private excludedFromFee;
    address public marketing = 0xE6B60bF772887c422210c1a9e7A545dfA22EeCfB;
    address public WETH;
    uint256 public buyTax = 5;
    uint256 public sellTax = 5;
    uint256 public limitNumber;
    uint256 public swapNumber;
    bool public blimit = false;
    bool public swapEth = false;
    address public uniswapV2Pair;
    IRouter public _router;


    constructor() ERC20("MEO", "MEO") Ownable(msg.sender)  {
        uint256 totalSupply = 10000000000 * 10**18;
        _mint(msg.sender, totalSupply);

        _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        WETH = _router.WETH();

        limitNumber = totalSupply / 100;
        swapNumber = totalSupply / 300;

        ERC20(WETH).approve(address(_router), type(uint256).max);
        _approve(address(this), address(_router), type(uint256).max);
        _approve(owner(), address(_router), type(uint256).max);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if(from == owner() 
        || from == marketing
        || from == address(_router)
        || excludedFromFee[from]
        || excludedFromFee[to]
        || to == owner() 
        || to == marketing
        || to == address(_router)
        || from == address(this)
        || to == address(this)) {
            super._transfer(from, to, amount);
            return;
        }

        if(uniswapV2Pair ==  from || uniswapV2Pair ==  to) {
            if(blimit && uniswapV2Pair ==  from && address(_router) != to){
                require((amount + balanceOf(to)) < limitNumber, "limit");
            }
            uint256 tax = 0;
            if(uniswapV2Pair ==  from) {
                tax = buyTax;
            }else{
                tax = sellTax;
            }
            uint256 t = tax * amount / 100;
            super._transfer(from, marketing, t);
            super._transfer(from, to, amount - t);
            return;
        }
        super._transfer(from, to, amount);
    }

    bool private inSwap;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    function swapfee() private lockTheSwap {
        uint256 balance = balanceOf(address(this));
        if(balance > swapNumber) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WETH;
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(balance, 0, path, marketing, block.timestamp + 300);
        }
    }

    function setlimit(bool _limit, uint256 _limitNumber) external onlyOwner {
        blimit = _limit;
        limitNumber = _limitNumber;
    }

    function setBuyTax(uint256 _tax) external onlyOwner {
        buyTax = _tax;   
    }

    function setSellTax(uint256 _tax) external onlyOwner {
        sellTax = _tax;   
    }


    function setSwapEth(bool isSwapEth) public onlyOwner {
        swapEth = isSwapEth;
    }

    function setSwapNumber(uint256 _swapNumber)  external onlyOwner {
        swapNumber = _swapNumber;
    }

    function setExcludedFromFee(address _address, bool _excluded) external onlyOwner {
        excludedFromFee[_address] = _excluded;
    }

    function setExcludedFromFeeList(address[] calldata addresses, bool _excluded) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            excludedFromFee[addresses[i]] = _excluded;
        }
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setblacklist(address[] calldata addresses, bool _isBlacklisting) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            blacklists[addresses[i]] = _isBlacklisting;
        }
    }

    function multiTransfer(address[] calldata addresses, uint256[] calldata amounts) public {
        require(addresses.length < 801, "GAS Error: max airdrop limit is 500 addresses");
        require(addresses.length == amounts.length, "Mismatch between Address and token count");

        uint256 sum = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            sum = sum + amounts[i];
        }

        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");
        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    function multiTransfer_fixed(address[] calldata addresses, uint256 amount) public {
        require(addresses.length < 2001, "GAS Error: max airdrop limit is 2000 addresses");

        uint256 sum = amount * addresses.length;
        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amount);
        }
    }

    function errorToken(address _token) external onlyOwner {
        ERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
    
    function withdawOwner(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    receive () external payable  {
    }
}