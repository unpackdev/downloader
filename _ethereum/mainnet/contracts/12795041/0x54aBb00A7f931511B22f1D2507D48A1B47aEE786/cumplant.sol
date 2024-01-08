// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Cumplant contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Cumplant is ERC721Enumerable, Ownable {
    // Cumplant Contract Constants
    uint256 public MINT_ETH_COST = 2 * 10 ** 16; // 0.02 ETH
    uint256 public RESERVED_SUPPLY = 50;
    uint256 public MAX_IN_ONE_GO = 20;
    uint256 public MAX_SUPPLY = 10000;
    uint256 public FREE_UNDER_SUPPLY = RESERVED_SUPPLY + 500;
    uint256 public MAX_SUPPLY_PER_ADDRESS = 500;
    // Provenance (and reveal) Hash.
    string public PROVENANCE_HASH = "";
    // The Genesis Cumplant provenance index.
    uint256 public GENESIS_CUMPLANT = 0;
    // Pre set reveal time.
    uint256 public REVEAL_TIMESTAMP = 1626487200;
    // End of pre-sale block number.
    uint256 public GENESIS_BLOCK = 0;

    // Interaction variables.
    // To prevent minting when not ready.
    bool private saleLock = true;
    // The base URI of the tokens.
    string internal tokenBaseURI;
    // Free Supply so far.
    uint256 public freeSupply = 0;

    // Company variables.
    address[] private companyAddresses;
    mapping (address => uint) private companyAddressAmounts;

    // And it begins...
    // Name: Cumplant, Symbol: CUMPLANTS
    constructor(string memory name, string memory symbol, address[] memory _companyAddresses)
        ERC721(name, symbol) {
        companyAddresses = _companyAddresses;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Degen Plantation Functions
    // - Degen Plantation finances...
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    function withdrawFunds(uint amount) external {
        require(amount > 0, "Withdraw amount  can't be 0");
        require(companyAddressAmounts[msg.sender] >= amount, "No funds left or not a member.");

        companyAddressAmounts[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }
    
    function withdrawOwner(uint amount) external onlyOwner {
        require(address(this).balance > 0, "Address balance can't be 0");
        require(amount > 0, "Withdraw amount can't be 0");
        require(amount <= address(this).balance, "Withdraw amount can't be more than what the contract has.");
        
        uint reservedFunds = 0;
        for (uint i = 0; i < companyAddresses.length; i++) {
            address _address = companyAddresses[i];
            reservedFunds += companyAddressAmounts[_address];
        }

        uint amountAvailableOwner = address(this).balance - reservedFunds;
        require(amount <= amountAvailableOwner, "The request amount can't be higher than what the owner has available.");

        uint amountToTransferEach = amount / companyAddresses.length;
        for (uint i = 0; i < companyAddresses.length; i++) {
            address _address = companyAddresses[i];
            (bool success, ) = payable(_address).call{value: amountToTransferEach}("");
            require(success, "Transfer failed.");
        }
    }

    function checkCompanyBalance() external view returns (uint) {
        return companyAddressAmounts[msg.sender];
    }

    function checkOwnerBalance() external view onlyOwner returns (uint256) {
        uint reservedFunds = 0;
        for (uint i = 0; i < companyAddresses.length; i++) {
            address _address = companyAddresses[i];
            reservedFunds += companyAddressAmounts[_address];
        }
        return address(this).balance - reservedFunds;
    }
    
    function updateAccounting() private {
        uint percent = 90 / companyAddresses.length;
        uint amountEach = msg.value * percent / 100;

        for (uint i = 0; i < companyAddresses.length; i++) {
            address a = companyAddresses[i];
            companyAddressAmounts[a] += amountEach;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // OnlyOwner functions.
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * The reveal timestamp.
     */
    function setRevealTimestamp(uint256 _revealTimeStamp) external onlyOwner {
        REVEAL_TIMESTAMP = _revealTimeStamp;
    }

    /**
     * Set the provenance reveal hash.
     */
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {  
        PROVENANCE_HASH = _provenanceHash;
    }

    /**
     * Returns the baseURI which in our case corresponds to tokenBaseURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    /**
     * Sets the baseURI which will be stored as tokenBaseURI.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    /**
     * Flip the sale lock. 
     */
    function flipSaleLock() external onlyOwner {
        saleLock = !saleLock;
    }

    /**
     * Allows the owner to claim the company tokens.
     * - Reserved for the team, giveaways, partnerships, etc.
     */
    function reserveCum() external onlyOwner {
        require(totalSupply() < RESERVED_SUPPLY, "Already claimed the reserved supply");
        
        for (uint i = 0; i < RESERVED_SUPPLY; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }
    
    /**
     * External owner access to set the Genesis Cumplant index.
     */
     function setGenesisCumplant() external onlyOwner {
        require(GENESIS_CUMPLANT == 0, "Genesis index already set");
        require(GENESIS_BLOCK != 0, "Genesis block must be set");

        setGenesisCumplantInner();
    }

    /**
     * External owner access to set the Genesis Block and then Genesis Cumplant index.
     */
    function setGenesisBlock() external onlyOwner {
        require(GENESIS_CUMPLANT == 0, "Genesis index already set");
        require(GENESIS_BLOCK == 0, "Genesis block already set");

        setGenesisBlockInner();
    }
       

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Private Functions
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * Sets the Genesis Cumplant index.
     */
    function setGenesisCumplantInner() private {
        require(GENESIS_CUMPLANT == 0, "Genesis index already set");
        require(GENESIS_BLOCK != 0, "Genesis block must be set");
        // We are aware that this could result in 0 which would be the default order.
        // We thought about removing that but it also removes part of the randomness.
        GENESIS_CUMPLANT = uint(keccak256(
            abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % MAX_SUPPLY;
    }

    /**
     * Sets the Genesis Block and then Genesis Cumplant index.
     */
    function setGenesisBlockInner() private {
        require(GENESIS_CUMPLANT == 0, "Genesis index already set");
        require(GENESIS_BLOCK == 0, "Genesis block already set");
        
        GENESIS_BLOCK = block.number;

        // Now set the Genesis Cumplant.
        setGenesisCumplantInner();
    }

    /**
     * Sets the Genesis Block if:
     * - The GENESIS Block and Cumplant have not been set.
     * - The max supply has been reached.
     * - The Pre-Sale period has ended.
     */  
    function setGenesisIfReady() private {
        if (GENESIS_CUMPLANT == 0 &&
            GENESIS_BLOCK == 0 &&
            (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
                setGenesisBlockInner();
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // General public functions
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////    
    /**
     * Returns the cost of minting N amount.
     */
    function price(uint amount) public view returns (uint256) {
        // 500 free and only 1 per address.
        if (freeSupply < FREE_UNDER_SUPPLY && balanceOf(msg.sender) == 0) {
            return MINT_ETH_COST * (amount - 1);
        }
        
        return MINT_ETH_COST * amount;
    }

    /**
     * Returns the holder token IDs which will help owners visualize their Cumplants in the website.
     */  
    function getHolderTokenIDs(address holder) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(holder);

        uint256[] memory tokensIDs = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++) {
            // Store the token indices.
            tokensIDs[i] = tokenOfOwnerByIndex(holder, i);
        }

        return tokensIDs;
    }

    /**
     * Mints CUMPLANTS
     */  
    function mintCum(uint tokenAmount) external payable {
        uint256 _nextMintTokenId = totalSupply();

        require(!saleLock, "The sale is not open yet");
        require(_nextMintTokenId < MAX_SUPPLY, "The sale has ended");
        require(_nextMintTokenId + tokenAmount <= MAX_SUPPLY, "Transaction exceeds max supply");        
        require(tokenAmount <= MAX_IN_ONE_GO, "Token Amount exceeded the max allowed per transaction (20)");
        require(balanceOf(msg.sender) + tokenAmount <= MAX_SUPPLY_PER_ADDRESS, "Exceeds max minted tokens for this address (500)");
        require(msg.value >= price(tokenAmount), "Value sent is below total cost");

        for (uint i = 0; i < tokenAmount; i++) {
            // Double check that we are not trying to mint more than the max supply.            
            if (totalSupply() < MAX_SUPPLY) {
                // Keep track of the free supply.
                if (freeSupply < FREE_UNDER_SUPPLY && balanceOf(msg.sender) == 0) {
                    freeSupply++;
                }
                _safeMint(msg.sender, totalSupply());
            }
        }
        // Set the Genesis Block if ready (if it's time).
        setGenesisIfReady();
        // Perform accounting.
        updateAccounting();
    }
}