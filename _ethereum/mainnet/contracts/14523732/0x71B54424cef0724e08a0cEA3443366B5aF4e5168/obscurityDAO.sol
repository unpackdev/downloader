// SPDX-License-Identifier: LGPL-3.0-or-later
/**
 * @title obscurityDAO
 * @email obscuirtyceo@gmail.com
 * @dev Nov 3, 2020
 * ERC-20 
 * obscurityDAO Copyright and Disclaimer Notice:
 */
pragma solidity ^0.8.7 <0.9.0;
import "./founders.sol";

import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract obscurityDAO is ERC20Upgradeable, PausableUpgradeable, UUPSUpgradeable, FounderWallets, ReentrancyGuardUpgradeable {
    
    bool initialized;
    bool crSaleZero;
    address crAddress;
    mapping(address => bytes32[]) usedMessages;
    function initialize() initializer public {
        require(!initialized, "I");
        initialized = true;
        __ERC20_init("obscurityDAO", "OBSC");
        __Pausable_init();
        __UUPSUpgradeable_init();
        _founders_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(globals.ADMIN_ROLE, tx.origin);
        _setupRole(globals.MINTER_ROLE, tx.origin);
        _grantRole(globals.UPGRADER_ROLE, tx.origin);
        
        _mint(tx.origin, 250000000000 * 10 ** decimals());
        _revokeRole(globals.MINTER_ROLE, tx.origin);

        _setupRole(globals.PAUSER_ROLE, address(0x60A7A4Ce65e314642991C46Bed7C1845588F6cD0));
        _setupRole(globals.PAUSER_ROLE, address(0x6188b15bAE64416d779560D302546e5dE15E5d1E));
    }

    /*Transfer Functions*/
    function transferForCrowdSale(address from, address to, uint256 amount)
    public
    virtual 
    nonReentrant()
    override (ERC20Upgradeable) {
        require(crAddress == msg.sender, "A");
        ERC20Upgradeable.transferFrom(from, to, amount);
    }

    function transferForAdminWallet(address from, address to, uint256 amount)
    internal 
    nonReentrant()  {   
        require(from != companyWallet.founderAddress, "C");
        require(from != charityWallet.founderAddress, "Y");
        require(from != vestingWalletSun.founderAddress, "S");
        require(from != vestingWalletMoon.founderAddress, "M");
        if(tx.origin == founderOne.founderAddress || tx.origin == founderTwo.founderAddress) {
            ERC20Upgradeable.transferFrom(from, to, amount);
        }
        else{
            require(1 == 0,  "F");
        }
    }

    function transferFrom(address from, address to, uint256 amount) 
    public virtual 
    nonReentrant()
    override (ERC20Upgradeable) returns (bool) {
        require(amount >= 100000, "N.");
        require(from != ADMIN_ADDRESS, "A");
        require(from != companyWallet.founderAddress, "C");
        require(from != charityWallet.founderAddress, "Y");
        require(from != vestingWalletSun.founderAddress, "S");
        require(from != vestingWalletMoon.founderAddress, "M");
        require(balanceOf(from) >= amount, "Z");
        uint256 fee;
        uint256 totalFee;
        uint256 newAmount;
        uint256 amountTransfered = amount;
        // 1 fee for each founder and the company 3 total
        unchecked {
            fee = amountTransfered / 10**5;
            totalFee =  fee;
            newAmount = amountTransfered - (7 * totalFee);  
            ERC20Upgradeable.transfer(founderOne.founderAddress, fee);
            ERC20Upgradeable.transfer(founderTwo.founderAddress, fee);
            ERC20Upgradeable.transfer(companyWallet.founderAddress, fee);

            ERC20Upgradeable.transfer(charityWallet.founderAddress, fee);
            
            ERC20Upgradeable.transfer(vestingWalletMoon.founderAddress, fee);

            ERC20Upgradeable.transfer(vestingWalletSun.founderAddress, 2*fee);
        }
        return ERC20Upgradeable.transferFrom(from, to, newAmount);
    }

    function transfer(address to, uint256 amount) 
    public virtual
    nonReentrant()
    override (ERC20Upgradeable) returns (bool) {
        //require(1 >= 10000, "use obscTransfer and obscTransferFrom.");
        require(amount >= 100000, "N");
        require(msg.sender != ADMIN_ADDRESS, "A");
        require(tx.origin != companyWallet.founderAddress, "C");
        require(tx.origin != charityWallet.founderAddress, "Y");
        require(balanceOf(tx.origin) >= amount, "Z");
        uint256 fee;
        uint256 totalFee;
        uint256 newAmount;
        uint256 amountTransfered = amount;
        // 1 fee for each founder and the company 3 total
        unchecked {
            fee = amountTransfered / 10**5;
            totalFee =  fee;
            newAmount = amountTransfered - (7 * totalFee);  
            ERC20Upgradeable.transfer(founderOne.founderAddress, fee);
            ERC20Upgradeable.transfer(founderTwo.founderAddress, fee);
            ERC20Upgradeable.transfer(companyWallet.founderAddress, fee);

            ERC20Upgradeable.transfer(charityWallet.founderAddress, fee);
            
            ERC20Upgradeable.transfer(vestingWalletMoon.founderAddress, fee);

            ERC20Upgradeable.transfer(vestingWalletSun.founderAddress, 2*fee);   
        }

        return ERC20Upgradeable.transfer(to, newAmount);
    }

    /*ADMIN/FOUNDER*/
    function pause() public {
        require(hasRole(globals.PAUSER_ROLE, tx.origin), "C");
        _pause();
    }

    function unpause() public {
        require(hasRole(globals.PAUSER_ROLE, tx.origin), "C");
        _unpause();
    }

     function setCRAddress(address newAddr) public {
        require(hasRole(globals.PAUSER_ROLE, tx.origin), "C");
        crAddress = newAddr;
    }

    function mint(address to, uint256 amount) 
    public 
    nonReentrant()
    onlyRole(globals.MINTER_ROLE) {
        _mint(to, amount);
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
    onlyRole(PAUSER_ROLE) {
        if(founderExecution(proposalID) == 1)
        {
            address pFrom =  proposalVotes[proposalID].pFrom;
            address tgts = proposalVotes[proposalID].pTargets; 
            uint256 vals = proposalVotes[proposalID].pValues; 
            transferForAdminWallet(pFrom, tgts, vals);
        }
    }

    function createFundsTransferProposal(address pFrom, address tgts, uint256 vals, bytes32 desc) 
    public 
    nonReentrant() 
    onlyRole(PAUSER_ROLE)  {
        _createProposal(pFrom, tgts, vals, desc);
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
    onlyRole(globals.PAUSER_ROLE) {
        addressSwapExecution(proposalID);
    }
    
    function createAddrTransferProposal(
        address payable oldAddr, 
        address payable newAddr, 
        bytes32 desc)  
    public 
    nonReentrant() 
    onlyRole(PAUSER_ROLE) {
        _createAddressSwapProposal(oldAddr, newAddr, desc);
    }

    function getAddrPState(uint256 proposalID) 
    public 
    view returns (uint256) {
        return gPSwapState(proposalID);
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
    nonReentrant() {
        require(hasRole(globals.PAUSER_ROLE, tx.origin), "C");

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

