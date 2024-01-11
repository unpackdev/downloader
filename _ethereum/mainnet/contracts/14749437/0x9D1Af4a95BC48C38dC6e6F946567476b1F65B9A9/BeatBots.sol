// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";

import "./ECDSA.sol";
import "./Pausable.sol";
import "./Ownable.sol";
/*
 _______    _______       __  ___________  _______     ______  ___________  ________  
|   _  "\  /"     "|     /""\("     _   ")|   _  "\   /    " \("     _   ")/"       ) 
(. |_)  :)(: ______)    /    \)__/  \\__/ (. |_)  :) // ____  \)__/  \\__/(:   \___/  
|:     \/  \/    |     /' /\  \  \\_ /    |:     \/ /  /    ) :)  \\_ /    \___  \    
(|  _  \\  // ___)_   //  __'  \ |.  |    (|  _  \\(: (____/ //   |.  |     __/  \\   
|: |_)  :)(:      "| /   /  \\  \\:  |    |: |_)  :)\        /    \:  |    /" \   :)  
(_______/  \_______)(___/    \___)\__|    (_______/  \"_____/      \__|   (_______/   
                                                                     
 */

/// @title BeatBots Mint Contract
/// @author GEN3 Studios
contract BeatBots is ERC721A, Ownable, Pausable {
    using Strings for uint256;
    using ECDSA for bytes32;

    string private baseURI;
    bool private _revealed;
    string private _unrevealedBaseURI;
    address private treasury;

    // General Mint Settings
    uint256 public MAX_SUPPLY = 3333;
    uint256 public  NFT_PRICE = 0.15 ether;
    uint256 public  MAX_NFT_PER_WALLET = 2;

    // Whitelist Sale Settings
    uint256 public privateSaleMaxSingle = 1; // Only allowed to mint one if in either Basic OR Mech
    uint256 public privateSaleMaxDouble = 2; // Only allowed to mint two if in both Basic AND Mech

    // Sale timings 
    uint256 public presaleWindow = 8 hours;
    uint256 public presaleStartTime = 1652277600; // 11th May 2022 10pm SGT
    uint256 public publicSaleStartTime = 1652306400; // 12th May 2022 6am SGT

    // Off-chain whitelist Variables
    address private signerAddressSingle;
    address private signerAddressDouble;

    mapping(address => uint256) public nftMintCount;

    // Events
    event PrivateMint(address indexed to, uint256 amount);
    event PublicMint(address indexed to, uint256 amount);
    event DevMint(uint256 amount);
    event WithdrawETH(uint256 amountWithdrawn);
    event Revealed(uint256 timestamp);

   
    // -------------------- MODIFIERS --------------------------

    /**
     * @dev Prevent Smart Contracts from calling the functions with this modifier
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "BeatBots: must use EOA");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initBaseURI,
        address _newOwner,
        address _signerAddressSingle,
        address _signerAddressDouble,
        address _treasury
    ) ERC721A(name_, symbol_) {
        _currentIndex = 1; // required for ERC721A since it starts from 0
        setNotRevealedURI(_initBaseURI);
        transferOwnership(_newOwner);
        signerAddressSingle = _signerAddressSingle;
        signerAddressDouble = _signerAddressDouble;
        treasury = _treasury;
    }

    // -------------------- MINT FUNCTIONS --------------------------

    /// @notice Allows owner of smart contract to mint for free
    /// @param _mintAmount a parameter just like in doxygen (must be followed by parameter name)
    function devMint(uint256 _mintAmount) public onlyEOA onlyOwner {
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "Beatbots: total mint amount exceeded supply"
        );

        _safeMint(msg.sender, _mintAmount);
        emit DevMint(_mintAmount);
        
    }
    /**
     * @notice Private Mint for users who are only in either Basic OR Mech allowlist
     * @param signature Signature retrieved from backend for Single Allowlist
     * @param nonce Random nonce retrieved from backend for Single Allowlist
     */
    function privateMintSingle(
        bytes memory nonce,
        bytes memory signature
    ) external payable onlyEOA whenNotPaused {
        // Check if user is whitelisted
        require(
            whitelistSignedSingle(msg.sender, nonce, signature),
            "BeatBots: Invalid Signature!"
        );

        // Check if public sale is open
        require(isPrivateSaleOpen(), "BeatBots: Private Sale Closed!");

        // Check if enough ETH is sent
        require(
            msg.value >= NFT_PRICE,
            "BeatBots: Insufficient ETH!"
        );

        // Check if mints exceed MAX_SUPPLY
        require(
            totalSupply() + 1 <= MAX_SUPPLY,
            "BeatBots: Max Supply exceeded!"
        );

        // Check that mints does not exceed max wallet allowance for Basic allowlist
        require(
            nftMintCount[msg.sender] + 1 <=
                privateSaleMaxSingle,
            "BeatBots: Wallet has already minted Max Amount for private sale!"
        );

        nftMintCount[msg.sender] += 1;

        _safeMint(msg.sender, 1);
        emit PrivateMint(msg.sender, 1);
    }

    /**
     * @notice Private Mint for users who are in both Basic and Mech roles
     * @param _mintAmount Amount to mint, users can select 1 or 2
     * @param signature Signature retrieved from backend for Double Allowlist
     * @param nonce Random nonce retrieved from backend for Double Allowlist
     */
    function privateMintDouble(
        uint256 _mintAmount,
        bytes memory nonce,
        bytes memory signature
    ) external payable onlyEOA whenNotPaused {
        // Check if user is whitelisted
        require(
            whitelistSignedDouble(msg.sender, nonce, signature),
            "BeatBots: Invalid Signature!"
        );
        
        // Check if public sale is open
        require(isPrivateSaleOpen(), "BeatBots: Private Sale Closed!");

        // Check if enough ETH is sent
        require(
            msg.value >= _mintAmount * NFT_PRICE,
            "BeatBots: Insufficient ETH!"
        );

        // Check if mints does not exceed MAX_SUPPLY
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "BeatBots: Max Supply for Private Sale Reached!"
        );

        // Check that mints does not exceed max wallet allowance for Mech allowlist
        require(
            nftMintCount[msg.sender] + _mintAmount <=
                privateSaleMaxDouble,
            "BeatBots: Wallet has already minted Max Amount for Private Sale!"
        );

        nftMintCount[msg.sender] += _mintAmount;

        _safeMint(msg.sender, _mintAmount);
        emit PrivateMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Public Mint
     * @param _mintAmount Amount that is minted
     */
    function publicMint(uint256 _mintAmount) external payable onlyEOA whenNotPaused{
        // Check if public sale is open
        require(isPublicSaleOpen(), "BeatBots: Public Sale Closed!");

        // Check if enough ETH is sent
        require(
            msg.value >= _mintAmount * NFT_PRICE,
            "BeatBots: Insufficient ETH!"
        );

        // Check if mints does not exceed MAX_SUPPLY
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "BeatBots: Max Supply for Public Mint Reached!"
        );

        // Check that mints does not exceed max wallet allowance for public sale
        require(
            nftMintCount[msg.sender] + _mintAmount <= MAX_NFT_PER_WALLET,
            "BeatBots: Wallet has already minted Max Amount for Public Sale"
        );

        nftMintCount[msg.sender] += _mintAmount;

        _safeMint(msg.sender, _mintAmount);
        emit PublicMint(msg.sender, _mintAmount);
    }

    // -------------------- WHITELIST FUNCTION ----------------------

    /**
     * @dev Checks if the the signature is signed by a valid signer for single allowlist
     * @param sender Address of minter
     * @param nonce Random bytes32 nonce
     * @param signature Signature generated off-chain
     */
    function whitelistSignedSingle(
        address sender,
        bytes memory nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return signerAddressSingle == hash.recover(signature);
    }

    /**
     * @dev Checks if the the signature is signed by a valid signer for double allowlist
     * @param sender Address of minter
     * @param nonce Random bytes32 nonce
     * @param signature Signature generated off-chain
     */
    function whitelistSignedDouble(
        address sender,
        bytes memory nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return signerAddressDouble == hash.recover(signature);
    }

    // ---------------------- VIEW FUNCTIONS ------------------------
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev gets baseURI from contract state variable
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!_revealed) {
            return _unrevealedBaseURI;
        }

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /**
     * @notice Check if Private Sale 1 is Open
     */
    function isPrivateSaleOpen() public view returns (bool) {
        return
            block.timestamp >= presaleStartTime &&
            block.timestamp < (presaleStartTime + presaleWindow);
    }

    /**
     * @notice Check if Public Sale is Open
     */
    function isPublicSaleOpen() public view returns (bool) {
        return block.timestamp >= publicSaleStartTime;
    }

    


    // ------------------------- OWNER FUNCTIONS ----------------------------
    /**
     * @notice Set presale start time
     * @param _presaleStartTime New presale start timing 
    */
    function setPresaleTiming(uint256 _presaleStartTime) external onlyOwner {
        presaleStartTime = _presaleStartTime;
    }

    /**
     * @notice Set public sale start time
     * @param _publicSaleStartTime New public sale start timing 
    */
    function setPublicSaleTiming(uint256 _publicSaleStartTime) external onlyOwner {
        publicSaleStartTime = _publicSaleStartTime;
    }

    /**
     * @notice Set presale duration
     * @param _presaleWindow New presale duration 
    */
    function setPresaleWindow(uint256 _presaleWindow) external onlyOwner {
        presaleWindow = _presaleWindow;
    }

    /**
     * @notice Set max supply of collection
     * @param _maxSupply New max supply of the collection 
    */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply <= 3333, "Beatbots: Only allowed to reduce max supply");
        MAX_SUPPLY = _maxSupply;
    }

    /**
     * @notice Pauses all minting except devMint
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses all minting except devMint
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Set Private Sale maximum amount of mints
     */
    function setSignerAddressSingle(address signer) external onlyOwner {
        signerAddressSingle = signer;
    }

    /**
     * @dev Set Private Sale maximum amount of mints
     */
    function setSignerAddressDouble(address signer) external onlyOwner {
        signerAddressDouble = signer;
    }

    /**
     * @dev Set the unrevealed URI
     * @param newUnrevealedURI unrevealed URI for metadata
     */
    function setNotRevealedURI(string memory newUnrevealedURI)
        public
        onlyOwner
    {
        _unrevealedBaseURI = newUnrevealedURI;
    }

    /**
     * @dev Set Revealed Metadata URI
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Set Revealed state of NFT metadata
     */
    function reveal(bool revealed) external onlyOwner {
        _revealed = revealed;
        emit Revealed(block.timestamp);
    }

    /**
    * @notice Set treasury address for withdrawal
    */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Withdraws ETH from smart contract to treasury
     */
    function withdrawToTreasury() external onlyOwner {
        (bool success, ) = treasury.call{ value: address(this).balance }(""); // returns boolean and data
        require(success, "Beatbots: Withdrawal failed");
        emit WithdrawETH(address(this).balance);
  }
}
