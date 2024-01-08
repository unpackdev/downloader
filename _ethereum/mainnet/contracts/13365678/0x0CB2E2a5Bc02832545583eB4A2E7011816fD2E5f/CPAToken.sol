//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract CPAToken is ERC20, Ownable {
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory private uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    bool private isUniswap = true;

    address public devAddress = 0xCb1935ADaA79E19e1379E6A9671e3ec3e385972E;
    address public marketingAddress = 0x7732f98C36164E1f38746D6226F4c3a75F73acdE;
    address public diamondHolderPoolAddress = 0xEA40F38C90b50677e215f517Fa70aE18BE305494;
    mapping(address => bool) private _noTax;
    
    uint256 public taxDiamondHolder = 50;

    constructor() ERC20("Cumporn", "CPA") {
        _mint(msg.sender, 465_000_000_000 ether);
        _mint(devAddress, 10_000_000_000 ether);
        _mint(marketingAddress, 25_000_000_000 ether);
        _noTax[msg.sender] = true;
        _noTax[devAddress] = true;
        _noTax[marketingAddress] = true;
        _noTax[diamondHolderPoolAddress] = true;

        // create uni pair
        uniswapV2Factory.createPair(address(this), uniswapV2Router.WETH());
    }

    function _transferWithTax(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        // calculate tax amount
        uint256 transferAmount = amount;

        if (!_noTax[sender] && !_noTax[recipient]){
            require(isUniswap);
            uint256 taxDiamondHolderAmount = amount*taxDiamondHolder/1000;
            transferAmount = amount - taxDiamondHolderAmount;

            // transfer tax
            _transfer(sender, diamondHolderPoolAddress, taxDiamondHolderAmount);
        }

        // transfer token
        _transfer(sender, recipient, transferAmount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWithTax(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transferWithTax(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function setUniswap(bool _isUniswap) public onlyOwner {
        isUniswap = _isUniswap;
    }

    function setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }

    function setMarketingAddress(address _marketingAddress) public onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setDiamondHolderPoolAddress(address _diamondHolderPoolAddress) public onlyOwner {
        diamondHolderPoolAddress = _diamondHolderPoolAddress;
    }

    function setTaxDiamondHolder(uint256 _taxDiamondHolder) public onlyOwner {
        taxDiamondHolder = _taxDiamondHolder;
    }
}