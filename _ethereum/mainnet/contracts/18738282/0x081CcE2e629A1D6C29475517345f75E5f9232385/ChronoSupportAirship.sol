// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./ERC721AUpgradeable.sol";
import "./ERC721ABurnableUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ECDSA.sol";

contract ChronoSupportAirship is
    ERC721AUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC721AQueryableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    //#region Setup
    //State variables arranged for optimised storage slots

    //Public sale active flag
    bool public saleActive;

    //Whitelist sale active flag
    bool public wlSaleActive;

    //Maximum amount of mints per transaction during whitelist sale
    uint8 public maxMintPerTxWl;

    //Maximum amount of mints per transaction during public sale
    uint8 public maxMintPerTxPublic;

    //Maximum supply of airships
    uint16 public maxSupply;

    //Whitelist mint price
    uint256 public wlMintPrice;

    //Public mint price
    uint256 public publicMintPrice;

    //Payable withdraw address
    address payable public withdrawAddress;

    //The collection base URI
    string public _currentBaseURI;

    /**
     * @dev To reduce smart contract size & gas usages, we are using custom errors rather than using require.
     */
    error WhitelistSaleInactive();
    error PublicSaleInactive();
    error InsufficientFunds();
    error InsufficientFundsInContract();
    error InsufficientRole();
    error InvalidSignature();
    error ExcessMintAmount();
    error ExcessTotalMint();
    error ExceedsMaxSupply();
    error TransferFailed();
    error InvalidSupplyUpdate();

    //Signer
    address public txSigner;

    //Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    //#endregion

    ///////////////////////////////////////////////////////////////////////////
    // Initialize Functions
    ///////////////////////////////////////////////////////////////////////////

    //Initialize function for proxy
    function initialize() public initializerERC721A initializer {
        __ERC721A_init("ChronoForge Support Airships", "CFSA");
        __ERC721ABurnable_init();
        __ERC721AQueryable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __airship_init();

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(WITHDRAW_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    //Initialize function which sets the defaults for state variables
    function __airship_init() internal initializer {
        _currentBaseURI = "https://api.chronoforge.gg/meta/supportairship/";
        maxSupply = 2500;
        publicMintPrice = 0.125 ether;
        wlMintPrice = 0.1 ether;
        maxMintPerTxPublic = 50;
        maxMintPerTxWl = 50;
        withdrawAddress = payable(0xDF53617A8ba24239aBEAaF3913f456EbAbA8c739);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint Functions
    ///////////////////////////////////////////////////////////////////////////

    /**
     * Internal helper that returns true if the signature has been signed by the signer address
     * @param data The hashed and encoded data
     * @param signature The signature of the data
     * @param signerAddress The address of the signer
     */
    function _isValidSig(
        bytes32 data,
        bytes memory signature,
        address signerAddress
    ) private pure returns (bool) {
        // Create an Ethereum specific prefixed hash of the data
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", data)
        );
        return ECDSA.recover(ethSignedMessageHash, signature) == signerAddress;
    }

    /**
     * Whitelist mints of airships. User can mint the same number of airships as they have adventurers.
     * Uses a signature to verify the caller mint allowance and that they mint from website.
     * Checks if WL sale is active.
     * Checks if caller has sent sufficient funds.
     * Checks if signature is valid.
     * Checks if number of mints is less than max mint per tx.
     * Checks if mint would exceed user allowance.
     * Checks if total supply will not be exceeded.
     * @param _allowedNumberOfMints the number of airships the user is allowed to mint
     * @param _numberOfMints the number of airships to mint
     * @param _signature the signature passed from the website
     */
    function mintAirshipWL(
        uint16 _allowedNumberOfMints,
        uint16 _numberOfMints,
        bytes memory _signature
    ) external payable {
        if (!wlSaleActive) revert WhitelistSaleInactive();

        if (msg.value < wlMintPrice * _numberOfMints)
            revert InsufficientFunds();

        if (
            !_isValidSig(
                keccak256(abi.encodePacked(msg.sender, _allowedNumberOfMints)),
                _signature,
                txSigner
            )
        ) revert InvalidSignature();

        if (_numberOfMints > maxMintPerTxWl) revert ExcessMintAmount();

        if (_numberMinted(msg.sender) + _numberOfMints > _allowedNumberOfMints)
            revert ExcessTotalMint();

        if (totalSupply() + _numberOfMints > maxSupply)
            revert ExceedsMaxSupply();

        _safeMint(msg.sender, _numberOfMints);
    }

    /**
     * Mints airship to caller address
     * Checks if sale is active.
     * Checks if caller has sent sufficient funds.
     * Checks if number of mints is less than max mint per tx.
     * Checks if total supply will not be exceeded.
     * @param _numberOfMints the number of airships to mint
     */
    function mintAirship(uint16 _numberOfMints) external payable {
        if (!saleActive) revert PublicSaleInactive();

        if (msg.value < publicMintPrice * _numberOfMints)
            revert InsufficientFunds();

        if (_numberOfMints > maxMintPerTxPublic) revert ExcessMintAmount();

        if (totalSupply() + _numberOfMints > maxSupply)
            revert ExceedsMaxSupply();

        _safeMint(msg.sender, _numberOfMints);
    }

    /**
     * Admin mint function to mint airship to a specific address.
     * Used to setup marketplace information as requires one airship to exist to do so.
     * @param _to the address to mint to
     */
    function adminMintAirship(
        address _to
    ) external payable onlyRole(ADMIN_ROLE) {
        if (totalSupply() + 1 > maxSupply) revert ExceedsMaxSupply();
        if (msg.value < wlMintPrice) revert InsufficientFunds();

        _safeMint(_to, 1);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Withdraw Functions
    ///////////////////////////////////////////////////////////////////////////

    /**
     * Withdraws the balance of the contract to the withdraw address if it exists.
     * If it does not exist, it withdraws to the caller.
     * Checks if caller has withdraw role or admin role.
     * Checks if withdraw address is valid.
     * @param _amount the amount to withdraw
     * @param _withdrawAll if true, withdraws the entire balance of the contract
     */
    function withdraw(
        uint256 _amount,
        bool _withdrawAll
    ) external nonReentrant {
        if (
            !hasRole(WITHDRAW_ROLE, msg.sender) &&
            !hasRole(ADMIN_ROLE, msg.sender)
        ) {
            revert InsufficientRole();
        }

        uint256 amountToWithdraw = _withdrawAll
            ? address(this).balance
            : _amount;

        // If _withdrawAll is false, then check if there are enough funds in the contract
        if (!_withdrawAll && amountToWithdraw > address(this).balance) {
            revert InsufficientFundsInContract();
        }

        address payable recipient = withdrawAddress != address(0)
            ? withdrawAddress
            : payable(msg.sender);

        _withdraw(recipient, amountToWithdraw);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Withdraw Functions
    ///////////////////////////////////////////////////////////////////////////

    /**
     * Internal helper for withdrawing ether from the contract
     * @param _address the address to withdraw to
     * @param _amount the amount to withdraw
     */
    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        if (!success) revert TransferFailed();
    }

    /**
     * Gets the number of airships minted for an owner.
     * @param _owner the owner of the airships to get the number minted for
     */
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    /**
     * Function to obtain the uri/json file of a particular token id.
     * @param _tokenId the token id to get the uri for
     */
    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    /**
     * Burns an airship token and removes it from the owner's list of airships.
     * Calling address must be owner or approved.
     * _burn checks for token ownership
     * @param _tokenId the token id to burn
     */
    function burn(uint256 _tokenId) public virtual override {
        _burn(_tokenId, true);
    }

    /**
     * ERC721AUpgradeable internal function to set the starting token id.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * Used to identify the interfaces supported by this contract.
     * @param interfaceId the interface id to check for support
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721AUpgradeable,
            IERC721AUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////////////
    //#region State Changes
    ///////////////////////////////////////////////////////////////////////////

    /**
     * Sets the sale active state of the contract
     * @param _saleActive state to change to
     */
    function setSaleActive(bool _saleActive) external onlyRole(ADMIN_ROLE) {
        saleActive = _saleActive;
    }

    /**
     * Sets the WL sale active state of the contract
     * @param _wlSaleActive state to change to
     */
    function setWlSaleActive(bool _wlSaleActive) external onlyRole(ADMIN_ROLE) {
        wlSaleActive = _wlSaleActive;
    }

    /**
     * Allows for a decrease in supply if necessary
     * @param _newSupply the new supply amount
     */
    function decreaseSupply(uint16 _newSupply) external onlyRole(ADMIN_ROLE) {
        if (_newSupply > maxSupply) revert InvalidSupplyUpdate();
        if (_newSupply < _totalMinted()) revert InvalidSupplyUpdate();
        maxSupply = _newSupply;
    }

    /**
     * Sets the public mint price per airship
     * @param _newPublicMintPrice the new public mint price
     */
    function setPublicMintPrice(
        uint256 _newPublicMintPrice
    ) external onlyRole(ADMIN_ROLE) {
        publicMintPrice = _newPublicMintPrice;
    }

    /**
     * Sets the WL mint price per airship
     * @param _newWlMintPrice the new WL mint price
     */
    function setWlMintPrice(
        uint256 _newWlMintPrice
    ) external onlyRole(ADMIN_ROLE) {
        wlMintPrice = _newWlMintPrice;
    }

    /**
     * Sets the max mint per tx for public sale
     * @param _newMaxMintPerTxPublic the new max mint per tx for public sale
     */
    function setMaxMintPerTxPublic(
        uint8 _newMaxMintPerTxPublic
    ) external onlyRole(ADMIN_ROLE) {
        maxMintPerTxPublic = _newMaxMintPerTxPublic;
    }

    /**
     * Sets the max mint per tx for wl sale
     * @param _newMaxMintPerTxWl the new max mint per tx for whitelist sale
     */
    function setMaxMintPerTxWl(
        uint8 _newMaxMintPerTxWl
    ) external onlyRole(ADMIN_ROLE) {
        maxMintPerTxWl = _newMaxMintPerTxWl;
    }

    /**
     * Sets the ticker symbol of the contract
     * @param _newSymbol the new ticker symbol
     */
    function setSymbol(
        string calldata _newSymbol
    ) external onlyRole(ADMIN_ROLE) {
        ERC721AStorage.layout()._symbol = _newSymbol;
    }

    /**
     * Sets the name of the contract
     * @param _newName the new name of the contract
     */
    function setName(string calldata _newName) external onlyRole(ADMIN_ROLE) {
        ERC721AStorage.layout()._name = _newName;
    }

    /**
     * Sets the txSigner address of the signatures
     * @param _newTxSigner the new txSigner address
     */
    function setTxSigner(address _newTxSigner) external onlyRole(ADMIN_ROLE) {
        txSigner = _newTxSigner;
    }

    /**
     * Sets the withdrawal address of the contract
     * @param _withdrawAddress address to withdraw to
     */
    function setWithdrawAddress(
        address payable _withdrawAddress
    ) external onlyRole(ADMIN_ROLE) {
        withdrawAddress = _withdrawAddress;
    }

    /**
     * Sets the base uri of the contract
     * @param _baseUri base uri to change to
     */
    function setBaseUri(
        string calldata _baseUri
    ) external onlyRole(ADMIN_ROLE) {
        _currentBaseURI = _baseUri;
    }

    /**
     * Overrides the base uri function in ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    //#endregion
}
