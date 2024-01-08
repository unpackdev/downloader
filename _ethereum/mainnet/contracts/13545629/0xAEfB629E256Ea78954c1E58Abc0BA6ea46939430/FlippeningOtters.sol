// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
	/$$$$$$$$ /$$ /$$                                         /$$                      /$$$$$$    /$$     /$$                                  
	| $$_____/| $$|__/                                        |__/                     /$$__  $$  | $$    | $$                                  
	| $$      | $$ /$$  /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$  /$$ /$$$$$$$   /$$$$$$ | $$  \ $$ /$$$$$$ /$$$$$$    /$$$$$$   /$$$$$$   /$$$$$$$
	| $$$$$   | $$| $$ /$$__  $$ /$$__  $$ /$$__  $$| $$__  $$| $$| $$__  $$ /$$__  $$| $$  | $$|_  $$_/|_  $$_/   /$$__  $$ /$$__  $$ /$$_____/
	| $$__/   | $$| $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$  \ $$| $$| $$  \ $$| $$  \ $$| $$  | $$  | $$    | $$    | $$$$$$$$| $$  \__/|  $$$$$$ 
	| $$      | $$| $$| $$  | $$| $$  | $$| $$_____/| $$  | $$| $$| $$  | $$| $$  | $$| $$  | $$  | $$ /$$| $$ /$$| $$_____/| $$       \____  $$
	| $$      | $$| $$| $$$$$$$/| $$$$$$$/|  $$$$$$$| $$  | $$| $$| $$  | $$|  $$$$$$$|  $$$$$$/  |  $$$$/|  $$$$/|  $$$$$$$| $$       /$$$$$$$/
	|__/      |__/|__/| $$____/ | $$____/  \_______/|__/  |__/|__/|__/  |__/ \____  $$ \______/    \___/   \___/   \_______/|__/      |_______/ 
					| $$      | $$                                         /$$  \ $$                                                          
					| $$      | $$                                        |  $$$$$$/                                                          
					|__/      |__/                                         \______/                                                           
*/
                                          
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./KeeperCompatibleInterface.sol";
import "./AggregatorV3Interface.sol";
import "./VRFConsumerBase.sol";

/**
 * Contract Timeline:
 * 1. Deploy the contract with right constructor params
 * 2. Send Link tokens to contract address
 * 3. Call getRandomNumber
 * 4. Set BaseURI, contractURI, lockMetadata
 * 5. Add presale address presale allocation
 * 6. Enable presale
 * 7. Add presale address giveaway allocation
 * 9. Enable sale
 * 10. Enable give away at 25% minting
 * 11. Enable companionUpdates at 50% minting
 * 12. Enable wingUpdates at 75% minting
 */ 
contract FlippeningOtters is ERC721, Ownable, KeeperCompatibleInterface, VRFConsumerBase {
    uint256 public constant OTTER_AIR_DROP_MAX = 300;
    uint256 public constant OTTER_GIVE_AWAY_MAX = 500;
    uint256 public constant OTTER_PRESALE_MAX = 300;
    uint256 public constant OTTER_MAX = 9999;
    uint256 public constant FLIPPENING_OTTER_TOKEN_ID = OTTER_MAX + 1;
    uint256 public constant OTTER_WING_PRICE = 0.02 ether;
    uint256 public constant OTTER_COMPANION_PRICE = 0.02 ether;
    uint256 public constant OTTER_PRESALE_PRICE = 0.01 ether;
    uint256 public OTTER_MINT_PRICE = 0.05 ether;
    address public gnosis_safe = 0xB836140717e545bCd59691aC1E4d50f1f94fb6b3;
    
    struct OtterAddOns { 
        string wing;
        string companion;
    }
    mapping(address => uint256) public giveAwayListAlloc;
    mapping(address => bool) public presalerListAlloc;
    mapping(uint256 => uint256) public tokenIdToImageId;
    mapping(uint256 => OtterAddOns) public tokenIdToAddons;
    
    string private _contractURI;
    string private _tokenBaseURI = "ipfs://Qmf41u6GGzoZeJWR3UccXVXvEvmxfrwczSUMvsLec6MU3j/";
	
    uint256 public airDropAmount;
    uint256 public giveAwayAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public totalAmountMinted;
    uint256 public finalShifter;
    
    bytes32 mintingFinalRandRequestId;
    bool public mintingFinalized;
    bool public presaleLive;
    bool public giveAwayLive;
    bool public saleLive;
    bool public companionsAvailable;
    bool public wingsAvailable;
    bool public locked;
    
    
    AggregatorV3Interface internal ethMarketCapFeed;
    AggregatorV3Interface internal btcMarketCapFeed;
    bool public flipped;
    
    bool internal enableKeeper;
    bytes32 internal randomKeyHash;
    uint256 internal randomLinkFee;
    uint256 public randomResult;
    
    // ETH Mainnet params.
    //
    // https://docs.chain.link/docs/ethereum-addresses
    // ethFeed: 0xAA2FE1324b84981832AafCf7Dc6E6Fe6cF124283
    // btcFeed: 0x47E1e89570689c13E723819bf633548d611D630C
    //
    // https://docs.chain.link/docs/vrf-contracts/
    // vrfLinkToken: 0x514910771AF9Ca656af840dff83E8264EcF986CA
    // vrfCoordinator: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
    // keyHash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
    // Fee: 2000000000000000000 
    //
    // Kovan: 0x9326BFA02ADD2366b30bacB125260Af641031331,0x6135b13325bfC4B00278B4abC5e20bbce2D6580e,0xa36085F69e2889c224210F603D836748e7dC0088,0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9,0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4,100000000000000000
    // Rinkeby: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e,0x2431452A0010a43878bF198e170F6319Af6d27F4,0x01BE23585060835E02B77ef475b0Cc51aA1e0709,0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B,0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311,100000000000000000
    constructor(address ethFeed, address btcFeed, address vrfLinkToken, address vrfCoordinator, bytes32 keyHash, uint256 linkFee) 
        ERC721("Flippening Otters", "FOT") 
        VRFConsumerBase(
            vrfCoordinator, // VRF Coordinator
            vrfLinkToken  // LINK Token
        ) { 
      ethMarketCapFeed = AggregatorV3Interface(ethFeed);
      btcMarketCapFeed = AggregatorV3Interface(btcFeed);
      randomKeyHash = keyHash;
      randomLinkFee = linkFee; // LINK (Varies by network)
    }
    
    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }

    function increaseGiveAwayBudget(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            giveAwayListAlloc[entry]++;
        }   
    }

    function decreaseGiveAwayBudget(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            giveAwayListAlloc[entry]--;
        }
    }

    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerListAlloc[entry], "DUPLICATE_ENTRY");
            presalerListAlloc[entry] = true;
        }   
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            presalerListAlloc[entry] = false;
        }
    }

    function mint(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        uint256 totalAmountMintedLocal = totalAmountMinted;
        require(totalAmountMintedLocal + tokenQuantity <= OTTER_MAX, "OUT_OF_STOCK");
        require(OTTER_MINT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            totalAmountMintedLocal++;
            shuffleMint(msg.sender, totalAmountMintedLocal);
        }
        totalAmountMinted = totalAmountMintedLocal;
    }
    
    function presaleBuy(uint256 tokenQuantity) external payable {
        require(presaleLive, "PRESALE_CLOSED");
        uint256 totalAmountMintedLocal = totalAmountMinted;
        uint256 privateAmountMintedLocal = privateAmountMinted;
        require(totalAmountMintedLocal + tokenQuantity <= OTTER_MAX, "OUT_OF_STOCK");
        require(privateAmountMintedLocal + tokenQuantity <= OTTER_PRESALE_MAX, "EXCEED_PRIVATE");
        require(presalerListAlloc[msg.sender], "NOT_ELIGIBLE");
        require(OTTER_PRESALE_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMintedLocal++;
            totalAmountMintedLocal++;
            shuffleMint(msg.sender, totalAmountMintedLocal);
        }
        privateAmountMinted = privateAmountMintedLocal;
        totalAmountMinted = totalAmountMintedLocal;
    }
    
    // Free give away.    
    function giveAwayBuy() external {
        require(giveAwayLive, "GIVE_AWAY_CLOSED");
        require(totalAmountMinted + 1 <= OTTER_MAX, "OUT_OF_STOCK");
        require(giveAwayAmountMinted + 1 <= OTTER_GIVE_AWAY_MAX, "EXCEED_GIVE_AWAY");
        require(giveAwayListAlloc[msg.sender] > 0, "NOT_QUALIFIED");

        giveAwayAmountMinted++;
        giveAwayListAlloc[msg.sender]--;
        totalAmountMinted++;
        shuffleMint(msg.sender, totalAmountMinted);
    }

    function airDrop(address[] calldata receivers) external onlyOwner {
        require(totalAmountMinted + receivers.length <= OTTER_MAX, "MAX_MINT");
        uint256 airDropAmountLocal = airDropAmount;
        uint256 totalAmountMintedLocal = totalAmountMinted;
        require(airDropAmount + receivers.length <= OTTER_AIR_DROP_MAX, "EXCEED_AIR_DROP");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            airDropAmountLocal++;
            totalAmountMintedLocal++;
            shuffleMint(receivers[i], totalAmountMintedLocal);
        }
        airDropAmount = airDropAmountLocal;
        totalAmountMinted = totalAmountMintedLocal;
    }
    
    function updateCompanion(uint256 tokenId, string calldata companionType) external payable {
        require(_exists(tokenId), "Cannot query non-existent token");
        require(companionsAvailable, "Companion changes are not available");
        require(ownerOf(tokenId) == msg.sender, "Only token owner can change companions");
        bool isDelete = compare(companionType, "");
        // Deletion is free.
        require(isDelete || OTTER_COMPANION_PRICE <= msg.value, "INSUFFICIENT_ETH");

        if (isDelete) {
            delete tokenIdToAddons[tokenId].companion;
        } else {
            tokenIdToAddons[tokenId].companion = companionType;
        }
    } 

    function updateWing(uint256 tokenId, string calldata wingType) external payable {
        require(_exists(tokenId), "Cannot query non-existent token");
        require(wingsAvailable, "Wing changes are not available");
        require(ownerOf(tokenId) == msg.sender, "Only token owner can change wings");
        bool isDelete = compare(wingType, "");
        // Deletion is free.
        require(isDelete || OTTER_WING_PRICE <= msg.value, "INSUFFICIENT_ETH");

        if (isDelete) {
            delete tokenIdToAddons[tokenId].wing;
        } else {
            tokenIdToAddons[tokenId].wing = wingType;
        }
    }

    /**
     * Generates a number between 1 to num (inclusive).
     */ 
    function rangedRandomNum(uint256 num) internal view returns (uint256) {
        return rangedRandomNumWithSeed(num, block.timestamp);
    }

    function rangedRandomNumWithSeed(uint256 num, uint256 counter) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(counter, msg.sender, totalAmountMinted, randomResult)))%num + 1;
    }

    // Finalize the allocation of Otters and stop minting forever.
    function finalizeMinting() public onlyOwner {
        if(!mintingFinalized) {
            saleLive = false;
            presaleLive = false;
            giveAwayLive = false;
            mintingFinalRandRequestId = getRandomNumber();
        }
    }

    function shuffleMint(address to, uint256 tokenId) internal {
        require(!mintingFinalized, "Fair minting has already completed");
        uint256 target = rangedRandomNum(tokenId);
        _safeMint(to, tokenId);
        // Swap target and tokenId image mapping.
        tokenIdToImageId[tokenId] = target;
        tokenIdToImageId[target] = tokenId;
        if(tokenId == OTTER_MAX) {
            finalizeMinting();
        }
    }

    
    function withdraw() external onlyOwner {
        payable(gnosis_safe).transfer(address(this).balance);
    }

    function setDesstinationAddress(address addr) external onlyOwner {
        gnosis_safe = addr;
    }
    
    function burn(uint256[] calldata tokenIds) external onlyOwner() {
          for (uint256 i = 0; i < tokenIds.length; i++) {
              _burn(tokenIds[i]);
              delete tokenIdToImageId[tokenIds[i]];
        }
    }
    
    // Owner functions for enabling presale, sale, revealing and setting the provenance hash
    function lockMetadata() external onlyOwner {
        locked = true;
    }
    
    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleGiveAwayStatus() external onlyOwner {
        giveAwayLive = !giveAwayLive;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function toggleCompanionsAvailable() external onlyOwner {
        companionsAvailable = !companionsAvailable;
    }

    function toggleWingsAvailable() external onlyOwner {
        wingsAvailable = !wingsAvailable;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        require(tokenIdToImageId[tokenId] > 0, "Cannot query non-existent imageId");
        
        uint256 imageId = 0; // "Wait for minting to complete"
        if(mintingFinalized) {
            imageId = tokenIdToImageId[tokenId];
            if(tokenId != FLIPPENING_OTTER_TOKEN_ID) {
                imageId = (imageId + finalShifter)%OTTER_MAX + 1;
            }
        }

        string memory uri = string(abi.encodePacked(_tokenBaseURI, Strings.toString(imageId), "/base"));
        if(bytes(tokenIdToAddons[tokenId].wing).length != 0) {
            uri = string(abi.encodePacked(uri, "_", tokenIdToAddons[tokenId].wing));
        }
        if(bytes(tokenIdToAddons[tokenId].companion).length != 0) {
            uri = string(abi.encodePacked(uri, "_", tokenIdToAddons[tokenId].companion));
        }
        uri = string(abi.encodePacked(uri, ".json"));
        return uri;
    }
    
    function compare(string memory s1, string memory s2) public pure returns (bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function updateLinkFee(uint256 linkFee) external onlyOwner {
      randomLinkFee = linkFee;
    }
    
    
    function updateKeyHash(bytes32 keyHash) external onlyOwner {
      randomKeyHash = keyHash;
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= randomLinkFee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(randomKeyHash, randomLinkFee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if(mintingFinalRandRequestId == requestId) {
            mintingFinalized = true;
            // All tokenId to imageId shifted by finalShifter, except Flippening Otter.
            finalShifter = randomness%OTTER_MAX;        
        } else {
            randomResult = randomness;
        }
    }
    
    // TODO: change it to internal function after testing.
    function isFlipped() public view returns (bool) {
        (, int256 btcMarketCap,,,) = btcMarketCapFeed.latestRoundData();
        (, int256 ethMarketCap,,,) = ethMarketCapFeed.latestRoundData();
        return btcMarketCap <= ethMarketCap ;
    }

	function setEnableKeeper() public onlyOwner {
		enableKeeper = true;
	}
    
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = enableKeeper && !flipped && isFlipped();
        // We don't use the checkData in this. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        require(!flipped, "Flippening otter should only be assigned once");
        require(isFlipped(), "Flippening event must have already happened");
        // Mint the Flippening Otter
        flipped = true;
        uint256 counter = block.timestamp;
        uint256 tokenId = rangedRandomNumWithSeed(totalAmountMinted, counter);
        // Find a tokenId with valid owner. This is required to handle burned tokens.
        while(ownerOf(tokenId) == address(0)) {
            counter++;
            tokenId = rangedRandomNumWithSeed(totalAmountMinted, counter);
        }
        // Assign Flippening Otter to owner of one of the existing otters.
        _safeMint(ownerOf(tokenId), FLIPPENING_OTTER_TOKEN_ID);
        tokenIdToImageId[FLIPPENING_OTTER_TOKEN_ID] = FLIPPENING_OTTER_TOKEN_ID;
    } 

    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }

    function setOtterMintPrice(uint256 price) external onlyOwner {
        OTTER_MINT_PRICE = price;
    }
}