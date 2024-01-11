// SPDX-License-Identifier: MIT
// @author st4rgard3n
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Cheebiez is ERC721A, Pausable, Ownable {

    // @todo check all constants and update; change name and symbol
    uint256 private constant PRICE = 0.1 ether;

    /*************************
     MAPPING STRUCTS EVENTS
     *************************/

    // mapping from Cheeblist address to claimed status
    mapping(address => bool) public cheebListClaim;

    // struct for efficiently packing time stamp data for public sale and cheeblist
    struct SaleConfig {
        uint16 maxMint;
        uint16 maxSupply;
        uint64 cheeblistStart;
        uint64 cheeblistEnd;
    }

     /*************************
     STATE VARIABLES
     *************************/

    // stores timestamps
    SaleConfig private saleConfig;

    // merkle tree root for cheebList claim
    bytes32 private _root;

    // URI slug for serving token metadata
    string public baseURI;

    // Bool for pausing public sale
    bool private _salePaused;

    // bool for locking the sale configuration
    bool private _contractLocked;

    constructor() ERC721A("Cheebiez", "CHEEBZ") {

        // Pre-reveal URI
        setBaseURI("https://cheebiez.s3.us-west-1.amazonaws.com/preview-data/");

        // pause contract during deployment
        pause();

        // Set the timestamps for cheeblist and public sales
        setSaleConfig(1654704900, 10000, 20);

    }

    /*************************
     MODIFIERS
     *************************/

    /**
    * @dev Modifier for preventing calls from contracts
    * Safety feature for preventing malicious contract call backs
    */
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract!");
        _;
    }

    /*************************
     VIEW AND PURE FUNCTIONS
     *************************/

    /**
    * @dev Helper function for validating a merkle proof and leaf
    * @param merkleProof is an array of proofs needed to authenticate a transaction
    * @param root is used along with proofs and our leaf to authenticate our transaction
    * @param leaf is generated from parameter data which can be enforced
    */
    function verifyClaim(
        bytes32[] memory merkleProof,
        bytes32 root,
        bytes32 leaf
    )
        public
        pure
        returns (bool valid)
    {
        return MerkleProof.verify(merkleProof, root, leaf);
    }

    /**
    * @dev Function for getting the price.
    * Allows front-ends to consume price data
    */
    function getPrice() public pure returns (uint) {
        return PRICE;
    }

    /**
    * @dev Function for getting the sale pause status
    * Allows front-ends to consume sale pause status
    */
    function getSalePauseStatus() public view returns (bool) {
        return _salePaused;
    }

    /**
    * @dev Returns true if the Cheeblist is live
    * returns false after the public sale starts
    */
    function isCheebListOn() public view returns (bool) {
        if (block.timestamp >= saleConfig.cheeblistStart && block.timestamp <= saleConfig.cheeblistEnd) {
            return true;
        } else {
            return false;
        }
    }

    /**
    * @dev Returns true if the public sale is live
    * returns false before the public sale starts
    */
    function isPublicSaleOn() public view returns (bool) {
        if (block.timestamp >= saleConfig.cheeblistEnd) {
            return !_salePaused;
        } else {
            return false;
        }
    }

    /**
    * @dev Returns true if the tokens are sold out
    * returns false before the tokens are sold out
    */
    function isSoldOut() external view returns (bool) {
        if (totalSupply() >= saleConfig.maxSupply) {
            return true;
        } else {
            return false;
        }
    }

    /*************************
     USER FUNCTIONS
     *************************/

    /**
     * @dev Public function for purchasing {amount} amount of tokens. Checks for current price.
     * Calls _safeMint() for minting process
     * @param to recipient of the NFT minted
     * @param amount number of NFTs minted
     */
    function getCheeb(address to, uint256 amount)
        public
        payable
        whenNotPaused
        callerIsUser
    {
        // require users aren't minting more than 20 Cheebz
        require(amount <= saleConfig.maxMint, "You can mint a maximum of 20 Cheebiez at a time!");

        // require that user's sent along the correct amount of ETH
        require(msg.value == PRICE * amount, "Ether amount sent is not correct!");

        // require public sale has started
        require(isPublicSaleOn() == true, "Public sale hasn't started or is paused!");

        // require that users aren't minting more than max supply
        require(totalSupply() + amount <= saleConfig.maxSupply, "Too many Cheebiez!");

        // mint user's tokens
        _safeMint(to, amount);
    }

    /**
     * @dev Public function for redeeming Cheeblist tokens
     * Calls _safeMint() for minting process
     * @param amount number of NFTs minted
     * @param merkleProof proof set for claims
     */
    function cheebListMint(uint amount, bytes32[] calldata merkleProof)
        public
        payable
        whenNotPaused
        callerIsUser
    {

        address user = _msgSender();

        // require user is minting 5 or less Cheebs
        require(amount < 6, "Can't mint more than 5 Cheebs from the Cheeblist!");

        // require that user hasn't already claimed these items
        require(!cheebListClaim[user], "Already claimed your Cheeblist!");

        // require that user's sent along the correct amount of ETH
        require(msg.value == PRICE * amount, "Ether amount sent is not correct!");

        // require that Cheeblist mint has started
        require(saleConfig.cheeblistStart <= block.timestamp, "The CheebList hasn't started!");

        // require that Cheeblist mint has not ended
        require(saleConfig.cheeblistEnd >= block.timestamp, "The Cheeblist is closed!");

        // require that users aren't minting more than max supply
        require(totalSupply() + amount <= saleConfig.maxSupply, "Too many Cheebiez!");

        // build our leaf from the recipient address and the hash of unique item ids
        bytes32 leaf = keccak256(abi.encodePacked(user));

        // authenticate the claim against our merkle tree
        require(verifyClaim(merkleProof, _root, leaf), "Invalid claim!");

        // set user's claim status
        cheebListClaim[user] = true;

        // claim the Entrance tokens
        _safeMint(user, amount);
    }

    /*************************
     ACCESS CONTROL FUNCTIONS
     *************************/

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * @dev Function for only owner to freeze all sale configuration parameters
    */
    function lock() public onlyOwner {
        _contractLocked = true;
    }

    /**
    * @dev Function for only owner to pause sale after it's time stamp is active
    * @param status boolean determining whether sale is paused after public sale has started
    */
    function setSalePauseStatus(bool status) public onlyOwner {
        _salePaused = status;
    }

    /**
    * @dev Function for only owner to set the whitelist starting time.
    * @param startTime the unix timestamp which will set all period timers.
    */
    function setSaleConfig(uint64 startTime, uint16 newMaxSupply, uint16 newMaxMint)
        public
        onlyOwner {

        // require that the sale configuration is not locked
        require(!_contractLocked, "Supply, price and sale are locked!");

        saleConfig.cheeblistStart = startTime;
        saleConfig.cheeblistEnd = startTime + 6 hours;
        saleConfig.maxSupply = newMaxSupply;
        saleConfig.maxMint = newMaxMint;
    }

    /**
    * @dev Function for only owner to mint team cheebiez.
    * @param to the address where cheebiez are minted
    * @param amount the number of cheebiez to mint
    */
    function teamCheebz(address to, uint amount) public onlyOwner {

        // require that users aren't minting more than max supply
        require(totalSupply() + amount <= saleConfig.maxSupply, "Too many Cheebiez!");

        // require that the sale configuration is not locked
        require(!_contractLocked, "Supply, price and sale are locked!");

        _safeMint(to, amount);
    }

    /**
    * @dev Function for setting the BaseURI.
    * Intended for onlyOwner to call in case the URI details need to be relocated
    * @param newBaseURI the new base URI slug
    */
    function setBaseURI(string memory newBaseURI)
        public
        onlyOwner {
        baseURI = newBaseURI;
    }

    /**
    * @dev Function for setting the merkle root for the cheeblist
    * Intended for onlyOwner to set the merkle tree's root for whitelisting
    * @param newRoot the merkle tree root node for authenticating claims
    */
    function setRoot(bytes32 newRoot)
        external
        onlyOwner {
        _root = newRoot;
    }

    /**
    * @dev Access control function allows owner to withdraw ETH
    */
    function withdrawAll()
        external
        onlyOwner {

        // transfer contract's balance to the multi-sig
        (bool success, ) = _msgSender().call{value: address(this).balance}("");

        // revert if transfer fails
        require(success, "Transfer failed.");

    }

    /*************************
     PRIVATE OR INTERNAL
     *************************/

    /**
    * @dev Function for getting the BaseURI.
    * Private function allows discovery of token URI data
    */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*************************
     OVERRIDES
     *************************/

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}
