// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

/**
  __  __ ______ _______        _____    __      _______ ____  _____   _____    _____         _      ______ 
 |  \/  |  ____|__   __|/\    / ____|  /\ \    / /_   _/ __ \|  __ \ / ____|  / ____|  /\   | |    |  ____|
 | \  / | |__     | |  /  \  | (___   /  \ \  / /  | || |  | | |__) | (___   | (___   /  \  | |    | |__   
 | |\/| |  __|    | | / /\ \  \___ \ / /\ \ \/ /   | || |  | |  _  / \___ \   \___ \ / /\ \ | |    |  __|  
 | |  | | |____   | |/ ____ \ ____) / ____ \  /   _| || |__| | | \ \ ____) |  ____) / ____ \| |____| |____ 
 |_|  |_|______|  |_/_/    \_\_____/_/    \_\/   |_____\____/|_|  \_\_____/  |_____/_/    \_\______|______|                                                                                                                                                                                                                                                                                                
                             
 */

import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @notice Represents NFT Smart Contract
 */
contract IMetaSaviorsERC721 {
    /** 
     * @dev ERC-721 INTERFACE 
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** 
     * @dev CUSTOM INTERFACE 
     */
    function mintTo(uint256 amount, address _to) external {}
    function maxMintPerTransaction() public returns (uint256) {}
}

/**
 * @title MetaSaviorsPreSaleLimitedContract.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract can be used to sell a fixed amount of NFTs where some of them are 
 * sold to permissioned wallets and the others are sold to the general public.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract MetaSaviorsPreSaleLimitedContract is Ownable {

    /** 
     * @notice The Smart Contract of the NFT being sold 
     * @dev ERC-721 Smart Contract 
     */
    IMetaSaviorsERC721 public immutable nft;
    
    /** 
     * @dev MINT DATA 
     */
    uint256 public reserved = 150;
    uint256 public maxSupplyPermissioned = 2500;
    uint256 public maxSupplyOpen = 8004 - maxSupplyPermissioned - reserved;
    
    uint256 public mintedPermissioned = 0;
    uint256 public mintedOpen = 0;

    uint256 public limitOpen = 2;

    uint256 public priceOpen = 0.18 ether;

    bool public isOpen = false;
    
    mapping(address => uint256) public addressToMintsPermissioned;
    mapping(address => uint256) public addressToMints;

     /** 
      * @dev MERKLE ROOTS 
      *
      * @dev Initial value is randomly generated from https://www.random.org/
      */
    bytes32 public merkleRoot = "";

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount, bool indexed permissioned);
    event setMaxSupplyPermissionedEvent(uint256 indexed maxSupply);
    event setMaxSupplyOpenEvent(uint256 indexed maxSupply);
    event setLimitOpenEvent(uint256 indexed limit);
    event setPriceOpenEvent(uint256 indexed price);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event setIsOpenEvent(bool indexed open);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _nftaddress
    ) Ownable() {
        nft = IMetaSaviorsERC721(_nftaddress);
    }
 
    /**
     * @dev SALE
     */

    /**
     * @notice Function to buy one or more NFTs.
     * @dev First the Merkle Proof is verified.
     * Then the mint is verified with the data embedded in the Merkle Proof.
     * Finally the NFTs are minted to the user's wallet.
     *
     * @param amount. The amount of NFTs to buy.
     * @param mintStart. The start date of the mint.
     * @param mintEnd. The end date of the mint.
     * @param mintPrice. The mint price for the user.
     * @param mintMaxAmount. The max amount the user can mint.
     * @param proof. The Merkle Proof of the user.
     */
    function buyPermissioned(uint256 amount, uint256 mintStart, uint256 mintEnd, uint256 mintPrice, uint256 mintMaxAmount, bytes32[] calldata proof) 
        external 
        payable {        

        /// @dev Verifies that user can perform permissioned mint based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");

        require(block.timestamp >= mintStart, "PERMISSIONED SALE HASN'T STARTED YET");
        require(block.timestamp < mintEnd, "PERMISSIONED SALE IS CLOSED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(amount <= nft.maxMintPerTransaction(), "CANNOT MINT MORE PER TX");
        require(addressToMintsPermissioned[_msgSender()] + amount <= mintMaxAmount, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(mintedPermissioned + amount <= maxSupplyPermissioned, "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= mintPrice * amount, "ETHER SENT NOT CORRECT");

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, mintStart, mintEnd, mintPrice, mintMaxAmount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet

        mintedPermissioned += amount;
        addressToMintsPermissioned[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount, true);
    }

    /**
     * @notice Function to buy one or more NFTs.
     *
     * @param amount. The amount of NFTs to buy.
     */
    function buyOpen(uint256 amount) 
        external 
        payable {
        
        /// @dev Verifies that user can perform open mint based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(isOpen, "OPEN SALE CLOSED");

        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(amount <= nft.maxMintPerTransaction(), "CANNOT MINT MORE PER TX");

        require(addressToMints[_msgSender()] + amount <= limitOpen, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(mintedOpen + amount <= maxSupplyOpen, "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= priceOpen * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet
        
        mintedOpen += amount;
        addressToMints[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount, false);
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the maximum supply of NFTs that are for sale in permissioned sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyPermissioned(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPermissioned = newMaxSupply;
        emit setMaxSupplyPermissionedEvent(newMaxSupply);
    }

    /**
     * @notice Change the maximum supply of NFTs that are for sale in open sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyOpen(uint256 newMaxSupply) external onlyOwner {
        maxSupplyOpen = newMaxSupply;
        emit setMaxSupplyOpenEvent(newMaxSupply);
    }

    /**
     * @notice Change the limit of NFTs per wallet in open sale.
     *
     * @param newLimitOpen. The new max supply.
     */
    function setLimitOpen(uint256 newLimitOpen) external onlyOwner {
        limitOpen = newLimitOpen;
        emit setLimitOpenEvent(newLimitOpen);
    }

    /**
     * @notice Change the price of NFTs that are for sale in open sale.
     *
     * @param newPriceOpen. The new max supply.
     */
    function setPriceOpen(uint256 newPriceOpen) external onlyOwner {
        priceOpen = newPriceOpen;
        emit setPriceOpenEvent(newPriceOpen);
    }

    /**
     * @notice Change the merkleRoot of the sale.
     *
     * @param newRoot. The new merkleRoot.
     */
    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
        emit setMerkleRootEvent(newRoot);
    }

    /**
     * @notice Change the state of the sale.
     *
     * @param open. The new state.
     */
    function setIsOpen(bool open) external onlyOwner {
        isOpen = open;
        emit setIsOpenEvent(open);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale.
     *
     * @param _to. The address to send the funds to.
     */
    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        
        payable(_to).transfer(contractBalance);

        emit WithdrawAllEvent(_to, contractBalance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}