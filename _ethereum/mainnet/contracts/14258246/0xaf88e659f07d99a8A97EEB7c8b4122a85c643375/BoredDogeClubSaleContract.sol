// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./Ownable.sol";
import "./IERC721.sol";
import "./MerkleProof.sol";

/**
 * @notice Represents NFT Smart Contract
 */
contract IBoredDogeClubERC721 {
    /** 
     * @dev ERC-721 INTERFACE 
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** 
     * @dev CUSTOM INTERFACE 
     */
    function mintTo(uint256 amount, address _to) external {}
    function getNextTokenId() external view returns(uint256) {}
    function exists(uint256 tokenId) external view returns(bool) {}
}

/**
 * @title BoredDogeClubSaleContract.
 *
 * @notice This Smart Contract can be used to sell a fixed amount of NFTs where some of them are 
 * sold to permissioned wallets and the others are sold to the general public.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract BoredDogeClubSaleContract is Ownable {

    /** 
     * @notice The Smart Contract of the NFT being sold 
     * @dev ERC-721 Smart Contract 
     */
    IBoredDogeClubERC721 public immutable boredDoge;

    /**
     * @dev Mutant Doge Address
     */
    address public MutantDoge;
    
    /** 
     * @dev MINT DATA 
     */
    uint256 public totalSupply = 5000;
    uint256 public maxSupplyPermissioned = 5000;
    
    uint256 public mintedPermissioned = 0;
    uint256 public mintedOpen = 0;

    uint256 public limitOpen = 5;

    uint256 public pricePermissioned = 0.1 ether;
    uint256 public priceOpen = 0.1 ether;

    uint256 public startPermissioned = 1645632000;
    uint256 public durationPermissioned = 365 days;
    bool public isStartedOpen;
    
    mapping(address => mapping(uint256 => uint256)) public addressToMints;

     /** 
      * @dev MERKLE ROOTS 
      *
      * @dev Initial value is randomly generated from https://www.random.org/
      */
    bytes32 public merkleRoot = "";

    /**
     * @dev DEVELOPER
     */
    address public immutable devAddress;
    uint256 public immutable devShare;

    /**
     * @dev Claiming
     */
    uint256 public claimStart = 1645804800;
    mapping(uint256 => uint256) public hasDogeClaimed; // 0 = false | 1 = true
    mapping(uint256 => uint256) public dogeToTransferMethod; // 0 = none | 1 = minted | 2 = claimed

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount, bool indexed permissioned);

    event setTotalSupplyEvent(uint256 indexed maxSupply);
    event setMaxSupplyPermissionedEvent(uint256 indexed maxSupply);    

    event setLimitOpenEvent(uint256 indexed limit);
    event setPricePermissionedEvent(uint256 indexed price);
    event setPriceOpenEvent(uint256 indexed price);

    event setStartTimePermissionedEvent(uint256 indexed startTime);
    event setDurationPermissionedEvent(uint256 indexed duration);
    event setIsStartedOpenEvent(bool indexed isStarted);

    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    event Claim(address indexed claimer, uint256 indexed amount);    
    event setClaimStartEvent(uint256 indexed time);

    event setMutantDogeAddressEvent(address indexed mutant);

    constructor(
        address _boredDogeAddress
    ) Ownable() {
        boredDoge = IBoredDogeClubERC721(_boredDogeAddress);
        devAddress = 0x841d534CAa0993c677f21abd8D96F5d7A584ad81;
        devShare = 1;
    }
 
    /**
     * @dev SALE
     */
    
    /**
     * @dev Returns the leftovers from raffle mint
     * regarding the total supply.
     */
    function maxSupplyOpen() public view returns(uint256) {
        return totalSupply - mintedPermissioned;
    }

    /**
     * @notice Function to buy one or more NFTs.
     * @dev First the Merkle Proof is verified.
     * Then the mint is verified with the data embedded in the Merkle Proof.
     * Finally the NFTs are minted to the user's wallet.
     *
     * @param amount. The amount of NFTs to buy.
     * @param mintMaxAmount. The max amount the user can mint.
     * @param proof. The Merkle Proof of the user.
     */
    function buyPermissioned(uint256 amount, uint256 mintMaxAmount, bytes32[] calldata proof) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, mintMaxAmount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can perform permissioned mint based on the provided parameters.

        require(address(boredDoge) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot != "" && !isStartedOpen, "PERMISSIONED SALE CLOSED");
       
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(addressToMints[msg.sender][1] + amount <= mintMaxAmount, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(mintedPermissioned + amount <= maxSupplyPermissioned, "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= pricePermissioned * amount, "ETHER SENT NOT CORRECT");
        
        require(block.timestamp < startPermissioned + durationPermissioned, "PERMISSIONED SALE IS CLOSED");
        require(block.timestamp >= startPermissioned, "PERMISSIONED SALE HASN'T STARTED YET");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet

        mintedPermissioned += amount;
        addressToMints[msg.sender][1] += amount;

        /// @dev Register that these Doges were minted
        dogeToTransferMethod[boredDoge.getNextTokenId()] = 1;
        boredDoge.mintTo(amount, msg.sender);

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

        require(address(boredDoge) != address(0), "NFT SMART CONTRACT NOT SET");
        require(isStartedOpen, "OPEN SALE CLOSED");

        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(addressToMints[msg.sender][2] + amount <= limitOpen, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(mintedOpen + amount <= maxSupplyOpen(), "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= priceOpen * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet
        
        mintedOpen += amount;
        addressToMints[msg.sender][2] += amount;

        /// @dev Register that these Doges were minted
        dogeToTransferMethod[boredDoge.getNextTokenId()] = 1;
        boredDoge.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount, false);
    }

    /**
     * @dev CLAIMING
     */

    /**
     * @dev Method to check if a doge was minted or claimed.
     * Method starts at dogeId and traverses lastDogeTransferStatus
     * mapping until it finds a non zero status. If the status is 1
     * the doge was minted. Otherwise it was claimed. A value will always 
     * be found as each mint or claim updates the mapping.
     *
     * @param dogeId. The id of the doge to query
     */
    function wasDogeMinted(uint256 dogeId) internal view returns(bool) {
        if (!boredDoge.exists(dogeId))
            return false;
        
        uint lastDogeTransferStatus;
        for (uint i = dogeId; i >= 0; i--) {
            if (dogeToTransferMethod[i] != 0) {
                lastDogeTransferStatus = dogeToTransferMethod[i];
                break;
            }
        }

        return lastDogeTransferStatus == 1;
    }

    /**
     * @notice Claim Bored Doge by providing your Bored Doge Ids
     * @dev Mints amount of Bored Doges to sender as valid Bored Doge bought 
     * provided. Validity depends on ownership, not having claimed yet and
     * whether the doges were minted.
     *
     * @param doges. The tokenIds of the doges.
     */
    function claimDoges(uint256[] calldata doges) external {
        require(address(boredDoge) != address(0), "DOGES NFT NOT SET");
        require(doges.length > 0, "NO IDS SUPPLIED");
        require(block.timestamp >= claimStart, "CANNOT CLAIM YET");

        /// @dev Check if sender is owner of all DOGEs and that they haven't claimed yet
        /// @dev Update claim status of each DOGE
        for (uint256 i = 0; i < doges.length; i++) {
            uint256 DOGEId = doges[i];
            require(IERC721( address(boredDoge) ).ownerOf(DOGEId) == msg.sender, "NOT OWNER OF DOGE");
            require(hasDogeClaimed[DOGEId] == 0, "DOGE HAS ALREADY CLAIMED DOGE");
            require(wasDogeMinted(DOGEId), "DOGE WAS NOT MINTED");
            hasDogeClaimed[DOGEId] = 1;
        }

        /// @dev Register that these Doges were claimed
        dogeToTransferMethod[boredDoge.getNextTokenId()] = 2;
        boredDoge.mintTo(doges.length, msg.sender);
        emit Claim(msg.sender, doges.length);
    }

    /**
     * @notice View which of your Bored Doges can still their Bored Doges
     * @dev Given an array of Bored Doges ids returns a subset of ids that
     * can still claim a Bored Doge. Used off chain to provide input of Bored Doges method.
     *
     * @param doges. The tokenIds of the doges.
     */
    function getStillClaimableDogesFromIds(uint256[] calldata doges) external view returns (uint256[] memory) {
        require(doges.length > 0, "NO IDS SUPPLIED");

        uint256 length = doges.length;
        uint256[] memory notClaimedDoges = new uint256[](length);
        uint256 counter;

        /// @dev Check if sender is owner of all doges and that they haven't claimed yet
        /// @dev Update claim status of each doge
        for (uint256 i = 0; i < doges.length; i++) {
            uint256 dogeId = doges[i];          
            if (hasDogeClaimed[dogeId] == 0 && wasDogeMinted(dogeId)) {
                notClaimedDoges[counter] = dogeId;
                counter++;
            }
        }

        return notClaimedDoges;
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
     * @notice Change the total supply of NFTs that are for sale.
     *
     * @param newTotalSupply. The new total supply.
     */
    function setTotalSupply(uint256 newTotalSupply) external onlyOwner {
        totalSupply = newTotalSupply;
        emit setTotalSupplyEvent(newTotalSupply);
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
     * @notice Change the startTime of the open sale.
     *
     * @param newIsStarted. The new public sale status.
     */
    function setIsStartedOpen(bool newIsStarted) external onlyOwner {
        isStartedOpen = newIsStarted;
        emit setIsStartedOpenEvent(newIsStarted);
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
     * @dev Set's the new start time for claiming
     *
     * @param newClaimStart. The new claim start time.
     */
    function setClaimStart(uint256 newClaimStart) external onlyOwner {
        claimStart = newClaimStart;
        emit setClaimStartEvent(newClaimStart);
    }

    /**
     * @dev Set's the address for the future mutant doge collection
     *
     * @param _mutant. The address of mutant doge
     */
    function setMutantDogeAddress(address _mutant) external onlyOwner {
        MutantDoge = _mutant;
        emit setMutantDogeAddressEvent(_mutant);
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