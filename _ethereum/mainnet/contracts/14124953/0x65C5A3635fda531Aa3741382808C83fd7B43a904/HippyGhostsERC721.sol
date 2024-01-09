// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// import "./console.sol";
import "./IERC20.sol";
import "./IERC2981.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SignatureVerification.sol";


/**
 * 6666 Hippy Ghosts
 * 1. 20: mint on creation [1,20]
 * 2. 6446: community private sale and public sale [101,6546]
 * 3. 200: keep for team [21,100], [6547,6666]
 */

contract HippyGhosts is ERC721, IERC2981, Ownable {

    /**
     * @dev Controls minting state
     * PAUSED - No sales allowed
     * PRIVATE - Signed mints only (eg. pre-sales or server managed sales)
     * PUBLIC - unrestricted minting (signed mints still work)
     */
    enum ContractState {
        PAUSED,
        PRIVATE,
        PUBLIC
    }


    /****************************************
     * Variables
     ****************************************/

    /**
     * @dev State of the contract
     */
    ContractState public state = ContractState.PRIVATE;

    /**
     * @dev See {IERC721Enumerable-totalSupply}
     * IERC721Enumerable is not implemented but totalSupply
     */
    uint256 public totalSupply;

    /**
     *  @dev Base URI for {IERC721Metadata-tokenURI}
     */
    string public baseURI;

    /**
     * @dev Ether value for each token in public sale
     */
    uint256 public mintPrice;

    /**
     * @dev index and upper bound for _mintInSequenceToAddress
     */
    uint256 private _mintIndex;
    uint256 private _maxMintIndex;

    /**
     * @dev Public address used to sign function calls parameters
     */
    address private _verificationAddress;

    /**
     * @dev Key(address) mapping to a claimed key.
     * Used to prevent address from rebroadcasting mint transactions
     */
    mapping(address => bool) private _claimedMintKeys;

    /**
     * @dev for gasless listings on opensea
     */
    address private _openSeaProxyRegistryAddress;
    bool private _isOpenSeaProxyActive = true;


    /****************************************
     * Events
     ****************************************/

    /**
     * @dev provides feedback on contract state changes
     */
    event StateChanged(ContractState newState);

    /**
     * @dev provide feedback on mint key used for signed mints
     */
    event MintKeyClaimed(
        address indexed claimer,
        address indexed mintKey,
        uint256 numberOfTokens
    );


    /****************************************
     * Functions
     ****************************************/

    constructor(
        string memory baseURI_,
        uint256 initialMintIndex_,
        uint256 maxMintIndex_,
        address verificationAddress_,
        address openSeaProxyRegistryAddress_
    ) ERC721("Hippy Ghosts", "GHOST") {
        baseURI = baseURI_;
        _mintIndex = initialMintIndex_;
        _maxMintIndex = maxMintIndex_;
        _verificationAddress = verificationAddress_;
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress_;
    }

    /* config functions */

    function setState(ContractState state_) external onlyOwner {
        if (state_ == ContractState.PUBLIC) {
            require(mintPrice > 0, "mintPrice is not set");
        }
        state = state_;
        emit StateChanged(state_);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        require(mintPrice_ > 0, "mintPrice must be greater than zero");
        mintPrice = mintPrice_;
    }

    function setVerificationAddress(address verificationAddress_) external onlyOwner {
        _verificationAddress = verificationAddress_;
    }

    function setIsOpenSeaProxyActive(bool isOpenSeaProxyActive_) external onlyOwner {
        _isOpenSeaProxyActive = isOpenSeaProxyActive_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function isMintKeyClaimed(address mintKey) external view returns (bool) {
        return _claimedMintKeys[mintKey];
    }

    /* mint functions */

    function _safeMint(address to, uint256 tokenId) internal override {
        _safeMint(to, tokenId, "");
        totalSupply = totalSupply + 1;
        require(totalSupply <= 6666, "Not enough ghosts remaining to mint");
    }

    function _mintInSequenceToAddress(address destination, uint256 numberOfTokens) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            // count to next index before minting
            _mintIndex = _mintIndex + 1;
            while (_exists(_mintIndex)) {
                // skip tokenId minted in mintMultipleTokensWithSignature
                _mintIndex = _mintIndex + 1;
            }
            require(_mintIndex >= 1 && _mintIndex <= _maxMintIndex, "Incorrect tokenId to mint");
            _safeMint(destination, _mintIndex);
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        require(state == ContractState.PUBLIC, "Public sale is not open");
        require(numberOfTokens <= 10, "Max ghosts to mint is 10");
        require(mintPrice > 0, "mintPrice is not set");
        require(mintPrice * numberOfTokens <= msg.value, "Incorrect ether value sent");

        _mintInSequenceToAddress(msg.sender, numberOfTokens);
    }

    function mintWithSignature(
        uint256 numberOfTokens,
        uint256 valueInWei,
        address mintKey,
        bytes memory signature
    ) external payable {
        require(state != ContractState.PAUSED, "Minting is paused");
        require(valueInWei == msg.value, "Incorrect ether value sent");
        require(_claimedMintKeys[mintKey] == false, "Mint key already claimed");

        SignatureVerification.requireValidSignature(
            abi.encodePacked(msg.sender, numberOfTokens, valueInWei, mintKey, this),
            signature,
            _verificationAddress
        );

        _claimedMintKeys[mintKey] = true;
        emit MintKeyClaimed(msg.sender, mintKey, numberOfTokens);

        _mintInSequenceToAddress(msg.sender, numberOfTokens);
    }

    function mintMultipleTokensWithSignature(
        uint256[] memory tokenIds,
        uint256 valueInWei,
        address mintKey,
        bytes memory signature
    ) external payable {
        require(state != ContractState.PAUSED, "Minting is paused");
        require(valueInWei == msg.value, "Incorrect ether value sent");
        require(_claimedMintKeys[mintKey] == false, "Mint key already claimed");

        SignatureVerification.requireValidSignature(
            abi.encodePacked(msg.sender, tokenIds, valueInWei, mintKey, this),
            signature,
            _verificationAddress
        );

        _claimedMintKeys[mintKey] = true;
        emit MintKeyClaimed(msg.sender, mintKey, tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _safeMint(msg.sender, tokenId);
        }
    }

    /* overrides */

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "royaltyInfo for nonexistent token");
        return (address(this), salePrice * 5 / 100);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
        if (_isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }


    /**
     * Withdraw from contract
     */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
