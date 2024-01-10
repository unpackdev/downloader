// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract IPoisonedBananas {
     function mintSingle(uint256 bananaType, address to) external {}
     function mintMultiple(uint256[] memory bananaTypes, uint256[] memory amounts, address to) external {}
}

contract IPoisonedBananaClaimRNG {
    function getRandomNumber(address _addr, uint256 apeId) external view returns (uint256) {}
}

contract PoisonedBananasClaim is Ownable {

    /**
     * @dev EXTERNAL ADDRESSES
     */
    IERC721 public primeApeNFT;
    IPoisonedBananas public bananas;
    IPoisonedBananaClaimRNG private claimRng;
    
    /** 
     * @dev GENERAL DATA 
     */
    uint256 public maxSupply = 7979;
    uint256 public lvl1Supply = 5000;
    uint256 public lvl2Supply = 2965;
    uint256 public lvl3Supply = 14;

    uint256 public lvl2Odds = 3;
    uint256 public lvl3Odds = 569;

    /**
     * @dev CLAIM DATA
     */
    mapping(uint256 => bool) public apeToClaimed;
    mapping(uint256 => uint256) public levelToClaimed;

    /**
     * @dev MINT DATA
     */
    uint256 public holderPrice = 0.07979 ether;
    uint256 public price = 0.15 ether;
    uint256 public minted;
    uint256 public mintMaxAmount = 1;
    bool public isHolderSale;
    bool public isSale;
    mapping(address => uint256) public addressToHolderMint;
    mapping(address => uint256) public addressToMints;
    
    /**
     * @dev Setter events.
     */
    event setPriceEvent(uint256 indexed price);
    event setMaxSupplyEvent(uint256 indexed maxSupply);

    /**
     * @dev Sale events.
     */
    event Purchase(address indexed buyer, uint256 indexed amount);
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _ape,
        address _banana,
        address _rng
    ) Ownable() {
        require(lvl1Supply + lvl2Supply + lvl3Supply == maxSupply, "Supply not correct");

        primeApeNFT = IERC721(_ape);
        bananas = IPoisonedBananas(_banana);
        claimRng = IPoisonedBananaClaimRNG(_rng);
    }

    /**
     * @dev HELPERS
     */

    /**
     * @dev returns the bananas supply that is left.
     */
    function supplyLeft() public view returns (uint256) {
        return maxSupply - minted;
    }

    /**
     * @dev given an array of apeIds see which ones can still
     * claim their banana.
     *
     * @param apeIds. The ape ids.
     */
    function getNotClaimedApes(uint256[] calldata apeIds) external view returns(uint256[] memory) {
        require(apeIds.length > 0, "No IDS supplied");

        uint256 length = apeIds.length;
        uint256[] memory notClaimedApes = new uint256[](length);
        uint256 counter;

        /// @dev Check if sender is owner of all apes and that they haven't claimed yet
        /// @dev Update claim status of each ape
        for (uint256 i = 0; i < apeIds.length; i++) {
            uint256 apeId = apeIds[i];         
            if (!apeToClaimed[apeId]) {
                notClaimedApes[counter] = apeId;
                counter++;
            }
        }

        return notClaimedApes;
    }

    function getBananaLevelForClaim(address claimer, uint256 claimingApeId) internal view returns (uint256) {
        uint256 rng = claimRng.getRandomNumber(claimer, claimingApeId);

        bool isLvl3 = rng % lvl3Odds == 0;
        bool isLvl2 = rng % lvl2Odds == 0;
        bool isLvl1 = !isLvl3 && !isLvl2;

        bool isLvl3Full = levelToClaimed[2] >= lvl3Supply;
        bool isLvl2Full = levelToClaimed[1] >= lvl2Supply;
        bool isLvl1Full = levelToClaimed[0] >= lvl1Supply;

        if (isLvl3) {
            if (!isLvl3Full)
                return 2;
            else if (!isLvl2Full)
                return 1;
            else if (!isLvl1Full)
                return 0;
        }

        if (isLvl2) {
            if (!isLvl2Full)
                return 1;
            else if (!isLvl1Full)
                return 0;
            else if (!isLvl2Full)
                return 2;
        }

        if (isLvl1) {
            if (!isLvl1Full)
                return 0;
            else if (!isLvl2Full)
                return 1;
            else if (!isLvl3Full)
                return 2;
        }

        //should not get to this
        revert("Logic error");
    }

    /**
     * @dev CLAIMING
     */
    
    /**
     * @dev Claims bananas to sender for each valid ape Id.
     *
     * @param apeIds. The ape Ids.
     */
    function claimBananas(uint256[] calldata apeIds) external {
        require(address(bananas) != address(0), "Banana contract not set");
        require(address(primeApeNFT) != address(0), "Ape contract not set");
        require(apeIds.length > 0, "No Ids supplied");
        require(!isSale && !isHolderSale, "Claiming stopped");

        uint256[] memory bananaTypes = new uint256[](apeIds.length);
        uint256[] memory amounts = new uint256[](apeIds.length);

        /// @dev Check if sender is owner of all apes and that they haven't claimed yet
        /// @dev Update claim status of each ape
        for (uint256 i = 0; i < apeIds.length; i++) {
            uint256 apeId = apeIds[i];
            require(primeApeNFT.ownerOf(apeId) == msg.sender, "Sender does not own ape");
            require(!apeToClaimed[apeId], "Ape already claimed banana");
            apeToClaimed[apeId] = true;

            uint256 bananaType = getBananaLevelForClaim(msg.sender, apeId);
            levelToClaimed[bananaType]++;

            bananaTypes[i] = bananaType;
            amounts[i] = 1;
        }

        minted += apeIds.length;
        bananas.mintMultiple(bananaTypes, amounts, msg.sender);
    }
    
    /**
     * @dev Claims banana to sender for ape Id.
     *
     * @param apeId. The ape Id.
     */
    function claimBanana(uint256 apeId) external {
        require(address(bananas) != address(0), "Banana contract not set");
        require(address(primeApeNFT) != address(0), "Ape contract not set");
        require(!isSale && !isHolderSale, "Claiming stopped");

        require(primeApeNFT.ownerOf(apeId) == msg.sender, "Sender does not own ape");
        require(!apeToClaimed[apeId], "Ape already claimed banana");
        apeToClaimed[apeId] = true;

        uint256 bananaType = getBananaLevelForClaim(msg.sender, apeId);
        levelToClaimed[bananaType]++;

        minted++;
        bananas.mintSingle(bananaType, msg.sender);
    }

    /**
     * @dev SALE
     */

    /**
     * @dev Allows unclaimed bananas to be sold to holders
     */
    function buyBananasHolders() 
        external 
        payable {
        uint256 amount = 1;

        require(primeApeNFT.balanceOf(msg.sender) > 0, "Have to be a prime ape holder");
        require(addressToHolderMint[msg.sender] == 0, "Can only buy one additional banana");
        require(minted + amount <= maxSupply, "Mint amount goes over max supply");
        require(msg.value >= holderPrice, "Ether sent not correct");
        require(isHolderSale, "Sale not started"); 

        addressToHolderMint[msg.sender] = 1;

        uint256 bananaType = getBananaLevelForClaim(msg.sender, minted);
        levelToClaimed[bananaType]++;

        minted++;
        bananas.mintSingle(bananaType, msg.sender);       

        emit Purchase(msg.sender, amount);
    }

    /**
     * @dev Allows unclaimed bananas to be sold to the public
     *
     * @param amount. The amount of bananas to be sold
     */
    function buyBananas(uint256 amount) 
        external 
        payable {
        
        require(amount > 0, "Have to buy more than 0");

        require(addressToMints[msg.sender] + amount <= mintMaxAmount, "Mint amount exceeds max for user");
        require(minted + amount <= maxSupply, "Mint amount goes over max supply");
        require(msg.value >= price * amount, "Ether sent not correct");
        require(isSale, "Sale not started"); 
        /// @dev Updates contract variables and mints `amount` NFTs to users wallet

        addressToMints[msg.sender] += amount;

        uint256[] memory bananaTypes = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 bananaType = getBananaLevelForClaim(msg.sender, minted + i);
            levelToClaimed[bananaType]++;

            bananaTypes[i] = bananaType;
            amounts[i] = 1;
        }

        minted += amount;
        bananas.mintMultiple(bananaTypes, amounts, msg.sender);    

        emit Purchase(msg.sender, amount);
    }

    /** 
     * @dev OWNER ONLY 
     */

    function setIsSale(bool _isSale) external onlyOwner {
        isSale = _isSale;
    }

    function setIsHolderSale(bool _isSale) external onlyOwner {
        isHolderSale = _isSale;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit setPriceEvent(newPrice);
    }

    function setHolderPrice(uint256 newPrice) external onlyOwner {
        holderPrice = newPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit setMaxSupplyEvent(newMaxSupply);
    }

    function setMaxMintAmount(uint256 newMaxMintAmount) external onlyOwner {
        mintMaxAmount = newMaxMintAmount;
    }

    function setLvl1Supply(uint256 newSupply) external onlyOwner {
        lvl1Supply = newSupply;
    }

    function setLvl2Supply(uint256 newSupply) external onlyOwner {
        lvl2Supply = newSupply;
    }

    function setLvl3Supply(uint256 newSupply) external onlyOwner {
        lvl3Supply = newSupply;
    }

    function setLvl2Odds(uint256 newOdds) external onlyOwner {
        lvl2Odds = newOdds;
    }

    function setLvl3Odds(uint256 newOdds) external onlyOwner {
        lvl3Odds = newOdds;
    }

    /**
     * @dev FINANCE
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