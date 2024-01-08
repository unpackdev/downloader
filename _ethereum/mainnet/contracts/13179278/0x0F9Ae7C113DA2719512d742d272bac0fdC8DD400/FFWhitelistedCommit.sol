// contracts/FFWhitelistedCommit.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";

/*
  ______              __                 _   
 |  ____|            / _|               | |  
 | |__ ___  _ __ ___| |_ _ __ ___  _ __ | |_ 
 |  __/ _ \| '__/ _ \  _| '__/ _ \| '_ \| __|
 | | | (_) | | |  __/ | | | | (_) | | | | |_ 
 |_|  \___/|_|  \___|_| |_|  \___/|_| |_|\__|
                                                                         
*/

/// @title Forefront News Community Whitelisted Commit
/// @notice A contract used to support the Forefront News Community Whitelisted Commitment,
/// allowing whitelisted users to commit USDC for escrowed Forefront tokens
/// @dev If using this contract, please be aware of the different decimals between USDC and FF
contract FFWhitelistedCommit is Ownable, Pausable {
  using SafeERC20 for IERC20;

  uint256 constant SALE_PERIOD = 2 days;

  uint256 public rateInUSDC;

  uint256 public totalUSDCAllocation;
  uint256 public totalUSDCCommitted;

  uint256 public uniqueContributions;

  uint256 public saleEndTimestamp;
  uint256 public saleStartTimestamp;

  IERC20 public USDCToken;

  mapping(address => WhitelistedAllocation) public allocations;
  mapping(uint256 => address) public contributionsByIndex;

  struct WhitelistedAllocation {
    uint256 allocatedUSDCAmount;
    uint256 contributedUSDCAmount;
  }

  event TokenCommitted(
    address indexed addr,
    uint256 ffAmount,
    uint256 usdcAmount
  );

  event TokensWithdrawn(address indexed tokenAddress, uint256 amount);

  event SaleStarted(uint256 started, uint256 ended);

  event WhitelistedAddressAdded(
    address indexed whitelistedAddress,
    uint256 allocationAmount
  );
  event WhitelistedAddressRemoved(address indexed whitelistedAddress);

  constructor(
    uint256 _rateInUSDC,
    address _usdcTokenAddress,
    uint256 _totalUSDCAllocation
  ) {
    rateInUSDC = _rateInUSDC;
    USDCToken = IERC20(_usdcTokenAddress);
    // the max cap is 200K FF, at a rate of 2 USDC, the max USDC cap is 400K USDC
    totalUSDCAllocation = _totalUSDCAllocation;
  }

  function commitUSDC(uint256 _usdcAmount)
    public
    whenNotPaused
    onlyWhitelisted
  {
    require(saleStartTimestamp < block.timestamp, "Sale is closed");
    require(saleEndTimestamp > block.timestamp, "Sale is closed");
    require(
      totalUSDCCommitted + _usdcAmount <= totalUSDCAllocation,
      "Sold Out: Commit cap reached"
    );
    require(
      allocations[msg.sender].contributedUSDCAmount + _usdcAmount <=
        allocations[msg.sender].allocatedUSDCAmount,
      "This address has insufficient allocation to fulfill this request"
    );

    /// @notice when the users contributions is 0 it means it is their first time contribution, we only want to count the unique-first time contributions
    if (allocations[msg.sender].contributedUSDCAmount == 0) {
      contributionsByIndex[uniqueContributions] = msg.sender;
      uniqueContributions++;
    }

    /// @notice we calculate the equivalent amount to emit in events so its easier to pass into an escrow contract
    uint256 totalFFAmount = (_usdcAmount * 1e24) / rateInUSDC / 1e6;

    allocations[msg.sender].contributedUSDCAmount += _usdcAmount;
    totalUSDCCommitted += _usdcAmount;

    USDCToken.safeTransferFrom(msg.sender, address(this), _usdcAmount);

    emit TokenCommitted(msg.sender, totalFFAmount, _usdcAmount);
  }

  function withdrawTokens(address _tokenAddress) public onlyOwner {
    IERC20 token = IERC20(_tokenAddress);
    uint256 tokenBalance = token.balanceOf(address(this));
    token.safeTransfer(msg.sender, tokenBalance);

    emit TokensWithdrawn(_tokenAddress, tokenBalance);
  }

  function openSale() public onlyOwner {
    saleStartTimestamp = block.timestamp;
    saleEndTimestamp = block.timestamp + SALE_PERIOD;

    emit SaleStarted(block.timestamp, block.timestamp + SALE_PERIOD);
  }

  function emergencyPause() public onlyOwner {
    _pause();
  }

  function emergencyUnpause() public onlyOwner {
    _unpause();
  }

  modifier onlyWhitelisted() {
    require(
      allocations[msg.sender].allocatedUSDCAmount > 0,
      "Wallet is not whitelisted"
    );
    _;
  }

  function addAddressToWhitelist(address _addr, uint256 _usdcAllocation)
    public
    onlyOwner
    returns (bool success)
  {
    allocations[_addr].allocatedUSDCAmount = _usdcAllocation;
    emit WhitelistedAddressAdded(_addr, _usdcAllocation);
    success = true;
  }

  function addAddressesToWhitelist(
    address[] memory _addrs,
    uint256 _usdcAllocation
  ) public onlyOwner returns (bool success) {
    for (uint256 i = 0; i < _addrs.length; i++) {
      if (addAddressToWhitelist(_addrs[i], _usdcAllocation)) {
        success = true;
      }
    }
  }

  function removeAddressFromWhitelist(address _addr)
    public
    onlyOwner
    returns (bool success)
  {
    allocations[_addr].allocatedUSDCAmount = 0;
    emit WhitelistedAddressRemoved(_addr);
    success = true;
  }

  function removeAddressesFromWhitelist(address[] memory _addrs)
    public
    onlyOwner
    returns (bool success)
  {
    for (uint256 i = 0; i < _addrs.length; i++) {
      if (removeAddressFromWhitelist(_addrs[i])) {
        success = true;
      }
    }
  }
}
