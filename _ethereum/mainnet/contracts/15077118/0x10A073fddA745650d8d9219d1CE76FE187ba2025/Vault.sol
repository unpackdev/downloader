// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";

contract Vault is  ERC20, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    bool public constant isVault = true;

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
    event Harvest(address indexed owner, address indexed token, uint256 indexed amount);
    event Mint(address indexed owner, uint256 mintedShares, uint256 amountUnderlying, uint256 sharePrice);
    event Burn(address indexed owner, uint256 burnedShares, uint256 amountUnderlying, uint256 sharePrice);
    event Deposit(address indexed manager, address indexed token, uint256 indexed amount);
    event Withdraw(address indexed manager, address indexed token, uint256 indexed amount);
    
    uint256 public sharePrice;
    event SharePriceChanged(uint256 indexed newPrice, uint256 indexed oldPrice);

    EnumerableSet.AddressSet private assetSet;
    
    constructor(string memory _name, string memory _symbol, address _underlying, address _owner) ERC20(_name, _symbol) {
        require(_owner != msg.sender, "Vault: manager cannot be owner");
        require(_underlying != address(0x0), "Vault: underlying cannot be 0x0");
        manager = msg.sender;
        owner = _owner;
        underlying = _underlying;
        sharePrice = 1e18;
        assetSet.add(_underlying);
        emit OwnerChanged(address(0x0), owner);
        emit ManagerChanged(address(0x0), manager);
        emit SharePriceChanged(0, sharePrice);
    }

    function mint(uint256 amountUnderlying) onlyOwner nonReentrant public {
        uint256 mintAmount = amountUnderlying * 1e18 / sharePrice;
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amountUnderlying);
        _mint(msg.sender, mintAmount);
        emit Mint(owner, mintAmount, amountUnderlying, sharePrice);
    }

    function burn(uint256 amountShares) onlyOwner nonReentrant public {
        uint256 amountUnderlying = amountShares * sharePrice / 1e18;
        require(amountShares <= balanceOf(msg.sender), "Vault: insufficient shares");
        require(IERC20(underlying).balanceOf(address(this)) >= amountUnderlying, "Vault: insufficient underlying");
        _burn(msg.sender, amountShares);
        IERC20(underlying).safeTransfer(msg.sender, amountUnderlying);
        emit Burn(owner, amountShares, amountUnderlying, sharePrice);
    }

    function harvest(address token, uint256 amount) onlyOwner nonReentrant public {
        if (token == address(0x0)) payable(owner).transfer(amount); 
            else IERC20(token).safeTransfer(owner, amount);
        emit Harvest(owner, token, amount);
    }

    function harvestETH(uint256 amount) onlyOwner nonReentrant public {
        payable(owner).transfer(amount); 
        emit Harvest(owner, address(0x0), amount);
    }

    function withdraw(address token, uint256 amount) onlyManager nonReentrant public {
        require(token != address(0x0), "Vault: cannot withdraw from invalid token address 0x0.");
        IERC20(token).safeTransfer(manager, amount);
        emit Withdraw(manager, token, amount);
    }

    function withdrawETH(uint256 amount) onlyManager nonReentrant public {
        payable(manager).transfer(amount); 
        emit Withdraw(manager, address(0x0), amount);
    }

    function deposit(address token, uint256 amount) onlyManager nonReentrant public {
        IERC20(token).safeTransferFrom(manager, address(this), amount);
        assetSet.add(token);
        emit Deposit(manager, token, amount);
    }

    function addAsset(address token) onlyManager public {
        require(token != address(this), "Vault: vault token cannot be in asset set.");
        assetSet.add(token);
    }

    function removeAsset(address token) onlyManager public {
        require(token != underlying, "Vault: underlying cannot be removed from asset set.");
        assetSet.remove(token);
    }

    function assets() public view returns (address[] memory) {
        return assetSet.values();
    }

    function setSharePrice(uint256 newPrice) onlyManager nonReentrant public {
        require(newPrice > 0, "Vault: share price cannot be zero");
        // The next line provokes an overflow error in solc > 0.8.x, which is intended.
        require(totalSupply() * newPrice / 1e18 >= 0, "Vault: total market cap too high");
        emit SharePriceChanged(newPrice, sharePrice);
        sharePrice = newPrice;
    }

    function setManager(address newManager) onlyManager public {
        require(newManager != owner, "Vault: manager cannot be owner");
        emit ManagerChanged(newManager, manager);
        manager = newManager;
    }

    function setOwner(address newOwner) onlyManager public {
        require(newOwner != manager, "Vault: manager cannot be owner");
        emit OwnerChanged(newOwner, owner);
        owner = newOwner;
    }

    function vaultId() public view returns (bytes32) {
        return sha256(abi.encode(name(), symbol(), underlying));
    }

    receive() onlyManager external payable {
        emit Deposit(manager, address(0x0), msg.value);
    }
    
}