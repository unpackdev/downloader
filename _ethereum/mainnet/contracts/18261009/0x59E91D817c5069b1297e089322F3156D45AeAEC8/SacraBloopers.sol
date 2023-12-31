// 
//                            @@@@     @@@           @@@       @@@@@          @@@                       
//                        @@@@@@      @@@@@         @@@@@@     @@@@@@@       @@@@@                      
//                      @@@@@@@       @@@@@@       @@@@@@@@    @@@@@@@@@     @@@@@@                     
//                     @@@@@@        @@@@@@@      @@@@@ @@@@   @@@@ @@@@    @@@@@@@                     
//                    @@@@@@@        @@@@@@@@    @@@@@    @@@ @@@@@ @@@@@   @@@@@@@@                    
//                     @@@@@@@      @@@@ @@@@    @@@@@        @@@@@@@@@@   @@@@ @@@                     
//                       @@@@@@@@   @@@@ @@@@   @@@@@         @@@@@@@@@    @@@@ @@@@                    
//                         @@@@@@@  @@@@@@@@@    @@@@@        @@@@@@@@     @@@@@@@@@                    
//                         @@@@@@@  @@@@@@@@@@    @@@@@@  @@   @@@@@@@@   @@@@@@@@@@@                   
//                        @@@@@@   @@@@    @@@     @@@@@@@@    @@@@@@@@@  @@@@    @@@                   
//                      @@@@@      @@@      @@@     @@@@@@     @@@   @@@  @@@      @@@                  
//                    @@@          @@        @@      @@@@      @@     @@@ @@        @@                  
// 
//  @@@@@        @@              @@@          @@@     @@@@@@@@@             @@   @@@@@              @@@@
//  @@@@@@@      @@@            @@@@@        @@@@@    @@@@@@@@@@@         @@@    @@@@@@@@       @@@@@@@ 
//  @@@@@@@@@    @@@@          @@@@@@@      @@@@@@@   @@@@@@@@@@@@      @@@@@    @@@@@@@@@    @@@@@@@   
//  @@@  @@@@@   @@@@        @@@@@@@@@@    @@@@@@@@@  @@@@@ @@@@@@   @@@@@@      @@@@ @@@@@  @@@@@@@    
//  @@@@ @@@@@   @@@@@       @@@@@@@@@@@  @@@@@@@@@@@ @@@@@@@@@@@@ @@@@@@@       @@@@ @@@@@  @@@@@@     
//  @@@@@@@@     @@@@       @@@@@@@@@@@@  @@@@@@@@@@@ @@@@@@@@@@@  @@@@@@@@      @@@@@@@@@    @@@@@@    
//  @@@@@@@@@@  @@@@@@      @@@@@  @@@@@ @@@@@@@@@@@@ @@@@@@@@@       @@@@@@@   @@@@@@@@@      @@@@@@@@ 
//  @@@@  @@@@@ @@@@@@      @@@@@ @@@@@@ @@@@@ @@@@@@ @@@@@           @@@@@@    @@@@@@@@@        @@@@@@@
//  @@@@  @@@@@ @@@@@@       @@@@@@@@@@   @@@@@@@@@@   @@@@         @@@@@@       @@@@@@@@@       @@@@@@@
//  @@@@@@@@@@@  @@@@@@@     @@@@@@@@@     @@@@@@@@@   @@@@        @@@@@@@       @@@@@@@@@      @@@@@@  
//  @@@@@@@@@@  @@@@@@@@@@@    @@@@@@       @@@@@@      @@@          @@@@@@@     @@@   @@@@   @@@@@     
//  @@@@@@@      @@@@@@@@       @@@@         @@@@       @@                @@@@@  @@      @@ @@@         
// 

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./ERC2981.sol";

/**
 * @dev Minting contract for Ugly Bitches
 */
contract SacraBloopers is ERC721AQueryable, ReentrancyGuard, Ownable, ERC2981 {
    // Variables
    // ---------------------------------------------------------------

    bool public isMintActive = false;

    uint256 public numGifts;

    uint256 private collectionSize;
    uint256 private reservedGifts;
    uint256 private mintPrice = 0.03 ether;
    uint256 private maxPerWallet;
    uint256 private maxPerTx;
    address private devAddress;
    string private _baseTokenURI;

    // Modifiers
    // ---------------------------------------------------------------

    /**
     * @dev This modifier ensures that the caller is a user and not a contract.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    /**
     * @dev This modifier ensures that public mint is open.
     */
    modifier publicMintActive() {
        require(isMintActive, "Mint is not open.");
        _;
    }

    /**
     * @dev This modifier ensures that there are gift tokens left.
     * @param quantity The number of tokens to be minted.
     */
    modifier giftsLeft(uint256 quantity) {
        require(
            numGifts + quantity <= reservedGifts,
            "There are no gift tokens left."
        );
        _;
    }

    /**
     * @dev This modifier ensures that there are public mint tokens left.
     * @param quantity The number of tokens to be minted.
     */
    modifier mintLeft(uint256 quantity) {
        require(
            totalSupply() + quantity <=
                collectionSize
                    - (reservedGifts - numGifts),
            "There are no public mint tokens left."
        );
        _;
    }

    /**
     * @dev This modifier ensures that the caller does not mint more than the max number of tokens per wallet.
     * @param quantity The number of tokens to be minted.
     */
    modifier lessThanMaxPerWallet(uint256 quantity) {
        require(
            _numberMinted(msg.sender) + quantity <=
                maxPerWallet,
            "The quantity exceeds the maximum number of tokens that can be minted per wallet."
        );
        _;
    }

    /**
     * @dev This modifier ensures that the caller does not mint more than the max number of tokens per transaction.
     * @param quantity The number of tokens to be minted.
     */
    modifier lessThanMaxPerTx(uint256 quantity) {
        require(
            quantity <= maxPerTx,
            "The quantity exceeds the maximum number of tokens that can be minted per transaction."
        );
        _;
    }

    /**
     * @dev This modifier ensures that the caller has sent the correct amount of ETH.
     * @param price The price of the token.
     * @param quantity The number of tokens to be minted.
     */
    modifier isCorrectPayment(uint256 price, uint256 quantity) {
        require(price * quantity == msg.value, "Incorrect amount of ETH sent.");
        _;
    }

    // Constructor
    // ---------------------------------------------------------------

    /**
     * @dev This function is the constructor for the contract.
     * @param collectionSize_ The number of tokens in the collection.
     * @param reservedGifts_ The number of tokens reserved for gifts.
     * @param maxPerWallet_ The maximum number of tokens that can be minted per wallet.
     * @param maxPerTx_ The maximum number of tokens that can be minted per transaction.
     * @param devAddress_ The address of the developer.
     */
    constructor(
        uint256 collectionSize_,
        uint256 reservedGifts_,
        uint256 maxPerWallet_,
        uint256 maxPerTx_,
        address devAddress_
    ) ERC721A("SacraBloopers", "SACRABLOOPERS") {
        collectionSize = collectionSize_;
        reservedGifts = reservedGifts_;
        maxPerWallet = maxPerWallet_;
        maxPerTx = maxPerTx_;
        devAddress = devAddress_;

        // Set royalty receiver to the contract creator,
        // at 7% (default denominator is 10000).
        _setDefaultRoyalty(0x7EE92f4be14b553b64C46bA3d2CB567A2A492c7D, 700);
    }

    // Public minting functions
    // ---------------------------------------------------------------

    /**
     * @notice Mint multiple tokens from public paid mint.
     * @param quantity The number of tokens to be minted.
     */
    function mint(
        uint256 quantity
    )
        external
        payable
        nonReentrant
        callerIsUser
        publicMintActive
        lessThanMaxPerTx(quantity)
        isCorrectPayment(mintPrice, quantity)
        mintLeft(quantity)
        lessThanMaxPerWallet(quantity)
    {
        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Mint a token to each address in an array.
     * @param addresses An array of addresses to mint to.
     */
    function gift(
        address[] calldata addresses
    ) external nonReentrant onlyOwner giftsLeft(addresses.length) {
        uint256 numToGift = addresses.length;
        numGifts += numToGift;
        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    /**
     * @notice Mint multiple tokens to each address in an array.
     * @param addresses An n-sized array of addresses to mint to.
     * @param quantities An n-sized array  quantities to mint to each corresponding address.
     */
    function giftMultiple(
        address[] calldata addresses,
        uint256[] calldata quantities
    ) external nonReentrant onlyOwner {
        require(
            addresses.length == quantities.length,
            "The number of recipients and quantities must be the same."
        );
        uint256 totalGifts = 0;
        for (uint256 i = 0; i < quantities.length; i++) {
            totalGifts += quantities[i];
        }
        require(
            numGifts + totalGifts <= reservedGifts,
            "There are not enough gift tokens."
        );
        numGifts += totalGifts;
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantities[i]);
        }
    }

    // Public read-only functions
    // ---------------------------------------------------------------

    /**
     * @notice Get the number of tokens minted by an address.
     * @param owner The address to check.
     * @return The number of tokens minted by the address.
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice Get the address that gets funds distributed to in the withdraw() method.
     * @return The number of tokens minted by the contract.
     */
    function getDevAddress() public view returns (address) {
        return devAddress;
    }

    /**
     * @notice Get the mint price for public sale.
     * @return The mint price.
     */
    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    /**
     * @notice Get the the maximum number of tokens that can be minted per wallet in the public sale.
     * @return The maximum number of tokens that can be minted per wallet in the public sale.
     */
    function getMaxPerWallet() public view returns (uint256) {
        return maxPerWallet;
    }

    /**
     * @notice Get the the maximum number of tokens that can be minted per transaction in the public sale.
     * @return The maximum number of tokens that can be minted per transaction in the public sale.
     */
    function getMaxPerTx() public view returns (uint256) {
        return maxPerTx;
    }

    /**
     * @notice Get the total number of tokens reserved for gifts.
     * @return The total number of reserved for gifts.
     */
    function getReservedGifts() public view returns (uint256) {
        return reservedGifts;
    }

    /**
     * @notice Get the total number of tokens that can ever be minted in the collection.
     * @return The total number of tokens.
     */
    function getCollectionSize() public view returns (uint256) {
        return collectionSize;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId The token ID to query.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    // Internal read-only functions
    // ---------------------------------------------------------------

    /**
     * @dev Returns base token metadata URI.
     * @return Base token metadata URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Owner only administration functions
    // ---------------------------------------------------------------

    /**
     * @notice Set public mint to active or inactive.
     * @param _isMintActive True to set mint to active, false to set to inactive.
     */
    function setMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    /**
     * @notice Set the public mint price.
     * @param _mintPrice The new mint price.
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @notice Set the maximum number of tokens that can be minted per wallet in the public sale.
     * @param _maxPerWallet The new maximum number of tokens that can be minted per wallet in the public sale.
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Set the maximum number of tokens that can be minted per transaction in the public sale.
     * @param _maxPerTx The new maximum number of tokens that can be minted per transaction in the public sale.
     */
    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    /**
     * @notice Set the number of tokens reserved for gifts.
     * @param _reservedGifts The new number of tokens reserved for gifts. Cannot be less than the number of tokens already gifted.
     */
    function setReservedGifts(uint256 _reservedGifts) external onlyOwner {
        require(
            numGifts <= _reservedGifts,
            "Cannot set reserved gifts to less than the number of tokens already gifted"
        );
        reservedGifts = _reservedGifts;
    }

    /**
     * @notice Reduce the number of tokens that can be minted.
     * @param _collectionSize The new number of total tokens that can ever be minted in the collection. Cannot be greater than the current collection size or smaller than the remaining tokens.
     */
    function setCollectionSize(uint256 _collectionSize) external onlyOwner {
        require(
            _collectionSize <= collectionSize,
            "Cannot increase collection size."
        );
        require(
            _collectionSize >= totalSupply() + reservedGifts - numGifts,
            "Cannot set collection size to less than the number of tokens already minted plus the remaining reserved gift tokens."
        );
        collectionSize = _collectionSize;
    }

    /**
     * @notice Set the base metadata URI.
     * @param baseURI The new base metadata URI.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Set the address that gets funds distributed to in the withdraw() method.
     * @param _devAddress The new dev address.
     */
    function setDevAddress(address _devAddress) external onlyOwner {
        devAddress = _devAddress;
    }

    /**
     * @notice Withdraw ETH from the contract.
     * @dev 80% of the contract balance is sent to the owner and 20% is sent to the dev address.
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool ownerWithdrawSuccess, ) = msg.sender.call{
            value: (address(this).balance * 8000) / 10000
        }("");
        require(ownerWithdrawSuccess, "Owner transfer failed");
        (bool devWithdrawSuccess, ) = devAddress.call{
            value: address(this).balance
        }("");
        require(devWithdrawSuccess, "Dev transfer failed");
    }

    /**
     * @notice Withdraw ERC-20 tokens from the contract.
     * @dev In case someone accidentally sends ERC-20 tokens to the contract.
     * @param token The token to withdraw.
     */
    function withdrawTokens(IERC20 token) external onlyOwner nonReentrant {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

}
