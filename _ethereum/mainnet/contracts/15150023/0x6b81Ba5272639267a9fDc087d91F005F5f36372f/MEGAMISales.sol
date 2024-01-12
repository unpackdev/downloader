// SPDX-License-Identifier: MIT

// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxdol:;,''....'',;:lodxxxxxxxxxxxxxxxxxxxxxdlc;,''....'',;:codxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxdc;'.                .';ldxxxxxxxxxxxxxxdl;'.                ..;cdxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxdl;.                        .;ldxxxxxxxxxo;.                        .;ldxxxxxxxxxxxxxx
// xxxxxxxxxxxxxl,.                            .,lxxxxxxo;.                            .'ldxxxxxxxxxxxx
// xxxxxxxxxxxo;.                                .,lddo;.                                .;oxxxxxxxxxxx
// xxxxxxxxxxo'                                    ....                                    'lxxxxxxxxxx
// xxxxxxxxxl'                             .                   .                            .lxxxxxxxxx
// xxxxxxxxo,                             'c,.              .,c'                             'oxxxxxxxx
// xxxxxxxxc.                             .lxl,.          .,ldo.                             .:xxxxxxxx
// xxxxxxxd,                              .:xxxl,.      .,ldxxc.                              'oxxxxxxx
// xxxxxxxo'                               ,dxxxxl,.  .,ldxxxd;                               .lxxxxxxx
// xxxxxxxo.                               .oxxxxxxl::ldxxxxxo'                               .lxxxxxxx
// xxxxxxxd,                               .cxxxxxxxxxxxxxxxxl.                               'oxxxxxxx
// xxxxxxxx:.           ..                  ;xxxxxxxxxxxxxxxx:                  ..            ;dxxxxxxx
// xxxxxxxxo'           ''                  'oxxxxxxxxxxxxxxd,                  .'           .lxxxxxxxx
// xxxxxxxxxc.          ;,                  .lxxxxxxxxxxxxxxo.                  ';.         .cxxxxxxxxx
// xxxxxxxxxxc.        .c,                  .:xxxxxxxxxxxxxxc.                  'c.        .cdxxxxxxxxx
// xxxxxxxxxxxl'       'l,       ..          ,dxxxxxxxxxxxxd;          ..       'l,       'lxxxxxxxxxxx
// xxxxxxxxxxxxd:.     ;o,       .'          .oxxxxxxxxxxxxo'          ..       'o:.    .:dxxxxxxxxxxxx
// xxxxxxxxxxxxxxd:.  .cd,       .;.         .cxxxxxxxxxxxxl.         .,'       'ol.  .:oxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxo:.,od,       .:.          ;xxxxxxxxxxxx:          .:'       'oo,.:oxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxdodd,       .l,          'dxxxxxxxxxxd,          'l'       'oxodxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxd;       .l:.         .lxxxxxxxxxxo.          :o'       ,dxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxd:.     .ol.         .:xxxxxxxxxxc.         .co'     .:oxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxd:.   .oo'          ;dxxxxxxxxd;          .oo'   .:oxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxo:. .od;          'oxxxxxxxxo'          ,do' .:oxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxd::oxc.         .cxxxxxxxxl.         .:xd::oxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.          ;xxxxxxxx:.         .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;          'dxxxxxxd,          ,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.        .lxxxxxxo.        .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.      .cxxxxxxc.      .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:.     ;dxxxxd;     .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.   'oxxxxo'   .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:. .cxxxxl. .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:'cxxxxc,:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//
// MEGAMI https://www.megami.io/

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./IMEGAMI.sol";

/**
 * @dev Implementation of the MEGAMI's sales contract.
 */
contract MEGAMISales is ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    /**
     * @dev The struct holding the status of each sale
     */
    struct SalesActiveStatus {
        bool auctionActive;
        bool privateSaleActive;
        bool publicSaleActive;
    }

    /**
     * @dev Minimum token ID of MEGAMI.
     */ 
    uint256 private constant START_TOKEN_ID = 1;

    /**
     * @notice Total supply of MEGAMI tokens.
     */
    uint256 public constant MAX_SUPPLY = 10000;

    /**
     * @notice Reserved MEGAMI tokens reserved for the team.
     */
    uint256 public constant RESERVED_TOKENS_FOR_TEAM = 450;

    /**
     * @notice Length of the auction (seconds)
     */
    uint256 public constant AUCTION_LENGTH = 48 * 60 * 60; // DA finishes after 48 hours

    /**
     * @notice Start price of Origins in the auction.
     */ 
    uint256 public constant AUCTION_STARTING_PRICE_ORIGIN    = 10 ether;

    /**
     * @notice Start price of Alters in the auction.
     */ 
    uint256 public constant AUCTION_STARTING_PRICE_ALTER     = 5 ether;

    /**
     * @notice Start price of Generateds in the auction.
     */ 
    uint256 public constant AUCTION_STARTING_PRICE_GENERATED = 0.2 ether;

    /**
     * @notice Lowest price of MEGAMI tokens in the auction.
     */
    uint256 public constant AUCTION_LOWEST_PRICE = 0.08 ether;

    /**
     * @notice Price drop unit of Origins in the auction. Price reaches the lowest price after 24 hours.
     */
    uint256 public constant AUCTION_PRICE_DROP_UNIT_ORIGIN    = 0.21 ether; 

    /**
     * @notice Price drop unit of Alters in the auction. Price reaches the lowest price after 24 hours.
     */
    uint256 public constant AUCTION_PRICE_DROP_UNIT_ALTER     = 0.1025 ether;

    /**
     * @notice Price drop unit of Generateds in the auction. Price reaches the lowest price after 24 hours.
     */
    uint256 public constant AUCTION_PRICE_DROP_UNIT_GENERATED = 0.0025 ether;

    /**
     * @notice Price drop frequency (seconds).
     */
    uint256 public constant AUCTION_PRICE_DROP_FREQUENCY = 30 * 60;

    /**
     * @notice Total release waves. 
     */
    uint256 public constant TOTAL_RELEASE_WAVES = 5;

    /**
     * @notice Number of Origins in a wave.
     */
    uint256 public constant NUMBER_OF_ORIGINS_IN_WAVE = 6;  // 30 origins divided by 5 waves

    /**
     * @notice Release interval (seconds.)
     */
    uint256 public constant RELEASE_WAVE_TIME_INTERVAL = 60 * 60 * 1; // Relese new wave every 1 hour

    /**
     * @notice Starting time (seconds) of the auction.
     * @dev To convert into readable time https://www.unixtimestamp.com/
     */
    uint256 public auctionStartingTimestamp;

    /**
     * @notice The status of each sale
     */
    SalesActiveStatus public salesStatus = SalesActiveStatus(false, false, false);

    /**
     * @notice The price of MEGAMI tokens in the private/public sale. 
     */
    uint256 public fixedSalePrice = 0.08 ether;

    /**
     * @notice Total number of MEGAMI tokens sold so far.
     */
    uint256 public totalSold = 0;

    /**
     * @dev Address of the fund manager contract.
     */
    address private fundManager;

    /**
     * @dev Address of the MEGAMI token contract.
     */
    IMEGAMI private megamiToken;
    
    /**
     * @dev Signer of the ML management signature.
     */
    address private mlSigner;

    /**
     * @dev Map to manage consumed ML spots per minter.
     */
    mapping(address => uint256) private userToUsedMLs;

    /**
     * @dev Constractor of MEGAMI's sales contract. Setting the MEGAMI token and fund manager.
     * @param megamiContractAddress Address of the MEGAMI token contract.
     * @param fundManagerContractAddress Address of the contract managing funds.
     */
    constructor(address megamiContractAddress, address fundManagerContractAddress){
        megamiToken = IMEGAMI(payable(megamiContractAddress));
        fundManager = payable(fundManagerContractAddress);
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @dev For receiving fund in case someone try to send it.
     */
    receive() external payable {}
    
    /**
     * @dev Set the address of the signer being used for validating Mintlist signatures.
     */
    function setSigner(address signer) external onlyOwner {
        mlSigner = signer;
    }

    /**
     * @dev Mint the specified MEGAMI token with auction price. 
     * @param signature Signature being used for validating the Mintlist spots of the minter.
     * @param mlSpots Total number of mintlist spots allocated to the minter.
     * @param tokenId Token ID being minted.
     */
    function mintDA(bytes calldata signature, uint8 mlSpots, uint256 tokenId) external payable callerIsUser nonReentrant {
        require(salesStatus.auctionActive, "DA isnt active");
        
        //Require DA started
        require(
            block.timestamp >= auctionStartingTimestamp,
            "DA has not started!"
        );        

        require(block.timestamp <= getAuctionEndTime(), "DA is finished");

        // Validate Mintlist
        require(verifySignature(signature, mlSpots), "Signer address mismatch.");

        // Check number of ML spots
        require(
            userToUsedMLs[msg.sender] < mlSpots,
            "All ML spots have been consumed"
        );

        // Check total sold
        require(totalSold < (MAX_SUPPLY - RESERVED_TOKENS_FOR_TEAM), "sold out");

        // Get current mint price
        uint256 _currentPrice = currentPrice(tokenId);

        // Validate the paid amount
        require(msg.value >= _currentPrice, "Did not send enough eth.");

        // Send back overpaid amount if minter sent more than _currentPrice
        if (msg.value > _currentPrice) {
            (bool sent, ) = msg.sender.call{value: msg.value - _currentPrice}("");
            require(sent, "failed to send back fund");
        }

        // Increment used ML spots
        unchecked { ++userToUsedMLs[msg.sender]; }

        // Increment total sold
        unchecked { ++totalSold; }

        megamiToken.mint(tokenId, msg.sender);
    }

    /**
     * @dev Returns the used ML spots of the user
     * @param user The address of a user being checked
     */
    function getUsedMLs(address user) external view returns(uint256) {
        return userToUsedMLs[user];
    }

    /**
     * @dev Set the price of the private/public sale.
     * @param newPrice The new price of the private/public sale.
     */
    function setFixedSalePrice(uint256 newPrice) external onlyOwner {
        fixedSalePrice = newPrice;
    }

    /**
     * @dev Mint the specified MEGAMI token with public price.  
     * @param tokenId Token ID being minted.
     */
    function mintPrivate(bytes calldata signature, uint8 mlSpots, uint256 tokenId) external payable callerIsUser nonReentrant {
        require(salesStatus.privateSaleActive, "Private sale isn't active");

        // Validate eligibility. 
        // Since we don't check the number of mlSpots in Private sale, 
        // mlSpots = 0 works as a waitlist which can mint in private sale.
        require(verifySignature(signature, mlSpots), "Signer address mismatch.");

        require(msg.value == fixedSalePrice, "Incorrect amount of eth.");

        // Check total sold
        require(totalSold < (MAX_SUPPLY - RESERVED_TOKENS_FOR_TEAM), "sold out");

        // Increment total sold
        unchecked { ++totalSold; }

        megamiToken.mint(tokenId, msg.sender);
    }

    /**
     * @dev Mint the specified MEGAMI token with public price.  
     * @param tokenId Token ID being minted.
     */
    function mintPublic(uint256 tokenId) external payable callerIsUser nonReentrant {
        require(salesStatus.publicSaleActive, "Public sale isn't active");
        require(msg.value == fixedSalePrice, "Incorrect amount of eth.");

        // Check total sold
        require(totalSold < (MAX_SUPPLY - RESERVED_TOKENS_FOR_TEAM), "sold out");

        // Increment total sold
        unchecked { ++totalSold; }

        megamiToken.mint(tokenId, msg.sender);
    }

    /**
     * @dev Mint the specified MEGAMI tokens and send to the specified recipient. Mainly used for giving Free MEGAMIs.
     * @param recipient Recipient whom minted tokens are transfered to.
     * @param tokenIds Token IDs being minted.
     */
    function mintTeam(address recipient, uint256[] calldata tokenIds) external onlyOwner {
        require(address(recipient) != address(0), "recipient address is necessary");
        uint256 count = tokenIds.length;
        for (uint256 i = 0; i < count;) {
            // Increment total sold
            unchecked { ++totalSold; }

            megamiToken.mint(tokenIds[i], recipient);
            unchecked { ++i; }
        }
    }

    /**
     * @dev Set the active status of auction.
     */
    function setDutchActionActive(bool isActive) external onlyOwner {
        require(mlSigner != address(0), "Mintlist signer must be set before starting auction");
        salesStatus.auctionActive = isActive;
    }

    /**
     * @dev Returns the active status of the auction
     */
    function getDutchAuctionActive() external view returns (bool) {
        return salesStatus.auctionActive;
    }

    /**
     * @dev Set the active status of private sale.
     */
    function setPrivateSaleActive(bool isActive) external onlyOwner {
        salesStatus.privateSaleActive = isActive;
    }

    /**
     * @dev Returns the active status of the private sale
     */
    function getPrivateSaleActive() external view returns (bool) {
        return salesStatus.privateSaleActive;
    }

    /**
     * @dev Set the active status of public sale.
     */
    function setPublicSaleActive(bool isActive) external onlyOwner {
        salesStatus.publicSaleActive = isActive;
    }

    /**
     * @dev Returns the active status of the public sale
     */
    function getPublicSaleActive() external view returns (bool) {
        return salesStatus.publicSaleActive;
    }
    
    /**
     * @dev Set the address of the fund manager contract.
     * @param contractAddr Address of the contract managing funds.
     */
    function setFundManagerContract(address contractAddr)
        external
        onlyOwner
    {
        require(contractAddr != address(0), "invalid address");
        fundManager = contractAddr;
    } 

    /**
     * @dev Return the address of the fund manager contarct.
     */
    function getFundManagerContract() external view returns (address) {
        return fundManager;
    }

    /**
     * @dev Allow owner to send funds directly to recipient. This is for emergency purpose and use moveFundToManager for regular withdraw.
     * @param recipient The address of the recipinet.
     */
    function emergencyWithdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "recipient shouldn't be 0");

        (bool sent, ) = recipient.call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    /**
     * @dev Move all of funds to the fund manager contract.
     */
    function moveFundToManager() external onlyOwner {
        require(fundManager != address(0), "fundManager shouldn't be 0");
        
        (bool sent, ) = fundManager.call{value: address(this).balance}("");
        require(sent, "failed to move fund to FundManager contract");
    }

    /**
     * @dev ERC20s should not be sent to this contract, but if someone does, it's nice to be able to recover them.
     *      Copied from ForgottenRunesWarriorsGuild. Thank you dotta ;)
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) public onlyOwner {
        token.transfer(msg.sender, amount);
    }

    /**
     * @dev Return the current price of the specified token.
     * @param tokenId Token ID the price is being returned for.
     */
    function currentPrice(uint256 tokenId) public view returns (uint256) {
        require(tokenId >= START_TOKEN_ID && tokenId < START_TOKEN_ID + MAX_SUPPLY, "invalid token id");

        uint256 currentTimestamp = block.timestamp;
        uint256 wave = getWave(tokenId);
        uint256 waveDAStartedTimestamp = auctionStartingTimestamp + (RELEASE_WAVE_TIME_INTERVAL * wave);

        require(
            currentTimestamp >= waveDAStartedTimestamp,
            "wave mint yet"
        );

        //Seconds since we started
        uint256 timeSinceStart = currentTimestamp - waveDAStartedTimestamp;

        //How many decrements should've happened since that time
        uint256 decrementsSinceStart = timeSinceStart / AUCTION_PRICE_DROP_FREQUENCY;

        // Check the type of Megami and setting staring price and price drop
        uint256 startingPrice = AUCTION_STARTING_PRICE_GENERATED;
        uint256 priceDecrement = AUCTION_PRICE_DROP_UNIT_GENERATED;

        // Since the range of tokenId is 1 to 10000, we need to convert it to 0 to 9999 for getting the expected sequence id
        uint256 sequenceIdInWave = (tokenId - 1) % getSupplyPerWave();
        if(sequenceIdInWave < NUMBER_OF_ORIGINS_IN_WAVE + getNumberOfAlters(wave)) {
            if(sequenceIdInWave < NUMBER_OF_ORIGINS_IN_WAVE) {
                // Origin
                startingPrice = AUCTION_STARTING_PRICE_ORIGIN;
                priceDecrement = AUCTION_PRICE_DROP_UNIT_ORIGIN;
            } else {
                // Alter
                startingPrice = AUCTION_STARTING_PRICE_ALTER;
                priceDecrement = AUCTION_PRICE_DROP_UNIT_ALTER;
            }
        }

        // How much eth to remove
        uint256 totalDecrement = decrementsSinceStart * priceDecrement;

        //If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= startingPrice - AUCTION_LOWEST_PRICE) {
            return AUCTION_LOWEST_PRICE;
        }

        //If not, return the starting price minus the decrement.
        return startingPrice - totalDecrement;
    }

    /**
     * @dev Return the wave the specified token is being released.
     * @param tokenId Token ID the release wave is being returned for.
     */
    function getWave(uint256 tokenId) public pure returns (uint256) {
        // Since the range of tokenId is 1 to 10000, we need to convert it to 0 to 9999 for getting the expected wave number
        return (tokenId - 1) / getSupplyPerWave();
    }

    /**
     * @dev Set the start time of the auction. 
     * @param startTime Start time in unix timestamp format.
     */
    function setAuctionStartTime(uint256 startTime) public onlyOwner {
        auctionStartingTimestamp = startTime;
    }

    /**
     * @dev Returns the end time of the auction in unix timestamp format.
     */
    function getAuctionEndTime() public view returns (uint256) {
        return auctionStartingTimestamp + AUCTION_LENGTH;
    }
    
    /**
     * @dev Do nothing for disable renouncing ownership.
     */ 
    function renounceOwnership() public override onlyOwner {}     

    /**
     * @dev Returns the release waves where extra Alter are released. 
     *      Since there are 24 Alters and we can't evenly release them in each release wave, we need to release extra Alter in some waves.
     * @param wave Relase wave that this function checks if extra Alter is relased or not.
     */
    function getNumberOfAlters(uint256 wave) private pure returns (uint256) {
        // Since there are only 24 alters, it runs short of them in the 5th wave.
        return wave == 4 ? 4 : 5;
    }

    /**
     * @dev Return the amount of tokens being released in each release wave.
     */
    function getSupplyPerWave() private pure returns (uint256) {
        return MAX_SUPPLY / TOTAL_RELEASE_WAVES;
    }

    /**
     * @dev Verify the signature passed to the auction/private mint functions
     */
    function verifySignature(bytes calldata signature, uint8 mlSpots) private view returns (bool) {
        // Message format is 1 byte shifted address + number of MLs (1 byte)
        uint256 message = (uint256(uint160(msg.sender)) << 8) + mlSpots;
        
        return
            mlSigner ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(message)
                    )
                ).recover(signature);
    }
}
