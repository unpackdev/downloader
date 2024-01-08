// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/*
████████╗██╗░░██╗███████╗██╗░░░░░░█████╗░░█████╗░██████╗░██╗███████╗░██████╗
╚══██╔══╝██║░░██║██╔════╝██║░░░░░██╔══██╗██╔══██╗██╔══██╗██║██╔════╝██╔════╝
░░░██║░░░███████║█████╗░░██║░░░░░██║░░██║██║░░██║██████╔╝██║█████╗░░╚█████╗░
░░░██║░░░██╔══██║██╔══╝░░██║░░░░░██║░░██║██║░░██║██╔═══╝░██║██╔══╝░░░╚═══██╗
░░░██║░░░██║░░██║███████╗███████╗╚█████╔╝╚█████╔╝██║░░░░░██║███████╗██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚══════╝╚═════╝░
*/

//HOW MANY? MAXIMUM DROP SIZE IS ~65000
//HOW MUCH? MAXIMUM TOKEN PRICE IS ~18 ETH
//WHEN? PUBLIC SALE MUST BEGIN BEFORE ~Sunday, February 7, 2106
//HOW MANY PER TRANSACTION? 10 AT MOST


// TODO RELEASE - UPDATE ALL require MESSAGES TO FIT BRANDING


import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";

contract TheLoopies is Ownable, ERC721Enumerable, ERC721Burnable, PaymentSplitter {

    using SafeMath for uint;
    using Counters for Counters.Counter;

    uint64 public salePrice; // TODO POST RELEASE - SET AFTER DEPLOYMENT

    uint16 public maxTokens; // TODO POST RELEASE - SET AFTER DEPLOYMENT
    
    uint8 private _packedBooleans = 0x00;
    
    uint8 constant private URILOCK_BIT          = 0x01;
    uint8 constant private PROVENANCELOCK_BIT   = 0x02;
    uint8 constant private TOKENPRICELOCK_BIT   = 0x08;
    uint8 constant private MAXTOKENSLOCK_BIT    = 0x10;
    uint8 constant private CONTRACTURILOCK_BIT  = 0x20;
    
    uint8 constant private MAX_MINT_PER_TRANSACTION = 5;

    string public provenanceHash; // TODO POST RELEASE -> SET PROVENANCE

    //REGISTRATION OF ADDRESSES
    mapping(address => uint256) private _registration;

    //REGISTRATION TYPES // TODO RELEASE -> VERIFY MINT LOGIC
    //PROMO AMOUNT CAN BE ADDED BY TEAM TO ACCOUNT IN REGISTRATION, PROMOS CAN THEN BE CLAIMED FOR ONLY THE GAS OF MINTING
    uint256 constant private PROMOAMOUNT_VAR_MASK   = 0x00000000000000000000000000000000000000000000000000000000000000FF;
    
    //OTHER FLAGS
    uint256 constant private TEAM_BIT               = 0x0000000000000000000000000000000000000000000000000000000000000100;

    //TEAM ADDRESSES FOR PAYMENT

    address constant private DEPLOY_ADDRESS = 0x77100d24c16888F12D48055FF001532602A80570;
    address constant private MAIN_PAY = 0xe2a00e3fB149807a3F57fac7D1ec4C481315ec0d;
    address constant private PAY1  = 0x7184a0C95eC5C398276E1FD23c330107B90d76e7;
    address constant private PAY2  = 0x2e1be603C693839CE29a6ff48de5cdD2Da017699;
    address constant private PAY3  = 0x87265eCF09A8874f4027ff3d98121FeEf9cC6ade;
    address constant private PAY4  = 0x46c5038e30B3FFca7F088c021575Efa787F171aC;



    address[] private _team = [MAIN_PAY, PAY1, PAY2, PAY3, PAY4];
    uint256[] private _team_shares = [80, 5, 5, 5, 5]; // TODO RELEASE -> UPDATE

    string private baseURI;
    string private _contractURI;

    // TODO RELEASE -> UPDATE TOKEN NAME AND SYMBOL
    constructor() 
        ERC721("TheLoopies", "LOoPY") 
        PaymentSplitter(_team, _team_shares)
    {
        //REGISTER CONTRACT CREATOR AND OTHER TEAM MEMBERS
        _registration[msg.sender] = _registration[msg.sender] | TEAM_BIT;
        _registration[MAIN_PAY] = _registration[MAIN_PAY] | TEAM_BIT;
        _registration[PAY1] = _registration[PAY1] | TEAM_BIT;
        _registration[PAY2] = _registration[PAY2] | TEAM_BIT;
        _registration[PAY3] = _registration[PAY3] | TEAM_BIT;
        _registration[PAY4] = _registration[PAY4] | TEAM_BIT;
    }

    // Modifiers

    modifier onlyTeam() {
        // IF TEAM FLAG IS NOT SET IN REGISTRATION -> THROW
        require((_registration[msg.sender] & TEAM_BIT) != 0, "You are not part of the team.");
        _;
    }

    // LOCKABLE SETTERS

    // URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory newURI_) external onlyOwner {
        require((_packedBooleans & CONTRACTURILOCK_BIT) == 0, "Cannot modify locked field.");
        _contractURI = newURI_;
    }

    function lockContractURI() external onlyOwner {
        _packedBooleans = _packedBooleans | CONTRACTURILOCK_BIT;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require((_packedBooleans & URILOCK_BIT) == 0, "Cannot modify locked field.");
        baseURI = baseURI_;
    }

    function lockBaseURI() external onlyOwner {
        _packedBooleans = _packedBooleans | URILOCK_BIT;
    }

    // PROVENANCE
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        require((_packedBooleans & PROVENANCELOCK_BIT) == 0, "Cannot modify locked field.");
        provenanceHash = _provenanceHash;
    }

    function lockProvenanceHash() external onlyOwner {
        _packedBooleans = _packedBooleans | PROVENANCELOCK_BIT;
    }

    // MINT PRICES
    function setPrices(uint64 _salePrice) external onlyOwner {
        require((_packedBooleans & TOKENPRICELOCK_BIT) == 0, "Cannot modify locked field.");
        salePrice = _salePrice;
    }

    function lockPrices() external onlyOwner {
        _packedBooleans = _packedBooleans | TOKENPRICELOCK_BIT;
    }

    // MAX TOKENS
    function setMaxTokens(uint16 _maxTokens) external onlyOwner {
        require((_packedBooleans & MAXTOKENSLOCK_BIT) == 0, "Cannot modify locked field.");
        maxTokens = _maxTokens;
    }

    function lockMaxTokens() external onlyOwner {
        _packedBooleans = _packedBooleans | MAXTOKENSLOCK_BIT;
    }

    // SALE LOGIC
    // TODO TEST RELEASE -> DOUBLE CHECK LOGIC

    // REGISTRATION EDITOR
    // DANGEROUS FUNCTION -> BE SURE YOU KNOW WHAT YOU'RE DOING BEFORE YOU CALL
    function setAccountRegistration(address _account, uint256 _registrationValue) external onlyTeam { 
        _registration[_account] = _registrationValue;
    }

    function getAccountRegistration(address _account) external view returns (uint256) {
        return _registration[_account];
    }

    function _multiMint(uint8 _amount) internal {
        require((_amount > 0) && (_amount <= MAX_MINT_PER_TRANSACTION), "Invalid amount to mint selected.");
        for (uint i = 0; i < _amount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function mintLoopie(uint8 _amount) external payable  {
        // MINT IS ALWAYS ACCESSIBLE
        require((_amount + totalSupply()) <= maxTokens, "Minting this amount would exceed max supply.");
        // CHECK FOR PROMOS
        uint promoAmount = _registration[msg.sender] & PROMOAMOUNT_VAR_MASK;
        if(promoAmount > 0) {
            require(_amount <= promoAmount, "You do not have that many promos.");
            require(msg.value == 0, "You don't want to pay for your promos!");
            _registration[msg.sender] = _registration[msg.sender].sub(_amount); // TODO ->THIS ONLY WORKS BECAUSE PROMOAMOUNT IS THE LEAST SIGNIFICANT BYTE
            _multiMint(_amount);
        }
        else {
            require(salePrice > 0, "Sale price not set yet.");
            require(msg.value >= uint256(salePrice).mul(_amount), "Transaction value is too low for selected amount.");
            _multiMint(_amount);
        }
    }

    // Withdraw
    function withdrawAll() public {
        for(uint i = 0; i < _team.length; i++) {
            release(payable(_team[i]));
        }
    }

    // MULTIPLE DEFINES IN PARENT CLASSES
    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
        ) public view override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/**

 Generative Art: @Jim Dee
 Smart Contract Consultant: @realkelvinperez
 Smart Contract Consultant: patrickpr12@gmail.com

 https://generativenfts.io/

**/