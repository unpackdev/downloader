pragma solidity ^0.6.6;

/**
 * @title Blockd Build Demo
 * 
 * @dev This is Blockd's demo contract for Blockd Build.
 *      In this contract we have multiple functions with big vulnerabilities
 *      that emulate big contract hacks that have happened in the past.
 * 
 *      If a user attempts to take advantage of these vulnerabilities,
 *      Blockd Build will race their transaction to blacklist them before
 *      their hack can execute.
 * 
 *      Blacklisting is used instead of a contract-wide pause or something less 
 *      centralized to make public testing less complicated. For the same reason,
 *      we pad the gas required for each function so as to not go broke when racing
 *      every person who attempts to hack the contract.
 * 
 *      Enjoy testing Blockd Build and good luck hacking this contract!
 * 
 *      P.S. This is not a honeypot! To attempt a hack, you need no Ether deposited.
 *      If you deposit Ether, you can withdraw that same amount just fine.
 * 
 * @author Robert M.C. Forster, Blockd L.L.C.
**/
contract BlockdBuildDemo {
    
    // Owner of the contract. For the purposes of this demo, despite making the contract
    // somewhat centralized, this address is allowed to blacklist users.
    address public owner;
    
    // Balances mapping. Users *should* never be able to withdraw more than is in here.
    mapping (address => uint256) public balances;
    
    // Ether price set by oracle. Doesn't have much of a purpose in this demo besides an example.
    uint256 public etherPrice;
    
    // Blacklist potential hackers on the contract. This centralizes things a bit and wouldn't
    // normally be suggested for Blockd Build, but a contract-wide pause would complicate testing.
    mapping (address => bool) public blacklist;
    
    // Arbitrary variable used to pad gas costs.
    uint256 private padVar;
    
    /**
     * @dev Set owner and Ether price..
    **/
    constructor()
      public
    {
        owner       = msg.sender;
        etherPrice  = 1;
    }
    
    /**
     * @dev Owner may transfer ownership of the contract.
     * @param _newOwner The new address that will have power over blacklisting.
     * @notice Uh-oh, this has no require! Anyone can call this successfully!
    **/
    function transferOwner( address _newOwner )
      public
      padGas
      notBLorSC
    {
        owner = _newOwner;
    }
    
    /**
     * @dev Callback may be used by Oracle to set new Ether price.
     *      API data is gotten from: "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD"
     *      Callback must equal USD value * 100
     * @param _etherPrice The new price of Ether (should always be 1).
     * @notice Uh-oh, this function does not check that sender is Oraclize!
    **/
    function callback( uint256 _etherPrice )
      public
      padGas
      notBLorSC
    {
        etherPrice = _etherPrice;
    }
    
    /**
     * @dev Allows users to withdraw funds from their balances.
     * @param _amount The amount of funds the user would like to withdraw.
     * @notice Uh-oh, this doesn't check to make sure the user has enough balance!
    **/
    function withdraw( uint256 _amount )
      public
      padGas
      notBLorSC
    {
        msg.sender.transfer( _amount );
        
        // Let's at least avoid underflows.
        uint256 balance = balances[msg.sender];
        if (balance - _amount < balance) balances[msg.sender] -= _amount;
    }
    
    /**
     * @dev Allows users to deposit funds into their balance.
     * @notice Not a vulnerable function. Simply exists to allow other vectors to be tested
     *         and to demonstrate that an allowed deposit/withdrawal will execute normally.
    **/
    function deposit()
      public
      payable
      padGas
      notBLorSC // Let's not let users deposit if they can't withdraw.
    {
        balances[ msg.sender ] += msg.value;    
    }
    
    /**
     * @dev Allows the owner to blacklist hackers from interacting with the contract.
     * @param _user The address to be blacklisted.
     * @param _blacklist True to blacklist user, false to take user off blacklist.
     * @notice This function is made to not be vulnerable by requiring the sender to be owner.
    **/
    function blacklistUser( address _user, bool _blacklist )
      public
    {
        require( msg.sender == owner );
        blacklist[ _user ]  = _blacklist;
    }
    
    /**
     * @dev Make sure the sender has not been blacklisted for attempting to hack this contract.
     *      Smart contracts are also blocked on this contract to simplify demo.
    **/
    modifier notBLorSC {
        require( !blacklist[ msg.sender ] );
        require( msg.sender == tx.origin );
        _;
    }
    
    /**
     * @dev For this demo contract, we're going to pad function gas costs because,
     *      with the amount of hacks we'll have to deal with, the low cost of these hacks,
     *      and the fact that we don't do a pause but continually just block single hackers,
     *      it would get very expensive for us to block everyone who would to race us.
     *      This should add 200,000 to the gas cost, ensuring a successful race would require
     *      around 10x the cost of a blacklist transaction.
    **/
    modifier padGas {
        for ( uint256 i = 1; i < 200; i++ ) {
            padVar = i;
        }
        _;
    }
    
}