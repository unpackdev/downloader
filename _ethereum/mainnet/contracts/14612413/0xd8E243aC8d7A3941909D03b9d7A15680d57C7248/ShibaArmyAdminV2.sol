// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;
import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ShibaArmy.sol";
contract ShibaArmyAdminV2 is Ownable {
    using Strings for uint256;
    enum saleTypes {WHITELIST, PRESALE, PUBLICSALE}
    struct saleConfig {
        uint256 price;
        uint256 maxAvailable;
        uint256 maxPerWallet;
        uint256 maxPerDogeArmy;
        saleTypes saleType;
    }
    saleConfig private publicSale = saleConfig(
        .25 ether,
        10000,
        10000,
        10000,
        saleTypes.PUBLICSALE
    );
    saleConfig private preSale = saleConfig(
        .2 ether,
        10000,
        10000,
        1,
        saleTypes.PRESALE
    );
    
    saleConfig private whitelistSale = saleConfig(
        .15 ether,
        2000,
        10,
        1,
        saleTypes.WHITELIST
    );
    IERC721 immutable private DOGE_ARMY;
    ShibaArmy immutable private SHIBA_ARMY;
    ShibaArmy immutable private SALE2;
    uint256 constant public MAX_SHIBA = 10000;
    mapping(uint256 => bool) private isDogeArmyMintClaimedAdmin; // presale
    mapping(address => uint256) public numDogeArmyHolderMintClaimed; // whitelist
    function isDogeArmyMintClaimed(uint256 id) public view returns (bool) {
        return(SHIBA_ARMY.isDogeArmyMintClaimed(id) || SALE2.isDogeArmyMintClaimed(id) || isDogeArmyMintClaimedAdmin[id]);
    }
    event DogeArmyMintClaimed(uint256 id);
    event totalDogeArmyHolderMinted(address holder, uint256 numMinted);
    event saleLaunched(uint256 launchTime);
    uint256 public tokensSold;
    uint256 public launchTime;
    bool public saleActive;
    bool public publicSaleStarted;
    constructor(ERC721 _dogeArmy, ShibaArmy _shibaArmy, ShibaArmy _sale2)  {
        DOGE_ARMY = _dogeArmy;
        tokensSold = 500;
        SHIBA_ARMY = _shibaArmy;
        SALE2 = _sale2;
    }
    function balanceOf(address holder) external view returns (uint256) {
        return SHIBA_ARMY.balanceOf(holder);
    }
    function totalSupply() public view returns (uint256) {
        return SHIBA_ARMY.totalSupply();
    }
    function mint(uint256 numTokensToMint, uint256[] calldata dogeArmyClaimIDs) external payable {
        // check that sale is active
        require(saleActive);
        require(!isSalePaused, "Sale has been paused by owner");
        // determine what sale type we are currently in
        saleConfig memory config = getSaleConfig();
        require(msg.value >= config.price * numTokensToMint, "Not enough ETH");
        require(config.maxAvailable >= tokensSold + numTokensToMint, "Not enough available tokens to mint");
        require(MAX_SHIBA >= tokensSold + numTokensToMint, "Not enough available tokens to mint in this phase");
        require(MAX_SHIBA >= totalSupply() + numTokensToMint, "Not enough supply available");
        
        if(config.maxPerWallet != MAX_SHIBA) {
            require(config.maxPerWallet >= SHIBA_ARMY.numDogeArmyHolderMintClaimed(msg.sender) + numDogeArmyHolderMintClaimed[msg.sender] + numTokensToMint, "Wallet has already claimed maximum mints");
            numDogeArmyHolderMintClaimed[msg.sender] += numTokensToMint;
            emit totalDogeArmyHolderMinted(msg.sender, numDogeArmyHolderMintClaimed[msg.sender]);
        }
        bool isDogeArmyMatch = false;
        if(config.maxPerDogeArmy != MAX_SHIBA){
            isDogeArmyMatch = true;
            require(dogeArmyClaimIDs.length == numTokensToMint);
        }
        for (uint256 i = 0; i < numTokensToMint; i++) {
            if(isDogeArmyMatch){
                require(!isDogeArmyMintClaimed(dogeArmyClaimIDs[i]), "DogeArmy Mint already claimed"); // has the Doge Army token already been used to claim a mint
                require(DOGE_ARMY.ownerOf(dogeArmyClaimIDs[i]) == msg.sender, "Caller not the owner of Doge Army Token");
                isDogeArmyMintClaimedAdmin[dogeArmyClaimIDs[i]] = true;
                emit DogeArmyMintClaimed(dogeArmyClaimIDs[i]);
            }
        }
        tokensSold += numTokensToMint;
        SHIBA_ARMY.reserve(numTokensToMint, msg.sender);
    }
    // returns the current sale config
    function getSaleConfig() public view returns (saleConfig memory currentConfig) {
        if(publicSaleStarted) {
            return publicSale;
        }
        uint256 daysSinceSaleStarted = (block.timestamp - launchTime)  / 60 / 60 / 24;
        if(daysSinceSaleStarted < 4){ // check for whitelist sale window
            // 500 per day of whitelist sale
            uint256 currentMaxAvailable = (daysSinceSaleStarted + 1) * 500;
            currentConfig = saleConfig(
                whitelistSale.price,
                currentMaxAvailable,
                whitelistSale.maxPerWallet,
                whitelistSale.maxPerDogeArmy,
                saleTypes.WHITELIST
            );
            return currentConfig;
        } else if (daysSinceSaleStarted < 7){ // check for presale window
            return preSale;
        }
    }
    // Owner functions
    function launchSale() external onlyOwner {
        launchTime = SHIBA_ARMY.launchTime();
        saleActive = true;
        emit saleLaunched(launchTime);
    }
    function setLaunchTime(uint256 newLaunchTime) external onlyOwner {
        launchTime = newLaunchTime;
    }
    function launchPublicSale() external onlyOwner {
        uint256 daysSinceSaleStarted = (block.timestamp - launchTime) % (1 days);
        require(saleActive);
        require(daysSinceSaleStarted > 7);
        publicSaleStarted = true;
    }
    bool isSalePaused = false;
    event salePauseToggled(bool isSalePaused);
    function toggleSalePaused() external onlyOwner {
        isSalePaused = !isSalePaused;
        emit salePauseToggled(isSalePaused);
    }
    function reserve(uint256 amount, address destination) external onlyOwner {
        SHIBA_ARMY.reserve(amount, destination);
    }
    function freezeURI() external onlyOwner {
        SHIBA_ARMY.freezeURI();
    }
    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    function withdrawSA() external onlyOwner {
        SHIBA_ARMY.withdraw();
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    function reveal() external onlyOwner {
        SHIBA_ARMY.reveal();
    }
    function setUnrevealedURI(string calldata _unrevealedURI) external onlyOwner {
        SHIBA_ARMY.setUnrevealedURI(_unrevealedURI);
    }
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        SHIBA_ARMY.setBaseURI(_newBaseURI);
    }
    function addProvenance(uint256 id) external onlyOwner {
        SHIBA_ARMY.addProvenance(id);
    }
    function transferSAOwnership() external onlyOwner() {
        SHIBA_ARMY.transferOwnership(msg.sender);
    }
}