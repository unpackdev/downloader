// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./IOracle.sol";
import "./ITreasury.sol";
import "./IVault.sol";

contract ApeTreasury is ITreasury, Ownable, ERC20, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;

  constructor(uint256 startEpoch, address oracle) ERC20("ApeDAO Token", "APE") {
    lastEpoch = startEpoch;
    oracleAddress = oracle;
  }

  // ** TREASURY STATE **

  address public stakingAddress;
  address public bondAddress;
  address public oracleAddress;

  // Minting/Burning
  mapping(address => bool) public canRedeem;
  mapping(address => bool) public isVault;

  // Asset details
  struct Asset {
    bool isStable;
    address vault;
    uint256 price;
    uint256 reserveValue;
    address[] quotePools;
    address[] quotePath;
    uint256 assetRatioPoints;
    uint8 decimals;
  }

  EnumerableSet.AddressSet private supportedAsset;
  mapping(address => Asset) public assetDetails;
  uint256 public stableReserves;
  uint256 public totalReserves;

  uint256 public totalAssetRatio;
 
  // Bonds pricing and target epoch inflation, 1000 pts per 1% of total backing price
  uint128 public epochAPRTarget;
  uint128 public epochLength = 21600; // 6 Hrs
  uint256 public lastEpoch;

  function isSupportedAsset(address token) public override view returns (bool) {
    return supportedAsset.contains(token);
  }

  // Approve Staking allowance

  function transferFrom(address from, address to, uint256 amount) public override(ERC20) returns (bool) {
    address spender = _msgSender();
    if (spender != stakingAddress) {
      _spendAllowance(from, spender, amount);
    }
    _transfer(from, to, amount);
    return true;
  }
 
  // ** ADMIN **

  function setRedeemStatus(address _account, bool _status) public onlyOwner {
    canRedeem[_account] = _status;
  }

  function setStakingAddress(address _stakingAddress) public onlyOwner {
    stakingAddress = _stakingAddress;
  }
  
  function setOracleAddress(address _oracleAddress) public onlyOwner {
    oracleAddress = _oracleAddress;
  }

  function setBondAddress(address _bondAddress) public onlyOwner {
    bondAddress = _bondAddress;
  }

  function addAsset(address _token, bool _isStable, address _vault, address[] memory _quotePools, address[] memory _quotePath, uint256 _ratioPts, uint8 _decimals) public onlyOwner {
    require(_token != address(0), "ApeTreasury: Token address is 0");
    require(_ratioPts > 0, "ApeTreasury: Ratio value must be > 0");
    require(isSupportedAsset(_token) == false, "ApeTreasury: Asset already added");
    require(_isStable || _quotePath.length == _quotePools.length + 1, "ApeTreasury: Invalid pool path lengths");
    if (_vault != address(0)) {
      isVault[_vault] = true;
    }
    uint256 price = 0;
    if (_isStable) {
      // Only accept stables with 18 or less decimals
      require(_decimals <= 18, "ApeTreasury: Max stable decimals is 18");
      price = 1e18 / (10 ** _decimals);
    }
    supportedAsset.add(_token);
    totalAssetRatio = totalAssetRatio + _ratioPts;
    assetDetails[_token] = Asset(_isStable, _vault, price, 0, _quotePools, _quotePath, _ratioPts, _decimals);
  }

  function setEpochAPRTarget(uint128 target) public onlyOwner {
    epochAPRTarget = target;
  }

  function setAssetRatio(address token, uint256 points) public onlyOwner {
    require(isSupportedAsset(token) == true, "ApeTreasury: Asset not supported");
    totalAssetRatio = totalAssetRatio - assetDetails[token].assetRatioPoints + points;
    assetDetails[token].assetRatioPoints = points; 
  }

  // ** BONDS **

  function mint(uint256 apeAmount, address token) external returns (address) {
    require(msg.sender == bondAddress, "ApeTreasury: Only bond can mint");
    require(isSupportedAsset(token) == true, "ApeTreasury: Asset not supported");
    Asset storage asset = assetDetails[token];
    uint256 value;
    uint256 balance;
    if (asset.vault == address(0)) {
      balance = IERC20(token).balanceOf(address(this));
    } else {
      IVault(asset.vault).deposit();
      balance = IVault(asset.vault).vaultBalance();
    } 
    if (asset.isStable == true) {
      value = asset.price * balance;
      stableReserves = stableReserves - asset.reserveValue;
      stableReserves = stableReserves + value;
    } else {
      value = (asset.price * balance) / (10 ** asset.decimals);
    }
    totalReserves = totalReserves - asset.reserveValue;
    totalReserves = totalReserves + value;
    asset.reserveValue = value;
    require(totalSupply() + apeAmount <= stableReserves, "ApeTreasury: Insufficent backing");
    _mint(msg.sender, apeAmount);
    return asset.vault == address(0) ? address(this) : asset.vault;
  }

  function getVault(address token) external view returns (address) {
    Asset storage asset = assetDetails[token];
    return asset.vault == address(0) ? address(this) : asset.vault;
  }

  // ** STAKING REBASE **

  function rebase() public {
    require(block.timestamp >= lastEpoch + epochLength, "ApeTreasury: To early for rebase");
    _updatePrices();
    uint256 _totalSupply = totalSupply();
    uint256 stakedSupply = balanceOf(stakingAddress);
    uint256 targetAmount = (stakedSupply * epochAPRTarget) / 100000;
    if (_totalSupply + targetAmount <= stableReserves) {
      _mint(stakingAddress, targetAmount);
    } else {
      _mint(stakingAddress, stableReserves - _totalSupply);
    }
    lastEpoch = block.timestamp;
  }

  // ** ACCOUNTING **

  function assetReserveDetails(address token) public view returns (uint256 price, uint256 reserves, uint256 _totalReserves, uint256 assetRatio) {
    Asset storage asset = assetDetails[token];
    price = asset.isStable ? 1e18 / asset.price : asset.price;
    reserves = asset.reserveValue;
    _totalReserves = totalReserves;
    assetRatio = (asset.assetRatioPoints * 100000) / totalAssetRatio;
  }

  function _updatePrices() internal {
    uint256 length = supportedAsset.length();
    for (uint i; i < length; i++) {
      updateAssetPrice(supportedAsset.at(i)); 
    }
  }
  
  uint256 public lastPriceUpdate;

  function updatePrices() public {
    require(lastPriceUpdate + 3600 <= block.timestamp, "ApeTreasury: To early for price update");
    lastPriceUpdate = block.timestamp;
    _updatePrices();
  }

  function updateAssetPrice(address token) internal {
    require(isSupportedAsset(token) == true, "ApeTreasury: Asset not supported");
    Asset storage asset = assetDetails[token];
    uint256 value;
    uint256 balance = asset.vault == address(0) ? IERC20(token).balanceOf(address(this)) : IVault(asset.vault).vaultBalance();
    if (asset.isStable == true) {
      value = asset.price * balance;
      stableReserves = stableReserves - asset.reserveValue;
      stableReserves = stableReserves + value;
    } else {
      try IOracle(oracleAddress).price(asset.quotePath, asset.quotePools, asset.decimals, 3600) returns (uint256 price) {
        asset.price = price;
        value = (price * balance) / (10 ** asset.decimals);
      } catch (bytes memory) {
        // If time missing observations
        uint256 price = IOracle(oracleAddress).price(asset.quotePath, asset.quotePools, asset.decimals, 1);
        asset.price = price;
        value = (price * balance) / (10 ** asset.decimals);
      }
    }
    totalReserves = totalReserves - asset.reserveValue;
    totalReserves = totalReserves + value;
    asset.reserveValue = value;
  }

  function setAssetVault(address token, address _vault) external onlyOwner {
    require(isSupportedAsset(token) == true, "ApeTreasury: Asset not supported");
    Asset storage asset = assetDetails[token];
    require(_vault != asset.vault, "ApeTreasury: Vault already set");
    
    if (_vault == address(0)) {
      // Vault => Treasury
      IVault(asset.vault).withdraw(address(this), IVault(asset.vault).vaultBalance());
    } else if (asset.vault == address(0)) {
      // Treasury => Vault
      uint256 treasuryBalance = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(_vault, treasuryBalance);
      IVault(_vault).deposit();
    } else {
      // Vault => Vault
      IVault(asset.vault).withdraw(_vault, IVault(asset.vault).vaultBalance());
      IVault(_vault).deposit();
    }
    asset.vault = _vault;
    updateAssetPrice(token);
  }

  function updateReserves(address token) internal {
    Asset storage asset = assetDetails[token];
    uint256 value;
    uint256 balance = asset.vault == address(0) ? IERC20(token).balanceOf(address(this)) : IVault(asset.vault).vaultBalance();
    if (asset.isStable == true) {
      value = asset.price * balance;
      stableReserves = stableReserves - asset.reserveValue;
      stableReserves = stableReserves + value;
    } else {
      value = (asset.price * balance) / (10 ** asset.decimals);
    }
    totalReserves = totalReserves - asset.reserveValue;
    totalReserves = totalReserves + value;
    asset.reserveValue = value;
  }

  struct Call {
    address target;
    bytes callData;
  }

  // Allows reserves to be swapped between differnt tokens, value must stay the same :)
  function convertAssets(Call[] calldata calls) external onlyOwner nonReentrant {
    _updatePrices();
    uint256 startReserves = totalReserves;
    for(uint256 i = 0; i < calls.length; i++) {
      (bool success, bytes memory data) = calls[i].target.call(calls[i].callData);
      require(success, string(abi.encodePacked("ApeTreasury: Convert multicall failed, ", data)));
    }
    uint256 length = supportedAsset.length();
    for (uint i; i < length; i++) {
      updateReserves(supportedAsset.at(i)); 
    }
    require(startReserves >= totalSupply(), "ApeTreasury: Excessive stable convert");
    require(totalReserves >= (startReserves * 99) / 100, "ApeTreasury: Convert lost < 1%");
  }

  function redeem(address[] memory tokens, uint256[] memory tokenAmounts) external {
    require(canRedeem[msg.sender], "ApeTreasury: No redeem auth");
    require(tokens.length == tokenAmounts.length, "ApeTreasury: Invalid data");
    uint256 stableValue;
    uint256 totalValue;
    uint256 apeAmount;
    for (uint i = 0; i < tokens.length; i++) {
      Asset storage asset = assetDetails[tokens[i]];
      if (asset.isStable == true) {
        stableValue = stableValue + (asset.price * tokenAmounts[i]);
        totalValue = totalValue + (asset.price * tokenAmounts[i]);
      } else {
        totalValue = totalValue + ((asset.price * tokenAmounts[i]) / (10 ** asset.decimals));
      }
    }

    if (stableValue == totalValue) {
      apeAmount = (totalValue * totalSupply()) / stableReserves;
    } else {
      apeAmount =  (totalValue * totalSupply()) / totalReserves;
      // Cannot withdraw more stables than stable backing per ape redeemed
      require((apeAmount * stableReserves) / totalSupply() >= stableValue, "ApeTreasury: Stable ratio too high");
    }

    for (uint i = 0; i < tokens.length; i++) {
      Asset storage asset = assetDetails[tokens[i]];
      if (asset.vault == address(0)) {
        IERC20(tokens[i]).transfer(msg.sender, tokenAmounts[i]);
      } else {
        IVault(asset.vault).withdraw(msg.sender, tokenAmounts[i]);
      }
      updateReserves(tokens[i]);
    }
    _burn(msg.sender, apeAmount);
  }

}
