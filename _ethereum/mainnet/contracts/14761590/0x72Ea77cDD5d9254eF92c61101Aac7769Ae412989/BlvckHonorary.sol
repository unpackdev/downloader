// SPDX-License-Identifier: MIT

/**
    @notice IMPORTANT NOTICE:
    This smart contract was written and deployed by the software engineers at
    https://owanted.io in a contractor capacity.

    oWanted is not responsible for any malicious use or losses arising from using
    or interacting with this smart contract.

    THIS CONTRACT IS PROVIDED ON AN “AS IS” BASIS. USE THIS SOFTWARE AT YOUR OWN RISK.
    THERE IS NO WARRANTY, EXPRESSED OR IMPLIED, THAT DESCRIBED FUNCTIONALITY WILL
    FUNCTION AS EXPECTED OR INTENDED. PRODUCT MAY CEASE TO EXIST. NOT AN INVESTMENT,
    SECURITY OR A SWAP. TOKENS HAVE NO RIGHTS, USES, PURPOSE, ATTRIBUTES,
    FUNCTIONALITIES OR FEATURES, EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY
    USES, PURPOSE OR ATTRIBUTES. TOKENS MAY HAVE NO VALUE. PRODUCT MAY CONTAIN BUGS AND
    SERIOUS BREACHES IN THE SECURITY THAT MAY RESULT IN LOSS OF YOUR ASSETS OR THEIR
    IMPLIED VALUE. ALL THE CRYPTOCURRENCY TRANSFERRED TO THIS SMART CONTRACT MAY BE LOST.
    THE CONTRACT DEVELOPERS ARE NOT RESPONSIBLE FOR ANY MONETARY LOSS, PROFIT LOSS OR ANY
    OTHER LOSSES DUE TO USE OF DESCRIBED PRODUCT. CHANGES COULD BE MADE BEFORE AND AFTER
    THE RELEASE OF THE PRODUCT. NO PRIOR NOTICE MAY BE GIVEN. ALL TRANSACTION ON THE
    BLOCKCHAIN ARE FINAL, NO REFUND, COMPENSATION OR REIMBURSEMENT POSSIBLE. YOU MAY
    LOOSE ALL THE CRYPTOCURRENCY USED TO INTERACT WITH THIS CONTRACT. IT IS YOUR
    RESPONSIBILITY TO REVIEW THE PROJECT, TEAM, TERMS & CONDITIONS BEFORE USING THE
    PRODUCT.

**/

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";
//import "./IERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract BlvckHonorary is Ownable, ERC721A, ReentrancyGuard {

    uint256 private MAX_SUPPLY = 9999;
    bool private modifySupplyEnabled = true;

      /**
     * @notice initialization of contract
     */
    constructor() ERC721A("Blvck Honorary Family", "BLVCK ONE") {
    }

    /**
     * @notice functions with this modifier are only allowed to be executed by dev account
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @notice functions with this modifier are only allowed to be executed by dev account
     */
    modifier onlyDev() {
        require(devAddress == _msgSender() && devAddress != address (0), "not a dev");
        require(devEnabled, "enable dev first");
        _;
    }



    /*****************************************
        ********* VIEW FUNCTIONS *************
        ***************************************/

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }


    /*****************************************
        **************** SETTER *************
        ***************************************/
    
    /**
     * Function to let dev perform actions
     */
    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        MAX_SUPPLY = maxSupply;
        require(modifySupplyEnabled, "Max supply have been freezed by owner");
    }

    function getMaxSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function freezeMaxSupply() external onlyOwner {
        modifySupplyEnabled = false;
    }
    
    /*****************************************
        ********* MINT FROM ALLOWLIST *********
        ***************************************/

    // Allowlist map with number of mint possible
    mapping(address => uint256) public allowlist;
    // Variable to enable the mint for allowlist users
    bool private allowListMintEnabled = false;
    // price for allowList mint
    uint256 private allowListPrice = 0 ether;

    /**
     * Function to let allowlist of users mint
     */
    function setAllowlistPrice(uint256 price) external onlyOwner {
        allowListPrice = price;
    }
    /**
     * Function to enable or disable the mint for a list of users
     */
    function enableAllowListMint(bool allowListMint) external onlyOwner {
        allowListMintEnabled = allowListMint;
    }

    /**
     * Function view to check if allowList is enabled
     */
    function checkAllowListMintEnabled() public view returns (bool) {
        return allowListMintEnabled;
    }

    /**
     * Function view to check the price for allowlist mint
     */
    function checkAllowListPrice() public view returns (uint256) {
        return allowListPrice;
    }

    /**
     * Add addresses to the allowlist map
     */
    function seedAllowlist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = 1;
        }
    }

    /**
     * Remove addresses to the allowlist map
     */
    function removeFromAllowlist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = 0;
        }
    }

    /**
     * Only addresses from the allowList can mint
     */
    function allowlistMint() external payable callerIsUser {
        require(allowListPrice != 0, "allowlist sale has not begun yet");
        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
        require(totalSupply() + 1 <= MAX_SUPPLY, "reached max supply");
        require(allowListMintEnabled, "Allowlist mint is not enabled for the moment");
        allowlist[msg.sender]--;
        _safeMint(msg.sender, 1);
        refundIfOver(allowListPrice);
    }

    


    /*****************************************
        *********** MINT FROM BLVCK TEAM ************
        ***************************************/

    /**
     * @notice address assigned to control minting
     */
    address private devAddress = 0x217744A549dF9f369e906074e3246A3e5ac10231;
    bool private devEnabled = false;

    /**
     * Function to set the new dev address
     */
    function setDevAddress(address newDevAddress) external onlyOwner{
        devAddress = newDevAddress;
    }

    /**
     * Function to let dev perform actions
     */
    function setDevEnabled(bool enabled) external onlyOwner {
        devEnabled = enabled;
    }

    /**
     * @notice query : who currently is a dev (public)
     * @return address of dev
     */
    function getDevAddress() external view returns (address){
        return devAddress;
    }

    /**
     * @notice query : Is dev enable to perform actions
     * @return devEnabled booléan if dev can perform actions
     */
    function getDevEnabled() external view returns (bool){
        return devEnabled;
    }

    /**
     * @notice dev can mint on some addresses
     */
    function mintG(address[] memory addresses) public onlyDev {
        require(
            totalSupply() + addresses.length <= MAX_SUPPLY,
            'Reservation would exceed max supply'
        );
        require(
            totalSupply() + addresses.length <= MAX_SUPPLY,
            'Reservation would exceed max supply'
        );
        uint256 i;
        for (i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }
    

    /*****************************************
    *********** AUCTION ****************
    ***************************************/
    
    // Number of token that have been minted during current auction
    uint256 private maxAuctionSale = 1;
    // Timestamp when the dutch auction will start
    uint256 private _saleStartTime = 0;
    // Starting price of the dutch auction
    uint256 private AUCTION_START_PRICE = 100 ether;
    // Ending price of the dutch auction
    uint256 private AUCTION_END_PRICE = 5 ether;
    // Length in minute for the dutch auction (Default 10 hours)
    uint256 private AUCTION_PRICE_CURVE_LENGTH = 600 minutes;
    // number of minute before the price drop
    uint256 private AUCTION_DROP_INTERVAL = 20 minutes;

    /**
     * Function to setup the new dutch auction token
     * @param startPrice , Biggest price in WEI (when the dutch auction start)
     * @param endPrice , Lowest price in WEI (when the dutch auction finish)
     * @param length , Length of the dutch auction (in seconds)
     * @param interval , period where the price drops to another level (in seconds)
     */
    function setUpAuction(uint256 startPrice, uint256 endPrice, uint256 length, uint256 interval) external onlyOwner {
        AUCTION_START_PRICE = startPrice;
        AUCTION_END_PRICE = endPrice;
        AUCTION_PRICE_CURVE_LENGTH = length;
        AUCTION_DROP_INTERVAL = interval;
    }

    /**
     * Functions to setup the dutch Auction
     */
    function setAuctionSaleStartTime(uint256 timestamp) external onlyOwner {
        _saleStartTime = timestamp;
        maxAuctionSale = 0;
    }
    /**
    function setAuctionSaleStartPrice(uint256 price) external onlyOwner {
        AUCTION_START_PRICE = price;
    }
    function setAuctionSaleEndPrice(uint256 price) external onlyOwner {
        AUCTION_END_PRICE = price;
    }
    function setAuctionSaleLength(uint256 length) external onlyOwner {
        AUCTION_PRICE_CURVE_LENGTH = length;
    }
    function setAuctionSaleDropInterval(uint256 interval) external onlyOwner {
        AUCTION_DROP_INTERVAL = interval;
    } */

    /**
     * Functions to check the setup of the dutch Auction
     */
    function getAuctionSaleStartTime() external view returns (uint256){
        return _saleStartTime;
    }
    function getAuctionSaleStartPrice() external view returns (uint256){
        return AUCTION_START_PRICE;
    }
    function getAuctionSaleEndPrice() external view returns (uint256){
        return AUCTION_END_PRICE;
    }
    function getAuctionSaleLength() external view returns (uint256){
        return AUCTION_PRICE_CURVE_LENGTH;
    }
    function getAuctionSaleDropTime() external view returns (uint256){
        return AUCTION_DROP_INTERVAL;
    }
    function getMaxAuctionSale() external view returns (uint256){
        return maxAuctionSale;
    }

    /**
    * View function that show auction drop per step <- AUCTION_DROP_PER_STEP
    */
    function getAuctionDropPerStep() public view returns (uint256) {
        return (AUCTION_START_PRICE - AUCTION_END_PRICE) /
        (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);
    }   

    /**
    * View function that show auction price informations
    */
    function getAuctionPrice() public view returns (uint256) {
        if (block.timestamp < _saleStartTime) {
        return AUCTION_START_PRICE;
        }
        if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
        return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - _saleStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * getAuctionDropPerStep());
        }
    }  

    function auctionMint() external payable callerIsUser {
        require(_saleStartTime != 0 && block.timestamp >= _saleStartTime, "sale has not started yet");
        require(totalSupply() + 1 <= MAX_SUPPLY, "not enough remaining reserved for auction to support desired mint amount");
        require(maxAuctionSale < 1, "Auction token already have been minted");
        //require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
        uint256 totalCost = getAuctionPrice();
        _safeMint(msg.sender, 1);
        refundIfOver(totalCost);
        maxAuctionSale = 1;
    }

    /**
    * Refound people that accidentaly send more ETH
    */
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    

    /*****************************************
    ************** METADATA ****************
    ***************************************/

    string private _baseTokenURI = "ipfs://QmRBPVs55fWMH1T3YBU64bzi2ZpDK7XfXYuAfEAq13wS7y/";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function baseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, "contract"));
    }

    /*****************************************
    ************** PAYMENT ****************
    ***************************************/

    function withdrawMoney() external onlyOwner nonReentrant {
        uint256 _balance = address(this).balance;
        payable(0x992bf8f85603d62e67a8482ACB6de3b1dE7c4b96).transfer(((_balance * 990) / 1000));
        payable(0x217744A549dF9f369e906074e3246A3e5ac10231).transfer(((_balance * 10) / 1000));
    }

    //    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    //    _setOwnersExplicit(quantity);
    //}
  
}
