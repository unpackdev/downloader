// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

/**
   _____ _______     _______ _______ ____    ____  ______          _____   _____    _____         _      ______ 
  / ____|  __ \ \   / /  __ \__   __/ __ \  |  _ \|  ____|   /\   |  __ \ / ____|  / ____|  /\   | |    |  ____|
 | |    | |__) \ \_/ /| |__) | | | | |  | | | |_) | |__     /  \  | |__) | (___   | (___   /  \  | |    | |__   
 | |    |  _  / \   / |  ___/  | | | |  | | |  _ <|  __|   / /\ \ |  _  / \___ \   \___ \ / /\ \ | |    |  __|  
 | |____| | \ \  | |  | |      | | | |__| | | |_) | |____ / ____ \| | \ \ ____) |  ____) / ____ \| |____| |____ 
  \_____|_|  \_\ |_|  |_|      |_|  \____/  |____/|______/_/    \_\_|  \_\_____/  |_____/_/    \_\______|______|                                                                                                                                                                                                                                                                                                                                  
 */

import "./IERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @notice Represents NFT Smart Contract
 */
contract ICryptoBearsERC721 {
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
 * @title CryptoBearsPreSaleContract.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract can be used to sell any fixed amount of NFTs where only permissioned
 * wallets are allowed to buy. Buying is limited to a certain time period.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract CryptoBearsPreSaleContract is Ownable {

    /** 
     * @notice The Smart Contract of the NFT being sold 
     * @dev ERC-721 Smart Contract 
     */
    ICryptoBearsERC721 public immutable nft;

    /**
     * @notice Crypto Bull Society NFT address
     */
    address public immutable bulls;
    
    /** 
     * @dev MINT DATA 
     */
    uint256 public startTimeWhitelist = 1644606000 - 120;
    uint256 public startTimeOpen = 1644607800 - 120;    

    uint256 public price = 0.22 ether;
    uint256 public maxSupply = 1111 - 60;
    uint256 public minted = 0;
    mapping(address => uint256) public addressToMints;

     /** 
      * @dev MERKLE ROOTS 
      */
    bytes32 public merkleRoot = 0xe0527f3c118a535e787f66f0358f3a3a72d4dbb7f3b9adc70be4816855d041aa;

    /**
     * @dev CLAIMING
     */
    uint256 public claimStart = 1644692400;
    mapping(uint256 => uint256) hasBullClaimed; // 0 = false | 1 = true

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
    event Claim(address indexed claimer, uint256 indexed amount);
    event setStartTimeOpenEvent(uint256 indexed startTime);
    event setStartTimeWhitelistEvent(uint256 indexed startTime);
    event setPriceEvent(uint256 indexed price);
    event setMaxSupplyEvent(uint256 indexed maxSupply);
    event setClaimStartEvent(uint256 indexed time);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _nftaddress
    ) Ownable() {
        nft = ICryptoBearsERC721(_nftaddress);
        bulls = 0x469823c7B84264D1BAfBcD6010e9cdf1cac305a3;
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
     * @param mintMaxAmount. The max amount the user can mint.
     * @param phase. The phase of the sale.
     * @param proof. The Merkle Proof of the user.
     */
    function buy(uint256 amount, uint256 mintMaxAmount, uint256 phase, bytes32[] calldata proof) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, mintMaxAmount, phase));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can mint based on the provided parameters.   

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");
        
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(amount <= nft.maxMintPerTransaction(), "CANNOT MINT MORE PER TX");
        require(addressToMints[msg.sender] + amount <= mintMaxAmount, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(minted + amount <= maxSupply, "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= price * amount, "ETHER SENT NOT CORRECT");

        /// @dev allow minting at two different times
        if (phase == 1) {
            require(block.timestamp >= startTimeWhitelist, "SALE HASN'T STARTED YET");
        } else if (phase == 2) {
            require(block.timestamp >= startTimeOpen, "SALE HASN'T STARTED YET");
        } else {
            revert("INCORRECT PHASE");
        }

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet

        minted += amount;
        addressToMints[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount);
    }

    /**
     * @dev CLAIMING
     */

    /**
     * @notice Claim bears by providing your crypto bull Ids
     * @dev Mints amount of bears to sender as valid crypto bulls 
     * provided. Validity depends on ownership and not having claimed yet.
     *
     * @param bullIds. The tokenIds of the bulls.
     */
    function claimBears(uint256[] calldata bullIds) external onlyOwner {
        require(address(nft) != address(0), "BEARS NFT NOT SET");
        require(bulls != address(0), "BULLS NFT NOT SET");
        require(bullIds.length > 0, "NO IDS SUPPLIED");
        require(block.timestamp >= claimStart, "CANNOT CLAIM YET");

        /// @dev Check if sender is owner of all bulls and that they haven't claimed yet
        /// @dev Update claim status of each bull
        for (uint256 i = 0; i < bullIds.length; i++) {
            uint256 bullId = bullIds[i];
            require(IERC721( bulls ).ownerOf(bullId) == msg.sender, "NOT OWNER OF BULL");
            require(hasBullClaimed[bullId] == 0, "BULL HAS ALREADY CLAIMED BEAR");
            hasBullClaimed[bullId] = 1;
        }

        nft.mintTo(bullIds.length, msg.sender);
        emit Claim(msg.sender, bullIds.length);
    }

    /**
     * @notice View which of your bulls can still claim bears
     * @dev Given an array of bull ids returns a subset of ids that
     * can still claim a bear. Used off chain to provide input of claimBears method.
     *
     * @param bullIds. The tokenIds of the bulls.
     */
    function getNotClaimedBullsOfOwner(uint256[] calldata bullIds) external view returns (uint256[] memory) {
        require(bullIds.length > 0, "NO IDS SUPPLIED");

        uint256[] memory notClaimedBulls;
        uint256 counter;

        /// @dev Check if sender is owner of all bulls and that they haven't claimed yet
        /// @dev Update claim status of each bull
        for (uint256 i = 0; i < bullIds.length; i++) {
            uint256 bullId = bullIds[i];
            require(IERC721( bulls ).ownerOf(bullId) == msg.sender, "NOT OWNER OF BULL");            
            if (hasBullClaimed[bullId] == 0) {
                notClaimedBulls[counter] = bullId;
                counter++;
            }
        }

        return notClaimedBulls;
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the start time of the raffle sale.
     *
     * @param newStartTime. The new start time.
     */
    function setStartTimeOpen(uint256 newStartTime) external onlyOwner {
        startTimeOpen = newStartTime;
        emit setStartTimeOpenEvent(newStartTime);
    }

    /**
     * @notice Change the start time of the whitelist sale.
     *
     * @param newStartTime. The new start time.
     */
    function setStartTimeWhiteList(uint256 newStartTime) external onlyOwner {
        startTimeWhitelist = newStartTime;
        emit setStartTimeWhitelistEvent(newStartTime);
    }

    /**
     * @notice Change the price of the sale.
     *
     * @param newPrice. The new price.
     */
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit setPriceEvent(newPrice);
    }

    /**
     * @notice Change the startime for bulls to claim their bears;
     *
     * @param newStart. The new start time.
     */
    function setClaimStart(uint256 newStart) external onlyOwner {
        claimStart = newStart;
        emit setClaimStartEvent(newStart);
    }

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