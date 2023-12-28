pragma solidity ^0.4.18;

contract GST {
  function transfer(address _to, uint256 _value) public returns (bool);
  function mint(uint256 value) public;
}

contract Gastoken {
    function free(uint256 value) public returns (bool success);
    function freeUpTo(uint256 value) public returns (uint256 freed);
    function freeFrom(address from, uint256 value) public returns (bool success);
    function freeFromUpTo(address from, uint256 value) public returns (uint256 freed);
}

contract Example {
    
    
    
        // GST1
  /* address private gastoken = 0x88d60255F917e3eb94eaE199d827DAd837fac4cB; */
  // GST2
  address private gastoken = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
  uint256 amount = 250; // 2.5 GST2 per invocation, feel free to change
  address admin;

  function Proxy() {
    admin = msg.sender;
  }
  
  

    // This function consumes a lot of gas
    function expensiveStuff() {
        /* lots of expensive stuff */
        
    
    GST(gastoken).mint(amount);
    // transfer minted gastoken
    GST(gastoken).transfer(admin, amount);    
        
        
        
        
        
        
    }

    /*
     * Frees `free' tokens from the Gastoken at address `gas_token'.
     * The freed tokens belong to this Example contract. The gas refund can pay
     * for up to half of the gas cost of the total transaction in which this 
     * call occurs.
     */
    function burnGasAndFree(address gas_token, uint256 free) public {
        require(Gastoken(gas_token).free(free));
        expensiveStuff();
    }

    /*
     * Frees `free' tokens from the Gastoken at address `gas_token'.
     * The freed tokens belong to the sender. The sender must have previously 
     * allowed this Example contract to free up to `free' tokens on its behalf
     * (i.e., `allowance(msg.sender, this)' should be at least `free').
     * The gas refund can pay for up to half of the gas cost of the total 
     * transaction in which this call occurs.
     */
    function burnGasAndFreeFrom(address gas_token, uint256 free) public {
        require(Gastoken(gas_token).freeFrom(msg.sender, free));
        expensiveStuff();
    }
    
}