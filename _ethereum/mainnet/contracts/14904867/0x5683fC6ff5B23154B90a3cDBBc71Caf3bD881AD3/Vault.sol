// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";


contract Vault is  ERC20, ReentrancyGuard {

    using SafeERC20 for IERC20;
    
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Vault: access restricted to owner");
        _;
    }

    event OwnerChanged(address indexed newOwner, address indexed oldOwner);

    address public manager;

    modifier onlyManager() {
        require(msg.sender == manager, "Vault: access restricted to manager");
        _;
    }

    event ManagerChanged(address indexed newManager, address indexed oldManager);


    address public underlying;
    
    event DividendsPayed(address indexed recipient, address indexed token, uint256 indexed amount);

    uint256 public sharePrice;
    
    event SharePriceChanged(uint256 indexed newPrice, uint256 indexed oldPrice);

    

    constructor(string memory _name, string memory _symbol, address _underlying) ERC20(_name, _symbol) {
        manager = msg.sender;
        owner = msg.sender;
        underlying = _underlying;
        sharePrice = 1e18;
    }


    function mint(uint256 amountUnderlying) onlyOwner nonReentrant public {
        uint256 mintAmount = amountUnderlying * 1e18 / sharePrice;

        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amountUnderlying);
        IERC20(underlying).safeTransfer(manager, amountUnderlying);
        _mint(msg.sender, mintAmount);
    }

    function burn(uint256 amountShares) onlyOwner nonReentrant public {
        uint256 amountUnderlying = amountShares * sharePrice / 1e18;
        require(amountShares <= balanceOf(msg.sender), "Vault: insufficient shares");
        require(IERC20(underlying).balanceOf(address(this)) >= amountUnderlying, "Vault: insufficient underlying");
        _burn(msg.sender, amountShares);
        IERC20(underlying).safeTransfer(msg.sender, amountUnderlying);
    }

    function payDividends(address token, uint256 amount) onlyManager public {
        uint256 tokenBalance = IERC20(token).balanceOf(manager);
        require(amount <= tokenBalance, "Vault: insufficient manager funds");
        IERC20(token).safeTransferFrom(manager, address(this), amount);
        IERC20(token).safeTransfer(owner, amount);
        emit DividendsPayed(owner, token, amount);
    }

    function setSharePrice(uint256 newPrice) onlyManager nonReentrant public {
        require(newPrice > 0, "Vault: share price cannot be zero");
        // The next line provokes an overflow error in solc > 0.8.x, which is intended.
        require(totalSupply() * newPrice / 1e18 >= 0, "Vault: total market cap too high");
        emit SharePriceChanged(newPrice, sharePrice);
        sharePrice = newPrice;
    }

    function setManager(address newManager) onlyManager public {
        emit ManagerChanged(newManager, manager);
        manager = newManager;
    }

    function setOwner(address newOwner) onlyManager public {
        emit OwnerChanged(newOwner, owner);
        owner = newOwner;
    }

    
}