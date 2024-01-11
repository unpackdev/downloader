// SPDX-License-Identifier: MIT

// Solidity version
pragma solidity 0.8.13;

// Imports
import "./Ownable.sol";  // Access control mechanism
import "./Pausable.sol";  // Emergency stop mechanism
import "./IERC20.sol";  // Interface of the ERC20 standard
import "./ReentrancyGuard.sol";  // Mechanism to prevent reentrancy

/**
 * @title The following smart contract facilities the claiming of WGMI2 tokens by spending the WGMI tokens.
 */
contract ClaimWGMI2 is Ownable, Pausable, ReentrancyGuard {
  /// The address of the version 1 of the WGMI token
  address public wgmiV1;
  /// The address of the version 2 of the WGMI token
  address public wgmiV2;
  /// The WGMI v1 to WGMI v2 exchange rate
  uint256 public exchangeRate = 75;
  /// The exchange rate denominator
  /// Ex.: If the exchangeRate = 75 and denominator = 1e5 (100000) then the WGMI v1 to WGMI v2
  /// conversion rate is 0.00075 (75 / 100000), meaning that 1 WGMI v1 token = 0.00075 WGMI v2 token.
  uint256 public denominator = 1e5;

  event ClaimToken(address indexed user, uint256 amountDeposited, uint256 amountToClaim, uint256 indexed timestamp);
  event WithdrawRemaining(uint256 amount, uint256 timestamp);


  /**
   * @notice The smart contract constructor that initializes the contract.
   * @param _wgmiV1 The address of the version 1 of the WGMI token
   * @param _wgmiV2 The address of the version 2 of the WGMI token
   */
  constructor(address _wgmiV1, address _wgmiV2) {
    // Setting the values
    wgmiV1 = _wgmiV1;
    wgmiV2 = _wgmiV2;
  }

  /**
   * @notice Sets the exchange rate.
   * @param _exchangeRate The WGMI v1 to WGMI v2 exchange rate
   * @param _denominator The exchange rate denominator
   */
  function setExchangeRate(uint256 _exchangeRate, uint256 _denominator) external onlyOwner {
    exchangeRate = _exchangeRate;
    denominator = _denominator;
  }

  /**
   * @notice Pauses the token conversion operations.
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Resumes the token conversion operations.
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Exchanges WGMI v1 tokens to WGMI v2 tokens.
   * @dev Requires the smart contract not to be paused. Reentrant calls to the function are forbidden.
   */
  function claim() external whenNotPaused nonReentrant {
    uint256 amountDeposited = IERC20(wgmiV1).balanceOf(msg.sender);
    require(amountDeposited > 0, "INVALID_CLAIM_AMOUNT");

    uint256 amountToClaim = (amountDeposited * exchangeRate) / denominator;

    require(IERC20(wgmiV2).balanceOf(address(this)) >= amountToClaim, "EXCEEDS_CONVERTER_BALANCE");
    require(IERC20(wgmiV1).transferFrom(msg.sender, address(this), amountDeposited), "TRANSFER_TOKEN_FAILED");
    require(IERC20(wgmiV2).transfer(msg.sender, amountToClaim), "CLAIM_WGMI2_FAILED");

    emit ClaimToken(msg.sender, amountDeposited, amountToClaim, block.timestamp);
  }

  /**
   * @notice Withdraws ETH from the contract
   * @dev Allows the contract owner to withdraw ETH from the contract.
   */
  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  /**
   * @notice Withdraws unclaimed WGMI v2 tokens to the owner's wallet.
   * @dev Allows the contract owner to withdraw the WGMI v2 tokens that were converted by the users but not claimed.
   */
  function withdrawErc20(IERC20 _token) public onlyOwner {
      _token.transfer(msg.sender, _token.balanceOf(address(this)));
  }
}
