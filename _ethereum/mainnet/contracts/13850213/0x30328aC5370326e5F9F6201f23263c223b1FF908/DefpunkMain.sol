// SPDX-License-Identifier: MIT LICENSE


pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
// import "./console.sol";
import "./ITraits.sol";
import "./IDefpunk.sol";
import "./IDefpunkMain.sol";
import "./IRandomizer.sol";


contract DefpunkMain is IDefpunkMain, Ownable, ReentrancyGuard, Pausable {
    using ECDSA for bytes32;

    event updateContracts(address _traits, address _defpunk, address _randomizer);
    event updateFuse(uint16 fuseTokenId, uint16 burnTokenId);
    event updateSales(bool _earlyAccessMintSale, bool _publicMintSale);
    event updateFusion(bool _fusionEnabled);
    event updateWhitelistSigner(address _whitelistSigner);
    event updateMintPrice(uint256 _mintPriceInWei);
    event updateTreasuryWallet(address _treasury);
    event updateMaxMintPerTransaction(uint256 _maxMintPerTransaction);
    event WithdrawFunds(uint256 _withdraw);
    event updateBaseURI(string _baseURI);

    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }
    struct Whitelist {
        uint256 mintClaimed;
    }

    mapping(address => LastWrite) private _lastWrite;
    mapping(address => Whitelist) public whitelist;

    // boolean => checks if the earlyAccessMintSale is open or closed
    bool public earlyAccessMintSale = true;
    // boolean => checks if the publicMintSale is open or closed
    bool public publicMintSale = false;
    // boolean => checks if the fusion is enabled of disabled
    bool public fusionEnabled = true;
    
    // reference to Traits
    ITraits public traits;
    // reference to NFT collection
    IDefpunk public defpunkNFT;
    // reference to Randomizercollection
    IRandomizer public randomizer;

    // bytes32 -> DomainSeparator
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 -> PRESALE_TYPEHASH
    bytes32 public constant PRESALE_TYPEHASH = keccak256("EarlyAccess(address buyer)");

    // address -> whitelist signer 
    address public whitelistSigner;
    // address -> treasury
    address public treasury;

    // mint price
    uint256 public mintPrice = .01 ether;

    // max mint per transaction
    uint8 public maxMintPerTransaction = 100;

    /**
     * instantiates contract and rarity tables
     */
    constructor() {
        _pause();

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("DEFPUNK")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /** CRITICAL TO SETUP */
    function setContracts(
        address _traits,
        address _defpunk,
        address _randomizer
    ) external onlyOwner {
        traits = ITraits(_traits);
        defpunkNFT = IDefpunk(_defpunk);
        randomizer = IRandomizer(_randomizer);

        emit updateContracts(_traits, _defpunk, _defpunk);
    }

    /** EXTERNAL */

    /** 
    * @dev Private mint
    */
    function _mint(uint256 amount) internal {
        require(tx.origin == _msgSender(), "Only EOA");

        uint16 minted = defpunkNFT.minted();

        uint256 maxTokens = defpunkNFT.getMaxTokens();
        uint256 seed = 0;
        uint256 mintAmount = earlyAccessMintSale && whitelist[_msgSender()].mintClaimed == 0 ? (amount + 1) : amount;

        if(earlyAccessMintSale && whitelist[_msgSender()].mintClaimed == 0) {
            require(minted + mintAmount <= maxTokens, "All tokens minted");
            require(mintAmount > 0 && mintAmount <= (maxMintPerTransaction + 1), "Invalid mint amount");
        } else {
            require(minted + amount <= maxTokens, "All tokens minted");
            require(amount > 0 && amount <= maxMintPerTransaction, "Invalid mint amount");
        }
        require(amount * mintPrice == msg.value, "Invalid payment amount");
        LastWrite storage lw = _lastWrite[tx.origin];

        uint16[] memory tokenIds = new uint16[](mintAmount);

        for (uint i = 0; i < mintAmount; i++) {
            minted++;
            seed = randomizer.random(minted, lw.time, lw.blockNum);
            tokenIds[i] = minted;
            defpunkNFT.mint(_msgSender(), seed);
        }
        defpunkNFT.updateOriginAccess(tokenIds);
        
        lw.time = uint64(block.timestamp);
        lw.blockNum = uint64(block.number);
    }
    
    /** 
    * @dev Fuse 2 token's into 1 new one.
    */
    function fuseTokens(uint16 fuseTokenId, uint16 burnTokenId) external whenNotPaused {
        require(fusionEnabled, "Fusion is not enabled");
        require(defpunkNFT.ownerOf(fuseTokenId) == _msgSender(), "This isn't your token");
        require(defpunkNFT.ownerOf(burnTokenId) == _msgSender(), "This isn't your token");

        LastWrite storage lw = _lastWrite[tx.origin];
        uint256 seed = randomizer.random(fuseTokenId, lw.time, lw.blockNum);
        uint16[] memory tokenIds = new uint16[](2);
        tokenIds[0] = fuseTokenId;
        tokenIds[1] = burnTokenId;

        defpunkNFT.fuseTokens(fuseTokenId, burnTokenId, seed);
        defpunkNFT.updateOriginAccess(tokenIds);
        emit updateFuse(fuseTokenId, burnTokenId);
        
        lw.time = uint64(block.timestamp);
        lw.blockNum = uint64(block.number);
    }

    /** 
    * @dev mint the public sale
    */
    function publicMint(uint256 _amount) external payable whenNotPaused {
        require(publicMintSale, "Public sale is not active");
        _mint(_amount);
    }

    /** 
    * @dev mint the private sale
    */
    function earlyAccessMint(uint256 _amount, bytes memory signature) external payable whenNotPaused {
        require(earlyAccessMintSale, "Early access is not active");

        // Verify EIP-712 signature
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PRESALE_TYPEHASH, msg.sender))));
        address recoveredAddress = digest.recover(signature);
        // Is the signature the same as the whitelist signer if yes? your able to mint.
        require(recoveredAddress != address(0) && recoveredAddress == address(whitelistSigner), "Invalid signature");
        
        _mint(_amount);

        if(whitelist[_msgSender()].mintClaimed == 0) whitelist[_msgSender()].mintClaimed = 1;
    }

    /** ADMIN */

    /**
     * @dev Enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
    * @dev Enables owner to pause / unpause contract for this contract and the defpunkNFT contract.
    */
    function setPausedAll(bool _paused) external onlyOwner {
        defpunkNFT.setPaused(_paused);

        if (_paused) _pause();
        else _unpause();
    }

    /**
    * @dev Updates the sales of the earlyAccess and the public sale
    */
    function setSales(bool _earlyAccessMintSale, bool _publicMintSale) external onlyOwner {
        earlyAccessMintSale = _earlyAccessMintSale;
        publicMintSale = _publicMintSale;

        emit updateSales(_earlyAccessMintSale, _publicMintSale);
    }

    /**
    * @dev Updates the fusion bool
    */
    function setFusionEnabled(bool _fusionEnabled) external onlyOwner {
        fusionEnabled = _fusionEnabled;

        emit updateFusion(_fusionEnabled);
    }
    
    /**
    * @dev Updates the sales of the earlyAccess and the public sale
    */
    function setWhitelistSigner(address _whitelistSigner) external onlyOwner {
        require(_whitelistSigner != address(0x0), 'Invalid treasury address');
        whitelistSigner = _whitelistSigner;

        emit updateWhitelistSigner(_whitelistSigner);
    }

    /**
    * @dev Updates the mint price
    */
    function setMintPrice(uint256 _mintPriceInWei) external onlyOwner {
        mintPrice = _mintPriceInWei;

        emit updateMintPrice(_mintPriceInWei);
    }

    /**
    * @dev Updates the treasury wallet
    */
    function setTreasuryWallet(address _treasury) external onlyOwner {
        require(_treasury != address(0x0), 'Invalid treasury address');
        treasury = _treasury;

        emit updateTreasuryWallet(_treasury);
    }

    /**
    * @dev Updates the max mints per transaction
    */
    function setMaxMintPerTransaction(uint8 _maxMintPerTransaction) external onlyOwner {
        maxMintPerTransaction = _maxMintPerTransaction;

        emit updateMaxMintPerTransaction(_maxMintPerTransaction);
    }

    /**
    * @dev Sets the new base URI
    */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        defpunkNFT.setBaseURI(_baseURI);

        emit updateBaseURI(_baseURI);
    }

    /**
     * @dev allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(address(treasury)).transfer(address(this).balance);

        emit WithdrawFunds(address(this).balance);
    }

    /**
     * @dev gets the base URI
     */
    function getBaseURI() external view returns (string memory) {
        return defpunkNFT.getBaseURI();
    }
}
