/**  
 SPDX-License-Identifier: GPL-3.0

    ░█████╗░████████╗███╗░░░███╗░█████╗░░██████╗██████╗░░█████╗░░█████╗░███████╗
    ██╔══██╗╚══██╔══╝████╗░████║██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
    ███████║░░░██║░░░██╔████╔██║██║░░██║╚█████╗░██████╔╝███████║██║░░╚═╝█████╗░░
    ██╔══██║░░░██║░░░██║╚██╔╝██║██║░░██║░╚═══██╗██╔═══╝░██╔══██║██║░░██╗██╔══╝░░
    ██║░░██║░░░██║░░░██║░╚═╝░██║╚█████╔╝██████╔╝██║░░░░░██║░░██║╚█████╔╝███████╗
    ╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝

 Written by: Lacuna Strategies
*/

// Solidity Version
pragma solidity ^0.8.9;

// Inherited Contracts Being Used
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";
import "./ERC721A.sol";

contract Atmospace is ERC721A, Ownable {
    using Counters for Counters.Counter;

    string  public              customBaseURI; // Variable to override Base URI

    address public              couponSigner; // Address of the wallet that generated the coupons
    address public              bankManager; // Address that controls payment splitter release
    
    uint256 public              maxPublicSupply = 7000; // Maximum tokens available during Public Sale mint phase
    uint256 public              maxWhitelistSupply = 3000; // Maximum tokens available during Whitelist mint phase
    uint256 public              maxReserveSupply = 100; // Maximum tokens available during Reserve mint phase

    uint256 public              maxPerTx = 5; // Maximum number of tokens allowed per address
    uint256 public              mintPrice   = 0.02 ether; // Price of each NFT in Ethereum
    
    struct MintTypes {
		uint256 _whitelistMintsByAddress; // Mint type used to track number of whitelist mints by address
	}

    struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

    enum CouponType {
		Whitelist
	}

    enum SalePhase {
        Locked,
        Reserve,
        PublicSale,
        Whitelist
    }

    mapping(address => MintTypes) public addressToMinted;

    SalePhase           public  phase = SalePhase.Locked; // Set initial phase to "Locked"
    Counters.Counter    private supplyMintCounter; // Counter used to track total number of tokens minted
    Counters.Counter    private reserveMintCounter; // Counter used to track total number of reserve tokens minted
    Counters.Counter    private whitelistMintCounter; // Counter used to track total number of whitelist tokens minted
    PaymentSplitter     private splitter; // Payment splitter for allocating % shares to specified wallets

    constructor(
        string memory _customBaseURI,
        address _couponSigner,
        address _bankManager,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721A("Atmospace", "ATMO") {
        customBaseURI = _customBaseURI;
        couponSigner = _couponSigner;
        bankManager = _bankManager;
        splitter = new PaymentSplitter(_payees, _shares);
    }

    // ====== Admin Functions ====== //
    /**
     * * Set Mint Phase
     * @dev Set the mint phase: Locked, Presale, PublicSale
     * @param _phase The new mint phase
     */
    function setSalePhase(SalePhase _phase) external onlyOwner {
        phase = _phase;
    }

    /**
     * * Set Mint Price
     * @dev Set the mint price (ether)
     * @param _price The new mint price
     */
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    /**
     * * Set Public Supply
     * @dev Set the maximum public supply currently available to mint
     * @param _maxPublicSupply The new maximum supply available to be minted
     */
    function setMaxPublicSupply(uint256 _maxPublicSupply) external onlyOwner {
        maxPublicSupply = _maxPublicSupply;
    }
    
    /**
     * * Set Whitelist Supply
     * @dev Set the maximum whitelist supply currently available to mint
     * @param _maxWhitelistSupply The new maximum supply available to be minted
     */
    function setMaxWhitelistSupply(uint256 _maxWhitelistSupply) external onlyOwner {
        maxWhitelistSupply = _maxWhitelistSupply;
    }
        
    /**
     * * Set Reserve Supply
     * @dev Set the maximum reserve supply currently available to mint
     * @param _maxReserveSupply The new maximum supply available to be minted
     */
    function setMaxReserveSupply(uint256 _maxReserveSupply) external onlyOwner {
        maxReserveSupply = _maxReserveSupply;
    }
   
    /**
     * * Set Max Per Transaction
     * @dev Set the maximum quantity allowed per transaction during Public Mint
     * @param _maxPerTx The new maximum supply available to be minted
     */
    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    /**
     * * Set Coupon Signer
     * @dev Set the coupon signing wallet
     * @param _couponSigner The new coupon signing wallet address
     */
    function setCouponSigner(address _couponSigner) external onlyOwner {
        couponSigner = _couponSigner;
    }

    /**
     * * Override Base URI
     * @dev Overrides default base URI
     * @notice Default base URI is ""
     */     
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /**
     * * Set Base URI
     * @dev Set a custom Base URI for token metadata
     * @param _newBaseURI The new URI to set as the base URI for token metadata
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        customBaseURI = _newBaseURI;
    }

    /**
     * * Release Payout
     * @dev Disburse payments to associated payees according to shareholder amount.
     * @notice A separate wallet can be provided for a "Bank Manager" to control payment release
     * @param _account Payee wallet address to release payment for
     */
    function release(address payable _account) public virtual {
        if (_msgSender() == bankManager || _msgSender() == owner()){
            splitter.release(_account);
        } else {
            revert();
        }
    }

    // ====== Helper Functions ====== //
    /**
     * * Verify Coupon
     * @dev Verify that the coupon sent was signed by the coupon signer and is a valid coupon
     * @notice Valid coupons will include coupon signer, type [Presale, Reserve], address, and allotted mints
     * @notice Returns a boolean value
     * @param _digest The digest
     * @param _coupon The coupon
     */
	function _isVerifiedCoupon(bytes32 _digest, Coupon memory _coupon) internal view returns (bool) {
		address signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
        require(signer != address(0), 'Zero Address');
		return signer == couponSigner;
	}

    // ====== Minting Functions ====== //

    /**
     * * Mint Reserve Tokens
     * @dev Minting function for tokens held in Reserve
     * @notice This mint function can only be called by the owner
     * @param _qty The number of tokens being minted by sender
     */
    function mintReserves(address _to, uint256 _qty) external onlyOwner {
        // Verify phase is set to Reserve
        require(phase == SalePhase.Reserve, "Reserve Phase Not Active");
        // Verify available supply has not been exceeded
        require(reserveMintCounter.current() + _qty < maxReserveSupply + 1, "Exceeded Max Reserve Supply");
 
        // Update Counter
        for (uint256 i = 0; i < _qty; i++) {
            reserveMintCounter.increment();
        }

        // Mint Tokens
        _mint(_to, _qty, "", true);
    }

    /**
     * * Mint Public Sale Tokens
     * @dev Minting function for tokens available during the Public Sale phase
     * @param _qty The number of tokens being minted by sender
     */
    function mint(uint256 _qty) external payable {
        // Check for Buy 5 Get 1 Deal
        uint256 mintQty;
        if (_qty == 5) {
            mintQty = 6;
        } else {
            mintQty = _qty;
        }
        // Verify phase is set to Public Sale
        require(phase == SalePhase.PublicSale, "Public Sale Not Active");
        // Verify available supply has not been exceeded
        require(supplyMintCounter.current() + mintQty < maxPublicSupply + 1, "Exceeded Max Supply");
        // Verify quantity minted has not exceed max allowed per transaction
        require(_qty < maxPerTx + 1, "Exceeded Max Per Transaction");
        // Verify Payment
        require(msg.value == mintPrice * _qty, "Incorrect Payment");

        // Update Counter
        for (uint256 i = 0; i < mintQty; i++) {
            supplyMintCounter.increment();
        }

        // Mint Tokens
        _mint(_msgSender(), mintQty, "", true);

        // Split Payment
        payable(splitter).transfer(msg.value);
    }

    /**
     * * Mint Whitelist Tokens
     * @dev Minting function for tokens available during the Whitelist phase
     * @notice Minting Whitelist tokens requires a valid coupon, associated with wallet and allotted amount
     * @param _qty The number of tokens being minted by sender
     * @param _allotted The allotted number of tokens specified in the Whitelist Coupon
     * @param _coupon The signed coupon
     */
    function mintWhitelist(uint256 _qty, uint256 _allotted, Coupon memory _coupon) external {
        // Verify phase is not locked
        require(phase == SalePhase.Whitelist, "Whitelist Not Active");
        // Create digest to verify against signed coupon
        bytes32 digest = keccak256(
			abi.encode(CouponType.Whitelist, _allotted, _msgSender())
		);
        // Verify digest against signed coupon
        require(_isVerifiedCoupon(digest,_coupon), "Invalid Coupon");
        // Verify quantity (including already minted reserves) does not exceed allotted reserve amount
        require(_qty + addressToMinted[_msgSender()]._whitelistMintsByAddress < _allotted + 1, "Exceeds Max Allotted");
        // Increment number of whitelist tokens minted by wallet
        addressToMinted[_msgSender()]._whitelistMintsByAddress += _qty;

        // Mint Reserve Tokens
        _mint(_msgSender(), _qty, "", true);
    }
 
}
