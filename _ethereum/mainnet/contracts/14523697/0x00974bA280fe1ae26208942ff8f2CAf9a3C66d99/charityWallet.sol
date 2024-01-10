// SPDX-License-Identifier: MIT
/**
 * @title obscurityDAO
 * @email obscuirtyceo@gmail.com
 * @dev Nov 3, 2020
 * ERC-20 
 * obscurityDAO Copyright and Disclaimer Notice:
 */


pragma solidity ^0.8.7 <0.9.0;


import "./ERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./founders.sol";

contract charityWallet is  ERC20Upgradeable, FounderWallets, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    event DepositFunds(address indexed sender, uint amount, uint balance);
    event TransferSuccessful(address indexed from_, address indexed to_, uint256 amount_);   
    event TransferFailed(address indexed from_, address indexed to_, uint256 amount_);
    
    ERC20Upgradeable public ERC20Interface;
    mapping(address => bytes32[]) usedMessages;
    mapping(bytes32 => address) public tokens; 
    address payable private _wallet;
    uint256 private _multiSigInitialized; 

    function initialize() initializer public {      
        require(_multiSigInitialized == 0);
        _multiSigInitialized = 1;
        globals_init();
        __Context_init();
        __UUPSUpgradeable_init();
        _founders_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(globals.ADMIN_ROLE, tx.origin);
        _grantRole(globals.UPGRADER_ROLE, tx.origin);

        _setupRole(globals.PAUSER_ROLE, address(0x60A7A4Ce65e314642991C46Bed7C1845588F6cD0));
        _setupRole(globals.PAUSER_ROLE, address(0x6188b15bAE64416d779560D302546e5dE15E5d1E));

        _wallet = payable(address(this));
    }

    receive() external payable {
        emit DepositFunds(tx.origin, msg.value, _wallet.balance); 
    }
  
    function addNewToken(bytes32 symbol_, address address_) public onlyRole(globals.PAUSER_ROLE) returns (bool) {  
        tokens[symbol_] = address_;  
        return true;  
    }  
    
    function removeToken(bytes32 symbol_) public  onlyRole(globals.PAUSER_ROLE) returns (bool) {  
      require(tokens[symbol_] != address(0x0));  
      delete(tokens[symbol_]);  
      return true;  
    }  

    function transferTokens(bytes32 symbol_, address to_, uint256 amount_) internal {  
      require(tokens[symbol_] != address(0x0));  
      require(amount_ > 0);  
      if(symbol_ == "ETH")
      {
        (bool success, ) = to_.call{value:amount_}("");
        require(success, "F");
      }
      else{
        address contract_ = tokens[symbol_];       
        ERC20Interface = ERC20Upgradeable(contract_);  
        ERC20Interface.transfer(to_, amount_);  
      }
      emit TransferSuccessful(address(this), to_, amount_);  
    }  

    function transferFrom(address from, address to, uint256 amount) 
    public virtual 
    nonReentrant()
    override (ERC20Upgradeable) returns (bool) {
        require(1 == 0, "N");
        return ERC20Upgradeable.transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount) 
    public virtual
    nonReentrant()
    override (ERC20Upgradeable) returns (bool) {
        require(1 == 0, "N");
        return ERC20Upgradeable.transfer(to, amount);
    }

    function transferForFounderFundProposal(bytes32 symbol, address to, uint256 amount)  
    onlyRole(globals.PAUSER_ROLE)
    private {
        transferTokens(symbol, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    override 
    nonReentrant()
    onlyRole(globals.ADMIN_ROLE){
        require(ADMIN_ADDRESS == tx.origin, "O");
    }

    /*Founder functions - Funds*/ 
    function completeFundsTransferProposal(uint256 proposalID)
    public 
    virtual onlyRole(PAUSER_ROLE) {
        if(founderExecution(proposalID) == 1)
        {
            address tgts = proposalVotes[proposalID].pTargets; 
            uint256 vals = proposalVotes[proposalID].pValues; 
            transferForFounderFundProposal(proposalVotes[proposalID].symbol, tgts, vals);
        }
    }
    
    function createFundsTransferProposal(bytes32 symbol, address pFrom, address tgts, uint256 vals,  bytes32 desc) 
    public 
    virtual
    nonReentrant() 
    onlyRole(PAUSER_ROLE)  {
        _createProposal(symbol, pFrom, tgts, vals, desc);
    }

    function getPState(uint256 proposalID) 
    public 
    view returns (uint256) {
        return gPState(proposalID);
    }

    function getPDesc(uint256 proposalID) 
    public 
    view returns (bytes32) {
        return gPDesc(proposalID);
    }

    function founderFundVote(
        uint256  proposalID,
        uint256 vote,
        address to, 
        uint256 amount, 
        string memory message,
        uint nonce,
        bytes memory signature
    ) external 
    nonReentrant()
    onlyRole(PAUSER_ROLE) {
        if (tx.origin == founderOne.founderAddress) {
            require(verify(founderOne.founderAddress, to, amount, message, nonce, signature) == true, "O");
            f1VoteOnFundsProposal(vote, proposalID);
        }
        if (tx.origin == founderTwo.founderAddress) {
            require(verify(founderTwo.founderAddress, to, amount, message, nonce, signature) == true, "T");
            f2VoteOnFundsProposal(vote, proposalID);
        }
    }
    
    /*Founder Functions - Addr*/
     function completeAddrTransferProposal(uint256 proposalID)
    public 
    virtual onlyRole(PAUSER_ROLE) {
        addressSwapExecution(proposalID);
    }
    
    function createAddrTransferProposal(
        address payable oldAddr, 
        address payable newAddr, 
        bytes32 desc)  
    public 
    virtual
    nonReentrant() 
    onlyRole(PAUSER_ROLE) {
        _createAddressSwapProposal(oldAddr, newAddr, desc);
    }

    function getAddrPState(uint256 proposalID) 
    public 
    view returns (uint256) {
        return gPSwapState(proposalID);
    }

    function getAddrPDesc(uint256 proposalID) 
    public 
    view returns (bytes32) {
        return gPSwapDesc(proposalID);
    }

    function founderAddrVote(
        uint256  proposalID,
        uint256 vote,
        address to, 
        uint256 amount, 
        string memory message,
        uint nonce,
        bytes memory signature
    ) external 
    nonReentrant()
    onlyRole(PAUSER_ROLE) {
        if (tx.origin == founderOne.founderAddress) {
            require(verify(founderOne.founderAddress, to, amount, message, nonce, signature) == true);
            f1VoteOnSwapProposal(vote, proposalID);
        }
        if (tx.origin == founderTwo.founderAddress) {
            require(verify(founderTwo.founderAddress, to, amount, message, nonce, signature) == true);
            f2VoteOnSwapProposal(vote, proposalID);
        }
    }

    /*Signature Methods*/
    function getMessageHash(
       address _to,
       uint _amount,
       string memory _message,
       uint _nonce
    ) 
    public 
    pure returns (bytes32) {
        return keccak256(abi.encode(_to, _amount, _message, _nonce));
    }

    function verify(
        address _signer,
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) 
    public returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);

        for(uint i = 0; i < usedMessages[tx.origin].length; i++) {
            require(usedMessages[tx.origin][i] != messageHash);
        }
        bool temp = recoverSigner(messageHash, signature) == _signer;
        if (temp)
            usedMessages[tx.origin].push(messageHash);
        return temp;
    }

    function recoverSigner(bytes32 msgHash, bytes memory _signature)
    public
    pure returns (address) {
        bytes32 _temp = ECDSAUpgradeable.toEthSignedMessageHash(msgHash);
        address tempAddr = ECDSAUpgradeable.recover(_temp, _signature);
        return tempAddr;
    }
}
