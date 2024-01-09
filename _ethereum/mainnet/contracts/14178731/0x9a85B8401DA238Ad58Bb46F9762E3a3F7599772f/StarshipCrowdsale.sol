// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

import "./ITreasury.sol";
import "./IStaking.sol";
import "./IBondDepository.sol";
import "./Ownable.sol";

/**
 *  This contract allows Starship seed investors and advisors to claim tokens.
 *  step was taken to ensure fair distribution of exposure in the network.
 */
contract StarshipCrowdsale is Ownable {
    /* ========== DEPENDENCIES ========== */

    /* ========== EVENTS ========== */

    event StarMinted(address caller, uint256 amount, address reserve);
    event CrowdsaleInitialized(address caller, uint256 startTime);
    
    /* ========== STATE VARIABLES ========== */

    // our token
    IERC20 public immutable star;
    // receieves deposits, mints and returns STAR
    ITreasury internal immutable treasury;
  
    IBondDepository internal immutable depository;

    uint public constant MAX_TOKENS = 12500000 * 1e9;
    uint256 public tokensMinted;

    uint256 public startTime;
    bool public isActive;
    bool public isCompleted;
        
    uint256 public endTime;

    constructor( address _star, address _treasury, address _depository )
    {
      tokensMinted = 0;
      star = IERC20(_star);
      treasury = ITreasury(_treasury);
      depository = IBondDepository(_depository);
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    /**
     * @notice allows wallet to mint STAR via the feb crowdsale
     * @param _amount uint256
     * @param _reserve address
     */
    function MintStar(uint256 _amount, address _reserve) external {
        uint256 minted = _crowdsaleMint(_amount, _reserve);
    }

    /**
     * @notice logic for purchasing STAR
     * @param _amount uint256
     * @param _reserve address
     * @return toSend_ uint256
     */
    function _crowdsaleMint(uint256 _amount, address _reserve) internal returns (uint256 toSend_) {
        
        require(activeSale(), "crowdsale is inactive");
        
        toSend_ = treasury.deposit(msg.sender,_amount, _reserve, treasury.tokenValue(_reserve, _amount) * 75 / 100);
        require(validTransaction(toSend_), "minting too many tokens");
        tokensMinted += toSend_;
        depository.crowdsalePurchase(toSend_);
        
        emit StarMinted(msg.sender, _amount, _reserve);
    }
    
    function initialize() external onlyOwner {
      isActive = true;
      startTime = block.timestamp;
      endTime = block.timestamp + 3 days;
      emit CrowdsaleInitialized(msg.sender, startTime);
    }
    
    function completeSale() external onlyOwner {
      isActive = false;
      isCompleted = true;
    }
    
    function resetCrowdsale() external onlyOwner {
      isActive = false;
      isCompleted = false;
      startTime = 0;
      endTime = 0;
      tokensMinted = 0;
    }

    function activeSale() public returns (bool) { 
    
      bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
      
      return isActive && withinPeriod;
    }
    
    function validTransaction(uint256 toSend_) internal returns (bool) {
      
      bool validPurchase = tokensMinted + toSend_ <= MAX_TOKENS;
      //bool nonZeroPurchase = msg.value != 0;
      return validPurchase;
    }

    /* ========== VIEW FUNCTIONS ========== */

}
