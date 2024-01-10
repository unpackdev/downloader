// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// @title:      Crypto Panther Club
// @developer:  Arthur V.
// @artist:     https://marcinglod.com
// @url:        https://cryptopanther.club

//                                                                                  
//                                                            ,,,.                  
//         ,(%&&&&/                                        ,@@@#//&@@#.             
//       (@&@#  .*                   .&@@&&@@%             (@% &@@.#@&@.            
//      #@&@,/@@@(  .#@@@@@@#,      #@@@@@@@@&@(           #@*,%*,%@@@(             
//       &@&@* /%* *@@@@&#(/,. *@@@. .,,*/*    * &@@@@@@@@@&&&%@@@&/                
//         .*#%(,*. *(#%@%*./@(,@&@#.&@@@@@@&&&./@&&&&&&&&&&&&@*                    
//            ,@@&@./@@@@@&*  *.,@&&@# ,#&&%, /@&&&&&&&&&&&&&&@%                    
//           ,@&&@@&( .*/#&@@& /@&&&&&&@@&&&@&&&&@&&&&&&&&&&&&@&                    
//            #@* *@@@@@@@@@# %@&&&&&&&@@&&&&&@@*.@&&&&&&&&&&&@*                    
//         .*              .,*(&@&&&&&#,.***,./&@&&&&&&&&&&@(                       
//        *.               /@@@@( ,@&&&&&@/ @@&&&&&&&&&&&@&.                        
//       %@@#.          .#@@@@@@@@% (@@&*.#@&&&&&&&&&@@#,                           
//       %@@@@@@(     #@@@@@@@@@@@@#  .%@&&&@@@@@@@@(                               
//        (/(&@@@@@.*@@@@@@@@@@&##&* &&&&&&/,#%#%*                                  
//         (@@@@@@@/*@@@@@@@@@@@&@& (%#((, *,.,,/&#                                 
//            .,,(#,   ,**/((#(//.*&@&&@/  #@&&@@@%                                 
//              %@@@@@@@@@@* *@@@( %@&@*    *@&&&&@*                                
//          ,**, /%@@@@&* /@@&&&&@.,@&,      .&@&&@&                                
//         %@&&&@@%  * *@@&&&&&&@/ @%          &@&&@#  ,&@@&%/.                     
//          (@@&&@&*.#@&&&&&&&@# #&,           .&@&@/.&@&&&&&&&@@&%(*.              
//             %@  @@&&&&&&@@/ .*               (@&&&&&&&&&&&&&&&&&&&&@@&(.         
//               %@&&&&&&/,/%&@@@@%.         #@&&@&#(%&@&&&&&&&&&&&&&&&&&&&@@&#*.   
//              /@&&&&&%%@&&&&@@@%%*        *@&@( /@@@(  %@&&&##&@@@@&&&&&&&&&&&&@@%
//               &@&&&&&&&&&#*/#%&&@#.      /@@,.@@@@@@@@* %@&&&&/    .*(%&@&&&&&&&&
//                %@&&&&&&&@@&&&&&&&&@/     /@( @@@@@@@@@@@ *@&&&@#          *&@@&&&
//                 /@&&&&&&&&@%(@@&&&@%     *@*.@@@@@@@@@@@@.,@&&&@%             ,/%
//                   &@&&&&&&&&@/ #@@@,     ,@*.@@@@@@@@@@@@@, @&&&&@,              
//                    /@&&&&&&&&&@%,        .@( @@@@@@@@@@@@@@/ &@&&&@/             
//                      &@&&&&&&&&&@*        &@ (@@@@@@@@@@@@@@# %@&&&@%            
//                       (@&&&&&&@#.         %@/ @@@@@@@@@@@@@@@&.*@&&&&@*          
//                        ,@&&&@#            #@@ /@@@@@@@@@@@@@@@@/ &@&&&@&         
//                         .&@&&@&,          #@@% %@@@@@@@@@@@@@@@@&./@&&&&@#       
//                           (@&&&@@.        (@&@( &@@@@@@@@@@@@@@@@@# &@&&&&@(     
//                            ,@&&&&@&*      /@&&@/ &@@@@@@@@@@@@@@@@@@*,&&&&&&@(   


import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./VRFConsumerBase.sol";
import "./Strings.sol";

contract CryptoPantherClub is ERC721, ReentrancyGuard, VRFConsumerBase, Ownable {
    
    // ======== Counter =========
    using Counters for Counters.Counter;
    Counters.Counter private supplyCounter;

    // ======== Supply =========
    uint256 public constant MAX_SUPPLY = 5555;

    // ======== Max Mints Per Address =========
    uint256 public maxPerAddressWhitelist;
    uint256 public maxPerAddressPublic;

    // ======== Price =========
    uint256 public priceWhitelist;
    uint256 public pricePublic;

    // ======== Mints Per Address Mapping ========
    struct MintTypes {
        uint256 _numberOfMintsByAddress;
    }
    mapping(address => MintTypes) public addressToMints;

    // ======== Base URI =========
    string private baseURI;

    // ======== Phase =========    
    enum SalePhase{ Locked, Whitelist, PrePublic, Public, Ended }
    SalePhase public phase = SalePhase.Locked;

    // ======== Chainlink VRF (v.1) ========
    bytes32 internal immutable keyHash;
    uint256 internal immutable fee;
    uint256 public indexShift = 0;

    // ======== Whitelist Coupons ========
    address private constant ownerSigner = 0x493e23ed0756415107993FE3D777Ca1A356FB038;
    enum CouponType{ Whitelist }
    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    // ======== Constructor =========
    constructor(
        string memory name_,
        string memory symbol_,
        string memory hiddenURI_
    )
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
        0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    )
    ERC721(name_, symbol_) {
        baseURI = hiddenURI_;
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445; // VRF keyHash
        fee = 2 * 10 ** 18; // 2 LINK  
    }

    // ======== Team Reserve (Events, Promotions, etc.) =========
    function reserve(uint256 amount_) 
        external
        onlyLockedPhase
        onlyOwner
    {
        require(amount_ > 0, "Amount can't be zero.");
        for(uint256 ind_ = 0; ind_ < amount_; ind_++) {
            _safeMint(msg.sender, totalSupply() + 1);
            supplyCounter.increment();
        }
    }

    // ======== Set Whitelist Price ========
    function setPriceWhitelist(uint256 price_)
        external
        onlyLockedPhase
        onlyOwner
    {
        priceWhitelist = price_;
    }

    // ======== Set Public Pirce ========
    function setPricePublic(uint256 price_)
        external
        onlyPrePublicPhase
        onlyOwner
    {
        pricePublic = price_;
    }

    // ======== Set Max Whitelist Mint Amount Per Address  ========
    function setMaxPerAddressWhitelist(uint256 amount_)
        external
        onlyLockedPhase
        onlyOwner
    {
        maxPerAddressWhitelist = amount_;
    }

    // ======== Set Max Public Mint Amount Per Address  ========
    function setMaxPerAddressPublic(uint256 amount_)
        external
        onlyPrePublicPhase
        onlyOwner
    {
        maxPerAddressPublic = amount_;
    }

    // ======== Enable Whitelist Mint =========
    function setWhitelistPhase() 
        external
        onlyLockedPhase
        onlyOwner
    {
        require(priceWhitelist != 0, "Whitelist price is not set.");
        require(maxPerAddressWhitelist != 0, "Max whitelist mint amount not set.");
        phase = SalePhase.Whitelist;
    }

    // ======== Enable PrePublic Phase =========
    function setPrePublicPhase() 
        external
        onlyWhitelistPhase
        onlyOwner
    {
        phase = SalePhase.PrePublic;
    }

    // ======== Enable Public Mint =========
    function setPublicPhase() 
        external
        onlyPrePublicPhase
        onlyOwner
    {
        require(pricePublic != 0, "Public price is not set.");
        require(maxPerAddressPublic != 0, "Max public mint amount not set.");
        phase = SalePhase.Public;
    }

    // ======== End Sale =========
    function setEndedPhase() external onlyOwner {
        phase = SalePhase.Ended;
    }

    // ======== Whitelist Mint =========
    function whitelistMint(uint256 amount_, Coupon memory coupon_)
        public
        payable
        onlyWhitelistPhase
        validateAmount(amount_, maxPerAddressWhitelist)
        validateSupply(amount_)
        validateEthPayment(amount_, priceWhitelist)
        nonReentrant
    {
        require(amount_ + addressToMints[msg.sender]._numberOfMintsByAddress <= maxPerAddressWhitelist, "Exceeds number of whitelist mints allowed.");
        
        bytes32 digest = keccak256(abi.encode(CouponType.Whitelist, msg.sender));
        require(isVerifiedCoupon(digest, coupon_), "Invalid coupon");

        addressToMints[msg.sender]._numberOfMintsByAddress += amount_;

        for(uint256 ind_ = 0; ind_ < amount_; ind_++) {
            _safeMint(msg.sender, totalSupply() + 1);
            supplyCounter.increment();
        }

        if (totalSupply() == MAX_SUPPLY) {
            phase = SalePhase.Ended;
        }
    }
    
    // ======== Public Mint =========
    function mint(uint256 amount_) 
        public
        payable
        onlyPublicPhase
        validateAmount(amount_, maxPerAddressPublic)
        validateSupply(amount_)
        validateEthPayment(amount_, pricePublic)
        nonReentrant
    {
        require(amount_ + addressToMints[msg.sender]._numberOfMintsByAddress <= maxPerAddressPublic, "Exceeds number of mints allowed.");

        addressToMints[msg.sender]._numberOfMintsByAddress += amount_;

        for(uint256 ind_ = 0; ind_ < amount_; ind_++) {
            _safeMint(msg.sender, totalSupply() + 1);
            supplyCounter.increment();
        }

        if (totalSupply() == MAX_SUPPLY) {
            phase = SalePhase.Ended;
        }
    }

    // ======== Reveal Metadata =========
    function reveal(string memory baseURI_)
        external
        onlyEndedPhase
        onlyZeroIndexShift
        onlyOwner
    {
        baseURI = baseURI_;
        requestRandomIndexShift();
    }

    // ======== Return Base URI =========
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // ======== Return Token URI =========
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token.");

        string memory sequenceId;

        if (indexShift > 0) {
            sequenceId = Strings.toString((tokenId + indexShift) % MAX_SUPPLY + 1);
        } else {
            sequenceId = "0";
        }
        return string(abi.encodePacked(baseURI, sequenceId));
    }

    // ======== Get Total Supply ========
    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    // ======== Get Random Number Using Chainlink VRF =========
    function requestRandomIndexShift() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK.");
        return requestRandomness(keyHash, fee);
    }

    // ======== Set Random Starting Index =========
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        indexShift = (randomness % MAX_SUPPLY) + 1;
    }

    // ======== Verify Coupon =========
    function isVerifiedCoupon(bytes32 digest_, Coupon memory coupon_) internal view returns (bool) {
        address signer = ecrecover(digest_, coupon_.v, coupon_.r, coupon_.s);
        require(signer != address(0), 'ECDSA: invalid signature');
        return signer == ownerSigner;
    }

    // ======== Withdraw =========
    function withdraw(address payee_, uint256 amount_) external onlyOwner {
        (bool success, ) = payee_.call{value: amount_}('');
		require(success, 'Transfer failed.');
    }

    // ======== Modifiers ========
    modifier validateEthPayment(uint256 amount_, uint256 price_) {
        require(amount_ * price_ <= msg.value, "Ether value sent is not correct.");
        _;
    }

    modifier validateSupply(uint256 amount_) {
        require(totalSupply() + amount_ <= MAX_SUPPLY, "Max supply exceeded.");
        _;
    }

    modifier validateAmount(uint256 amount_, uint256 max_) {
        require(amount_ > 0 && amount_ <= max_, "Amount is out of range.");
        _;
    }

    modifier onlyLockedPhase() {
        require(phase == SalePhase.Locked, "Minting is not locked.");
        _;
    }

    modifier onlyWhitelistPhase() {
        require(phase == SalePhase.Whitelist, "Whitelist sale is not active.");
        _;
    }

    modifier onlyPrePublicPhase() {
        require(phase == SalePhase.PrePublic, "PrePublic phase is not active.");
        _;
    }

    modifier onlyPublicPhase() {
        require(phase == SalePhase.Public, "Public sale is not active.");
        _;
    }
    
    modifier onlyEndedPhase() {
        require(phase == SalePhase.Ended, "Sale has not ended.");
        _;
    }

    modifier onlyZeroIndexShift() {
        require(indexShift == 0, "Already randomized.");
        _;
    }
}