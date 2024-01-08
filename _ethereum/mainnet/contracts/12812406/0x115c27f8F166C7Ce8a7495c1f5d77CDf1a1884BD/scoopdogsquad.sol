// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//################################################################################
//#########################################.######################################
//#########################################,.#####################################
//#########################################/*%####################################
//#########################################/@,*###################################
//##########################################*,.*##################################
//##########################################(/ //#################################
//##########################################((,*(%################################
//#########################################%(*,,/(################################
//######################################***/(/&/(@/////###########################
//###################################/*//(((((((((((((((/#########################
//##################################//((((((((((((((((((((########################
//#################################/((((((((((((((((((((((@#######################
//##############################@(((((((((((((((((((((((@(@(######################
//#############################/((,((((((((#(#####((((####@*((((##################
//############################*((*(@((((((######@##(((@%@@@#,,*@(((((((###########
//###########################/((,.((((((((, @@@ , @(((((, #@/,,,,,,,,,,,,@########
//#########################@((*,,,,(((@(((((@*..@(((((((((/###**@,,,,,,,,,########
//#######################/((,,,,,*&(((((((((((((((((((((((/((#####@*/*@###########
//#####################//,,,,,,,/&#(((((((((((((((((((((((((((@###################
//#####################,,,,,,,/@###@((((((((((((((((((((@&&&&&&###################
//######################@. @##.####@(##((((((((((((((((((((@@(((##################
//########################## @#####@/(((##(((((((((( @,,//((((((##################
//#################################/((((((##(((((((((((@-----,(###################
//################################@/((((((((#@(((((((((((@@(((####################
//###############################@/((((((((((((((####@((/((((((###################
//############################## /((((((((((((((@######@@((((((###################
//##########################(----@/@ ,(((((((((((#######((((@&####################
//#######################@,*------------.,,,,,.-------,####(@#####################
//#####################@ ////****************************@#@######################
//####################------------------------------------.#######################
//###################******,#@&/@-----------------@***(****,######################

/**
 * @title SCOOPDOG-SQUAD contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SCOOPDOGSQUAD is ERC721Enumerable, Ownable {
    // ScoopDog-Squad Contract Constants
    uint256 public MINT_ETH_COST = 69 * 10**15; // 0.069 ETH
    uint256 public RESERVED_SUPPLY = 50;
    uint256 public MAX_IN_ONE_GO = 20;
    uint256 public MAX_SUPPLY = 10000;

    // Provenance (and reveal).
    // The IPFS reveal hash.
    string public PROVENANCE_HASH = "";
    // The First SDOG provenance index.
    uint256 public FIRST_SDOG = 0;
    // Pre set reveal time.
    uint256 public REVEAL_TIMESTAMP = 1627264800;
    // End of pre-sale block number.
    uint256 public FIRST_BLOCK = 0;

    // Interaction variables.
    // To prevent minting when not ready.
    bool private saleLock = true;
    // The base URI of the tokens.
    string internal tokenBaseURI;

    // Naming variables
    mapping (uint256 => string) private sdogNames;
    mapping (string => bool) private usedNames;
    event Named(uint256 indexed index, string name);

    // Company variables(all private).
    address[] private companyAddresses;
    mapping (address => uint) private companyAddressAmounts;

    // And it begins...
    // Name: ScoopDogSquad, Symbol: SDOG
    constructor(string memory name, string memory symbol, address[] memory _companyAddresses)
        ERC721(name, symbol) {
        companyAddresses = _companyAddresses;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Company Functions.
    //////////////////////////////////////////////////////////////////////////////////////////
    function withdrawFunds(uint amount) external {
        require(companyAddressAmounts[msg.sender] >= amount, "No funds left or not a member.");

        // Update amount before sending to prevent re-entrancy attacks
        companyAddressAmounts[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawOwner(uint amount) external onlyOwner {        
        // Get the reserved funds to not step over those.
        uint reservedFunds = 0;
        for (uint i = 0; i < companyAddresses.length; i++) {
            address _address = companyAddresses[i];
            reservedFunds += companyAddressAmounts[_address];
        }

        // Make sure the owner is not withdrawing more than what it has available to him.
        uint amountAvailableOwner = address(this).balance - reservedFunds;
        require(amount <= amountAvailableOwner, 
            "Amount higher than owner's");

        // The amount to tranfer to each of the members.
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

    /////////////////////////////////////////////////////////////////////////////////////////
    // OnlyOwner functions.
    /////////////////////////////////////////////////////////////////////////////////////////
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
     * Set the mint price.
     */
    function setMintCost(uint256 _mintCost) external onlyOwner {    
        MINT_ETH_COST = _mintCost;
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
    function reserveSDOGs() external onlyOwner {
        require(totalSupply() < RESERVED_SUPPLY, "The reserved supply has already been requested");
        
        for (uint i = 0; i < RESERVED_SUPPLY; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    /**
     * External owner access to set the First SDOG index.
     */
     function setFirstSDOG() external onlyOwner {
        require(FIRST_SDOG == 0, "First SDOG has already been set");
        require(FIRST_BLOCK != 0, "First Block has to be set first");

        setFirstSDOGInner();
    }

    /**
     * External owner access to set the First Block and then First SDOG index.
     */
    function setFirstBlock() external onlyOwner {
        require(FIRST_BLOCK == 0, "First Block has already been set");

        setFirstBlockInner();
    }

    /**
     * Safety function to remove bad names.
     */
    function removeName(uint256 tokenId) external onlyOwner {
        require(tokenId < totalSupply(), "The token ID is not valid");
        // We will keep the name in the disallow list to prevent it
        // from been used again.
        sdogNames[tokenId] = "";
    }  

    /////////////////////////////////////////////////////////////////////////////////////////
    // Private Functions
    /////////////////////////////////////////////////////////////////////////////////////////
    /**
     * Sets the First SDOG index.
     * Ideally, we won't get 0 as the First SDOG, but it could be the case.
     * We need to keep things as random as possible.
     */
    function setFirstSDOGInner() private {
        require(FIRST_BLOCK != 0, "First Block has to be set first");
        FIRST_SDOG = uint(keccak256(
            abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % MAX_SUPPLY;
    }

    /**
     * Sets the First Block and then First SDOG index.
     */
    function setFirstBlockInner() private {   
        require(FIRST_BLOCK == 0, "First Block has already been set");     
        FIRST_BLOCK = block.number;
        setFirstSDOGInner();
    }

    /**
     * Sets the First Block if:
     * - The First Block and Cumplant have not been set.
     * - The max supply has been reached.
     * - The Pre-Sale period has ended.
     */  
    function setFirstIfReady() private {
        if (FIRST_SDOG == 0 &&
            FIRST_BLOCK == 0 &&
            (totalSupply() == MAX_SUPPLY ||
              block.timestamp >= REVEAL_TIMESTAMP)) {
                setFirstBlockInner();
        }
    }

    /**
     * Converts the given string to lower case.
     */
    function toLower(string memory str) private pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    // Convenient Web3 functions
    /////////////////////////////////////////////////////////////////////////////////////////
    /**
     * Returns the HODLer token IDs which we plan to use for web3 stuff in the future.
     */  
    function getMemberTokenIDs(address member) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(member);

        uint256[] memory tokensIDs = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            // Store the token indices.
            tokensIDs[i] = tokenOfOwnerByIndex(member, i);
        }

        return tokensIDs;
    }

    /**
     * Returns the name given an index.
     */
    function tokenNameByTokenID(uint256 tokenId) external view returns (string memory) {
        require(tokenId < totalSupply(), "The token ID is not valid");
        return sdogNames[tokenId];
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    // Naming and Minting functions (General Public)
    /////////////////////////////////////////////////////////////////////////////////////////

    /**
     * Checks is the name has been used, remember, we want names to be unique.
     */
    function isNameUsed(string memory name) public view returns (bool) {
        require(isValidName(name) == true, "This is not a valid name");
        return usedNames[toLower(name)];
    }

    /**
     * Validates the provided name.
     */
    function isValidName(string memory name) public pure returns (bool isValid) {
        bytes memory b = bytes(name);

        require(b.length >= 3, "Can't be shorter than 3 chars");
        require(b.length <= 32, "Can't be longer than 32 chars.");
        require(b[0] != 0x20, "Can't start with space.");
        require(b[b.length - 1] != 0x20, "Can't end with space.");

        bytes1 lastChar = b[0];// Last Processed char
        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            require(char != 0x20 || lastChar != 0x20, "No 2+ consecutive spaces.");
            require((char >= 0x30 && char <= 0x39) || // not 0-9
                (char >= 0x41 && char <= 0x5A) || // not A-Z
                (char >= 0x61 && char <= 0x7A) || // not a-z
                (char == 0x20), "Only 0-9, A-Z, a-z and Space are allowed.");

            if ((char >= 0x41 && char <= 0x5A) || // is A-Z
                (char >= 0x61 && char <= 0x7A)) { // is a-z
                    isValid = true;
                }
            lastChar = char;
        }
        // Not alphabet char in the name will return false.
        require(isValid, "The name needs to have at least 1 alphabet(A-z) character.");
        return true;
    }

    /**
     * Set SDOG Name function.
     */
    function setSDogName(uint256 tokenId, string memory name) external {
        require(FIRST_BLOCK != 0, "The reveal has not happened");
        require(msg.sender == ownerOf(tokenId), "This token does not belong to the requesting address");
        require(isValidName(name) == true, "This is not a valid name");
        require(isNameUsed(name) == false, "The name has already been used");
        // Release the old name.
        if (bytes(sdogNames[tokenId]).length > 0) {
            usedNames[toLower(sdogNames[tokenId])] = false;
        }
        usedNames[toLower(name)] = true;
        sdogNames[tokenId] = name;
        emit Named(tokenId, name);
    }

    /**
     * Mints SDOGs
     */  
    function mintSDOG(uint tokenAmount) external payable {
        require(!saleLock, "The sale is closed");
        require(totalSupply() < MAX_SUPPLY, "The sale has ended");
        require(totalSupply() + tokenAmount <= MAX_SUPPLY, "Transaction exceeds max supply");        
        require(tokenAmount <= MAX_IN_ONE_GO, "Token Amount exceeded the max allowed per transaction (20)");
        require(msg.value >= tokenAmount * MINT_ETH_COST, "Value sent is below total cost");

        for (uint i = 0; i < tokenAmount; i++) {
            // Double check that we are not trying to mint more than the max supply.
            if (totalSupply() < MAX_SUPPLY) {                
                _safeMint(msg.sender, totalSupply());
            }
        }
        // Set the First Block if ready (if it's time).
        setFirstIfReady();
        // Perform accounting.
        updateAccounting();
    }
}