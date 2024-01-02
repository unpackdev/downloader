pragma solidity 0.8.22;

import "./IERC721.sol";
import "./MerkleProofUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ERC721ABurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OperatorFilterer.sol";
import "./IDelegationRegistry.sol";

contract Undeadz is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    ERC2981Upgradeable
{
    /// @dev Maximum total supply
    uint256 public maxTotalSupply;

    /// @dev Maximum amount of mints per wallet
    uint256 public maxPerWallet;

    /// @dev Determines whether phase 1 is live
    bool public isPhase1;

    /// @dev Determines whether phase 2 is live
    bool public isPhase2;

    /// @dev Determines whether phase 3 is live
    bool public isPhase3;

    /// @dev Price in wei of a gu mint
    uint256 public guPrice;

    /// @dev Price in wei of a whitelist mint
    uint256 public wlPrice;

    /// @dev Price in wei of a public mint
    uint256 public price;

    /// @dev The mint start time
    uint256 public liveAt;

    /// @dev The mint end time
    uint256 public endsAt;

    /// @dev The base uri for token metadata
    string public baseURI;

    /// @dev The hidden uri for token metadata
    string public hiddenURI;

    /// @dev Determine whether to show hidden or revealed metadata
    bool public isHidden;

    /// @dev The whitelist merkle root
    bytes32 public merkleRoot;

    /// @dev Operator filter enabled
    bool public operatorFilteringEnabled;

    /// @dev Genuine Undead Contract
    IERC721 public guContract;

    /// @dev GU mint mapping
    mapping(uint256 => bool) public reservedMints;

    /// @dev WL mint max
    mapping(address => uint256) public minted;

    /// @notice Delegation registry
    address public delegationRegistryAddress;

    /// @dev Used for off-chain indexing of GU mints that refer to a specific token id
    event Phase1Mint(uint256 startTokenId, uint256[] guTokenIds);

    error AlreadyMinted();
    error MaxSupplyReached();
    error MaxMintedPerWallet();
    error InsufficientFunds();
    error InvalidMerkle();
    error InvalidOwner();
    error PhaseNotLive();
    error InvalidDelegate();
    error FailedToWithdraw();

    modifier isDelegate(address vault) {
        bool isDelegateValid = IDelegationRegistry(delegationRegistryAddress)
            .checkDelegateForContract(msg.sender, vault, address(this));
        if (!isDelegateValid) revert InvalidDelegate();
        _;
    }

    function initialize(
        address _guContractAddress,
        address _delegationRegistryAddress,
        string calldata _hiddenURI
    ) public initializer initializerERC721A {
        __ERC721A_init("Undeadz", "UNDEAD");
        __Ownable_init();
        __ERC2981_init();

        // Initialize filter registry
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);

        // Set external contract integrations
        delegationRegistryAddress = _delegationRegistryAddress;
        guContract = IERC721(_guContractAddress);

        // Mint conditionals
        maxTotalSupply = 3333;
        maxPerWallet = 5;

        // Pricing
        guPrice = 0.017 ether;
        wlPrice = 0.02 ether;
        price = 0.03 ether;

        // Mint window
        liveAt = 1702324800;
        endsAt = 1702411200;

        // Metadata
        hiddenURI = _hiddenURI;
        isHidden = true;
    }

    /// @dev Overrides the starting token ID
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev Overrides base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Phase 1 GU mint
    function guMint(uint256[] calldata tokenIds) external payable {
        _guMint(tokenIds, msg.sender);
    }

    /// @notice Delegated Phase 1 GU mint
    function guMintDelegated(
        uint256[] calldata tokenIds,
        address vault
    ) external payable isDelegate(vault) {
        _guMint(tokenIds, vault);
    }

    /**
     * @dev Internal impl of GU mint. Allows GU NFTs to be minted 1:1 for a particular set of token ids.
     *      There needs to be off-chain indexing between the `nextTokenId` and length of tokenIds
     * @param tokenIds The GU token ids to mint
     * @param vault The owner address of the token ids
     */
    function _guMint(
        uint256[] calldata tokenIds,
        address vault
    ) internal {
        if (!isPhase1 || block.timestamp < liveAt || block.timestamp > endsAt)
            revert PhaseNotLive();

        uint256 mintAmount = tokenIds.length;

        if (totalSupply() + mintAmount > maxTotalSupply)
            revert MaxSupplyReached();

        // Discount pricing
        // 3+ 0.015 per
        // 15+ 0.012 per
        // 1 or 2 0.017 per
        if(mintAmount > 14){
            if(mintAmount * 0.012 ether != msg.value) revert InsufficientFunds();
        } else if(mintAmount > 2){
            if(mintAmount * 0.015 ether != msg.value) revert InsufficientFunds();
        } else if(mintAmount * guPrice != msg.value){
            revert InsufficientFunds();
        }


        uint256 tokenId;
        address owner;

        // Check token ownership & mark tokens as used
        for (uint256 i = 0; i < mintAmount; i++) {
            tokenId = tokenIds[i];
            owner = guContract.ownerOf(tokenId);
            if (owner != vault) revert InvalidOwner();
            if (reservedMints[tokenId]) revert AlreadyMinted();
            reservedMints[tokenId] = true;
        }

        uint256 startTokenId = _nextTokenId();

        _mint(vault, mintAmount);

        emit Phase1Mint(startTokenId, tokenIds);
    }

    /// @notice Phase 2 WL mint
    function wlMint(
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable {
        _wlMint(quantity, proof, msg.sender);
    }

    /// @notice Delegated Phase 2 WL mint
    function wlMintDelegated(
        uint256 quantity,
        bytes32[] calldata proof,
        address vault
    ) external payable isDelegate(vault) {
        _wlMint(quantity, proof, vault);
    }

    /**
     * @dev Internal impl of WL mint. Allows for a randomized set of mints given a whitelist.
            Max mints depends on `maxPerWallet` configuration.
     * @param quantity The amount of whitelist mint
     * @param proof The merkle proof to allow minting
     * @param vault The address to mint to
     */
    function _wlMint(
        uint256 quantity,
        bytes32[] calldata proof,
        address vault
    ) internal {
        if (!isPhase2 || block.timestamp < liveAt || block.timestamp > endsAt)
            revert PhaseNotLive();

        uint256 guBalance = guContract.balanceOf(vault);
        uint256 pricing = guBalance > 0 ? guPrice : wlPrice;

        if (quantity * pricing != msg.value) revert InsufficientFunds();

        if (minted[vault] + quantity > maxPerWallet)
            revert MaxMintedPerWallet();

        if (totalSupply() + quantity > maxTotalSupply) revert MaxSupplyReached();

        bytes32 leaf = keccak256(abi.encodePacked(vault));

        // Check whitelist
        if (!MerkleProofUpgradeable.verify(proof, merkleRoot, leaf))
            revert InvalidMerkle();

        // Track max minted
        minted[vault] += quantity;

        _mint(vault, quantity);
    }

    /// @notice Phase 3 mint
    function mint(uint256 quantity) external payable {
        _mint(quantity, msg.sender);
    }

    /// @notice Delegated Phase 3 mint
    function mintDelegated(
        uint256 quantity,
        address vault
    ) external payable isDelegate(vault) {
        _mint(quantity, vault);
    }

    /**
     * @dev Internal impl of public mint. Allows for a randomized set of mints. No max mint.
     * @param quantity The amount of mints
     * @param vault The address to mint to
     */
    function _mint(uint256 quantity, address vault) internal {
        if (!isPhase3 || block.timestamp < liveAt || block.timestamp > endsAt)
            revert PhaseNotLive();

        if (quantity * price != msg.value) revert InsufficientFunds();

        if (totalSupply() + quantity > maxTotalSupply) revert MaxSupplyReached();

        _mint(vault, quantity);
    }

    /**
     * @notice Token URI
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId The amount of mints
     */
    function tokenURI(uint256 tokenId) public view virtual override(IERC721AUpgradeable, ERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if(isHidden){
            return hiddenURI;
        }
        return bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId))) : '';
    }

    /**
     * @notice Team mint
     * @param to The address to send nfts
     * @param quantity The amount of mints
     */
    function teamMint(address to, uint256 quantity) external payable onlyOwner {
        if (totalSupply() + quantity > maxTotalSupply) revert MaxSupplyReached();
        _mint(to, quantity);
    }

    /**
     * @notice Sets base uri
     * @param baseURI_ The base uri to use
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Sets whether to use a hidden uri or not
     * @param _isHidden The hidden uri to use
     */
    function setIsHidden(bool _isHidden) external onlyOwner {
        isHidden = _isHidden;
    }

    /**
     * @notice Sets the merkle root for the whitelist
     * @param _merkleRoot The merkle root value
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the phases
     * @dev [isPhase1, isPhase2, isPhase3]
     * @param phases The phases of booleans, can toggle phases independently
     * @param _liveAt The live at unix timestamp
     * @param _endsAt The end at unix timestamp
     */
    function setPhases(
        bool[] calldata phases,
        uint256 _liveAt,
        uint256 _endsAt
    ) external onlyOwner {
        isPhase1 = phases[0];
        isPhase2 = phases[1];
        isPhase3 = phases[2];
        liveAt = _liveAt;
        endsAt = _endsAt;
    }

    /**
     * @notice Sets the prices
     * @dev [guPrice, wlPrice, price]
     * @param prices The prices in wei
     */
    function setPrices(uint256[] calldata prices) external onlyOwner {
        guPrice = prices[0];
        wlPrice = prices[1];
        price = prices[2];
    }

    /**
     * @notice Sets max total supply
     * @param _maxTotalSupply The max total supply for the collection
     */
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    /**
     * @notice Sets the max per wallet
     * @param _maxPerWallet The max mint count per address
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets the delegation registry address
     * @param _delegationRegistryAddress The delegation registry address to use
     */
    function setDelegationRegistryAddress(
        address _delegationRegistryAddress
    ) external onlyOwner {
        delegationRegistryAddress = _delegationRegistryAddress;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /// @notice Withdraw any eth
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert FailedToWithdraw();
    }
}
