// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC2981.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./WithLimitedSupply.sol";
import "./LibPart.sol";

contract PlantParadeToken is ERC721A, WithLimitedSupply, ERC2981, Ownable {
    using SafeMath for uint;
    using Strings for uint256;

    uint public constant MAX_SUPPLY = 5000;
    uint public constant MAX_RESERVE_TOKEN = 100;
    uint public constant MAKETING_PERCENTAGE = 3;
    uint public constant COMMUNITY_PERCENTAGE = 11;
    uint public constant DONATIONS_PERCENTAGE = 12;
    uint public constant OWNER1_PERCENTAGE = 37;
    uint public constant OWNER2_PERCENTAGE = 37;

    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 private constant RARIBLE_INTERFACE_ID_ROYALTIES = 0xcad96cca;

    // Used for random index assignment
    mapping(uint16 => uint16) private tokenMatrix;

    uint public maxAllowedMint = 4;
    string public baseTokenURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint public saleTimeStamp;
    bool public paused = false;
    bool public revealed = false;
    uint public cost = 0.04 ether;
    bool reserveMinted = false;
    uint public presaleSlot1StartTime;
    uint public presaleSlot1EndTime;
    uint public presaleSlot2StartTime;
    uint public presaleSlot2EndTime;
    uint public presaleSlot3StartTime;
    uint public presaleSlot3EndTime;
    address public marketingWallet;
    address public communityWallet;
    address public donationsWallet; 
    address public owner1Wallet;
    address public owner2Wallet;
    
    //Map of address to slot number for whitelisting of addresses. If slot is 0 then it is invalid address
    mapping(address => uint8) public whitelist;

    RoyaltyInfo private nftRoyaltyInfo;

    event Mint(address indexed to, uint indexed totalNumber);
    event RoyaltyPaymentReceived(address from, uint256 amount);
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _initNotRevealedUri,
        uint _saleStartTimestamp,
        address[] memory wallets) 
        ERC721A(_name, _symbol)
        WithLimitedSupply(MAX_SUPPLY) {

        require(_saleStartTimestamp - block.timestamp > (14 * 24 * 60 * 60), "Sale start time too early");
        require(bytes(_baseTokenURI).length > 0, "Token base URI must not be blank");
        require(bytes(_initNotRevealedUri).length > 0, "Toke Not reveal URI must not be blank");
        
        setBaseURI(_baseTokenURI);
        setNotRevealedURI(_initNotRevealedUri);
        _setDefaultRoyalty(address(this), 1000);
        nftRoyaltyInfo = RoyaltyInfo(address(this), 1000);
        saleTimeStamp = _saleStartTimestamp;
        presaleSlot1StartTime = saleTimeStamp - (14 * 24 * 60 * 60);
        presaleSlot1EndTime = presaleSlot1StartTime + (4 * 24 * 60 * 60);
        presaleSlot2StartTime = saleTimeStamp - (10 * 24 * 60 * 60);
        presaleSlot2EndTime = presaleSlot2StartTime + (2 * 24 * 60 * 60);
        presaleSlot3StartTime = saleTimeStamp - (8 * 24 * 60 * 60);
        presaleSlot3EndTime = presaleSlot3StartTime + (2 * 24 * 60 * 60);
        if(wallets.length > 0) {
            require(wallets.length == 5, "Total 5 wallet addresses must be set");
            marketingWallet = wallets[0];
            communityWallet = wallets[1];
            donationsWallet = wallets[2];
            owner1Wallet = wallets[3];
            owner2Wallet = wallets[4];
        }
    }
    /**
     * @dev The Ether received will be logged with {RoyaltyPaymentReceived} events.
     * This function recieves the payments and credit into contract
     */
    receive() external payable virtual {
        emit RoyaltyPaymentReceived(msg.sender, msg.value);
    }
    /**
     * @dev This function shows the interfaces supported by the contract
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
        return  ERC2981.supportsInterface(interfaceId) || 
                interfaceId == RARIBLE_INTERFACE_ID_ROYALTIES ||
                ERC721A.supportsInterface(interfaceId);
    }
    /**
     * @dev Withdraw whole amount from Contract to registered wallets as per distribution percentage.
     */
    function withdraw() public onlyOwner {
        require(marketingWallet != address(0), 'Marketting wallet address empty');
        require(communityWallet != address(0), 'Community wallet address empty');
        require(donationsWallet != address(0), 'Donations wallet address empty');
        require(owner1Wallet != address(0), 'Owner1 wallet address empty');
        require(owner2Wallet != address(0), 'Owner2 wallet address empty');
        uint amount = address(this).balance;
        require(amount > 0, "No amount left to withdraw");
        uint marketingAmt = amount * MAKETING_PERCENTAGE /100;
        uint communityAmt = amount * COMMUNITY_PERCENTAGE /100;
        uint donationsAmt = amount * DONATIONS_PERCENTAGE /100;
        uint owner1Amount = amount * OWNER1_PERCENTAGE /100;
        uint owner2Amount = amount * OWNER2_PERCENTAGE /100;
        payable(marketingWallet).transfer(marketingAmt);
        payable(communityWallet).transfer(communityAmt);
        payable(donationsWallet).transfer(donationsAmt);
        payable(owner1Wallet).transfer(owner1Amount);
        payable(owner2Wallet).transfer(owner2Amount);
    }
    /***************************** Mint related functions ***********************/
    /**
     * @dev Mint requested number of tokens.
     */
    function mint(uint8 _mintAmount) public payable {
        require(!paused, "Mint Paused");
        require(_mintAmount > 0, "Min amount to mint be more than 0");
        require(canMint(msg.sender, _mintAmount), "Can not Mint");
        
        if(reserveMinted) {
            require(totalSupply().add(_mintAmount) <= MAX_SUPPLY, "Exceeded Max supply.");
        } else {
            require(totalSupply().add(_mintAmount) <= MAX_SUPPLY.sub(MAX_RESERVE_TOKEN), "Exceeded Max supply.");
        }
        if (msg.sender != owner()) {
            require(msg.value >= cost.mul(_mintAmount), "Incorrect price for Cost");
        }
        uint16[] memory tokenIds = new uint16[](_mintAmount);
        for(uint16 i = 0; i < _mintAmount; i++) {
            tokenIds[i] = nextToken();
        }
        _safeMint(msg.sender, tokenIds);
        emit Mint(msg.sender, _mintAmount);
    }
    /**
     * @dev This function returns true if user wallet is not minted max cap per wallet
     * And if Whitelisted wallet then it retruns true if within presale window
     * And if general wallet then it returns true if general sale started.
     */
    function canMint(address user, uint _mintAmount) internal view returns (bool) {
        require(balanceOf(user).add(_mintAmount) <= maxAllowedMint, "Exceeded Max Mint per wallet");

        if(whitelist[user] == 1) { // Slot 1
            return isWithinPresaleSlot1Window() || isSaleStarted();
        }
        if(whitelist[user] == 2) { // Slot 1
            return isWithinPresaleSlot2Window() || isSaleStarted();
        }
        if(whitelist[user] == 3) { // Slot 1
            return isWithinPresaleSlot3Window() || isSaleStarted();
        }
        return isSaleStarted();
    }
    //only owner
    /**
     * @dev Mint reserve 200 tokens
     */
    function mintReserveToken() external onlyOwner {
        require(!paused);
        require(balanceOf(msg.sender).add(MAX_RESERVE_TOKEN) <= MAX_RESERVE_TOKEN, "Exceeded Max Reserve Token Limit");
        require(totalSupply().add(MAX_RESERVE_TOKEN) <= MAX_SUPPLY, "Exceeded Max supply.");
        
        uint16[] memory tokenIds = new uint16[](MAX_RESERVE_TOKEN);
        for(uint16 i = 0; i < MAX_RESERVE_TOKEN; i++) {
            tokenIds[i] = nextToken();
        }
        _safeMint(msg.sender, tokenIds);
        emit Mint(msg.sender, MAX_RESERVE_TOKEN);
    }
    /*************************** Read Functions *****************************/
    /**
     * @dev Implementation of Rarible Royalty interface
     */
    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = nftRoyaltyInfo.royaltyFraction;
        _royalties[0].account = payable(nftRoyaltyInfo.receiver);
        return _royalties;
    }
    /**
     * @dev Function returns tokenids for an wallet.
     */
    function walletOfOwner(address _owner) external view returns (uint16[] memory) {
        return _ownersData[_owner];
    }
    /**
     * @dev Function returns token uri for a token id.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(uint16(tokenId)), "ERC721Metadata: URI query for nonexistent token");

        if(!revealed) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
    /**
     * @dev Function to check if sale is started or not
     */
    function isSaleStarted() public view returns (bool) {
        return block.timestamp >= saleTimeStamp;
    }
    /************************* Write Functions *************************/
    /**
     * @dev Function to set Base URI of the NFT
     */
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    /**
     * @dev Function to set Not Revealed URI
     */
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    /**
     * @dev Function to set base extension for NFT
     */
    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }
    /**
     * @dev Function to set reveal NFT or not flag
     */
    function reveal(bool _reveal) public onlyOwner {
        revealed = _reveal;
    }
    /**
     * @dev Function to set pause NFT mint or not flag
     */
    function pause(bool _state) external onlyOwner {
        paused = _state;
    }
    /**
     * @dev Function to set cost per NFT to mint
     */
    function setCost(uint _newCost) public onlyOwner {
        cost = _newCost;
    }
    /**
     * @dev Function to set Max Allowed mint per wallet
     */
    function setMaxAllowedMint(uint _maxAllowed) public onlyOwner {
        maxAllowedMint = _maxAllowed;
    }
    /**
     * @dev Function to set sale start time
     */
    function setSaleStartTime(uint _saleStartTimestamp) public onlyOwner {
        saleTimeStamp = _saleStartTimestamp;
    }
    /**
     * @dev Function to set pre-sale slot1 window w.r.t sale start time
     * @param _daysPrior number of days prior to sale start time
     * @param durationInSecs duration of presale in seconds or epoch from slot1 start time
     */
    function setPreSaleSlot1Window(uint _daysPrior, uint durationInSecs) public onlyOwner {
        presaleSlot1StartTime = saleTimeStamp - (_daysPrior * 24 * 60 * 60);
        presaleSlot1EndTime = presaleSlot1StartTime + durationInSecs;
    }
    /**
     * @dev Function to set pre-sale slot2 window w.r.t sale start time
     * @param _daysPrior number of days prior to sale start time
     * @param durationInSecs duration of presale in seconds or epoch from slot1 start time
     */
    function setPreSaleSlot2Window(uint _daysPrior, uint durationInSecs) public onlyOwner {
        presaleSlot2StartTime = saleTimeStamp - (_daysPrior * 24 * 60 * 60);
        presaleSlot2EndTime = presaleSlot2StartTime + durationInSecs;
    }
    /**
     * @dev Function to set marketing wallet address
     */
    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = _marketingWallet;
    }
    /**
     * @dev Function to set community wallet address
     */
    function setCommunityWallet(address _communityWallet) public onlyOwner {
        communityWallet = _communityWallet;
    }
    /**
     * @dev Function to set donations wallet address
     */
    function setDonationsWallet(address _donationsWallet) public onlyOwner {
        donationsWallet = _donationsWallet;
    }
    /**
     * @dev Function to set Owner1 wallet address
     */
    function setOwner1Wallet(address _owner1Wallet) public onlyOwner {
        owner1Wallet = _owner1Wallet;
    }
    /**
     * @dev Function to set Owner2 wallet address
     */
    function setOwner2Wallet(address _owner2Wallet) public onlyOwner {
        owner2Wallet = _owner2Wallet;
    }
    /**
     * @dev Function to set pre-sale slot2 window w.r.t sale start time
     * @param _daysPrior number of days prior to sale start time
     * @param durationInSecs duration of presale in seconds or epoch from slot1 start time
     */
    function setPreSaleSlot3Window(uint _daysPrior, uint durationInSecs) public onlyOwner {
        presaleSlot3StartTime = saleTimeStamp - (_daysPrior * 24 * 60 * 60);
        presaleSlot3EndTime = presaleSlot3StartTime + durationInSecs;
    }
    /**
     * @dev Add wallet address as whitelisted address to be eligible to participate in presale window
     */
    function addAddressToWhitelist(address wallet, uint8 _slot) public onlyOwner {
        require(whitelist[wallet] <= 0, "Address Whitelisted");
        require(_slot > 0 && _slot <= 3, "Invalid Slot");
        whitelist[wallet] = _slot;
    }
    /**
     * @dev Add List of wallet addresses as whitelisted address to be eligible to participate in presale window
     */
    function addAddressesToWhitelist(address[] memory wallets, uint8[] memory _slots) external onlyOwner {
        for(uint i = 0; i < wallets.length; i++) {
            addAddressToWhitelist(wallets[i], _slots[i]);
        }
    }
    /**
     * @dev Remove a wallet address from whitelisted list
     */
    function removeFromWhitelist(address wallet) external onlyOwner {
        require(whitelist[wallet] > 0, "Address Not Whitelisted");
        whitelist[wallet] = 0;
    }
    /************************** Internal functions ***************************/
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
    function isWithinPresaleSlot1Window() internal view returns (bool) {
        return block.timestamp >= presaleSlot1StartTime && 
               block.timestamp <= presaleSlot1EndTime;
    }
    function isWithinPresaleSlot2Window() internal view returns (bool) {
        return block.timestamp >= presaleSlot2StartTime && 
               block.timestamp <= presaleSlot2EndTime;
    }
    function isWithinPresaleSlot3Window() internal view returns (bool) {
        return block.timestamp >= presaleSlot3StartTime && 
               block.timestamp <= presaleSlot3EndTime;
    }
    /** 
     * Get the next token ID
     * @dev Randomly gets a new token ID and keeps track of the ones that are still available.
     * @return the next token ID
     */
    function nextToken() internal override ensureAvailability returns (uint16) {
        uint16 maxIndex = uint16(_totalSupply - totalSupply());
        uint randomVal = uint(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp
            )
        )) % maxIndex;
        uint16 random = uint16(randomVal);
        uint16 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }
        _tokenOwnership[value].owner = msg.sender;
        _tokenOwnership[value].approvalFor = address(0);
        // Increment counts
        super.nextToken();
        
        return value;
    }
}