pragma solidity ^0.8.0;



/*

 Club SOS

 DAO for community-based marketing
 
 Stake SOS in this contract in exchange for shares in the club.  This allows applications to easily donate their revenue in terms of SOS to all participants as a marketing strategy.
 
 Unstake your original SOS at any time and you will always recieve what you originally staked plus any donation proceeds.

*/
                                                                                 
  
 
 


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

   

interface MintableERC20  {
     function mint(address account, uint256 amount) external ;
     function burn(address account, uint256 amount) external ;
}

 
 
  
  
  
/**
 * 
 * 
 *  Staking contract that supports community-extractable donations 
 *
 */
contract ClubSOS
{
  
  address public _stakeableCurrency; 
  address public _reservePoolToken; 
  uint256 immutable multiplierFactor = 1000000 ether;
   
    
  constructor(  address stakeableCurrency, address reservePoolToken  ) 
  {     
   _stakeableCurrency = stakeableCurrency;
   _reservePoolToken = reservePoolToken;
  } 
 
  
  function stakeCurrency( address from,  uint256 currencyAmount ) public returns (bool){
       
      uint256 reserveTokensMinted = _reserveTokensMinted(  currencyAmount) ;
     
      require( IERC20(_stakeableCurrency).transferFrom(from, address(this), currencyAmount ), 'transfer failed'  );
          
      MintableERC20(_reservePoolToken).mint(from, reserveTokensMinted) ;
      
     return true; 
  }
  
   
  function unstakeCurrency( uint256 reserveTokenAmount, address currencyToClaim) public returns (bool){
             
      uint256 vaultOutputAmount =  _vaultOutputAmount( reserveTokenAmount, currencyToClaim );
            
      MintableERC20(_reservePoolToken).burn(msg.sender,  reserveTokenAmount ); 
             
      IERC20(currencyToClaim).transfer( msg.sender, vaultOutputAmount );
       
     return true; 
  }
  

    //amount of reserve_tokens to give to staker 
  function _reserveTokensMinted(  uint256 currencyAmount ) public view returns (uint){

      uint256 totalReserveTokens = IERC20(_reservePoolToken).totalSupply();

      uint256 internalVaultBalance =  IERC20(_stakeableCurrency).balanceOf(address(this));       
     
      if(totalReserveTokens == 0 || internalVaultBalance == 0 ){
        return currencyAmount;
      }
            
      uint256 incomingTokenRatio = (currencyAmount*multiplierFactor) / internalVaultBalance;
              
      return ( ( totalReserveTokens) * incomingTokenRatio) / multiplierFactor;
  }
  
  
    //amount of output tokens to give to redeemer
  function _vaultOutputAmount( uint256 reserveTokenAmount, address currencyToClaim ) public view returns (uint){

      uint256 internalVaultBalance = IERC20(currencyToClaim ).balanceOf(address(this));      

      uint256 totalReserveTokens = IERC20(_reservePoolToken).totalSupply(); 
       
      uint256 burnedTokenRatio = (reserveTokenAmount*multiplierFactor) / totalReserveTokens;      
       
      return (internalVaultBalance * burnedTokenRatio) / multiplierFactor;
  }

 
  
   
     // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------
 
    fallback() external payable { revert(); }
    receive() external payable { revert(); }
   

}