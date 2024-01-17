// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import Solidity Modules
import "./Ownable.sol";
import "./OnlyEOA.sol";
import "./MerkleAllowlist.sol";
import "./WaterfallMint.sol";
import {PayableGovernance} from 
    "cyphersuite/governance/PayableGovernance.sol";

// Interfaces 
interface iMachina {
    function totalSupply() external view returns (uint256);
    function nextTokenId() external view returns (uint256);
    function mintAsController(address to_, uint256 amount_) external;
}

contract MachinaSale is Ownable, OnlyEOA, MerkleAllowlist, 
WaterfallMint, PayableGovernance {

    ///// Interfaces /////
    iMachina public Machina;

    ///// Constraints /////
    uint256 public maxSupply;               // 7777
    uint256 public allowlistPrice;          // 0.0666 ether     || 66600000000000000
    uint256 public publicPrice;             // 0.0777 ether     || 77700000000000000

    ///// Times /////
    uint256 public waterfallStartTime;      // 1668781800
    uint256 public featherMintDuration;     // 30 minutes || 1800
    uint256 public machinaMintDuration;     // 3 hours || 10800

    ///// Configs /////
    bool public publicMintOpen;             // default: true

    ///// Proxy Initializer /////
    bool public proxyIsInitialized;

    function proxyInitialize(
        address newOwner_, 
        address machinaAddress_,
        uint256 maxSupply_, 
        uint256 allowlistPrice_, 
        uint256 publicPrice_,
        uint256 waterfallStartTime_, 
        uint256 featherMintDuration_, 
        uint256 machinaMintDuration_, 
        bool publicMintOpen_
    ) public {

        require(!proxyIsInitialized, "Proxy already initialized");
        proxyIsInitialized = true;

        // Hardcode
        owner = newOwner_; // Ownable.sol
        payableGovernanceSetter = newOwner_; // PayableGovernance.sol

        // Interface
        Machina = iMachina(machinaAddress_);

        // Sale Configs
        maxSupply = maxSupply_;
        allowlistPrice = allowlistPrice_;
        publicPrice = publicPrice_;

        waterfallStartTime = waterfallStartTime_;
        featherMintDuration = featherMintDuration_;
        machinaMintDuration = machinaMintDuration_;

        publicMintOpen = publicMintOpen_;
    }

    ///// Constructor (For Implementation) /////
    constructor() {
        proxyInitialize(
            msg.sender, 
            address(0), 
            0, 
            100_000_000 ether, 
            100_000_000 ether, 
            0, 
            0, 
            0, 
            false);
    }

    ///// Token Ranges /////
    uint256 public constant teamReserved = 400;
    uint256 public constant featherMintUpper = 1399;
    uint256 public constant machinaMintLower = 1000;

    ///// Ownable Configs /////
    function setMachina(address machina_) external onlyOwner {
        Machina = iMachina(machina_);
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setAllowlistPrice(uint256 allowlistPrice_) external onlyOwner {
        allowlistPrice = allowlistPrice_;
    }
    function setPublicPrice(uint256 publicPrice_) external onlyOwner {
        publicPrice = publicPrice_;
    }

    function setWaterfallStartTime(uint256 time_) external onlyOwner {
        waterfallStartTime = time_;
    }
    function setFeatherMintDuration(uint256 duration_) external onlyOwner {
        featherMintDuration = duration_;
    }
    function setMachinaMintDuration(uint256 duration_) external onlyOwner {
        machinaMintDuration = duration_;
    }

    function setPublicMintState(bool bool_) external onlyOwner {
        publicMintOpen = bool_;
    }

    function setAllowlistRoot(uint256 index_, bytes32 allowlistRoot_) 
    external onlyOwner {
        _setAllowlistRoot(index_, allowlistRoot_);
    }

    ///// Ownable Functions (Mint) /////
    function ownerMint(address to_, uint256 amount_) external onlyOwner {
        require(maxSupply >= (totalSupply() + amount_),
                "ownerMint exceeds maxSupply");
            
        Machina.mintAsController(to_, amount_);
    }

    ///// Eligibility Checks /////
    function isFeatherMintActive(uint256 startId_, uint256 mintAmount_) public view
    returns (bool) {
        uint256 _featherMintStartTime   = waterfallStartTime;
        uint256 _featherMintEndTime     = waterfallStartTime + featherMintDuration;
        uint256 _featherMintStartId     = 402; // 401 Tokens must be minted to trigger
        uint256 _featherMintEndId       = featherMintUpper;
        
        // This function will always return a boolean.
        return _returnWaterfallState(startId_, mintAmount_, 
                                    _featherMintStartTime, _featherMintEndTime,
                                    _featherMintStartId, _featherMintEndId);
    }
    function isMachinaMintActive(uint256 startId_, uint256 mintAmount_) public view
    returns (bool) {
        uint256 _machinaMintStartTime   = waterfallStartTime + featherMintDuration;
        uint256 _machinaMintEndTime     = _machinaMintStartTime + machinaMintDuration;
        uint256 _machinaMintStartId     = machinaMintLower;
        uint256 _machinaMintEndId       = maxSupply;

        // This function will always return a boolean.
        return _returnWaterfallState(startId_, mintAmount_,
                                    _machinaMintStartTime, _machinaMintEndTime,
                                    _machinaMintStartId, _machinaMintEndId);
    }
    function isPublicMintActive() public view returns (bool) {
        uint256 _machinaMintEndTime = 
            waterfallStartTime + featherMintDuration + machinaMintDuration;
        if (block.timestamp > _machinaMintEndTime && publicMintOpen) return true;
        return false;
    }

    ///// View Helpers /////
    function nextTokenId() public view returns (uint256) {
        return Machina.nextTokenId();
    }
    function totalSupply() public view returns (uint256) {
        return Machina.totalSupply();
    }

    ///// Feather Mint /////
    mapping(address => uint32) public addressToFeatherMinted;

    function featherMint(uint256 mintAmount_, uint256 proofAmount_, 
    bytes32[] calldata proof_) external payable onlyEOA {

        // Grab the NextTokenId and do a waterfall-stage check
        uint256 _nextTokenId = nextTokenId();
        require(isFeatherMintActive(_nextTokenId, mintAmount_),
                "FeatherMint is not active!");

        // Do a allowlisted check with index[1]
        require(isAllowlisted(1, msg.sender, proofAmount_, proof_),
                "You are not featherlisted!");
        
        // Do a quota check. Here, we use a custom mapping.
        uint32 _mintedAmount = addressToFeatherMinted[msg.sender];
        require(proofAmount_ >= (_mintedAmount + mintAmount_),
                "Mint amout exceeds quota!");

        addressToFeatherMinted[msg.sender] += uint32(mintAmount_);
        
        // Check that the msg.sender is sending the correct value
        uint256 _totalPrice = mintAmount_ * allowlistPrice;
        require(msg.value == _totalPrice,
                "Invalid value sent!");
        
        // Mint the tokens to the user
        Machina.mintAsController(msg.sender, mintAmount_);
    }

    ///// Machina Mint /////
    mapping(address => uint32) public addressToMachinaMinted;

    function machinaMint(uint256 mintAmount_, uint256 proofAmount_, 
    bytes32[] calldata proof_) external payable onlyEOA {

        // Grab the NextTokenId to do a waterfall-stage check
        uint256 _nextTokenId = nextTokenId();
        require(isMachinaMintActive(_nextTokenId, mintAmount_),
                "MachinaMint is not active!");

        // Do a allowlisted check with index[2]
        require(isAllowlisted(2, msg.sender, proofAmount_, proof_),
                "You are not machinalisted!");
        
        // Do a quota check. Here, we use a custom mapping.
        uint32 _mintedAmount = addressToMachinaMinted[msg.sender];
        require(proofAmount_ >= (_mintedAmount + mintAmount_),
                "Mint amout exceeds quota!");

        addressToMachinaMinted[msg.sender] += uint32(mintAmount_);
        
        // Check that the msg.sender is sending the correct value
        uint256 _totalPrice = mintAmount_ * allowlistPrice;
        require(msg.value == _totalPrice,
                "Invalid value sent!");
        
        // Mint the tokens to the user
        Machina.mintAsController(msg.sender, mintAmount_);
    }

    ///// Public Mint /////
    uint256 public constant maxMintPerPublicTx = 10;

    function publicMint(uint256 mintAmount_) external payable onlyEOA {
        
        // Check that the Public Mint is active
        require(isPublicMintActive(), 
            "Public Mint is not active!");
        
        // Check that the mintAmount_ is within TX limits
        require(maxMintPerPublicTx >= mintAmount_,
            "Amount exceeds max mints per TX!");
        
        // Check that msg.sender is sending the correct value
        uint256 _totalPrice = mintAmount_ * publicPrice;
        require(msg.value == _totalPrice,
                "Invalid value sent!");
        
        // Mint the tokens to the user
        Machina.mintAsController(msg.sender, mintAmount_);
    }
}