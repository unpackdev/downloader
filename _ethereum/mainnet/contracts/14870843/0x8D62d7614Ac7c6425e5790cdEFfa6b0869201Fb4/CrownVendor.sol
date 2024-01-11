pragma solidity 0.8.14;
// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

/// @title Crown Capital Token Vendor
/// @author sters.eth
/// @notice Contract will emit Crown for USDC
contract CrownVendor is Ownable, ReentrancyGuard { 

    string public constant name = "Crown Capital Vendor";

    // @dev Token Contracts
    IERC20 public _crownToken;
    IERC20 public _usdcToken;
    
    // @dev the conversion rate of USDC to Crown
    uint256 public USDCPerCrown;

    // @dev boolean to turn whitelist requirement on and off
    bool public whitelist;

    // @dev whitelist addresses
    address[] public wlAddresses;

    // Initialize events
    event PayUSDC(address sender, uint256 amount);
    event BoughtCrown(address receiver, uint256 amount);
    event WithdrawCrown(address owner, uint256 vendorBalance);
    event WithdrawUSDC(address owner, uint256 vendorBalance);
    event WhitelistStatusUpdated(address _from, bool status);
    event AddedWlAddress(address _from, address userAddress);
    event RemovedWlAddress(address _from, address userAddress);
    event ResetWhitelist(address _from);


    constructor(IERC20 crownAddress, IERC20 usdcAddress) {
        _crownToken = crownAddress;
        _usdcToken = usdcAddress;
        USDCPerCrown = 200000;
        whitelist=false;
    }


    /**
    * @notice Set the USDC to Crown rate with 6 digit accuracy (e.g. $0.20 CROWN/USDC = 200000)
    */
    function setUSDCPerCrown(uint256 rate) external onlyOwner {
       USDCPerCrown = rate;
    }


    /** @dev set whitelist to true or false.
    */  
    function setWhitelist(bool status) external onlyOwner {
        whitelist = status;
        emit WhitelistStatusUpdated(msg.sender, status);
    }


    /** @dev Owner may add addresses to whitelist.
    * @param userAddress address of user with whitelist access.
    */  
    function addToWhitelist(address userAddress) external onlyOwner {
        require(userAddress != address(0), 'address can not be zero address');
        wlAddresses.push(userAddress);
        emit AddedWlAddress(msg.sender, userAddress);
    }


    /// @dev deletes an address from the whitelist if found in whitelist
    function removeAddressFromWl(address userAddress) external onlyOwner {
        for (
            uint256 wlIndex = 0;
            wlIndex < wlAddresses.length;
            wlIndex++
        ) {
            if(userAddress == wlAddresses[wlIndex]){
                if(wlAddresses.length == 1){
                    resetWhitelist();
                }                    
                else {
                    wlAddresses[wlIndex] = wlAddresses[wlAddresses.length - 1];
                    wlAddresses.pop(); // Remove the last element
                    emit RemovedWlAddress(msg.sender, userAddress);
                }
            }
        }
    }


  /// @dev deletes all entries from whitelist
  function resetWhitelist() public onlyOwner {
      delete wlAddresses;
      emit ResetWhitelist(msg.sender);
  }


    /**
    * @notice Allow users to buy crown for USDC by specifying the number of Crown tokens desired. 
    */
    function buyCrown(uint256 crownTokens) external nonReentrant {
        // Check that the requested amount of tokens to sell is more than 0
        require(crownTokens > 0, "Specify an amount of Crown greater than zero");

        // Check that the Vendor's balance is enough to do the swap
        uint256 vendorBalance = _crownToken.balanceOf(address(this));
        require(vendorBalance >= crownTokens, "Vendor contract does not have a suffcient Crown balance.");
        
        // Check if whitelist is active
        if(whitelist){
            bool userOnWhitelist = false;
            for (
                uint256 wlIndex = 0;
                wlIndex < wlAddresses.length;
                wlIndex++
            ) {
                if(msg.sender == wlAddresses[wlIndex]){
                    userOnWhitelist = true;
                }
            }
            require(userOnWhitelist, "User not found on whitelist");
        }

        // Calculate USDC needed
        uint256 usdcToSpend = crownToUSDC(crownTokens);

        // Check that the user's USDC balance is enough to do the swap
        address sender = msg.sender;
        uint256 userBalance = _usdcToken.balanceOf(sender);
        require(userBalance >= usdcToSpend, "You do not have enough USDC.");

        // Check that user has approved the contract
        uint256 contractAllowance = _usdcToken.allowance(sender, address(this));
        require(contractAllowance >= usdcToSpend, "Must approve this contract to spend more USDC.");

        // Transfer USDC from user to contract
        (bool recieved) = _usdcToken.transferFrom(sender, address(this), usdcToSpend);
        require(recieved, "Failed to transfer USDC from vendor to user");
        emit PayUSDC(sender, usdcToSpend);

        // Send Crown to Purchaser
        (bool sent) = _crownToken.transfer(sender, crownTokens);
        require(sent, "Failed to transfer Crown from  to vendor");
        emit BoughtCrown(sender, crownTokens);
    }


    /**
    * @notice Allow the owner of the contract to withdraw all $USDC
    */
    function withdrawUSDC() external onlyOwner {
      uint256 vendorBalance = _usdcToken.balanceOf(address(this));
      require(vendorBalance > 0, "Nothing to Withdraw");
      (bool sent) = _usdcToken.transfer(msg.sender, vendorBalance);
      require(sent, "Failed to transfer tokens from user to Farm");

      emit WithdrawUSDC(msg.sender, vendorBalance);
    }


    /**
    * @notice Allow the owner of the contract to withdraw all $CROWN
    */
    function withdrawCrown() external onlyOwner {
      uint256 vendorBalance = _crownToken.balanceOf(address(this));
      require(vendorBalance > 0, "Nothing to Withdraw");
      (bool sent) = _crownToken.transfer(msg.sender, vendorBalance);
      require(sent, "Failed to transfer tokens from user to Farm");

      emit WithdrawCrown(msg.sender, vendorBalance);
    }


    /**
    * @notice Helper function: Convert Crown tokens to USDC 
    */
    function crownToUSDC(uint256 crownTokens) public view returns (uint256 usdc) {
      usdc = (crownTokens * USDCPerCrown)/10**18;
      return usdc;
    }


    /**
    * @notice Helper function: Convert USDC tokens to Crown
    */
    function usdcToCrown(uint256 USDC) external view returns (uint256 crownTokens) {
      crownTokens = (USDC / USDCPerCrown) * 10**18;
      return crownTokens;
    }
}
