//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721Upgradeable.sol";

import "./CountersUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./IERC721.sol";

import "./ICandyToken.sol";

contract UninterestedUnicornsV2 is
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    struct Parents {
        uint16 parent_1;
        uint16 parent_2;
    }

    // Stores quantity of UUs left in a season
    uint256 public QUANTITY_LEFT;

    // Breeding Information
    uint256 public BREEDING_COST; // UCD Breeding Cost
    uint256 public BREEDING_COST_ETH; // ETH Breeding cost
    uint256[] public BREEDING_DISCOUNT_THRESHOLD; // UCD to hold for discount
    uint256[] public BREEDING_DISCOUNT_PERC; // UCD to hold for discount

    // Signers
    address private BREED_SIGNER;
    address private WHITELIST_SIGNER;

    // External Contracts
    ICandyToken public CANDY_TOKEN;

    // GNOSIS SAFE
    address public TREASURY;

    // Passive Rewards
    uint256 public REWARDS_PER_DAY;
    mapping(uint256 => uint256) public lastClaim;

    // Private Variables
    CountersUpgradeable.Counter private _tokenIds;
    string private baseTokenURI;

    // UU Status
    mapping(uint256 => bool) private isBred; // Mapping that determines if the UUv1 is Bred

    // Toggles
    bool private breedingOpen;
    bool private presaleOpen;
    bool private publicOpen;

    // Mint Caps
    mapping(address => uint8) private privateSaleMintedAmount;
    mapping(address => uint8) private publicSaleMintedAmount;

    // Nonce
    mapping(bytes => bool) private _nonceUsed;

    // Parent Mapping
    mapping(uint256 => Parents) private _parents;

    // Reserve Storage (important: New variables should be declared below)
    uint256[50] private ______gap;

    // ------------------------ EVENTS ----------------------------
    event Minted(address indexed minter, uint256 indexed tokenId);

    event Breed(
        address indexed minter,
        uint256 tokenId,
        uint256 parent_1_tokenId,
        uint256 parent_2_tokenId
    );

    event RewardsClaimed(
        address indexed user,
        uint256 tokenId,
        uint256 amount,
        uint256 timestamp
    );

    // ---------------------- MODIFIERS ---------------------------

    /// @dev Only EOA modifier
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "UUv2: Only EOA");
        _;
    }

    function __UUv2_init(
        address owner,
        address _treasury,
        address _breedSigner,
        address _whitelistSigner
    ) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained("UninterestedUnicornsV2", "UUv2");
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __Pausable_init_unchained();

        transferOwnership(owner);
        TREASURY = _treasury;
        REWARDS_PER_DAY = 2 ether;
        BREEDING_COST = 1000 ether;
        BREEDING_COST_ETH = 0.1 ether;
        BREEDING_DISCOUNT_THRESHOLD = [10000 ether, 5000 ether];
        BREEDING_DISCOUNT_PERC = [75, 90]; // Percentage Discount
        BREED_SIGNER = _breedSigner;
        WHITELIST_SIGNER = _whitelistSigner;
        QUANTITY_LEFT = 5000;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // To revoke access after deployment
        grantRole(DEFAULT_ADMIN_ROLE, TREASURY);
        _setBaseURI(
            "https://lit-island-00614.herokuapp.com/api/v1/uuv2/chromosomes/"
        );
    }

    // ------------------------- USER FUNCTION ---------------------------

    /// @dev Takes the input of 2 genesis UU ids and breed them together
    /// @dev Ownership verication is done off-chain and signed by BREED_SIGNER
    function breed(
        uint16 parent_1_tokenId,
        uint16 parent_2_tokenId,
        bytes memory nonce,
        bytes memory signature
    ) public {
        require(
            breedSigned(
                msg.sender,
                nonce,
                signature,
                parent_1_tokenId,
                parent_2_tokenId
            ),
            "UUv2: Invalid Signature"
        );
        require(isBreedingOpen(), "UUv2: Breeding is not open");
        require(
            CANDY_TOKEN.balanceOf(msg.sender) > BREEDING_COST,
            "UUv2: Insufficient UCD for breeding"
        );
        require(QUANTITY_LEFT != 0, "UUv2: No more UUs available");
        require(
            !isBred[parent_1_tokenId] && !isBred[parent_2_tokenId],
            "UUv2: UUs have been bred before!"
        );

        // Reduce Quantity Left
        QUANTITY_LEFT -= 1;
        // Increase Token ID
        _tokenIds.increment();
        isBred[parent_1_tokenId] = true;
        isBred[parent_2_tokenId] = true;
        // Burn UCD Token
        CANDY_TOKEN.burn(msg.sender, BREEDING_COST);

        // Store Parent Id
        _parents[_tokenIds.current()] = Parents(
            parent_1_tokenId,
            parent_2_tokenId
        );

        // Set Last Claim
        lastClaim[_tokenIds.current()] = block.timestamp;

        // Mint
        _mint(msg.sender, _tokenIds.current());

        emit Breed(
            _msgSender(),
            _tokenIds.current(),
            parent_1_tokenId,
            parent_2_tokenId
        );
    }

    /// @dev Mint a random UUv2. Whitelisted addresses only
    /// @dev Whitelist is done off-chain and signed by WHITELIST_SIGNER
    function whitelistMint(bytes memory nonce, bytes memory signature)
        public
        payable
        onlyEOA
    {
        require(isPresaleOpen(), "UUv2: Presale Mint not open!");
        require(!_nonceUsed[nonce], "UUv2: Nonce was used");
        require(
            whitelistSigned(msg.sender, nonce, signature),
            "UUv2: Invalid signature"
        );

        require(
            privateSaleMintedAmount[msg.sender] < 1,
            "UUv2: Presale Limit Exceeded!"
        );

        require(
            msg.value == getETHPrice(msg.sender),
            "UUv2: Insufficient ETH!"
        );
        require(QUANTITY_LEFT != 0, "UUv2: No more UUs available");
        QUANTITY_LEFT -= 1;
        _tokenIds.increment();

        // Set Last Claim
        lastClaim[_tokenIds.current()] = block.timestamp;

        _mint(msg.sender, _tokenIds.current());

        (bool success, ) = TREASURY.call{value: msg.value}(""); // forward amount to treasury wallet
        require(success, "PropertyNFT: Unable to forward message to treasury!");
    }

    /// @dev Mint a random UUv2
    function mint(uint256 _amount) public payable onlyEOA {
        require(isPublicOpen(), "UUv2: Public Mint not open!");
        require(_amount <= 5, "UUv2: Maximum of 5 mints per transaction!");
        require(
            publicSaleMintedAmount[msg.sender] + _amount < 5,
            "UUv2: Public Limit Exceeded!"
        );
        require(
            msg.value == getETHPrice(msg.sender) * _amount,
            "UUv2: Insufficient ETH!"
        );

        for (uint256 i; i < _amount; i++) {
            require(QUANTITY_LEFT != 0, "UUv2: No more UUs available");
            QUANTITY_LEFT -= 1;
            _tokenIds.increment();

            // Set Last Claim
            lastClaim[_tokenIds.current()] = block.timestamp;

            _mint(msg.sender, _tokenIds.current());
        }

        (bool success, ) = TREASURY.call{value: msg.value}(""); // forward amount to treasury wallet
        require(success, "PropertyNFT: Unable to forward message to treasury!");
    }

    /// @dev Allow UUv2 Holders to claim UCD Rewards
    function claimRewards(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "UUv2: Claimant is not the owner!"
        );
        uint256 amount = calculateRewards(tokenId);

        // Update Last Claim
        lastClaim[tokenId] = block.timestamp;

        CANDY_TOKEN.mint(msg.sender, amount);
        emit RewardsClaimed(msg.sender, tokenId, amount, block.timestamp);
    }

    /// @dev Allow UUv2 Holders to claim UCD Rewards for a array of tokens
    function claimRewardsMultiple(uint256[] memory tokenIds) public {
        uint256 amount = 0; // Store total amount

        // Update Last Claim
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                ownerOf(tokenIds[i]) == msg.sender,
                "UUv2: Claimant is not the owner!"
            );
            uint256 claimAmount = calculateRewards(tokenIds[i]);
            amount += claimAmount;
            lastClaim[tokenIds[i]] = block.timestamp;
            emit RewardsClaimed(
                msg.sender,
                tokenIds[i],
                claimAmount,
                block.timestamp
            );
        }

        // Claim all tokens in 1 transaction
        CANDY_TOKEN.mint(msg.sender, amount);
    }

    // --------------------- VIEW FUNCTIONS ---------------------

    /// @dev Determines if UU has already been used for breeding
    function canBreed(uint256 tokenId) public view returns (bool) {
        return !isBred[tokenId];
    }

    /// @dev Get last claim timestamp of a specified tokenId
    function getLastClaim(uint256 tokenId) public view returns (uint256) {
        return lastClaim[tokenId];
    }

    /**
     * @dev Get Token URI Concatenated with Base URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    /// @dev Get ETH Mint Price. Discounts are calculated here.
    function getETHPrice(address _user) public view returns (uint256) {
        uint256 discount;
        if (CANDY_TOKEN.balanceOf(_user) >= BREEDING_DISCOUNT_THRESHOLD[0]) {
            discount = BREEDING_DISCOUNT_PERC[0];
        } else if (
            CANDY_TOKEN.balanceOf(_user) >= BREEDING_DISCOUNT_THRESHOLD[1]
        ) {
            discount = BREEDING_DISCOUNT_PERC[1];
        } else {
            discount = 100;
        }
        // Take original breeding cost multiply by 90, divide by 100
        return (BREEDING_COST_ETH * discount) / 100;
    }

    /// @dev Get UCD cost for breeding
    function getUCDPrice() public view returns (uint256) {
        return BREEDING_COST;
    }

    /// @dev Determine if breeding is open
    function isBreedingOpen() public view returns (bool) {
        return breedingOpen;
    }

    /// @dev Determine if pre-sale is open
    function isPresaleOpen() public view returns (bool) {
        return presaleOpen;
    }

    /// @dev Determine if public sale is open
    function isPublicOpen() public view returns (bool) {
        return publicOpen;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getParents(uint256 tokenId) public view returns (Parents memory) {
        return _parents[tokenId];
    }

    // ----------------------- CALCULATION FUNCTIONS ----------------------

    /// @dev Checks if the the signature is signed by a valid signer for breeding
    function breedSigned(
        address sender,
        bytes memory nonce,
        bytes memory signature,
        uint256 parent_1_id,
        uint256 parent_2_id
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(sender, nonce, parent_1_id, parent_2_id)
        );
        return BREED_SIGNER == hash.recover(signature);
    }

    /// @dev Checks if the the signature is signed by a valid signer for whitelists
    function whitelistSigned(
        address sender,
        bytes memory nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return WHITELIST_SIGNER == hash.recover(signature);
    }

    /// @dev Calculates the amount of UCD that can be claimed
    function calculateRewards(uint256 tokenId)
        public
        view
        returns (uint256 rewardAmount)
    {
        rewardAmount =
            ((REWARDS_PER_DAY) * (block.timestamp - getLastClaim(tokenId))) /
            (1 days);
    }

    /** @dev Calculates the amount of UCD that can be claimed for multiple tokens
        @notice Since ERC721Enumerable is not used, we must get the tokenIds owned by
                the user off-chain using Moralis.
    */
    function calculateRewardsMulti(uint256[] memory tokenIds)
        public
        view
        returns (uint256 rewardAmount)
    {
        for (uint256 i; i < tokenIds.length; i++) {
            rewardAmount += calculateRewards(tokenIds[i]);
        }
    }

    // ---------------------- ADMIN FUNCTIONS -----------------------

    /// @dev Set UCD Contract
    function setCandyToken(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        CANDY_TOKEN = ICandyToken(_addr);
    }

    /// @dev Set Quantity of mints/breeds left
    function setQuantity(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        QUANTITY_LEFT = _amount;
    }

    /// @dev Set Rewards per day for holding UU
    function setRewardsPerDay(uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        REWARDS_PER_DAY = _amount;
    }

    /// @dev Set Breeding Cost
    function setBreedingCost(uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BREEDING_COST = _amount;
    }

    /// @dev Set Mint Cost
    function setMintCost(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BREEDING_COST_ETH = _amount;
    }

    /// @dev Update token metadata baseURI
    function updateBaseURI(string memory newURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBaseURI(newURI);
    }

    /// @dev Toggle Breeding Open
    function toggleBreeding() public onlyRole(DEFAULT_ADMIN_ROLE) {
        breedingOpen = !breedingOpen;
    }

    /// @dev Toggle Presale Open
    function togglePresale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleOpen = !presaleOpen;
    }

    /// @dev Toggle Public Open
    function togglePublicSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        publicOpen = !publicOpen;
    }

    ///  @dev Pauses all token transfers.
    function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @dev Unpauses all token transfers.
    function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // --------------------- INTERNAL FUNCTIONS ---------------------

    /// @dev Set Base URI internal function
    function _setBaseURI(string memory _baseTokenURI) internal virtual {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Gets baseToken URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
