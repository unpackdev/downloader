// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract KaijuLegends is Ownable, ERC721A, ReentrancyGuard, Pausable {
    /* ======== LIBRARIES ======== */

    using ECDSA for bytes32;

    /* ======== EVENTS ======== */

    event UpdatePrivateSaleActive(bool privateSaleActive);
    event UpdateMaxMintPerTx(uint256 maxMintPerTx);
    event UpdatePrivateSaleSupply(uint256 privateSaleSupply);
    event UpdateTreasury(address treasury);
    event UpdateWhitelistSigner(address whitelistSigner);
    event UpdateBaseURI(string baseURI);
    event UpdatePlaceholderURI(string placeholderURI);
    event UpdatePrivateSalePrice(uint256 privateSalePrice);
    event UpdatePrivateSaleMaxMint(uint256 privateSaleMaxMint);

    /* ======== VARIABLES ======== */

    bool public privateSaleActive = true;

    uint256 public constant COLLECTION_SUPPLY = 7777;
    uint256 public maxMintPerTx = 9999;
    uint256 public privateSaleMaxMint = 9999;
    uint256 public privateSaleSupply = 4777;
    uint256 public privateSalePrice = .15 ether;

    address public treasury;
    address public whitelistSigner;

    string public baseURI;
    string public placeholderURI;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PRESALE_TYPEHASH =
        keccak256("PrivateSale(address buyer)");

    /* ======== CONSTRUCTOR ======== */

    constructor() ERC721A("Miauw Miauw", "Miauww") {
        _pause();

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("KAIJU")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        whitelistSigner = owner();
    }

    /* ======== MODIFIERS ======== */

    /*
     * @notice: Checks if the msg.sender is the owner or the treasury address
     */
    modifier callerIsTreasuryOrOwner() {
        require(
            treasury == _msgSender() || owner() == _msgSender(),
            "The caller is another address"
        );
        _;
    }

    /* ======== SETTERS ======== */

    /*
     * @notice: Pause the smart contract
     * @param: paused_: A boolean to pause or unpause the contract
     */
    function setPaused(bool paused_) external onlyOwner {
        if (paused_) _pause();
        else _unpause();
    }

    /*
     * @notice: Set the private sale enabled or enabled
     * @param: privateSaleActive_: A boolean to pause or unpause the private sale
     */
    function setPrivateSale(bool privateSaleActive_) external onlyOwner {
        require(
            privateSaleActive != privateSaleActive_,
            "KaijuLegends: Sale is the same"
        );
        privateSaleActive = privateSaleActive_;
        emit UpdatePrivateSaleActive(privateSaleActive_);
    }

    /*
     * @notice: Set the private sale price
     * @param: privateSalePrice_: The new price for the private sale in WEI
     */
    function setPrivateSalePrice(uint256 privateSalePrice_) external onlyOwner {
        privateSalePrice = privateSalePrice_;
        emit UpdatePrivateSalePrice(privateSalePrice_);
    }

    /*
     * @notice: Set the max mint per transaction
     * @param: maxMintPerTx_: The new max mint per transaction
     */
    function setMaxMintPerTx(uint256 maxMintPerTx_) external onlyOwner {
        maxMintPerTx = maxMintPerTx_;
        emit UpdateMaxMintPerTx(maxMintPerTx_);
    }

    /*
     * @notice: Set the private sale supply
     * @param: privateSaleSupply_: The mint amount you want to sell for the private sale
     */
    function setPrivateSaleSupply(uint256 privateSaleSupply_)
        external
        onlyOwner
    {
        privateSaleSupply = privateSaleSupply_;
        emit UpdatePrivateSaleSupply(privateSaleSupply_);
    }

    /*
     * @notice: Set the new base URI
     * @param: baseURI_: The string of the new base uri
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit UpdateBaseURI(baseURI_);
    }

    /*
     * @notice: Set the new placeholder URI
     * @param: placeholderURI_: The string of the new placeholder URI
     */
    function setPlaceholderURI(string memory placeholderURI_)
        external
        onlyOwner
    {
        placeholderURI = placeholderURI_;
        emit UpdatePlaceholderURI(placeholderURI_);
    }

    /*
     * @notice: Set the new treasury address
     * @param: treasury_: The address of the new treasury
     */
    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
        emit UpdateTreasury(treasury_);
    }

    /*
     * @notice: Set the new whitelist signer
     * @param: whitelistSigner_: The address of the new whitelist signer
     */
    function setWhitelistSigner(address whitelistSigner_) external onlyOwner {
        whitelistSigner = whitelistSigner_;
        emit UpdateWhitelistSigner(whitelistSigner_);
    }

    /*
     * @notice: Set the new private sale max mint per wallet
     * @param: privateSaleMaxMint_: The max amount per wallet
     */
    function setPrivateSaleMaxMint(uint256 privateSaleMaxMint_)
        external
        onlyOwner
    {
        privateSaleMaxMint = privateSaleMaxMint_;
        emit UpdatePrivateSaleMaxMint(privateSaleMaxMint_);
    }

    /* ======== INTERNAL ======== */

    /*
     * @notice: Validations of the mint process
     */
    function _validateMint(uint256 quantity_) private {
        require(
            privateSaleActive,
            "KaijuLegends: Private sale has not begun yet"
        );
        require(
            (totalSupply() + quantity_) <= privateSaleSupply,
            "KaijuLegends: Reached max private sale supply"
        );
        require(
            quantity_ > 0 && quantity_ <= maxMintPerTx,
            "KaijuLegends: Reached max mint per tx"
        );
         require(
            (_numberMinted(_msgSender()) + quantity_) <= privateSaleMaxMint,
            "KaijuLegends: Reached max mint per wallet"
        );
        _refundIfOver(privateSalePrice * quantity_);
    }

    /*
     * @notice: Recovering the hash and checking if the signer is equal to the `whitelistSigner`
     */
    function _validatePrivateSaleSignature(bytes memory signature_)
        private
        view
    {
        // Verify EIP-712 signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PRESALE_TYPEHASH, _msgSender()))
            )
        );
        address recoveredAddress = digest.recover(signature_);
        require(
            recoveredAddress != address(0) &&
                recoveredAddress == address(whitelistSigner),
            "KaijuLegends: Invalid signature"
        );
    }

    /*
     * @notice: If a user sends more ETH than the actuall mint price than the exceeded amount will be send back
     * @param: price_: The total price for the mint
     */
    function _refundIfOver(uint256 price_) private {
        require(msg.value >= price_, "Need to send more ETH.");
        if (msg.value > price_) {
            payable(_msgSender()).transfer(msg.value - price_);
        }
    }

    /* ======== EXTERNAL ======== */
    /*
     * @notice: The private sale mint
     * @param: quantity_: The mint amount
     * @param: signature_: The signature hash that will be used to verify the user has been whitelisted
     */
    function privateSaleMint(uint256 quantity_, bytes memory signature_)
        external
        payable
        whenNotPaused
    {
        _validateMint(quantity_);
        _validatePrivateSaleSignature(signature_);

        _safeMint(_msgSender(), quantity_);
    }

    /*
     * @notice: This batch mint is meant for the CRYPTO.COM sale / Giveaways / Collaborations. Only the `treasury / owner` can mint them to a wallet
     * @param: to_: The address that will receive the token ids
     * @param: quantity_: The mint amount
     */
    function batchMint(address to_, uint256 quantity_)
        external
        callerIsTreasuryOrOwner
    {
        require(
            (totalSupply() + quantity_) <= COLLECTION_SUPPLY,
            "KaijuLegends: Reached max supply"
        );

        _safeMint(to_, quantity_);
    }

    /*
     * @notice: Withdraw the ETH from the contract to the treasury address
     */
    function withdrawEth() external callerIsTreasuryOrOwner nonReentrant {
        payable(address(treasury)).transfer(address(this).balance);
    }

    /*
     * @notice: Burn a token id to reduce the token supply
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    /* ======== OVERRIDES ======== */

    /*
     * @notice: returns the baseURI for the token metadata
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /*
     * @notice: returns a URI for the tokenId
     * @param: tokenId_: the minted token id
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "URI query for nonexistent token");

        if (bytes(baseURI).length <= 0) {
            return placeholderURI;
        }

        string memory uri = _baseURI();
        return string(abi.encodePacked(uri, Strings.toString(tokenId_)));
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }
}
