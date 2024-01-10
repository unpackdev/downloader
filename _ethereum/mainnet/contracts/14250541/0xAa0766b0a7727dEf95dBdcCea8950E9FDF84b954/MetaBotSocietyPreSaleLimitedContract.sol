// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/**
  __  __ ______ _______       ____   ____ _______    _____  ____   _____ _____ ______ _________     __
 |  \/  |  ____|__   __|/\   |  _ \ / __ \__   __|  / ____|/ __ \ / ____|_   _|  ____|__   __\ \   / /
 | \  / | |__     | |  /  \  | |_) | |  | | | |    | (___ | |  | | |      | | | |__     | |   \ \_/ / 
 | |\/| |  __|    | | / /\ \ |  _ <| |  | | | |     \___ \| |  | | |      | | |  __|    | |    \   /  
 | |  | | |____   | |/ ____ \| |_) | |__| | | |     ____) | |__| | |____ _| |_| |____   | |     | |   
 |_|  |_|______|  |_/_/    \_\____/ \____/  |_|    |_____/ \____/ \_____|_____|______|  |_|     |_|                                                                                                                                                                                                                                   
                             
 */

import "./IERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @notice Represents NFT Smart Contract
 */
contract IMetaBotSocietyERC721 {
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
 * @title MetaBotSocietyPreSaleLimitedContract.
 *
 * @notice This Smart Contract can be used to sell any fixed amount of NFTs where only permissioned
 * wallets are allowed to buy. Buying is limited to a certain time period.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract MetaBotSocietyPreSaleLimitedContract is Ownable {

    /** 
     * @notice The Smart Contract of the MetaBotSocietyNFT
     * @dev MetaBotSocietyNFT Smart Contract 
     */
    IMetaBotSocietyERC721 public immutable nft;
    
    /** 
     * @dev MINT DATA 
     */
    uint256 internal safetyMargin = 2 minutes;
    uint256 public startTimePhaseOne = 1646074800 - safetyMargin; // 28 Feb 2022 19:00 UTC
    uint256 public startTimePhaseTwo = 1646334000 - safetyMargin; // 3 Mar 2022 19:00 UTC
    uint256 public startTimeOpen = 1646679600 - safetyMargin; // 7 Mar 2022 19:00 UTC

    uint256 public pricePhaseOne = 0.075 ether;
    uint256 public pricePhaseTwo = 0.08 ether;
    uint256 public priceOpen = 0.1 ether;
    
    uint256 public maxSupplyPhaseOne = 100;
    uint256 public maxSupplyPhaseTwo = 1500;
    uint256 public totalSupply = 9999;
    uint256 public limitOpen = 20;

    mapping(uint256 => uint256) public mintedPhases;
    uint256 public mintedOpen;
    mapping(address => mapping(uint256 => uint256)) public addressToMints;

     /** 
      * @dev MERKLE ROOTS 
      */
    bytes32 public merkleRoot = "";

    /**
     * @dev PAYMENT
     */
    address[] public recipients;
    uint256[] public shares;
    
    /**
     * @dev Events
     */
    
    /**
     * @dev Setter Events.
     */
    event setStartTimePhaseOneEvent(uint256 indexed startTime);
    event setStartTimePhaseTwoEvent(uint256 indexed startTime);

    event setPricePhaseOneEvent(uint256 indexed price);
    event setPricePhaseTwoEvent(uint256 indexed price);

    event setMaxSupplyPhaseOneEvent(uint256 indexed maxSupply);
    event setMaxSupplyPhaseTwoEvent(uint256 indexed maxSupply);

    event setMerkleRootEvent(bytes32 indexed merkleRoot);

    event setStartTimeOpenEvent(uint256 indexed time);
    event setTotalSupplyEvent(uint256 indexed supply);
    event setPriceOpenEvent(uint256 indexed price);
    event setLimitOpenEvent(uint256 indexed limit);

    event setRecipientsEvent(address[] indexed addresses, uint256[] indexed shares);

    /**
     * @dev Sale Events.
     */
    event Purchase(address indexed buyer, uint256 indexed amount, uint256 indexed phase);
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _nftaddress
    ) Ownable() {
        nft = IMetaBotSocietyERC721(_nftaddress);      
    }
 
    /**
     * @dev SALE
     */

    /**
     * @notice Returns the max supply for the public sale.
     * @dev Is calculated by substracting the sales made in the
     * first and second phases from the total supply
     */
    function maxSupplyOpen() public view returns(uint256) {
        return totalSupply - mintedPhases[1] - mintedPhases[2];
    }

    /**
     * @notice Validates the sale data for each phase per user
     *
     * @dev For each phase validates that the time is correct,
     * that the ether supplied is correct and that the purchase 
     * amount doesn't exceed the max amount
     *
     * @param amount. The amount the user want's to purchase
     * @param phase. The sale phase of the user
     */
    function validatePhaseSpecificPurchase(uint256 amount, uint256 phase) internal {
        if (phase == 1) {                          
            require(msg.value >= pricePhaseOne * amount, "ETHER SENT NOT CORRECT");
            require(mintedPhases[1] + amount <= maxSupplyPhaseOne, "BUY AMOUNT GOES OVER MAX SUPPLY");
            require(block.timestamp >= startTimePhaseOne, "PHASE ONE SALE HASN'T STARTED YET");

        } else if (phase == 2) {                     
            require(msg.value >= pricePhaseTwo * amount, "ETHER SENT NOT CORRECT");
            require(mintedPhases[2] + amount <= maxSupplyPhaseTwo, "BUY AMOUNT GOES OVER MAX SUPPLY");
            require(block.timestamp >= startTimePhaseTwo, "PHASE TWO SALE HASN'T STARTED YET");

        } else {
            revert("INCORRECT PHASE");
        }
    }

    /**
     * @notice Function to buy one or more NFTs.
     * @dev First the Merkle Proof is verified.
     * Then the buy is verified with the data embedded in the Merkle Proof.
     * Finally the NFTs are bought to the user's wallet.
     *
     * @param amount. The amount of NFTs to buy.     
     * @param buyMaxAmount. The max amount the user can buy.
     * @param phase. The permissioned sale phase.
     * @param proof. The Merkle Proof of the user.
     */
    function buyPhases(uint256 amount, uint256 buyMaxAmount, uint256 phase, bytes32[] calldata proof) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, buyMaxAmount, phase));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verify that user can perform permissioned sale based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");
        
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(addressToMints[msg.sender][phase] + amount <= buyMaxAmount, "BUY AMOUNT EXCEEDS MAX FOR USER");            

        /// @dev Verify that user can perform permissioned sale based on phase of user

        validatePhaseSpecificPurchase(amount, phase);

        /// @dev Permissioned sale closes as soon as public sale starts
        require(block.timestamp < startTimeOpen, "PERMISSIONED SALE CLOSED");

        /// @dev Update mint values

        mintedPhases[phase] += amount;
        addressToMints[msg.sender][phase] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount, phase);
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
        require(block.timestamp >= startTimeOpen, "OPEN SALE CLOSED");

        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(addressToMints[msg.sender][3] + amount <= limitOpen, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(mintedOpen + amount <= maxSupplyOpen(), "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= priceOpen * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet
        
        mintedOpen += amount;
        addressToMints[msg.sender][3] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount, 3);
    }

    /**
     * @dev VIEW
     */

    /**
     * @dev Returns the total amount of NFTs minted 
     * accross all phases.
     */
    function totalMinted() external view returns(uint256) {
        return mintedPhases[1] + mintedPhases[2] + mintedOpen;
    }

    /**
     * @dev Returns the total amount of NFTs minted 
     * accross all phases by a specific wallet.
     */
    function totalMintedByAddress(address user) external view returns(uint256) {
        return addressToMints[user][1] + addressToMints[user][2] + addressToMints[user][3];
    }

    /**
     * @dev Returns the total amount of NFTs left
     * accross all phases.
     */
    function nftsLeft() external view returns(uint256) {
        return totalSupply - mintedPhases[1] - mintedPhases[2] - mintedOpen;
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the start time of phase one.
     *
     * @param newStartTime. The new start time.
     */
    function setStartTimePhaseOne(uint256 newStartTime) external onlyOwner {
        startTimePhaseOne = newStartTime;
        emit setStartTimePhaseOneEvent(newStartTime);
    }

    /**
     * @notice Change the start time of phase two.
     *
     * @param newStartTime. The new start time.
     */
    function setStartTimePhaseTwo(uint256 newStartTime) external onlyOwner {
        startTimePhaseTwo = newStartTime;
        emit setStartTimePhaseTwoEvent(newStartTime);
    }

    /**
     * @notice Change the price of phase one.
     *
     * @param newPrice. The new price.
     */
    function setPricePhaseOne(uint256 newPrice) external onlyOwner {
        pricePhaseOne = newPrice;
        emit setPricePhaseOneEvent(newPrice);
    }

    /**
     * @notice Change the price of phase two.
     *
     * @param newPrice. The new price.
     */
    function setPricePhaseTwo(uint256 newPrice) external onlyOwner {
        pricePhaseTwo = newPrice;
        emit setPricePhaseTwoEvent(newPrice);
    }

    /**
     * @notice Change the maximum supply of phase one.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyPhaseOne(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPhaseOne = newMaxSupply;
        emit setMaxSupplyPhaseOneEvent(newMaxSupply);
    }

    /**
     * @notice Change the maximum supply of phase two.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyPhaseTwo(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPhaseTwo = newMaxSupply;
        emit setMaxSupplyPhaseTwoEvent(newMaxSupply);
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
     * @notice Change the start time of the public sale.
     *
     * @param time. The new start time.
     */
    function setStartTimeOpen(uint256 time) external onlyOwner {
        startTimeOpen = time;
        emit setStartTimeOpenEvent(time);
    }

    /**
     * @notice Change the total supply.
     *
     * @param supply. The new max supply.
     */
    function setTotalSupply(uint256 supply) external onlyOwner {
        totalSupply = supply;
        emit setTotalSupplyEvent(supply);
    }

    /**
     * @notice Change the price of public sale.
     *
     * @param price. The new price.
     */
    function setPriceOpen(uint256 price) external onlyOwner {
        priceOpen = price;
        emit setPriceOpenEvent(price);
    }

    /**
     * @notice Change the maximum purchasable NFTs per wallet during public sale.
     *
     * @param limit. The new limit.
     */
    function setLimitOpen(uint256 limit) external onlyOwner {
        limitOpen = limit;
        emit setLimitOpenEvent(limit);
    }    

    /**
     * @notice Set recipients for funds collected in smart contract.
     *
     * @dev Overrides old recipients and shares
     *
     * @param _addresses. The addresses of the new recipients.
     * @param _shares. The shares corresponding to the recipients.
     */
    function setRecipients(address[] calldata _addresses, uint256[] calldata _shares) external onlyOwner {
        require(_addresses.length > 0, "HAVE TO PROVIDE AT LEAST ONE RECIPIENT");
        require(_addresses.length == _shares.length, "PAYMENT SPLIT NOT CONFIGURED CORRECTLY");

        delete recipients;
        delete shares;

        for (uint i = 0; i < _addresses.length; i++) {
            recipients.push(_addresses[i]);
            shares.push(_shares[i]);
        }

        emit setRecipientsEvent(_addresses, _shares);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale to the specified recipients.
     *
     */
    function withdrawAll() external {
        bool senderIsRecipient = false;
        for (uint i = 0; i < recipients.length; i++) {
            senderIsRecipient = senderIsRecipient || (msg.sender == recipients[i]);
        }
        require(senderIsRecipient, "CAN ONLY BE CALLED BY RECIPIENT");
        require(recipients.length > 0, "CANNOT WITHDRAW TO ZERO ADDRESS");
        require(recipients.length == shares.length, "PAYMENT SPLIT NOT CONFIGURED CORRECTLY");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        for (uint i = 0; i < recipients.length; i++) {
            address _to = recipients[i];
            uint256 _amount = contractBalance * shares[i] / 1000;
            payable(_to).transfer(_amount);
            emit WithdrawAllEvent(_to, _amount);
        }        
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}