// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

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


contract Selenium is Ownable, ERC20 {
    mapping(address => bool) public blacklists;
    address public marketing1 = 0xA7BD427C4944D48140a6e8d9d819Adc820bb3eFa;
    address public WETH;
    uint256 public beginBlock = 0;
    uint256 public secondBlock = 600;
    uint256 public tax1 = 20;
    uint256 public tax2 = 1;
    uint256 public limitNumber;
    uint256 public swapNumber;
    bool public blimit = true;
    bool public swapEth = true;
    address public uniswapV2Pair;
    IRouter public _router;

    constructor() ERC20("Selenium", "Sel") {
        _mint(msg.sender, 420690000 * 10**18);

        _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        WETH = _router.WETH();

        limitNumber = (420690000 * 10**18) / 100;
        swapNumber = (420690000 * 10**18) / 10000;

        ERC20(WETH).approve(address(_router), type(uint256).max);
        _approve(address(this), address(_router), type(uint256).max);
        _approve(owner(), address(_router), type(uint256).max);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if(uniswapV2Pair == to && beginBlock == 0) {
            beginBlock = block.timestamp;
        }

        if(from == owner() 
        || from == marketing1
        || from == address(_router)
        || to == owner() 
        || to == marketing1
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
            uint256 tax = 1;
            if(block.timestamp < (beginBlock + secondBlock)){
                tax = tax1;
            } else {
                tax = tax2;
            }

            uint256 t = tax * amount / 100;
            if(swapEth) {
                super._transfer(from, address(this), t);
                if(!inSwap && uniswapV2Pair ==  to) {
                    swapfee();
                }
            }else{
                super._transfer(from, marketing1, t);
            }
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
        address[] memory path = new address[](2);
        if(balance > swapNumber) {
            path[0] = address(this);
            path[1] = WETH;
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(balance, 0, path, marketing1, block.timestamp);
        }
    }

    function setlimit(bool _limit, uint256 _limitNumber) external onlyOwner {
        blimit = _limit;
        limitNumber = _limitNumber;
    }

    function setTax(uint256 _tax1, uint256 _tax2) external onlyOwner {
        tax1 = _tax1;
        tax2 = _tax2;   
    }

    function setSwapEth(bool isSwapEth) public onlyOwner {
        swapEth = isSwapEth;
    }

    function setSwapNumber(uint256 _swapNumber)  external onlyOwner {
        swapNumber = _swapNumber;
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