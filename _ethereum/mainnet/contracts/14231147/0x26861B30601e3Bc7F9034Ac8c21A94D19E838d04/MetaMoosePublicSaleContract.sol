// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @notice Represents NFT Smart Contract
 */
contract IMetaMooseERC721 {
    /** 
     * @dev ERC-721 INTERFACE 
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** 
     * @dev CUSTOM INTERFACE 
     */
    function mintTo(uint256 amount, address _to) external {}
}

/**
 * @title MetaMoosePublicSaleContract.
 *
 * @notice This Smart Contract can be used to sell a fixed amount of NFTs where some of them are 
 * sold to permissioned wallets and the others are sold to the general public.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract MetaMoosePublicSaleContract is Ownable {

    /** 
     * @notice The Smart Contract of the NFT being sold 
     * @dev ERC-721 Smart Contract 
     */
    IMetaMooseERC721 public immutable nft;
    
    /** 
     * @dev MINT DATA 
     */
    uint256 public maxSupplyPermissioned = 8888;
    uint256 public maxSupplyOpen = 0;
    
    uint256 public mintedPermissioned = 0;
    uint256 public mintedOpen = 0;

    uint256 public limitOpen = 4;
    uint256 public limitPermissioned = 4;

    uint256 public pricePermissioned = 0.18 ether;
    uint256 public priceOpen = 0.18 ether;

    uint256 public startPermissioned = 1645203600 - 120;
    uint256 public durationPermissioned = 22 hours;
    bool public startOpen;
    
    mapping(address => uint256) public addressToMints;
    mapping(address => uint256) public addressToMintsPermissioned;

     /** 
      * @dev MERKLE ROOTS 
      *
      * @dev Initial value is randomly generated from https://www.random.org/
      */
    bytes32 public merkleRoot = 0x7d7fafd8ba617696e24b9f85e3f648449cb53865837245c8fee8a2a3222d2038;

    /**
     * @dev DEVELOPER
     */
    address public immutable devAddress;
    uint256 public immutable devShare;

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount, bool indexed permissioned);
    event setMaxSupplyPermissionedEvent(uint256 indexed maxSupply);
    event setMaxSupplyOpenEvent(uint256 indexed maxSupply);
    event setLimitOpenEvent(uint256 indexed limit);
    event setLimitPermissionedEvent(uint256 indexed limit);
    event setPricePermissionedEvent(uint256 indexed price);
    event setPriceOpenEvent(uint256 indexed price);
    event setStartTimePermissionedEvent(uint256 indexed startTime);
    event setDurationPermissionedEvent(uint256 indexed duration);
    event setStartOpenEvent(bool indexed open);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _nftaddress
    ) Ownable() {
        nft = IMetaMooseERC721(_nftaddress);
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
     * @param proof. The Merkle Proof of the user.
     */
    function buyPermissioned(uint256 amount, bytes32[] calldata proof) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can perform permissioned mint based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");

        require(block.timestamp >= startPermissioned, "PERMISSIONED SALE HASN'T STARTED YET");
        require(block.timestamp < startPermissioned + durationPermissioned, "PERMISSIONED SALE IS CLOSED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        
        require(addressToMintsPermissioned[msg.sender] + amount <= limitPermissioned, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(mintedPermissioned + amount <= maxSupplyPermissioned, "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= pricePermissioned * amount, "ETHER SENT NOT CORRECT");

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
        require(startOpen, "OPEN SALE CLOSED");

        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(addressToMints[msg.sender] + amount <= limitOpen, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(mintedOpen + amount <= maxSupplyOpen, "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= priceOpen * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet
        
        mintedOpen += amount;
        addressToMints[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount, false);
    }

    /**
     * @dev VIEW
     */

    /**
     * @dev Returns the total amount of NFTs minted 
     * accross all phases.
     */
    function totalMinted() external view returns(uint256) {
        return mintedOpen + mintedPermissioned;
    }

    /**
     * @dev Returns the total amount of NFTs minted 
     * accross all phases by a specific wallet.
     */
    function totalMintedByAddress(address user) external view returns(uint256) {
        return addressToMints[user] + addressToMintsPermissioned[user];
    }

    /**
     * @dev Returns the total amount of NFTs left
     * accross all phases.
     */
    function nftsLeft() external view returns(uint256) {
        return maxSupplyOpen - mintedOpen + maxSupplyPermissioned - mintedPermissioned;
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
     * @notice Change the limit of NFTs per wallet in permissioned sale.
     *
     * @param newLimitPermissioned. The new max supply.
     */
    function setLimitPermissioned(uint256 newLimitPermissioned) external onlyOwner {
        limitPermissioned = newLimitPermissioned;
        emit setLimitPermissionedEvent(newLimitPermissioned);
    }

    /**
     * @notice Change the price of NFTs that are for sale in open sale.
     *
     * @param newPricePermissioned. The new max supply.
     */
    function setPricePermissioned(uint256 newPricePermissioned) external onlyOwner {
        pricePermissioned = newPricePermissioned;
        emit setPriceOpenEvent(newPricePermissioned);
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
     * @notice Change the startTime of the permissioned sale.
     *
     * @param startTime. The new start time.
     */
    function setStartTimePermissioned(uint256 startTime) external onlyOwner {
        startPermissioned = startTime;
        emit setStartTimePermissionedEvent(startTime);
    }

    /**
     * @notice Change the duration of the permissioned sale.
     *
     * @param duration. The new duration.
     */
    function setDurationPermissioned(uint256 duration) external onlyOwner {
        durationPermissioned = duration;
        emit setDurationPermissionedEvent(duration);
    }

   /**
     * @notice Change the state of the open sale.
     *
     * @param open. The new state.
     */
    function setStartOpen(bool open) external onlyOwner {
        startOpen = open;
        emit setStartOpenEvent(open);
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