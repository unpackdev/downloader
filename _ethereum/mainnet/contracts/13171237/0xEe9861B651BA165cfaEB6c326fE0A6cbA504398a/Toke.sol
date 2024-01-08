pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./console.sol";


import "./Ownable.sol";
import "./ERC1155.sol";
import "./ReentrancyGuard.sol";


contract Toke is Ownable, ERC1155, ReentrancyGuard {
    using SafeMath for uint256;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/
    // For Minting and Burning, locks the prices
    bool private _enabled = false;
    // For metadata (scripts), when locked, cannot be changed
    bool private _locked = false;

    // Number of script sections stored
    uint256 public scriptCount = 0;
    // The scripts that can be used to render the NFT (audio and visual)
    mapping (uint256 => string) scripts;

    // The 40 bit is flag to distinguish prints - 1 for print
    uint256 constant SEED_MASK = uint40(~0);
    uint256 constant PRINTS_FLAG_BIT = 1 << 39;

    // Supply restriction on prints
    uint256 constant MAX_PRINT_SUPPLY = 120;
    // Supply restriction on seeds/original NFTs
    uint256 constant MAX_SEEDS_SUPPLY = 27;

    // Owner of the seed/original NFT
    mapping(uint256 => address payable) public seedToOwner;

    // Total number of seeds/original NFTs minted
    uint256 public originalsMinted = 0;

    // Total supply of prints and seeds/original NFTs
    mapping(uint256 => uint256) public totalSupply;
    
    // Cost of minting an original/seed 
    uint256 public mintPrice = 0.271 ether;
    // Funds reserved for burns
    uint256 public reserve = 0;

    // For bonding curve
    uint256 constant K = 1 ether;
    uint256 constant B = 50;
    uint256 constant C = 26;
    uint256 constant D = 8;
    uint256 constant SIG_DIGITS = 3;


    /**
     * @dev Emitted when an original NFT with a new seed is minted
     */
    event MintOriginal(
        address indexed to, 
        uint256 seed, 
        uint256 indexed originalsMinted
    );

    /**
    * @dev Emitted when an print is minted
    */
    event PrintMinted(
        address indexed to,
        uint256 id,
        uint256 indexed seed,
        uint256 pricePaid,
        uint256 nextPrintPrice,
        uint256 nextBurnPrice,
        uint256 printsSupply,
        uint256 royaltyPaid,
        uint256 reserve,
        address indexed royaltyRecipient
    );

    /**
     * @dev Emitted when an print is burned
     */
    event PrintBurned(
        address indexed to,
        uint256 id,
        uint256 indexed seed,
        uint256 priceReceived,
        uint256 nextPrintPrice,
        uint256 nextBurnPrice,
        uint256 printsSupply,
        uint256 reserve
    );


    constructor() public ERC1155("https://holdyourtoke.com/api2/token/{id}.json") {
        // pineapple_express
        mintMaster(1, address(0x3d335baC4bdF75587D6d6D1666E8a5a34EA4e0e0));

        // gorilla_glue
        mintMaster(2, address(0xfa17925c3566a95901FC0874515193B759127CBa));

        // og_kush
        mintMaster(3, address(0x26921A182Cf9D6F33730D7F37E1a86fd430863Af));

        // acapulco_gold
        mintMaster(4, address(0x308FfD2CBa9dC0994EC0f1c7fa0298985d2Ae85a));

        // alien_dawg
        mintMaster(5, address(0x1AF69C824E0B8c0E433b744A674FCbb1Ea67Ce60));

        // star_dawg
        mintMaster(6, address(0x8aF339E7D066A8743E90d3475da42F5723e4db5A));

        // purple_haze
        mintMaster(7, address(0xDB32BA810398F8926B5C30Ee213723484999d0C6));

        // strawberry_cough
        mintMaster(8, address(0x6cc226e09Bf5ddC6A919afA7775c19Af283178F6));

        // ak_47
        mintMaster(9, address(0x544D7c95EBE35677aF8A1Ac539495327ccBaFC9A));

        // chem_dawg
        mintMaster(10, address(0x7c58cB9a5ebcd75452489dAc2Cd502387069c480));

        // cookies_and_cream
        mintMaster(11, address(0xBA29bF8046D46D687Dc00f09caddB0C83540CaEB));

        // ghost_train_haze
        mintMaster(12, address(0x09055D850Dc88258ebA0F69b1d2b4572f2358de8));

        // headband
        mintMaster(13, address(0x26921A182Cf9D6F33730D7F37E1a86fd430863Af));

        // birthday_cake
        mintMaster(14, address(0xdf8016FD49e1942E76A75a89c7ff8A6a73b5a8aF));

        // captain_kush
        mintMaster(15, address(0x3145B6AFBe66a0a15CfBa8CF1414941ed54B37f9));

        // brain_og
        mintMaster(16, address(0x8aF339E7D066A8743E90d3475da42F5723e4db5A));

        // blue_dream
        mintMaster(17, address(0x6cc226e09Bf5ddC6A919afA7775c19Af283178F6));

        // bubblegum
        mintMaster(18, address(0xcD815B9302bC6a828294CE6aa7C353B206997A4e));

        // maui_wowie
        mintMaster(19, address(0xC7592F5A79b8d7D49A692999B84801D08F39749e));

        // purple_punch
        mintMaster(20, address(0xD55Eb5Bae961a39C8923c809fB0E12F6164D7f9f));

        // sour_diesel
        mintMaster(21, address(0xC1ba9285ACBae7dC403153F9E5c2B4108AB5ACdc));    
    }
    

    modifier onlyWhenEnabled() {
        require(_enabled, "Contract is disabled");
        _;
    }
    modifier onlyWhenDisabled() {
        require(!_enabled, "Contract is enabled");
        _;
    }
    modifier onlyUnlocked() {
        require(!_locked, "Contract is locked");
        _;
    }


    function mintMaster(uint256 seed, address account)
         public
         onlyOwner
         returns (uint256)
    {
        uint256 newOriginalsMinted = originalsMinted.add(1);
        
        require(
            newOriginalsMinted <= MAX_SEEDS_SUPPLY,
            "Max supply reached"
        );

        originalsMinted = newOriginalsMinted;

        _mint(account, seed, 1, "");

        emit MintOriginal(account, seed, newOriginalsMinted);
        return seed;
    }

    /**
        * @dev Function to mint prints from an existing seed. Msg.value must be sufficient.
        * @param seed The NFT id to mint print of
        */
    function mintPrint(uint256 seed)
        public
        payable
        nonReentrant
        onlyWhenEnabled
        returns (uint256)
    {
        require(seedToOwner[seed] != address(0), "Seed does not exist");
        uint256 tokenId = getPrintTokenIdFromSeed(seed);
        uint256 oldSupply = totalSupply[tokenId];

        // Get price to mint the next print
        uint256 printPrice = getPrintPrice(oldSupply + 1);

        require(msg.value >= printPrice, "Insufficient funds");

        uint256 newSupply = totalSupply[tokenId].add(1);
        totalSupply[tokenId] = newSupply;

        // Update reserve - reserveCut == Price to burn next token
        uint256 reserveCut = getBurnPrice(newSupply);
        reserve = reserve.add(reserveCut);

        // Calculate fees - seedOwner gets 80% of fee (printPrice - reserveCut)
        uint256 seedOwnerRoyalty = _getSeedOwnerCut(printPrice.sub(reserveCut));

        // Mint token
        _mint(msg.sender, tokenId, 1, "");

        // // Disburse royalties
        address seedOwner = seedToOwner[seed];
        (bool success, ) = seedOwner.call{value: seedOwnerRoyalty}("");
        require(success, "Payment failed");
        // Remaining 20% kept for contract/Treum

        // If buyer sent extra ETH as padding in case another purchase was made they are refunded
        _refundSender(printPrice);

        emit PrintMinted(msg.sender, tokenId, seed, printPrice, getPrintPrice(newSupply.add(1)), reserveCut, newSupply, seedOwnerRoyalty, reserve, seedOwner);
        return tokenId;
    }

    /**
     * @dev Function to burn a print
     * @param seed The seed for the print to burn.
     * @param minimumSupply The minimum token supply for burn to succeed, this is a way to set slippage. 
     * Set to 1 to allow burn to go through no matter what the price is.
     */
    function burnPrint(uint256 seed, uint256 minimumSupply) 
        public 
        nonReentrant
        onlyWhenEnabled
    {
        require(seedToOwner[seed] != address(0), "Seed does not exist");
        uint256 tokenId = getPrintTokenIdFromSeed(seed);

        uint256 oldSupply = totalSupply[tokenId];
        require(oldSupply >= minimumSupply, 'Min supply not met');

        uint256 burnPrice = getBurnPrice(oldSupply);

        uint256 newSupply = totalSupply[tokenId].sub(1);
        totalSupply[tokenId] = newSupply;

        // Update reserve
        reserve = reserve.sub(burnPrice);

        _burn(msg.sender, tokenId, 1);

        // Disburse funds
        (bool success, ) = msg.sender.call{value: burnPrice}("");
        require(success, "Burn payment failed");

        emit PrintBurned(msg.sender, tokenId, seed, burnPrice, getPrintPrice(oldSupply), getBurnPrice(newSupply), newSupply, reserve);
    }


    /***********************************|
    |   Public Getters - Pricing        |
    |__________________________________*/
    /**
     * @dev Function to get print price
     * @param printNumber the print number of the print Ex. if there are 2 existing prints, and you want to get the
     * next print price, then this should be 3 as you are getting the price to mint the 3rd print
     */
    function getPrintPrice(uint256 printNumber) public pure returns (uint256 price) {
        require(printNumber <= MAX_PRINT_SUPPLY, "Maximum supply exceeded");

        uint256 decimals = 10 ** SIG_DIGITS;
        if (printNumber < B) {
            price = (10 ** ( B.sub(printNumber) )).mul(decimals).div(11 ** ( B.sub(printNumber)));
        } else if (printNumber == B) {
            price = decimals;     // price = decimals * (A ^ 0)
        } else {
            price = (11 ** ( printNumber.sub(B) )).mul(decimals).div(10 ** ( printNumber.sub(B) ));
        }
        price = price.add(C.mul(printNumber));

        price = price.sub(D);
        price = price.mul(1 ether).div(decimals);
    }

    /**
     * @dev Function to get funds received when burned
     * @param supply the supply of prints before burning. Ex. if there are 2 existing prints, to get the funds
     * receive on burn the supply should be 2
     */
    function getBurnPrice(uint256 supply) public pure returns (uint256 price) {
        uint256 printPrice = getPrintPrice(supply);
        price = printPrice * 90 / 100;  // 90 % of print price
    }

    /***********************************|
    | Public Getters - Seed + Prints    |
    |__________________________________*/
    /**
     * @dev Get the number of prints minted for the corresponding seed
     * @param seed The seed/original NFT token id
     */
    function seedToPrintsSupply(uint256 seed)
        public
        view
        returns (uint256)
    {
        uint256 tokenId = getPrintTokenIdFromSeed(seed);
        return totalSupply[tokenId];
    }

    function getNextPrintPrice(uint256 seed)
        public
        view
        returns (uint256 printPrice)
    {
        uint256 tokenId = getPrintTokenIdFromSeed(seed);
        return getPrintPrice(totalSupply[tokenId] + 1);
    }

    function getNextBurnPrice(uint256 seed)
        public
        view
        returns (uint256 burnPrice)
    {
        uint256 tokenId = getPrintTokenIdFromSeed(seed);
        return getBurnPrice(totalSupply[tokenId]);
    }


    /**
     * @dev The token id for the prints contains the seed/original NFT id
     * @param seed The seed/original NFT token id
     */
    function getPrintTokenIdFromSeed(uint256 seed) public pure returns (uint256) {
        return seed | PRINTS_FLAG_BIT;
    }

    /***********************************|
    |  Internal Functions - Prints      |
    |__________________________________*/
    function _getSeedOwnerCut(uint256 fee) internal pure returns (uint256) {
        return fee.mul(8).div(10);
    }

    function _refundSender(uint256 printPrice) internal {
        if (msg.value.sub(printPrice) > 0) {
            (bool success, ) =
                msg.sender.call{value: msg.value.sub(printPrice)}("");
            require(success, "Refund failed");
        }
    }


    /***********************************|
    |        Admin                      |
    |__________________________________*/
    /**
     * @dev Set mint price for seed/original NFT
     * @param _mintPrice The cost of an original
     */
    function setPrice(uint256 _mintPrice) public onlyOwner onlyWhenDisabled {
        mintPrice = _mintPrice;
    }

    function addScript(string memory _script) public onlyOwner onlyUnlocked {
        scripts[scriptCount] = _script;
        scriptCount = scriptCount.add(1);
    }

    function updateScript(string memory _script, uint256 index) public onlyOwner onlyUnlocked {
        require(index < scriptCount, "Index out of bounds");
        scripts[index] = _script;
    }

    function resetScriptCount() public onlyOwner onlyUnlocked {
        scriptCount = 0;
    }

    /**
     * @dev Withdraw earned funds from original Nft sales and print fees. Cannot withdraw the reserve funds.
     */
    function withdraw() public onlyOwner {
        uint256 withdrawableFunds = address(this).balance.sub(reserve);
        msg.sender.transfer(withdrawableFunds);
    }

    /**
     * @dev Function to enable/disable token minting
     * @param enabled The flag to turn minting on or off
     */
    function setEnabled(bool enabled) public onlyOwner {
        _enabled = enabled;
    }

    /**
     * @dev Function to lock/unlock the on-chain metadata
     * @param locked The flag turn locked on
     */
    function setLocked(bool locked) public onlyOwner onlyUnlocked {
        _locked = locked;
    }

    /**
     * @dev Function to update the base _uri for all tokens
     * @param newuri The base uri string
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /***********************************|
    |        Hooks                      |
    |__________________________________*/
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            // If token is original, keep track of owner so can send them fees
            if (ids[i] & PRINTS_FLAG_BIT != PRINTS_FLAG_BIT) {
                uint256 seed = ids[i];
                seedToOwner[seed] = payable(to);
            }
        }
    }

}
