// SPDX-License-Identifier: MIT
// dev: @brougkr

/**@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,.................................#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%............................................../@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@........................................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@,...............................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@......................................................................#@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@.............,,***..........................................................@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@..............,******...........................................................*@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#.................,***,...............................................................@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@%........................................................................................,@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@.......,**,.................................................................................#@@@@@@@@@@@@@
@@@@@@@@@@@@*...............................................................................................@@@@@@@@@@@@
@@@@@@@@@@@..................................................................................................@@@@@@@@@@@
@@@@@@@@@@..................................................................................................../@@@@@@@@@
@@@@@@@@@........,............................................................................................./@@@@@@@@
@@@@@@@@........,,..............................................................................................#@@@@@@@
@@@@@@@........,,................................................................................................@@@@@@@
@@@@@@(........**..,*****,........................................................................................@@@@@@
@@@@@@........,*,..,****,,........................................................................................&@@@@@
@@@@@%........***,................................................................................................,@@@@@
@@@@@,........**,*.................................................................................................@@@@@
@@@@@........,****..................................WEN...MOON...?.................................................@@@@@
@@@@@........,**,**................................................................................................@@@@@
@@@@@.........*****,    ................,*******...................................................................@@@@@
@@@@@*........**,***.     ..............********,..Moonopoly 2022..................................................@@@@@
@@@@@&.........   ,**.    ...............******.........**........................................................,@@@@@
@@@@@@.....          *.  ...............................,,........................................................@@@@@@
@@@@@@%...           .*,..........................................................................................@@@@@@
@@@@@@@....          ,***...........        .....................................................................@@@@@@@
@@@@@@@@....       .******,.........        ...............   ..................................................&@@@@@@@
@@@@@@@@@.........,,,,,,,,,,,.........     .....,,,,,..........................................................%@@@@@@@@
@@@@@@@@@@..........**********,..................,,...........................................................&@@@@@@@@@
@@@@@@@@@@@..........***....,***,...............................................,**..........................@@@@@@@@@@@
@@@@@@@@@@@@%..........*....****,**,..........................................,*****,......................,@@@@@@@@@@@@
@@@@@@@@@@@@@@...........*******,*****,.........,***,.......,,.................,,**,......................@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@...........*****,,,*******.....******.....,****.........................................(@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@...........,.......*********,..,,.................................................../@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@.................**************,.......................................,,.......&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@#.............,***,***,***,***,**,..........................,,,***,........,@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@*..............,******,.,******......**,*******************,..........@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.................    .*************,*************,............*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.......................,,,,****,,,,,..................*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(............................................,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*...............................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%%&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@**/

pragma solidity 0.8.11;
import "./ERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract MoonopolyV1 is ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable
{
    // Initialization
    string public constant name = "Moonopoly";
    string public constant symbol = "MOON";
    string public _BASE_URI;

    // Variables
    uint256 public _CARDS_MINTED;
    uint256 public _MAX_CARDS;
    uint256 public _MAX_CARDS_PURCHASE;
    uint256 public _AIRDROP_AMOUNT;
    uint256 public _CARD_PRICE;
    uint256 public _UNIQUE_CARDS;
    uint256 public _MINIMUM_CARD_INDEX;
    uint256 private _randomSeed;

    // Sale State
    bool public _SALE_ACTIVE;
    bool public _AIRDROP_ACTIVE;
    bool public _ALLOW_MULTIPLE_PURCHASES;

    // Mappings
    mapping (uint256 => uint256) public _CARD_ID_ALLOCATION;
    mapping (address => bool) public minted;
    mapping (address => uint256) public airdrop;

    // Events
    event MoonopolyAirdropClaimed(address indexed recipient, uint256 indexed amt);
    event MoonopolyPublicMint(address indexed recipient, uint256 indexed amt);
    event AddAirdropRecipients(address[] wallets);

    /**
     * @dev Proxy Initializer
     */
    function initialize() public initializer
    {   
        __Context_init_unchained(); // Init Context
        __ERC1155_init_unchained("https://ipfs.io/ipfs/QmUQBkrxxk9dm78zhzNR41FmHPYrXKUB1QCAJ4ewtRPX7s/{id}.json"); // Init ERC1155
        __Ownable_init_unchained(); // Init Ownable
        __Pausable_init_unchained(); // Init Pausable
        transferOwnership(0x366DA24FD360C5789A5bEb2bE0e72a0FF3BD853C);
        _BASE_URI = "https://ipfs.io/ipfs/QmUQBkrxxk9dm78zhzNR41FmHPYrXKUB1QCAJ4ewtRPX7s/";
        _CARDS_MINTED = 1;
        _MAX_CARDS = 5555;
        _MAX_CARDS_PURCHASE = 5;
        _AIRDROP_AMOUNT = 3;
        _CARD_PRICE = 0.03 ether;
        _UNIQUE_CARDS = 33;
        _MINIMUM_CARD_INDEX = 1;
        _randomSeed = 0x00;
        _SALE_ACTIVE = false;
        _AIRDROP_ACTIVE = true;
        _ALLOW_MULTIPLE_PURCHASES = true;
        _CARD_ID_ALLOCATION[1] = 1; // Lagos Full Miner
        _CARD_ID_ALLOCATION[2] = 3; // Lagos 4 Node
        _CARD_ID_ALLOCATION[3] = 5; // Lagos 3 Node
        _CARD_ID_ALLOCATION[4] = 7; // Lagos 2 Node
        _CARD_ID_ALLOCATION[5] = 9; // Lagos 1 Node
        _CARD_ID_ALLOCATION[6] = 40; // Miami
        _CARD_ID_ALLOCATION[7] = 40; // NYC
        _CARD_ID_ALLOCATION[8] = 60; // Beijing
        _CARD_ID_ALLOCATION[9] = 60; // Shanghai
        _CARD_ID_ALLOCATION[10] = 60; // Hong Kong
        _CARD_ID_ALLOCATION[11] = 90; // Mumbai
        _CARD_ID_ALLOCATION[12] = 90; // New Delhi
        _CARD_ID_ALLOCATION[13] = 90; // Kolkata
        _CARD_ID_ALLOCATION[14] = 100; // Zurich
        _CARD_ID_ALLOCATION[15] = 100; // Geneva
        _CARD_ID_ALLOCATION[16] = 100; // Basel
        _CARD_ID_ALLOCATION[17] = 150; // Lima
        _CARD_ID_ALLOCATION[18] = 150; // Cusko
        _CARD_ID_ALLOCATION[19] = 150; // Arequipa
        _CARD_ID_ALLOCATION[20] = 250; // Istanbul
        _CARD_ID_ALLOCATION[21] = 250; // Ankara
        _CARD_ID_ALLOCATION[22] = 250; // Izmir
        _CARD_ID_ALLOCATION[23] = 300; // Davao
        _CARD_ID_ALLOCATION[24] = 300; // Manila
        _CARD_ID_ALLOCATION[25] = 300; // Bohol
        _CARD_ID_ALLOCATION[26] = 400; // Saigon
        _CARD_ID_ALLOCATION[27] = 400; // Hanoi
        _CARD_ID_ALLOCATION[28] = 200; // Coinbase
        _CARD_ID_ALLOCATION[29] = 200; // Binance
        _CARD_ID_ALLOCATION[30] = 200; // Gemini
        _CARD_ID_ALLOCATION[31] = 200; // Kraken
        _CARD_ID_ALLOCATION[32] = 500; // Solar
        _CARD_ID_ALLOCATION[33] = 500; // Wind
    }

    /*---------------------*
    *   PUBLIC FUNCTIONS   * 
    *----------------------*/

    /**
     * @dev Moonopoly Public Mint
     */
    function MoonopolyMint(uint256 numberOfTokens) public payable nonReentrant
    {
        require(_SALE_ACTIVE, "Public Sale Must Be Active To Mint Cards");
        require(numberOfTokens <= _MAX_CARDS_PURCHASE, "Can Only Mint 5 Cards At A Time");
        require(_CARDS_MINTED + numberOfTokens <= _MAX_CARDS, "Purchase Would Exceed Max Supply Of Cards");
        require(_CARD_PRICE * numberOfTokens == msg.value, "Ether Value Sent Is Not Correct.");
        if(!_ALLOW_MULTIPLE_PURCHASES) { require(!minted[msg.sender], "Address Has Already Minted"); }
        minted[msg.sender] = true;
        for(uint256 i = 0; i < numberOfTokens; i++) 
        {
            uint256 cardID = _drawCard(numberOfTokens);
            _CARD_ID_ALLOCATION[cardID] -= 1;
            _CARDS_MINTED += 1;
            _mint(msg.sender, cardID, 1, "");
        }
        emit MoonopolyPublicMint(msg.sender, numberOfTokens);
    }

    /**
     * @dev Moonopoly Airdrop
     */
    function MoonopolyAirdrop() public nonReentrant
    {
        require(_AIRDROP_ACTIVE, "Airdrop is not active");
        uint256 amt = airdrop[msg.sender];
        require(amt > 0, "Sender wallet is not on airdrop Access List");
        airdrop[msg.sender] = 0;
        for(uint256 i = 0; i < amt; i++)
        {
            uint256 cardID = _drawCard(amt);
            _CARD_ID_ALLOCATION[cardID] -= 1;
            _CARDS_MINTED += 1;
            _mint(msg.sender, cardID, 1, "");
        }
        emit MoonopolyAirdropClaimed(msg.sender, amt);
    }

    /*---------------------*
    *   PRIVATE FUNCTIONS  * 
    *----------------------*/

    /**
     * @dev Draws Pseudorandom Card From Available Stack
     */
    function _drawCard(uint256 salt) private returns (uint256) 
    {
        for (uint256 i = 1; i < 4; i++) 
        {
            uint256 value = _pseudoRandom(i + _CARDS_MINTED + salt);
            if (_canMint(value)) 
            { 
                _randomSeed = value;
                return value; 
            }
        }

        // If Pseudorandom Card Is Not Valid After 3 Tries, Draw From Top Of The Stack
        return _drawAvailableCard();
    }

    /*---------------------*
    *    VIEW FUNCTIONS    * 
    *----------------------*/

    /**
     * @dev Returns Total Supply
     */
    function totalSupply() external view returns (uint256) { return(_CARDS_MINTED); }

    /**
     * @dev Returns URI for decoding storage of tokenIDs
     */
    function uri(uint256 tokenId) override public view returns (string memory) { return(string(abi.encodePacked(_BASE_URI, StringsUpgradeable.toString(tokenId), ".json"))); }

    /**
     * @dev Returns Result Of Card ID Has Sufficient Allocation
     */
    function _canMint(uint256 cardID) private view returns (bool) { return (_CARD_ID_ALLOCATION[cardID] > 0); }

    /**
     * @dev Returns Pseudorandom Number
     */
    function _pseudoRandom(uint256 salt) private view returns (uint256) 
    {
        uint256 pseudoRandom =
            uint256(
                keccak256(
                    abi.encodePacked(
                        salt,
                        block.timestamp,
                        blockhash(block.difficulty - 1),
                        block.number,
                        _randomSeed,
                        'MOONOPOLY',
                        'WEN MOON?',
                        msg.sender
                    )
                )
            ) % _UNIQUE_CARDS+_MINIMUM_CARD_INDEX;
        return pseudoRandom;
    }
    
    /**
     * @dev Decrements Through Available Card Stack
     */
    function _drawAvailableCard() private view returns (uint256) 
    {
        for(uint256 i = _UNIQUE_CARDS; i > _MINIMUM_CARD_INDEX; i--)
        {
            if(_canMint(i)) 
            { 
                return i;
            }
        }
        revert("Insufficient Card Amount"); // Insufficient Allocation Of CardIDs To Mint
    }

    /**
     * @dev Conforms to ERC-1155 Standard
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override 
    { 
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data); 
    }

    /*---------------------*
    *    ADMIN FUNCTIONS   * 
    *----------------------*/

    /**
     * @dev Batch Transfers Tokens
     */
    function __batchTransfer(address[] calldata recipients, uint256[] calldata tokenIDs, uint256[] calldata amounts) external onlyOwner 
    { 
        for(uint256 i=0; i < recipients.length; i++) 
        { 
            _safeTransferFrom(msg.sender, recipients[i], tokenIDs[i], amounts[i], ""); 
        }
    }

    /**
     * @dev Modify Airdrop Recipients On Airdrop Access List
     */
    function __modifyAirdropRecipients(address[] calldata recipients) external onlyOwner
    {
        for(uint256 i = 0; i < recipients.length; i++)
        {
            airdrop[recipients[i]] = _AIRDROP_AMOUNT;
        }
        emit AddAirdropRecipients(recipients);
    }

    /**
     * @dev Modify Airdrop Recipients On Airdrop Access List With Amounts
     */
    function __modifyAirdropRecipientsAmt(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner
    {
        require(recipients.length == amounts.length, "Invalid Data Formatting");
        for(uint256 i = 0; i < recipients.length; i++)
        {
            airdrop[recipients[i]] = amounts[i];
        }
        emit AddAirdropRecipients(recipients);
    }

    /**
     * @dev Modifies Card Allocations For Future Expansions
     */
    function __modifyCardAllocations(uint256[] calldata cardIDs, uint256[] calldata amounts) external onlyOwner
    {
        require(cardIDs.length == amounts.length, "Invalid Data Formatting");
        for(uint256 i = 0; i < cardIDs.length; i++)
        {
            _CARD_ID_ALLOCATION[cardIDs[i]] = amounts[i];
        }
    }

    /**
     * @dev ADMIN: Mints Expansion Cards For Future Community Airdrops Outside Of The Core Collection :)
     */
    function __mintExpansionCards(address[] calldata addresses, uint256[] calldata cardIDs, uint256[] calldata amounts) external onlyOwner
    {
        require(addresses.length == cardIDs.length && cardIDs.length == amounts.length, "Invalid Data Formatting");
        _CARDS_MINTED += amounts.length;
        for(uint256 i = 0; i < addresses.length; i++) 
        { 
            _mint(addresses[i], cardIDs[i], amounts[i], ""); 
        }
    } 

    /**
     * @dev ADMIN: Reserves Cards For Marketing & Core Team
     */
    function __reserveCards(uint256 amt, address account) external onlyOwner
    {
        require(_CARDS_MINTED + amt <= _MAX_CARDS, "Overflow");
        for(uint256 i = 0; i < amt; i++)
        {
            uint256 cardID = _drawCard(amt);
            _CARD_ID_ALLOCATION[cardID] -= 1;
            _CARDS_MINTED += 1;
            _mint(account, cardID, 1, "");
        }
    }

    /**
     * @dev ADMIN: Sets Base URI For .json Hosting
     */
    function __setBaseURI(string memory BASE_URI) external onlyOwner { _BASE_URI = BASE_URI; }
    
    /**
     * @dev ADMIN: Sets Max Cards For future Card Expansion Packs
     */
    function __setMaxCards(uint256 MAX_CARDS) external onlyOwner { _MAX_CARDS = MAX_CARDS; }

    /**
     * @dev ADMIN: Sets Unique Card Index For Future Card Expansion Packs
     */
    function __setUniqueCards(uint256 uniqueCards) external onlyOwner { _UNIQUE_CARDS = uniqueCards; }

    /**
     * @dev ADMIN: Sets Minimum Card Index
     */
    function __setCardIndex(uint256 MINIMUM_CARD_INDEX) external onlyOwner { _MINIMUM_CARD_INDEX = MINIMUM_CARD_INDEX; }

    /**
     * @dev ADMIN: Sets Max Cards Purchasable By Wallet
     */
    function __setMaxCardsPurchase(uint256 MAX_CARDS_PURCHASE) external onlyOwner { _MAX_CARDS_PURCHASE = MAX_CARDS_PURCHASE; }

    /**
     * @dev ADMIN: Sets Future Card Price
     */
    function __setCardPrice(uint256 CARD_PRICE) external onlyOwner { _CARD_PRICE = CARD_PRICE; }

    /**
     * @dev ADMIN: Flips Allowing Multiple Purchases For Future Card Expansion Packs
     */
    function __flip_allowMultiplePurchases() external onlyOwner { _ALLOW_MULTIPLE_PURCHASES = !_ALLOW_MULTIPLE_PURCHASES; }
    
    /**
     * @dev ADMIN: Flips Sale State
     */
    function __flip_saleState() external onlyOwner { _SALE_ACTIVE = !_SALE_ACTIVE; }
    
    /**
     * @dev ADMIN: Flips Airdrop State
     */
    function __flip_airdropState() external onlyOwner { _AIRDROP_ACTIVE = !_AIRDROP_ACTIVE; }

    /**
     * @dev ADMIN: Withdraws Ether from Contract
     */
    function __withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev ADMIN: Pauses Contract
     */
    function __pause() external onlyOwner { _pause(); }

    /**
     * @dev ADMIN: Unpauses Contract
     */
    function __unpause() external onlyOwner { _unpause(); }
}
