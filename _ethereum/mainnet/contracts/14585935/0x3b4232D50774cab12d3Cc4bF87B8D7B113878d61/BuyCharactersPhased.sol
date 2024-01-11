// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*

▄▄▄█████▓ ██░ ██ ▓█████     ██░ ██ ▓█████  ██▓  ██████ ▄▄▄█████▓
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▓██░ ██▒▓█   ▀ ▓██▒▒██    ▒ ▓  ██▒ ▓▒
▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██▀▀██░▒███   ▒██▒░ ▓██▄   ▒ ▓██░ ▒░
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░▓█ ░██ ▒▓█  ▄ ░██░  ▒   ██▒░ ▓██▓ ░ 
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░▓█▒░██▓░▒████▒░██░▒██████▒▒  ▒██▒ ░ 
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒ ░░▒░▒░░ ▒░ ░░▓  ▒ ▒▓▒ ▒ ░  ▒ ░░   
    ░     ▒ ░▒░ ░ ░ ░  ░    ▒ ░▒░ ░ ░ ░  ░ ▒ ░░ ░▒  ░ ░    ░    
  ░       ░  ░░ ░   ░       ░  ░░ ░   ░    ▒ ░░  ░  ░    ░      
          ░  ░  ░   ░  ░    ░  ░  ░   ░  ░ ░        ░           
                                                                
*/

import "./Ownable.sol";
import "./ECDSA.sol";

import "./PaymentsShared.sol";
import "./I_TokenCharacter.sol"; 

contract BuyCharactersPhased is Ownable, PaymentsShared {

    using ECDSA for bytes32;

    //phases
    enum PHASE{ PAUSED, ONE, TWO, PUBLIC }
    PHASE public currentPhase = PHASE.PAUSED;

    uint256 public constant MAX_MINTABLE = 10000;
    uint256 public TOKEN_PRICE = 0.09 ether;

    uint256 public P1_TOKENS_PER_MINT = 1;
    uint256 public MINTS_PER_TRANSACTION = 5;

    I_TokenCharacter tokenCharacter;
    
    //events
    event SalePhaseChanged(uint256 newStage);

    //Allowlist verification
    address authority;
    string salt = "ALLOW_LIST_HEIST";

    mapping(address => uint8) public ALMints;

    constructor(address _tokenCharacterAddress, address signer) {
        tokenCharacter = I_TokenCharacter(_tokenCharacterAddress);
        authority = signer;
    }

    function buy(uint8 amountToBuy, bytes memory signature) external payable {

        require(amountToBuy > 0, "Buy at least 1");
        require(msg.sender == tx.origin,"EOA only");

        //check price and soft supply
        require(msg.value >= TOKEN_PRICE * amountToBuy,"Not enough ETH");
        require(tokenCharacter.totalSupply() + amountToBuy < MAX_MINTABLE + 1,"Sold out");

        //phase 1: AL + wallet limit
        if (currentPhase == PHASE.ONE)
        {
            require(verifySignature(signature, msg.sender), "Wrong signature");
            require(ALMints[msg.sender] + amountToBuy < P1_TOKENS_PER_MINT + 1,"Over AL allocation");
            ALMints[msg.sender] += amountToBuy;
        }
        //phase 2: AL + transaction limit
        else if (currentPhase == PHASE.TWO)
        {
            require (amountToBuy < MINTS_PER_TRANSACTION + 1,"Over max per transaction");
            require(verifySignature(signature, msg.sender), "Wrong signature");
        }
        //phase 3: public + transaction limit
        else if (currentPhase == PHASE.PUBLIC)
        {
            require(amountToBuy < MINTS_PER_TRANSACTION + 1,"Over max per transaction");
        }
        else 
        {
            revert("Sale is not live");
        }

        //Do minting
        tokenCharacter.Mint(amountToBuy, msg.sender);

    }

    function getPrice() external view returns (uint256) {
      return TOKEN_PRICE;
    }

    //Variables
    function setPrice(uint256 newPrice) external onlyOwner {
      TOKEN_PRICE = newPrice;
    }

    function setPhase1Amount(uint256 newAmount) external onlyOwner {
      P1_TOKENS_PER_MINT = newAmount;
    }

    function setTransactionLimit(uint256 newAmount) external onlyOwner {
      MINTS_PER_TRANSACTION = newAmount;
    }

    //Allowlist minting
    function verifySignature (bytes memory signature, address senderAddress)
        internal view returns (bool)
    {
        //generate message, hash it, and compare signature
        bytes memory message = abi.encodePacked(senderAddress,salt);
        bytes32 messagehash = keccak256(message);
        address signingAddress = messagehash.toEthSignedMessageHash().recover(signature);

        return signingAddress == authority;
    }

    function setSalt(string memory newSalt) external onlyOwner {
        salt = newSalt;
    }

    function setSigner(address newSigningAddress) external onlyOwner {
        authority = newSigningAddress;
    }

    //Start phases and pause 
    function pauseSale() external onlyOwner {
      currentPhase = PHASE.PAUSED;
      emit SalePhaseChanged(uint256(currentPhase));
    }

    function getPhase() external view returns (uint256) {
      return uint256(currentPhase);
    }

    function getWalletMints(address minter) external view returns (uint256) {
      return ALMints[minter];
    }

    function startPhaseOne() external onlyOwner {
      currentPhase = PHASE.ONE;
      emit SalePhaseChanged(uint256(currentPhase));
    }

    function startPhaseTwo() external onlyOwner {
      currentPhase = PHASE.TWO;
      emit SalePhaseChanged(uint256(currentPhase));
    }

    function startPublicSale() external onlyOwner {
      currentPhase = PHASE.PUBLIC;
      emit SalePhaseChanged(uint256(currentPhase));
    }

}