// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";

/// @title ApeBankingClub - Join the Banking club a collection of 10 322 unique NFTs
/// @notice Each owner of an ABC NFT will be automatically eligible to open a bank account on the ABC META BANK | First bank of the metaverse.
/// @author Tavux - <contact@tavux.tech>
/// @custom:project-website  https://www.apebanking.club/
/// @custom:security-contact contact@tavux.tech
contract ApeBankingClub is
    ERC721,
    ERC721Enumerable,
    Pausable,
    AccessControl,
    Ownable,
    PaymentSplitter
{
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Strings for uint256;

    /* ========================
     *          Events
     * ========================
     */
    event AddedToReservedTokens(uint256[] ids);
    event RemovedFromReservedTokens(uint256[] ids);
    event ChangeMaxMintAmountFor(address indexed to, uint256 value);
    event ChangeMaxWalletSupplyFor(address indexed to, uint256 value);
    event ChangeMaxMintAmount(uint256 value);
    event ChangeMaxWalletSupply(uint256 value);
    event ChangePresaleConfig(
        uint256 newPrice,
        uint256 newDuration,
        uint256 newMaxMintPerWallet,
        uint256 newStartTime
    );
    event ChangeSaleConfig(
        uint256 newMin,
        uint256 newMax,
        uint256 newDecreaseAmount,
        uint256 newDecreaseTime,
        uint256 startTime
    );
    event SaleMint(address indexed minter, uint256 amount, uint256 price);
    event PresaleMint(address indexed minter, uint256 amount, uint256 price);
    event BurntToken(address indexed burner, uint256 tokenId);
    event SoldOut(uint256 totalMinted);
    event AllSoldOut(uint256 totalMinted);
    event ChangedBaseURI(string newURI);
    event ChangedNotRevealedUri(string newURI);
    event ChangedBaseExtension(string newURI);
    event RevealedTokens();
    event ChangedIsBurnEnabled(bool isEnabled);

    /* ========================
     *        Structures
     * ========================
     */
    struct PresaleConfig {
        uint256 price;
        uint256 duration;
        uint256 maxMintPerWallet;
        uint256 startTime;
    }

    struct SaleConfig {
        uint256 minPrice;
        uint256 maxPrice;
        uint256 decreaseAmount;
        uint256 decreaseTime;
        uint256 startTime;
    }

    enum WorkflowStatus {
        NotStarted,
        Presale,
        PresaleEnded,
        Sale,
        SoldOut,
        AllSoldOut
    }

    /* ========================
     *  Constants & Immutables
     * ========================
     */
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    uint256 public constant MAX_TOTAL_SUPPLY = 10322;

    /* ========================
     *         Storage
     * ========================
     */
    mapping(uint256 => bool) private _reservedTokens;
    mapping(address => uint256) private _maxMintPerAddress;
    mapping(address => uint256) private _maxWalletSupplyPerAddress;
    mapping(address => uint256) private _mintPerAddress;
    mapping(address => uint256[]) private _burntTokensPerAddress;
    mapping(uint256 => bool) private _burntTokens;
    uint256[] private _burntTokensList;
    uint256 public reservedTokensCount;
    uint256 public distributeMintCount;
    uint256 public saleMintCount;
    uint256 public presaleMintCount;
    uint256 public maxMintAmount = 10322;
    uint256 public maxWalletSupplyAmount = 10322;
    bool public isBurnEnabled;
    uint256 private _tokenIdCounter;

    // URI and revealed
    bool public revealed = false;
    string private baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    // prices
    SaleConfig public saleConfig;
    PresaleConfig public presaleConfig;

    // Payments
    uint256[] private _teamShares = [29, 29, 29, 10, 3];
    address[] private _team = [
        0x4f5d20491D9fD522898da93f05F0adEa6C73ac1C,
        0x9e78a07aD7db4213E2405a168fEDEa72D41dEaCE,
        0xDA7EC08572F2cae2816A5528427baA731A95D8d3,
        0x72dd10C9C9d47316fF740c9AfDA36DAEf1e058c9,
        0x49B730F78f8dCC4f7cd091D6a52b01915002A834
    ];

    /* ========================
     *     Public Functions
     * ========================
     */
    constructor()
        ERC721("APE BANKING CLUB", "ABC")
        PaymentSplitter(_team, _teamShares)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DISTRIBUTOR_ROLE, msg.sender);
        _setupRole(VALIDATOR_ROLE, msg.sender);
    }

    /* ========================
     *        Modifiers
     * ========================
     */
    modifier isWhitelisted(bytes32 hash, bytes memory sig) {
        require(isValidated(hash, sig), "ABC: user is not whitelisted");
        _;
    }

    modifier canHaveNewTokens(address wallet, uint256 amount) {
        require(
            getRemainingWalletSupplyFor(wallet) >= amount,
            "ABC: number of tokens exceeded"
        );
        _;
    }

    modifier canHaveNewTokensOr0Address(address wallet, uint256 amount) {
        require(
            wallet == address(0) ||
                getRemainingWalletSupplyFor(wallet) >= amount,
            "ABC: number of tokens exceeded"
        );
        _;
    }

    modifier canMintNewTokens(address wallet, uint256 amount) {
        require(
            getRemainingMintAmountFor(wallet) >= amount &&
                getRemainingTokens() >= amount,
            "ABC: number of minted tokens exceeded"
        );
        _;
    }

    /* ========================
     *         External
     * ========================
     */

    /// @dev Mint the `amount` of token in presale if msg.sender is whitelisted by a validator
    /// @param payloadExpiration The maximum timestamp before the signature is considered invalid
    /// @param sig The EC signature generated by an validator
    function presaleMint(
        uint256 amount,
        uint256 payloadExpiration,
        bytes memory sig
    )
        external
        payable
        whenNotPaused
        isWhitelisted(
            keccak256(abi.encodePacked(msg.sender, payloadExpiration))
                .toEthSignedMessageHash(),
            sig
        )
        canHaveNewTokens(msg.sender, amount)
        canMintNewTokens(msg.sender, amount)
    {
        require(payloadExpiration >= block.timestamp, "ABC: payload expired");
        _presaleMint(amount);
    }

    /// @notice Mint the `amount` of token in public sale
    function mint(uint256 amount)
        external
        payable
        whenNotPaused
        canHaveNewTokens(msg.sender, amount)
        canMintNewTokens(msg.sender, amount)
    {
        _saleMint(amount);
    }

    /// @notice Burn the `tokenId` if burning is enabled
    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "ABC: burning is disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ABC: burn caller is not owner nor approved"
        );
        _burn(tokenId);
        _burntTokensPerAddress[msg.sender].push(tokenId);
        _burntTokens[tokenId] = true;
        _burntTokensList.push(tokenId);
        emit BurntToken(msg.sender, tokenId);
    }

    /// @notice Mint `tokenId` (if not already minted) and transfers it to `to`. Only `DISTRIBUTOR_ROLE`.
    function distribute(address to, uint256 tokenId)
        external
        onlyRole(DISTRIBUTOR_ROLE)
    {
        _safeDistribute(to, tokenId);
        distributeMintCount = distributeMintCount.add(1);
    }

    /// @notice Mint all `tokenIds` (if not already minted) and transfers them to `to`. Only `DISTRIBUTOR_ROLE`.
    function distributeMultiple(address to, uint256[] calldata tokenIds)
        external
        onlyRole(DISTRIBUTOR_ROLE)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeDistribute(to, tokenIds[i]);
        }
        distributeMintCount = distributeMintCount.add(tokenIds.length);
    }

    /// @notice Mint all `tokenIds` (if not already minted) and transfer them respectively to `toList`. Only `DISTRIBUTOR_ROLE`.
    function distributeRespectively(
        address[] calldata toList,
        uint256[] calldata tokenIds
    ) external onlyRole(DISTRIBUTOR_ROLE) {
        require(
            toList.length == tokenIds.length,
            "The two lists must have the same size"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeDistribute(toList[i], tokenIds[i]);
        }
    }

    /// @notice Add tokens to the _reservedTokens list. Only `DISTRIBUTOR_ROLE`.
    /// @param ids Array of id to add
    function addToReservedTokens(uint256[] calldata ids)
        external
        onlyRole(DISTRIBUTOR_ROLE)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            require(!_existsOrBurn(ids[i]), "ERC721: token already minted");
            require(ids[i] <= MAX_TOTAL_SUPPLY, "ABC: max supply exceeded");
            if (_reservedTokens[ids[i]] == false) {
                _reservedTokens[ids[i]] = true;
                reservedTokensCount = reservedTokensCount.add(1);
            }
        }
        emit AddedToReservedTokens(ids);
    }

    /// @notice Remove tokens from the _reservedTokens list. Ids to be removed must be greater than the last public mined token. Only `DISTRIBUTOR_ROLE`.
    /// @param ids Array of id to remove
    function removeFromReservedTokens(uint256[] calldata ids)
        external
        onlyRole(DISTRIBUTOR_ROLE)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] <= MAX_TOTAL_SUPPLY, "ABC: max supply exceeded");
            require(
                _existsOrBurn(ids[i]) || ids[i] > _tokenIdCounter,
                "ABC: token already mined"
            );
            if (_reservedTokens[ids[i]]) {
                _reservedTokens[ids[i]] = false;
                reservedTokensCount = reservedTokensCount.sub(1);
            }
        }
        emit RemovedFromReservedTokens(ids);
    }

    /// @notice Set the maximum of NFT that `to` wallet can mint. Only `DEFAULT_ADMIN_ROLE`.
    /// @param to The wallet that has a specific maximum
    /// @param value The maximum of NFT (0 for default maximum)
    function setMaxMintAmountFor(address to, uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _mintPerAddress[to] <= value ||
                (value == 0 && _mintPerAddress[to] <= maxMintAmount),
            "ABC: already exceeded the new maximum"
        );
        require(_maxMintPerAddress[to] != value);
        _maxMintPerAddress[to] = value;
        emit ChangeMaxMintAmountFor(to, value);
    }

    /// @notice Set the maximum of NFT that `to` wallet can hold. Only `DEFAULT_ADMIN_ROLE`.
    /// @param to The wallet that has a specific maximum
    /// @param value The maximum of NFT (0 for default maximum)
    function setMaxWalletSupplyFor(address to, uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            balanceOf(to) <= value ||
                (value == 0 && balanceOf(to) <= maxWalletSupplyAmount),
            "ABC: already exceeded the new maximum"
        );
        require(_maxWalletSupplyPerAddress[to] != value);
        _maxWalletSupplyPerAddress[to] = value;
        emit ChangeMaxWalletSupplyFor(to, value);
    }

    /// @notice Set the maximum of NFT that a wallet can mint. Only `DEFAULT_ADMIN_ROLE`.
    /// @param newMaxMintAmount The new maximum mint amount
    function setMaxMintAmount(uint256 newMaxMintAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            newMaxMintAmount > maxMintAmount,
            "ABC: the new amount is lower than the old one"
        );
        maxMintAmount = newMaxMintAmount;
        emit ChangeMaxMintAmount(newMaxMintAmount);
    }

    /// @notice Set the maximum of NFT that a wallet can hold. Only `DEFAULT_ADMIN_ROLE`.
    /// @param newMaxWalletSupplyAmount The new maximum mint amount
    function setMaxWalletSupplyAmount(uint256 newMaxWalletSupplyAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            newMaxWalletSupplyAmount > maxWalletSupplyAmount,
            "ABC: the new amount is lower than the old one"
        );
        maxWalletSupplyAmount = newMaxWalletSupplyAmount;
        emit ChangeMaxWalletSupply(newMaxWalletSupplyAmount);
    }

    /// @notice Set the presale configuration. Only `DEFAULT_ADMIN_ROLE`.
    /// @param newPrice The new price
    /// @param newStartTime The pre sale start time (0 if pre sale is not active)
    /// @param newMaxMintPerWallet The maximum that a user can mint during the presale
    /// @param newDuration The number of seconds to wait before the end of the presale
    function setPresaleConfig(
        uint256 newPrice,
        uint256 newStartTime,
        uint256 newMaxMintPerWallet,
        uint256 newDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            newDuration > 900,
            "ABC: the duration has to be greater than 900 seconds"
        );
        presaleConfig = PresaleConfig(
            newPrice,
            newDuration,
            newMaxMintPerWallet,
            newStartTime
        );
        emit ChangePresaleConfig(
            newPrice,
            newDuration,
            newMaxMintPerWallet,
            newStartTime
        );
    }

    /// @notice Set the sale configuration for set the price. Only `DEFAULT_ADMIN_ROLE`.
    /// @param newMin The new minimum price
    /// @param newMax The new maximum price which will be decreasing
    /// @param newDecreaseAmount The number of gwei that will be subtracted from the price every `newDecreaseTime` (0 if no decrease)
    /// @param newDecreaseTime The number of seconds to wait between each decreasing (must be > 900)
    /// @param newStartTime The sale start time (0 if sale is not active)
    function setSaleConfig(
        uint256 newMin,
        uint256 newMax,
        uint256 newDecreaseAmount,
        uint256 newDecreaseTime,
        uint256 newStartTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            newDecreaseTime > 900,
            "ABC: the decrease time has to be greater than 900 seconds"
        );
        require(
            newMax >= newMin,
            "ABC: the maximum price has to be greater than the minimum"
        );
        saleConfig = SaleConfig(
            newMin,
            newMax,
            newDecreaseAmount,
            newDecreaseTime,
            newStartTime
        );
        emit ChangeSaleConfig(
            newMin,
            newMax,
            newDecreaseAmount,
            newDecreaseTime,
            newStartTime
        );
    }

    /// @notice Change the baseURI. Only `DEFAULT_ADMIN_ROLE`.
    function setBaseURI(string memory _newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _newBaseURI;
        emit ChangedBaseURI(_newBaseURI);
    }

    /// @notice Change the URI base extension (ex: .json). Only `DEFAULT_ADMIN_ROLE`.
    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseExtension = _newBaseExtension;
        emit ChangedBaseExtension(_newBaseExtension);
    }

    /// @notice Change the URI of the NotRevealed animation. Only `DEFAULT_ADMIN_ROLE`.
    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        notRevealedUri = _notRevealedURI;
        emit ChangedNotRevealedUri(_notRevealedURI);
    }

    /// @notice Activate or disabled the burn function
    function setIsBurnEnabled(bool enabledBurn)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isBurnEnabled = enabledBurn;
        emit ChangedIsBurnEnabled(enabledBurn);
    }

    /// @notice Triggers stopped state. Only `DEFAULT_ADMIN_ROLE`.
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Returns to normal state. Only `DEFAULT_ADMIN_ROLE`.
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Activate token revelation. Only `DEFAULT_ADMIN_ROLE`.
    function reveal() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!revealed, "ABC: tokens are already revealed");
        revealed = true;
        emit RevealedTokens();
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner or an administrator.
    function transferOwnership(address newOwner) public override {
        require(
            owner() == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ABC: caller is not admin nor owner"
        );
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /* ========================
     *          Views
     * ========================
     */

    /// @notice Return the sale price of a token
    function getPrice() public view returns (uint256) {
        SaleConfig memory saleConfig_ = saleConfig;
        if (
            saleConfig_.decreaseTime == 0 ||
            block.timestamp < saleConfig_.startTime
        ) {
            return saleConfig_.maxPrice;
        }
        uint256 decreaseBy = block
            .timestamp
            .sub(saleConfig_.startTime)
            .div(saleConfig_.decreaseTime)
            .mul(saleConfig_.decreaseAmount);
        if (
            decreaseBy > saleConfig_.maxPrice ||
            saleConfig_.maxPrice.sub(decreaseBy) <= saleConfig_.minPrice
        ) {
            return saleConfig_.minPrice;
        }
        return saleConfig_.maxPrice.sub(decreaseBy);
    }

    /// @notice Get the maximum of NFT that `to` wallet can mint
    function getMaxMintAmountFor(address to) public view returns (uint256) {
        if (_maxMintPerAddress[to] > 0) {
            return _maxMintPerAddress[to];
        }
        return maxMintAmount;
    }

    /// @notice Get the maximum of NFT that `to` wallet can hold
    function getMaxWalletSupplyFor(address to) public view returns (uint256) {
        if (_maxWalletSupplyPerAddress[to] > 0) {
            return _maxWalletSupplyPerAddress[to];
        }
        return maxWalletSupplyAmount;
    }

    /// @notice Get the remaining NFT number that `to` wallet can mint
    function getRemainingMintAmountFor(address to)
        public
        view
        returns (uint256)
    {
        if (_mintPerAddress[to] >= getMaxMintAmountFor(to)) {
            return 0;
        }
        return getMaxMintAmountFor(to).sub(_mintPerAddress[to]);
    }

    /// @notice Get the remaining NFT number that `to` wallet can mint on presale
    function getRemainingPresaleMintAmountFor(address to)
        public
        view
        returns (uint256)
    {
        if (_mintPerAddress[to] >= presaleConfig.maxMintPerWallet) {
            return 0;
        }
        uint256 remainingPresaleMintAmount = presaleConfig.maxMintPerWallet.sub(
            _mintPerAddress[to]
        );
        uint256 remainingMintAmount = getRemainingMintAmountFor(to);

        return
            remainingPresaleMintAmount <= remainingMintAmount
                ? remainingPresaleMintAmount
                : remainingMintAmount;
    }

    /// @notice Get remaining NFT number that `to` wallet can hold
    function getRemainingWalletSupplyFor(address to)
        public
        view
        returns (uint256)
    {
        if (balanceOf(to) >= getMaxWalletSupplyFor(to)) {
            return 0;
        }
        return getMaxWalletSupplyFor(to).sub(balanceOf(to));
    }

    /// @notice Returns the number of tokens that can still be mined by the public
    function getRemainingTokens() public view returns (uint256) {
        return
            MAX_TOTAL_SUPPLY.sub(
                saleMintCount.add(presaleMintCount).add(reservedTokensCount)
            );
    }

    /// @notice Returns the URI of `tokenId` or the `notRevealedUri` if the tokens have not been revealed yet
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!revealed) {
            return notRevealedUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            tokenId.toString(),
                            baseExtension
                        )
                    )
                    : "";
        }
    }

    /// @notice Return the array of burnt tokens for `wallet`
    function getBurntTokensFor(address wallet)
        external
        view
        returns (uint256[] memory)
    {
        return _burntTokensPerAddress[wallet];
    }

    /// @notice Return whether `tokenId` was burned
    function isBurnt(uint256 tokenId) external view returns (bool) {
        return _burntTokens[tokenId];
    }

    /// @notice Return the array of burnt tokens for all `wallet`
    function getBurntTokensList() external view returns (uint256[] memory) {
        return _burntTokensList;
    }

    /// @notice Returns the baseURI in memory
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Returns whether `tokenId` exists or has existed
    function _existsOrBurn(uint256 tokenId) internal view returns (bool) {
        return _exists(tokenId) || _burntTokens[tokenId];
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Checks if a hash has been signed by a validator
    /// @param hash The data that was used to generate the signature
    /// @param sig The EC signature generated by an validator
    /// @return True if the signature was generated by an validator
    function isValidated(bytes32 hash, bytes memory sig)
        public
        view
        returns (bool)
    {
        return hasRole(VALIDATOR_ROLE, hash.recover(sig));
    }

    /// @dev Return the workflow status (view WorkflowStatus enum)
    function getWorkflowStatus() external view returns (WorkflowStatus) {
        // AllSoldOut
        if (totalSupply() == MAX_TOTAL_SUPPLY) {
            return WorkflowStatus.AllSoldOut;
        }

        // SoldOut,
        if (getRemainingTokens() == 0) {
            return WorkflowStatus.SoldOut;
        }

        // Sale
        SaleConfig memory saleConfig_ = saleConfig;
        if (
            saleConfig_.startTime > 0 &&
            block.timestamp >= saleConfig_.startTime
        ) {
            return WorkflowStatus.Sale;
        }

        // Presale and PresaleEnded
        PresaleConfig memory presaleConfig_ = presaleConfig;
        if (
            presaleConfig_.startTime > 0 &&
            block.timestamp >= presaleConfig_.startTime
        ) {
            if (
                block.timestamp <=
                presaleConfig_.startTime.add(presaleConfig_.duration)
            ) {
                return WorkflowStatus.Presale;
            }
            return WorkflowStatus.PresaleEnded;
        }

        // NotStarted
        return WorkflowStatus.NotStarted;
    }

    /* ========================
     *         INTERNAL
     * ========================
     */

    /// @dev Safely mint `tokenId` (if not already minted) and transfers it to `to`.
    function _safeDistribute(address to, uint256 tokenId)
        internal
        canHaveNewTokens(to, 1)
    {
        require(tokenId > 0, "ABC: Token ID can be 0");
        require(tokenId <= MAX_TOTAL_SUPPLY, "ABC: max supply exceeded");
        require(!_existsOrBurn(tokenId), "ABC: token already minted or burnt");

        if (_reservedTokens[tokenId] == false) {
            _reservedTokens[tokenId] = true;
            reservedTokensCount = reservedTokensCount.add(1);
        }
        _safeMint(to, tokenId);

        if (totalSupply() >= MAX_TOTAL_SUPPLY) {
            emit AllSoldOut(totalSupply());
        }
    }

    /// @dev Safely mint the next token that is not in the reserved list and transfers it to `to`.
    function _safeMint(address to)
        internal
        canHaveNewTokens(to, 1)
        canMintNewTokens(to, 1)
    {
        uint256 tokenId = _tokenIdCounter.add(1);
        // pass the reserved identifiers
        while (
            (_reservedTokens[tokenId] || _existsOrBurn(tokenId)) &&
            tokenId <= MAX_TOTAL_SUPPLY
        ) {
            tokenId = tokenId.add(1);
        }
        require(tokenId <= MAX_TOTAL_SUPPLY, "ABC: max supply exceeded");
        _safeMint(to, tokenId);
        _tokenIdCounter = tokenId;

        if (_tokenIdCounter >= MAX_TOTAL_SUPPLY) {
            emit SoldOut(totalSupply());
        }

        if (totalSupply() >= MAX_TOTAL_SUPPLY) {
            emit AllSoldOut(totalSupply());
        }
    }

    /// @dev Mint the `amount` of token in presale
    function _presaleMint(uint256 amount) internal {
        PresaleConfig memory presaleConfig_ = presaleConfig;
        require(amount > 0, "ABC: zero amount");
        require(presaleConfig_.startTime > 0, "ABC: presale is not active");
        require(
            block.timestamp >= presaleConfig_.startTime,
            "ABC: presale not started"
        );
        require(
            block.timestamp <=
                presaleConfig_.startTime.add(presaleConfig_.duration),
            "ABC: presale is ended"
        );
        require(
            _mintPerAddress[msg.sender].add(amount) <=
                presaleConfig_.maxMintPerWallet,
            "ABC: maximum mint number exceeded"
        );
        require(
            presaleConfig_.price * amount <= msg.value,
            "ABC: Ether value sent is not correct"
        );
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender);
        }
        _mintPerAddress[msg.sender] = _mintPerAddress[msg.sender].add(amount);
        presaleMintCount = presaleMintCount.add(amount);
        emit PresaleMint(msg.sender, amount, msg.value);
    }

    /// @dev Mint the `amount` of token in public sale
    function _saleMint(uint256 amount) internal {
        SaleConfig memory saleConfig_ = saleConfig;
        require(amount > 0, "ABC: zero amount");
        require(saleConfig_.startTime > 0, "ABC: sale is not active");
        require(
            block.timestamp >= saleConfig_.startTime,
            "ABC: sale not started"
        );
        uint256 price = getPrice();
        require(
            price * amount <= msg.value,
            "ABC: Ether value sent is not correct"
        );
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender);
        }
        _mintPerAddress[msg.sender] = _mintPerAddress[msg.sender].add(amount);
        saleMintCount = saleMintCount.add(amount);
        emit SaleMint(msg.sender, amount, msg.value);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused
        canHaveNewTokensOr0Address(to, 1)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
