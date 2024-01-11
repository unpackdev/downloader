// SPDX-License-Identifier: MIT

// 888b     d888 8888888888 .d8888b.        .d8888b.  8888888888 888b    888 8888888888 .d8888b. 8888888 .d8888b.  
// 8888b   d8888 888       d88P  Y88b      d88P  Y88b 888        8888b   888 888       d88P  Y88b  888  d88P  Y88b 
// 88888b.d88888 888       888    888      888    888 888        88888b  888 888       Y88b.       888  Y88b.      
// 888Y88888P888 8888888   888             888        8888888    888Y88b 888 8888888    "Y888b.    888   "Y888b.   
// 888 Y888P 888 888       888  88888      888  88888 888        888 Y88b888 888           "Y88b.  888      "Y88b. 
// 888  Y8P  888 888       888    888      888    888 888        888  Y88888 888             "888  888        "888 
// 888   "   888 888       Y88b  d88P      Y88b  d88P 888        888   Y8888 888       Y88b  d88P  888  Y88b  d88P 
// 888       888 8888888888 "Y8888P88       "Y8888P88 8888888888 888    Y888 8888888888 "Y8888P" 8888888 "Y8888P"

/// @title MysteryEgg
/// @author Manuel (ManuelH#0001)


pragma solidity ^ 0.8 .9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract MysteryEgg is ERC721A, Ownable {
	// Variables
	using Strings for uint256;

        uint256 private constant maxSupply = 1206;
	// --- Merkle Roots ---

	bytes32 public RaffleSaleMerkleRoot;
	bytes32 public PreSaleMerkleRoot;
	// This is for whitelists, used to save gas!

	// --- Sale status --- //

	bool public isPreSaleActive = false;
	bool public isRaffleSaleActive = false;
	bool public isPublicSaleActive = false;
	// They are all on false to make sure on deployment no one can mint //

	// --- MetaData --- //

	bool public isRevealed = false; // Makes sure the collection does not reveal directly after minting;
	string public HiddenMetadataURI; //  Unrevealed metadata URI
	string public BaseURI; // Revealed metadata URI

	// --- Safety matter --- //

	bool public isContractPaused; // If contract is corrupt, pause it to prevent anyone from minting / putting out any transaction.

	// --- Prices --- //
	uint256 public isPresaleCost = 70000000000000000;
	uint256 public isRaffleCost = 70000000000000000;
	uint256 public isPublicCost = 70000000000000000;
	// Costs per mint

	// --- Max mints --- //

	uint8 public isMaxPresaleMints = 3;
	uint8 public isMaxRaffleSaleMints = 1;
	uint8 public isMaxPublicSaleMints = 1;
    // Max mints per wallet

    // --- Mapping addresses that minted/details --- //

    mapping(address => uint256) public hasPresaleMinted;
    mapping(address => uint256) public hasRaffleMinted;
    mapping(address => uint256) public hasPublicMinted;


	// --- Payment addresses --- //

	address private constant team = 0xB938D59B63cB6ebAE47F5c0d85FbfB506395b4c8;

    constructor() ERC721A("Mystery Egg Genesis", "MEG") { }


    /**
     * @notice Blocks contracts from minting (bots) and disables mint functions when paused.
     */
	modifier transactionCheck() {
        require(tx.origin == msg.sender, "CALLER_IS_CONTRACT");
        require(!isContractPaused, "CONTRACT_PAUSED");
        _;
    }

    /**
     * @notice Mints for free in batch for the Team. (Only owner)
     */
    function mintTeam(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "MAX_SUPPLY_REACHED");
        _safeMint(owner(), _quantity);
    }

    /**
     * @notice Mints in the PreSale Sale based on the MerkleRoot, validation has to be proved using Proofs, quantity needs to be given aswell.
     */
    function mintPreSale(uint256 _quantity, bytes32[] calldata proof) external payable transactionCheck() {
        require(isPreSaleActive, "PRE_SALE_INACTIVE");
        require(msg.value == isPresaleCost * _quantity, "WRONG_ETH_AMOUNT");
        require(hasPresaleMinted[msg.sender] + _quantity <= isMaxPresaleMints, "MAX_MINTED_BY_ADDRESS");
        require(totalSupply() + _quantity <= maxSupply, "MAX_SUPPLY_REACHED");

        require(MerkleProof.verify(proof, PreSaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "INVALID_PROOF");
        hasPresaleMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Mints in the Raffle Sale based on the MerkleRoot, validation has to be proved using Proofs, quantity needs to be given aswell.
     */
    function mintRaffleSale(uint256 _quantity, bytes32[] calldata proof) external payable transactionCheck() {
        require(isRaffleSaleActive, "RAFFLE_SALE_INACTIVE");
        require(msg.value == isRaffleCost * _quantity, "WRONG_ETH_AMOUNT");
        require(hasRaffleMinted[msg.sender] + _quantity <= isMaxRaffleSaleMints, "MAX_MINTED_BY_ADDRESS");
        require(totalSupply() + _quantity <= maxSupply, "MAX_SUPPLY_REACHED");

        require(MerkleProof.verify(proof, RaffleSaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "INVALID_PROOF");
        hasRaffleMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Mints in public sale the given quantity.
     */
    function mintPublicSale(uint256 _quantity) external payable transactionCheck() {
        require(isPublicSaleActive, "PUBLIC_SALE_INACTIVE");
        require(msg.value == isPublicCost * _quantity, "WRONG_ETH_AMOUNT");
        require(hasPublicMinted[msg.sender] + _quantity <= isMaxPublicSaleMints, "MAX_MINTED_BY_ADDRESS");

        require(totalSupply() + _quantity <= maxSupply, "MAX_SUPPLY_REACHED");
        hasPublicMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Get's the metadata URI using the token id.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for non-existent token");
        if (!isRevealed) {
            return HiddenMetadataURI;
        } else {
            return string(abi.encodePacked(BaseURI, _tokenId.toString()));
        }
    }

    /** 
    *   @notice first token ID will become 1;
    */
    function _startTokenId() internal view virtual override(ERC721A) returns(uint256) {
        return 1;
    }

    // --- Mint Setters --- //

    /**
     * @notice Sets all details for the Presale mints. (merkle root, price, max mints)
     */
    function setPreSaleDetails(bytes32 _root, uint256 _price, uint8 _maxMint) external onlyOwner {
        PreSaleMerkleRoot = _root;
        isPresaleCost = _price;
        isMaxPresaleMints = _maxMint;
    }
    /**
     * @notice Sets all details for the Raffle mints. (merkle root, price, max mints)
     */
    function setRaffleSaleDetails(bytes32 _root, uint256 _price, uint8 _maxMint) external onlyOwner {
        RaffleSaleMerkleRoot = _root;
        isRaffleCost = _price;
        isMaxRaffleSaleMints = _maxMint;
    }
    /**
     * @notice Sets all details for the public mints. (price, max mints)
     */
    function setPublicSaleDetails(uint256 _price, uint8 _maxMint) external onlyOwner {
        isPublicCost = _price;
        isMaxPublicSaleMints = _maxMint;
    }

    // --- Sale statuses --- //

    /**
     * @notice Activates the PreSale, will do the opposite of the current status. (Only owner)
     */
    function togglePreSaleActive() external onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }
    /**
     * @notice Activates the RaffleSale, will do the opposite of the current status. (Only owner)
     */
    function toggleRaffleSaleActive() external onlyOwner {
        isRaffleSaleActive = !isRaffleSaleActive;
    }
    /**
     * @notice Activates the PublicSale , will do the opposite of the current status. (Only owner)
     */
    function togglePublicSaleActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    // --- Revealing --- //

    /**
    * @notice Reveals the collection, need to give the BaseURI to no longer hide metadata, will update on OpenSea. (Only owner)
    */
    function setRevealer(string memory URI) external onlyOwner {
        BaseURI = URI;
        isRevealed = !isRevealed;
    }

    function SetHiddenMetadataURI(string memory URI) external onlyOwner {
        HiddenMetadataURI = URI;
    }

    /**
     * @notice Pauses the contract partically, no minting allowed.
     */
    function contractPause() external onlyOwner {
        isContractPaused = !isContractPaused;
    }

    // --- Final withdrawal of all funds --- //

    /**
    * @notice Withdraws money out of the contract to the dedicated wallets. (Only owner)
    */
    function withdrawal() external onlyOwner {
        (bool os, ) = payable(team).call {
            value: address(this).balance
        } ("");
        require(os);
    }
}