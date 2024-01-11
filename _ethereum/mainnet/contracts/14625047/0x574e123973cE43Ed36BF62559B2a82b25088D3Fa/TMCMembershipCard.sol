// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Counters.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./MerkleProof.sol";
import "./AbstractERC1155Factory.sol";

/**
 * @title ERC1155 tokens for The Meta Charity Membership Card
 *
 * @dev struct allows gas optimization for different configs for each Card
 * This contract allows user to mint different membership card for TMC
 * Each card has its own config which sets max number of tokens, max per tx, state of each card
 * Defined 2 methods for each card which makes OG and Public minting
 * @author heet_v
 */
contract TMCMembershipCard is AbstractERC1155Factory {

    struct StandardConfig { 
        uint64 tokenPrice;
        uint32 maxTokens;
        bool isPreSaleActive;
        bool isPublicSaleActive;
        uint32 maxPerWallet;
    }

    struct EpicConfig { 
        uint64 tokenPrice;
        uint32 maxTokens;
        bool isPreSaleActive;
        bool isPublicSaleActive;
        uint32 maxPerWallet;
    }

    struct LegendaryConfig { 
        uint64 tokenPrice;
        uint32 maxTokens;
        bool isPreSaleActive;
        bool isPublicSaleActive;
        uint32 maxPerWallet;
    }

    // initialize structs with default values
    StandardConfig public standardConfig;
    EpicConfig public epicConfig;
    LegendaryConfig public legendaryConfig;

    // Token id's for each card
    // Provides easy readability for various operations
    uint256 public constant TOKEN_ID_STANDARD = 1;
    uint256 public constant TOKEN_ID_EPIC = 2;
    uint256 public constant TOKEN_ID_LEGENDARY = 3;

    // Merkle root
    bytes32 public merkleRoot;

    // map of metadata URI for each token 
    mapping (uint256 => string) public tokenURI;

    // Used to ensure each token id can only be minted as set by maxPerWallet for each card.
    mapping(address => uint256) public purchaseTxsStandard;
    mapping(address => uint256) public purchaseTxsEpic;
    mapping (address => uint256) public purchaseTxsLegendary;
    
    constructor(
        string memory uriBase,
        string memory uriStandard,
        string memory uriEpic,
        string memory uriLegendary,
        string memory _name,
        string memory _symbol
    ) ERC1155(uriBase) {
        name_ = _name;
        symbol_ = _symbol;

        tokenURI[TOKEN_ID_STANDARD] = uriStandard;
        tokenURI[TOKEN_ID_EPIC] = uriEpic;
        tokenURI[TOKEN_ID_LEGENDARY] = uriLegendary;
    }

    // Modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
      * @notice Set the config for Standard Card
      *
      * @param _tokenPrice - price of each token
      * @param _maxTokens - max number of tokens in given card
      * @param _maxPerWallet - max allowed per wallet
      */
    function setStandardConfig(
        uint64 _tokenPrice,
        uint32 _maxTokens,
        uint32 _maxPerWallet
    ) external onlyOwner {
        standardConfig = StandardConfig(
            _tokenPrice,
            _maxTokens,
            standardConfig.isPreSaleActive,
            standardConfig.isPublicSaleActive,
            _maxPerWallet
        );
    }

    /**
      * @notice Set the config for Epic Card
      *
      * @param _tokenPrice - price of each token
      * @param _maxTokens - max number of tokens in given card
      * @param _maxPerWallet - max allowed per wallet
      */
    function setEpicConfig(
        uint64 _tokenPrice,
        uint32 _maxTokens,
        uint32 _maxPerWallet
    ) external onlyOwner {
        epicConfig = EpicConfig(
            _tokenPrice,
            _maxTokens,
            epicConfig.isPublicSaleActive,
            epicConfig.isPreSaleActive,
            _maxPerWallet
        );
    }

    /**
      * @notice Set the config for Legendary Card
      *
      * @param _tokenPrice - price of each token
      * @param _maxTokens - max number of tokens in given card
      * @param _maxPerWallet - max allowed per wallet
      */
    function setLegendaryConfig(
        uint64 _tokenPrice,
        uint32 _maxTokens,
        uint32 _maxPerWallet
    ) external onlyOwner {
        legendaryConfig = LegendaryConfig(
            _tokenPrice,
            _maxTokens,
            legendaryConfig.isPublicSaleActive,
            legendaryConfig.isPreSaleActive,
            _maxPerWallet
        );
    }

    /**
      * @notice edit the merkle root for early access sale
      *
      * @param _merkleRoot the new merkle root
      */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
      * @notice returns the metadata uri for a given id
      *
      * @param _tokenId tokenid of the card to get URI
      * @return tokenURI custom URI for given token id, if not set returns the base URI
      */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        // If no URI exists for the specific id requested, fallback to the default ERC-1155 URI.
        if (bytes(tokenURI[_tokenId]).length == 0) {
            return super.uri(_tokenId);
        }
        return tokenURI[_tokenId];
    }

    /**
      * @notice Set/Update URI for given token id
      *
      * @param newTokenURI new uri of the token to be updated
      * @param _tokenId token id of the card to update URI
      */
    function setURI(string memory newTokenURI, uint256 _tokenId) external onlyOwner {
        tokenURI[_tokenId] = newTokenURI;
    }

    /**
      * @notice Set the global default ERC-1155 base URI to be used for any tokens without unique URIs
      *
      * @param newTokenURI the new base URI
      */
    function setGlobalURI(string memory newTokenURI) external onlyOwner {
        _setURI(newTokenURI);
    }

    /**
      * @notice Set Standard Public Sale state to true or false to make sale as active or inactive
      *
      * @param _isPublicSaleActive new sale state for Standard Card
      */
    function setStandardPublicSaleState(bool _isPublicSaleActive) external onlyOwner {
        require(standardConfig.isPublicSaleActive != _isPublicSaleActive, "New state is identical to current state");
        standardConfig.isPublicSaleActive = _isPublicSaleActive;
    }

    /**
      * @notice Set Standard Pre-Sale state to true or false to make sale as active or inactive
      *
      * @param _isPreSaleActive new pre-sale state for Standard Card
      */
    function setStandardPreSaleState(bool _isPreSaleActive) external onlyOwner {
        require(standardConfig.isPreSaleActive != _isPreSaleActive, "New state is identical to current state");
        standardConfig.isPreSaleActive = _isPreSaleActive;
    }

    /**
      * @notice Set Epic Public Sale state to true or false to make sale as active or inactive
      *
      * @param _isPublicSaleActive new sale state for Epic Card
      */
    function setEpicPublicSaleState(bool _isPublicSaleActive) external onlyOwner {
        require(epicConfig.isPublicSaleActive != _isPublicSaleActive, "New state is identical to current state");
        epicConfig.isPublicSaleActive = _isPublicSaleActive;
    }

    /**
      * @notice Set Epic Pre-Sale state to true or false to make sale as active or inactive
      *
      * @param _isPreSaleActive new pre-sale state for Epic Card
      */
    function setEpicPreSaleState(bool _isPreSaleActive) external onlyOwner {
        require(epicConfig.isPreSaleActive != _isPreSaleActive, "New state is identical to current state");
        epicConfig.isPreSaleActive = _isPreSaleActive;
    }

    /**
      * @notice Set Legendary Public Sale state to true or false to make sale as active or inactive
      *
      * @param _isPublicSaleActive new sale state for Legendary Card
      */
    function setLegendaryPublicSaleState(bool _isPublicSaleActive) external onlyOwner {
        require(legendaryConfig.isPublicSaleActive != _isPublicSaleActive, "New state is identical to current state");
        legendaryConfig.isPublicSaleActive = _isPublicSaleActive;
    }

    /**
      * @notice Set Legendary Pre-Sale state to true or false to make sale as active or inactive
      *
      * @param _isPreSaleActive new pre-sale state for Legendary Card
      */
    function setLegendaryPreSaleState(bool _isPreSaleActive) external onlyOwner {
        require(legendaryConfig.isPreSaleActive != _isPreSaleActive, "New state is identical to current state");
        legendaryConfig.isPreSaleActive = _isPreSaleActive;
    }

    /**
      * @notice allows users to purchase Standard membership card during early access sale
      *
      * @param numberOfTokens the amount of cards to purchase
      * @param merkleProof the valid merkle proof of sender to check early access eligibility
      */
    function ogStandardMint(
        uint256 numberOfTokens,
        bytes32[] calldata merkleProof
    ) external payable callerIsUser whenNotPaused {
        // Check if sale/pre-sale is active
        require(standardConfig.isPreSaleActive, "Pre Sale is not active");

        // check max per wallet is not exceeded
        uint256 maxPerWallet = uint256(standardConfig.maxPerWallet);
        require(numberOfTokens > 0 && numberOfTokens <= maxPerWallet, "Purchase amount prohibited");
        require(purchaseTxsStandard[msg.sender] + numberOfTokens <= maxPerWallet , "Minting amount exceeds max allowed per wallet");

        // Check if max supply reached
        require(totalSupply(TOKEN_ID_STANDARD) + numberOfTokens <= uint256(standardConfig.maxTokens), "Supply reached max tokens");

        // Check sent proof is part of the merkle tree
        bytes32 leafNode = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leafNode),
            "Invalid Proof"
        );

        _mint(msg.sender, TOKEN_ID_STANDARD, numberOfTokens, "");

        // update mapping to set wallet address has minted given number of tokens
        purchaseTxsStandard[msg.sender] += numberOfTokens;
    }

    /**
      * @notice allows users to purchase Standard membership card during public sale
      *
      * @param numberOfTokens the amount of cards to purchase
      */
    function publicStandardMint(uint256 numberOfTokens) external payable callerIsUser whenNotPaused {
        // Check if sale/pre-sale is active
        require(standardConfig.isPublicSaleActive, "Public Sale is not active");

        // check max per wallet is not exceeded
        uint256 maxPerWallet = uint256(standardConfig.maxPerWallet);
        require(numberOfTokens > 0 && numberOfTokens <= maxPerWallet, "Number of tokens prohibited");
        require(purchaseTxsStandard[msg.sender] + numberOfTokens <= maxPerWallet , "Number of tokens exceeds max allowed per wallet");

        // Check if max supply reached
        require(totalSupply(TOKEN_ID_STANDARD) + numberOfTokens <= uint256(standardConfig.maxTokens), "Supply reached max tokens");

        _mint(msg.sender, TOKEN_ID_STANDARD, numberOfTokens, "");

        // update mapping to set wallet address has minted given number of tokens
        purchaseTxsStandard[msg.sender] += numberOfTokens;
    }

    /**
      * @notice allows users to purchase Epic membership card during early access sale
      *
      * @param numberOfTokens the amount of cards to purchase
      * @param merkleProof the valid merkle proof of sender to check early access eligibility
      */
    function ogEpicMint(
        uint256 numberOfTokens,
        bytes32[] calldata merkleProof
    ) external payable callerIsUser whenNotPaused {
        // Check if sale/pre-sale is active
        require(epicConfig.isPreSaleActive, "Pre Sale is not active");

        // Check correct price is sent
        require(msg.value == numberOfTokens * uint256(epicConfig.tokenPrice), "Sent price is not correct");
        
        // check max per wallet is not exceeded
        uint256 maxPerWallet = uint256(epicConfig.maxPerWallet);
        require(numberOfTokens > 0 && numberOfTokens <= maxPerWallet, "Purchase amount prohibited");
        require(purchaseTxsEpic[msg.sender] + numberOfTokens <= maxPerWallet , "Minting amount exceeds max allowed per wallet");

        // Check if max supply reached
        require(totalSupply(TOKEN_ID_EPIC) + numberOfTokens <= uint256(epicConfig.maxTokens), "Supply reached max tokens");

        // Check sent proof is part of the merkle tree
        bytes32 leafNode = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leafNode),
            "Invalid Pro"
        );

        _mint(msg.sender, TOKEN_ID_EPIC, numberOfTokens, "");

        // update mapping to set wallet address has minted given number of tokens
        purchaseTxsEpic[msg.sender] += numberOfTokens;
    }

    /**
      * @notice allows users to purchase Epic membership card during public sale
      *
      * @param numberOfTokens the amount of cards to purchase
      */
    function publicEpicMint(uint256 numberOfTokens) external payable callerIsUser whenNotPaused {
        // Check if sale/pre-sale is active
        require(epicConfig.isPublicSaleActive, "Public Sale is not active");

        // Check correct price is sent
        require(msg.value == numberOfTokens * uint256(epicConfig.tokenPrice), "Sent price is not correct");

        // check max per wallet is not exceeded
        uint256 maxPerWallet = uint256(epicConfig.maxPerWallet);
        require(numberOfTokens > 0 && numberOfTokens <= maxPerWallet, "Number of tokens prohibited");
        require(purchaseTxsEpic[msg.sender] + numberOfTokens <= maxPerWallet , "Number of tokens exceeds max allowed per wallet");

        // Check if max supply reached
        require(totalSupply(TOKEN_ID_EPIC) + numberOfTokens <= uint256(epicConfig.maxTokens), "Supply reached max tokens");

        _mint(msg.sender, TOKEN_ID_EPIC, numberOfTokens, "");

        // update mapping to set wallet address has minted given number of tokens
        purchaseTxsEpic[msg.sender] += numberOfTokens;
    }

    /**
      * @notice purchase cards during early access sale
      *
      * @param numberOfTokens the amount of cards to purchase
      * @param merkleProof the valid merkle proof of sender
      */
    function ogLegendaryMint(
        uint256 numberOfTokens,
        bytes32[] calldata merkleProof
    ) external payable callerIsUser whenNotPaused {
        // Check if sale/pre-sale is active
        require(legendaryConfig.isPreSaleActive, "Pre Sale is not active");

        // Check correct price is sent
        require(msg.value == numberOfTokens * uint256(legendaryConfig.tokenPrice), "Sent price is not correct");
        
        // check max per wallet is not exceeded
        uint256 maxPerWallet = uint256(legendaryConfig.maxPerWallet);
        require(numberOfTokens > 0 && numberOfTokens <= maxPerWallet, "Purchase amount prohibited");
        require(purchaseTxsLegendary[msg.sender] + numberOfTokens <= maxPerWallet , "Minting amount exceeds max allowed per wallet");

        // Check if max supply reached
        require(totalSupply(TOKEN_ID_LEGENDARY) + numberOfTokens <= uint256(legendaryConfig.maxTokens), "Supply reached max tokens");

        // Check sent proof is part of the merkle tree
        bytes32 leafNode = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leafNode),
            "Invalid Pro"
        );

        _mint(msg.sender, TOKEN_ID_LEGENDARY, numberOfTokens, "");

        // update mapping to set wallet address has minted given number of tokens
        purchaseTxsLegendary[msg.sender] += numberOfTokens;
    }

    /**
      * @notice allows users to purchase Legendary membership card during public sale
      *
      * @param numberOfTokens the amount of cards to purchase
      */
    function publicLegendaryMint(uint256 numberOfTokens) external payable callerIsUser whenNotPaused {
       // Check if sale/pre-sale is active
        require(legendaryConfig.isPublicSaleActive, "Public Sale is not active");

        // Check correct price is sent
        require(msg.value == numberOfTokens * uint256(legendaryConfig.tokenPrice), "Sent price is not correct");

        // check max per wallet is not exceeded
        uint256 maxPerWallet = uint256(legendaryConfig.maxPerWallet);
        require(numberOfTokens > 0 && numberOfTokens <= maxPerWallet, "Number of tokens prohibited");
        require(purchaseTxsLegendary[msg.sender] + numberOfTokens <= maxPerWallet , "Number of tokens exceeds max allowed per wallet");

        // Check if max supply reached
        require(totalSupply(TOKEN_ID_LEGENDARY) + numberOfTokens <= uint256(legendaryConfig.maxTokens), "Supply reached max tokens");

        _mint(msg.sender, TOKEN_ID_LEGENDARY, numberOfTokens, "");

        // update mapping to set wallet address has minted given number of tokens
        purchaseTxsLegendary[msg.sender] += numberOfTokens;
    }

    /**
      * @notice Allow minting of any new future tokens if needed as part of the same collection,
      * which can then be transferred to another contract for distribution purposes
      *
      * @param account which address to mint to
      * @param _tokenId new token id to create
      * @param numberOfTokens number of tokens to mint
      */
    function futureMint(address account, uint256 _tokenId, uint256 numberOfTokens) external onlyOwner
    {
        require(_tokenId != TOKEN_ID_STANDARD && _tokenId != TOKEN_ID_EPIC && _tokenId != TOKEN_ID_LEGENDARY, "Existing token ID prohibited");
        _mint(account, _tokenId, numberOfTokens, "");
    }

    /**
      * @notice Allow minting of tokens for the giveaways by owner
      * This function doesnt have any checks applied as it is only called by the owner saves gas
      *
      * @param account which address to mint to
      * @param _tokenId new token id to create
      * @param numberOfTokens number of tokens to mint
      */
    function giveawayMint(address account, uint256 _tokenId, uint256 numberOfTokens) external onlyOwner {
        _mint(account, _tokenId, numberOfTokens, "");
    }

    /**
      * @notice Override ERC1155 such that zero amount token transfers are disallowed to prevent arbitrary creation of new tokens in the collection.
      * @dev overrided _beforeTokenTransfer(added in abstract contract file) to prevent transfer of token when contract is paused, in emergency cases
      *
      * @param from address of sender
      * @param to address of receiver
      * @param _tokenID token id
      * @param numberOfTokens number of tokens to transfer
      * @param data data
      */
    function safeTransferFrom(
        address from,
        address to,
        uint256 _tokenID,
        uint256 numberOfTokens,
        bytes memory data
    ) public override {
        require(numberOfTokens > 0, "Number of tokens must be greater than 0");
        return super.safeTransferFrom(from, to, _tokenID, numberOfTokens, data);
    }

    /**
      * @notice withdraw funds from the contract to owner
      */
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
      * @notice withdraw funds from the contract to given wallet address
      * Allows owner to distribute fund to different charity wallets
      *
      * @param to_ withdraw amount to
      */
    function withdrawTo(address payable to_) external onlyOwner {
        (bool success, ) = payable(to_).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
