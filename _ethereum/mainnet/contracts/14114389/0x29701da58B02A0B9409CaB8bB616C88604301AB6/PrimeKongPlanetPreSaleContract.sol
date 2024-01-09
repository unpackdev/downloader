// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

/**
  _____  _____  _____ __  __ ______   _  ______  _   _  _____   _____  _               _   _ ______ _______    _____         _      ______ 
 |  __ \|  __ \|_   _|  \/  |  ____| | |/ / __ \| \ | |/ ____| |  __ \| |        /\   | \ | |  ____|__   __|  / ____|  /\   | |    |  ____|
 | |__) | |__) | | | | \  / | |__    | ' / |  | |  \| | |  __  | |__) | |       /  \  |  \| | |__     | |    | (___   /  \  | |    | |__   
 |  ___/|  _  /  | | | |\/| |  __|   |  <| |  | | . ` | | |_ | |  ___/| |      / /\ \ | . ` |  __|    | |     \___ \ / /\ \ | |    |  __|  
 | |    | | \ \ _| |_| |  | | |____  | . \ |__| | |\  | |__| | | |    | |____ / ____ \| |\  | |____   | |     ____) / ____ \| |____| |____ 
 |_|    |_|  \_\_____|_|  |_|______| |_|\_\____/|_| \_|\_____| |_|    |______/_/    \_\_| \_|______|  |_|    |_____/_/    \_\______|______|                                                                                                                                                                                                                                                                                                                                                               
                             
 */

import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @notice Represents PrimeKongPlanetERC721 Smart Contract
 */
contract IPrimeKongPlanetERC721 {
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
 * @title PrimeKongPlanetPreSaleContract.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract can be used to sell any fixed amount of NFTs where only permissioned
 * wallets are allowed to buy. Buying is limited to a certain time period.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract PrimeKongPlanetPreSaleContract is Ownable {

    /** 
     * @notice The Smart Contract of the NFT being sold 
     * @dev ERC-721 Smart Contract 
     */
    IPrimeKongPlanetERC721 public immutable nft;
    
    /** 
     * @dev MINT DATA 
     */
    uint256 public maxSupply = 9797 - 350;
    uint256 public minted = 0;
    mapping(address => uint256) public addressToMints;

     /** 
      * @dev MERKLE ROOTS 
      */
    bytes32 public merkleRoot = "";

    /**
     * @dev DEVELOPER
     */
    address public immutable devAddress;
    uint256 public immutable devShare;
    
    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount);
    event setMaxSupplyEvent(uint256 indexed maxSupply);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _nftaddress
    ) Ownable() {
        nft = IPrimeKongPlanetERC721(_nftaddress);
        devAddress = 0x841d534CAa0993c677f21abd8D96F5d7A584ad81;
        devShare = 1;
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
    function buy(uint256 amount, uint256 mintStart, uint256 mintEnd, uint256 mintPrice, uint256 mintMaxAmount, bytes32[] calldata proof) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, mintStart, mintEnd, mintPrice, mintMaxAmount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can mint based on the provided parameters.   

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");

        require(block.timestamp >= mintStart, "SALE HASN'T STARTED YET");
        require(block.timestamp < mintEnd, "SALE IS CLOSED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(amount <= nft.maxMintPerTransaction(), "CANNOT MINT MORE PER TX");
        require(addressToMints[_msgSender()] + amount <= mintMaxAmount, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(minted + amount <= maxSupply, "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value == mintPrice * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet

        minted += amount;
        addressToMints[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount);
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the maximum supply of NFTs that are for sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit setMaxSupplyEvent(newMaxSupply);
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

        uint256 developerCut = contractBalance * devShare / 100;
        uint remaining = contractBalance - developerCut;

        payable(devAddress).transfer(developerCut);
        payable(_to).transfer(remaining);

        emit WithdrawAllEvent(_to, remaining);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}