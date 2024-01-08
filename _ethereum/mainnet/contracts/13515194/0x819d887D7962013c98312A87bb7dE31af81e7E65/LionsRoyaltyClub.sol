// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract LionsRoyaltyClub is ERC721, Ownable, ReentrancyGuard {
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        uint256 presaleMintPrice,
        uint256 presaleMintStart,
        uint256 presaleMintEnd,
        uint256 publicMintPrice,
        uint256 publicMintStart,
        uint256 publicMintEnd,
        uint64 publicMintMaxPerTransaction
    ) ERC721("LionsRoyaltyClub", "LRC") {
        require(presaleMintEnd >= block.timestamp, "Presale mint cannot end in the past");
        require(presaleMintPrice > 0, "Presale mint cannot be free");
        require(presaleMintStart <= presaleMintEnd, "Presale mint cannot start after it ends");
        
        require(publicMintPrice > 0, "Public mint cannot be free");
        require(publicMintEnd >= block.timestamp, "Public mint cannot end in the past");
        require(publicMintMaxPerTransaction > 0, "Public mint max per transaction cannot be less than 1");
        require(publicMintStart <= publicMintEnd, "Public mint cannot start after it ends");
        
        // CONFIGURE PRESALE Mint
        presaleMint.mintPrice = presaleMintPrice; 
        presaleMint.startDate = presaleMintStart == 0 ? block.timestamp : presaleMintStart; 
        presaleMint.endDate = presaleMintEnd; 
        
        // CONFIGURE PUBLIC MINT
        publicMint.mintPrice = publicMintPrice; 
        publicMint.startDate = publicMintStart == 0 ? block.timestamp : publicMintStart;
        publicMint.endDate = publicMintEnd; 
        publicMint.maxPerTransaction = publicMintMaxPerTransaction;
    }
    
    event Paid(address sender, uint256 amount);
    event Withdraw(address recipient, uint256 amount);
    
    struct WhitelistedMint {
        uint256 mintPrice;
        /**
         * A mapping of addresses to remaining
         * allowed.
         */
        mapping(address => uint64) whitelist;
        /**
         * The maximum per wallet,
         * uses the whitelist mapping
         * if not specified.
         */
        uint64 maxPerWallet;
        /**
         * The start date in unix seconds
         */
        uint256 startDate;
        /**
         * The end date in unix seconds
         */
        uint256 endDate;
    }
    
    struct PublicMint {
        uint256 mintPrice;
        /**
         * The maximum per transaction
         */
        uint64 maxPerTransaction;
        /**
         * The start date in unix seconds
         */
        uint256 startDate;
        /**
         * The end date in unix seconds
         */
        uint256 endDate;
    }
    
    string baseURI = "";
    
    uint64 public maxSupply = 5500;
    uint64 public supply = 0;
    uint64 public minted = 0;
    
    /**
     * An exclusive mint for members granted
     * presale from influencers
     */
    WhitelistedMint presaleMint;

    /**
     * The public mint for everybody.
     */
    PublicMint private publicMint;
    
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() override internal view virtual returns (string memory) {
        return baseURI;
    }
    
    /**
     * Sets the base URI for all tokens
     * 
     * @dev be sure to terminate with a slash
     * @param uri - the target base uri (ex: 'https://google.com/')
     */
    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }
    
    /**
     * Burns the provided token id if you own it.
     * Reduces the supply by 1.
     * 
     * @param tokenId - the ID of the token to be burned.
     */
    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You do not own this token");
        
        _burn(tokenId);
        supply--;
    }
    
    // ------------------------------------------------ MINT STUFFS ------------------------------------------------
    
    /**
     * Gets all of the data related to the presale mint.
     * @return startDate - the start date (UNIX Seconds)
     * @return endDate - the end date (UNIX Seconds)
     * @return mintPrice - the cost of the presale mint in WEI
     */
    function getPresaleMint() public view returns (uint256 startDate, uint256 endDate, uint256 mintPrice) {
        startDate = presaleMint.startDate;
        endDate = presaleMint.endDate;
        mintPrice = presaleMint.mintPrice;
    }
    
    /**
     * Gets all of the data related to the presale mint.
     * @return startDate - the start date (UNIX Seconds)
     * @return endDate - the end date (UNIX Seconds)
     * @return mintPrice - the cost of the presale mint in WEI
     * @return maxPerTransaction - the maximum amount a user can have in their wallet for the public mint
     */
    function getPublicMint() public view returns (
        uint256 startDate,
        uint256 endDate,
        uint256 mintPrice,
        uint64 maxPerTransaction
    ) {
        startDate = publicMint.startDate;
        endDate = publicMint.endDate;
        mintPrice = publicMint.mintPrice;
        maxPerTransaction = publicMint.maxPerTransaction;
    }
    
    /**
     * Sets users for the whitelist with the given allowed mint quantity.
     * 
     * @param users - the addresses of the users to whitelist
     * @param quantities - the quanities each address specified can mint
     */
    function setMintWhitelist(address[] calldata users, uint64[] calldata quantities) public onlyOwner {
        require(users.length == quantities.length, "User array does not correspond with quantities");

        // add new values
        for (uint256 i = 0; i < users.length; i++) {
            presaleMint.whitelist[users[i]] = quantities[i];
        }
    }

    function whitelistQuantity(address user) view public returns (uint256) {
        return presaleMint.whitelist[user];
    }
    
    /**
     * Updates the presale mint's characteristics
     * 
     * @param mintPrice - the cost for that mint in WEI
     * @param startDate - the start date for that mint in UNIX seconds
     * @param endDate - the end date for that mint in UNIX seconds
     */
    function updatePresaleMint(uint256 mintPrice, uint256 startDate, uint256 endDate) public onlyOwner {
        require(mintPrice > 0, "Presale mint cannot be free");
        require(startDate <= endDate, "Presale mint cannot start after it ends");
        
        presaleMint.mintPrice = mintPrice;
        presaleMint.startDate = startDate;
        presaleMint.endDate = endDate;
    }
    
    /**
     * Updates the public mint's characteristics
     * 
     * @param mintPrice - the cost for that mint in WEI
     * @param maxPerTransaction - the maximum amount allowed in a wallet to mint in the public mint
     * @param startDate - the start date for that mint in UNIX seconds
     * @param endDate - the end date for that mint in UNIX seconds
     */
    function updatePublicMint(uint256 mintPrice, uint64 maxPerTransaction, uint256 startDate, uint256 endDate) public onlyOwner {
        require(startDate <= endDate, "Public mint cannot start after it ends");
        require(mintPrice > 0, "Public mint cannot be free");
        require(maxPerTransaction > 0, "Public mint max per transaction cannot be less than 1");
        
        publicMint.mintPrice = mintPrice;
        publicMint.maxPerTransaction = maxPerTransaction;
        publicMint.startDate = startDate;
        publicMint.endDate = endDate;
    }
    
    /**
     * Mints the given quantity of tokens provided it is possible to.
     * 
     * @notice This function choses the appropriate mint depending on the timestamp
     *         and will expend the first mint in which you can mint that quantity
     *         with the precedence: Free -> Presale -> Public.
     * 
     * @param quantity - the number of tokens to mint
     */
    function mint(uint64 quantity) public payable nonReentrant {
        uint256 remaining = SafeMath.sub(maxSupply, minted);
        
        require(remaining > 0, "The mint has concluded");
        require(quantity >= 1, "Must mint at least one");
        require(quantity <= remaining, "Cannot mint more than are available");
        
        if (owner() == msg.sender) {
            // OWNER MINTING FOR FREE
            require(msg.value == 0, "The contract owner cannot pay to mint");
        } else if (
            block.timestamp >= presaleMint.startDate &&
            block.timestamp <= presaleMint.endDate &&
            presaleMint.whitelist[msg.sender] >= quantity
        ) {
            // PRESALE MINT
            require(SafeMath.mul(quantity, presaleMint.mintPrice) == msg.value, "Invalid value provided to mint in presale");
            presaleMint.whitelist[msg.sender] -= quantity;
        } else if (
            block.timestamp >= publicMint.startDate &&
            block.timestamp <= publicMint.endDate
        ) {
            // PUBLIC MINT
            require(quantity <= publicMint.maxPerTransaction, "Exceeds the public mint maximum");
            require(SafeMath.mul(quantity, publicMint.mintPrice) == msg.value, "Invalid value provided to mint");
        } else {
            // NOT ELIGIBLE FOR PUBLIC MINT
            revert("You cannot mint the quantity specified at this time");
        }
        
        // DISTRIBUTE THE TOKENS
        uint64 i = 0;
        for (i; i < quantity; i++) {
            supply += 1;
            minted += 1;
            _safeMint(msg.sender, minted);
        }
    }
    
    /**
     * Withdraws balance from the contract to the owner (sender).
     * @param amount - the amount to withdraw, much be <= contract balance.
     */
    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance <= amount, "Invalid withdraw amount");
        
        (bool success, ) = msg.sender.call{ value: amount }("");
        require(success, "Transaction failed");
        emit Withdraw(msg.sender, amount);
    }
    
    /**
     * The receive function, does nothing
     */
    receive() external payable {
        emit Paid(msg.sender, msg.value);
    }
}