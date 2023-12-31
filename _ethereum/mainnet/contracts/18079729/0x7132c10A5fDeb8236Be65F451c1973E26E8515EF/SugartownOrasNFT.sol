// SPDX-License-Identifier: MIT
// Zynga Web3 Contracts v1.0.0

pragma solidity ^0.8.19;

import "./ECDSAUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol"; // to prevent reentry attacks
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./BitMapsUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

import "./ERC721zUpgradeable.sol";
import "./IAddressRegistryV1.sol";
import "./IAddressRegistryReceiverV1.sol";

/**
 * 
 *  ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
 *  ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 *  ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 *  ||||||||||g@@@g||||$gg@||||ggg||||gg@@@g|||||||gggg|||||ggggggg||||gggggggggg|||gg@gg||||ggg||||||ggg|jggg|||jgg@|||||||
 *  ||||||||@@@@NB@@@g|$@@@|||1@@@||@@@@NN@@@@||||$@@@@@|||l@@@BBB@@@@|@@@@@@@@@@|@@@@@@@@@||$@@||||||@@@|]@@@@g|]@@@|||||||
 *  |||||||]@@@|||]BB@|$@@@|||1@@@|j@@@||||%BBW||$@@P]@@@||l@@@||||$@@@|||]@@@|||$@@@|||]NNN|$@@|j@@||@@@|]@@@@@@$@@@|||||||
 *  ||||||||@@@@@gg||||$@@@|||1@@@|j@@@|||||||||j@@@||$@@||l@@@||||@@@P|||]@@@|||$@@@||||||||]@@|$@@@l@@M|]@@@|B@@@@@|||||||
 *  |||||||||TRB@@@@@g|$@@@|||1@@@|j@@@||$@@@@W|@@@@@@@@@@|l@@@@@@@@@$||||]@@@|||$BBM|||j@@@|J@@|@@@@1@@W|]@@@||]B@@@|||||||
 *  ||||||||gg||||]@@@|$@@@|||1@@@|j@@@||||$@@Wl@@@||||@@@|l@@@|]@@@p|||||]@@@||||||||||j@@@||@@Q@@$@@@@||]@@@|||]@@@|||||||
 *  |||||||2@@@ggg@@@@|]@@@gg$@@@@||$@@@ggg@@@|l@@@|||l@@@|l@@@|||$@@@||||]@@@|||]@@@gg$@@@M||@@@@@]@@@@||]@@@|||]@@@|||||||
 *  |||||||||%B@@@@N$||||N@@@@@N$||||%B@@@@@B||l@@@|||l@@@|l@@@||||$@@W|||]@@@|||||$@@@@@R||||&BBBWJBBB@||]BB@|||]BB@|||||||
 *  ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 *  ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 *  ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 * 
 */

/**
 * @dev To reduce smart contract size & gas usages, we used custom errors rather than using require.
 */
error TokenOnHold();
error TokenAlreadyStaked();
error InvalidMerkleProof();
error MintNotStarted();
error CanNotExceedSupply();
error CanNotExceedWeeklyRaffleLimit();
error CanNotExceedMintSpot();
error NonGuaranteedNoMoreSupply();
error MintLimitPerUserExceeded();
error UserAlreadyMinted();
error ContractTriedToMint();
error ETHTransferFailed();
error WalletBlocked();
error RegistryIsNotAContract();
error OnlyAddressRegistry();
error AccountDataMismatch();
error CanNotSetLessThanOne();
error InvalidSignature();
error SignatureAlreadyUsed();
error MintLimitPerTransactionExceeded();
error ScreeningFailed();
error AirDropDataMismatch();
error ScreeningRequestAlreadyExist();

contract SugartownOrasNFT is ERC721zUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, DefaultOperatorFiltererUpgradeable, IAddressRegistryReceiverV1 {
    
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    /**
     * @dev counter for determining tokenIds of minted NFTs.
     *
     * Our NFTs' token ids will start from one. Counter is incremented by one in the initialization
     * function and that counter value is used for first minted NFT. Counter is
     * incremented by one after each mint.
     */
    uint64 private _tokenIdCounter;

    /**
     * @dev admin address field
     */
    address private _admin;

    /**
     * @dev merkle tree root for whitelisting users for guaranteed free mint phase
     */
    bytes32 private _guaranteedFreeMintMerkleRoot;

    /**
     * @dev merkle tree root for whitelisting users for non-guaranteed free mint phase
     */
    bytes32 private _nonGuaranteedFreeMintMerkleRoot;

    /**
     * @dev mint signature to is used map for tracking consumed signatures for raffle mints
     */
    mapping(bytes => bool) private _signatureToIsUsed;

    /**
     * @dev user to MintCounts count map for tracking users' mints
     */
    mapping(address => MintCounts) private _userToMintCounts;

    /**
     * @dev week to raffle mint count
     */
    mapping(uint256 => uint64) public nftsMintedPerWeek;

    /**
     * @dev field for storing public mint limit
     */
    uint64 public publicMintLimit;

    /**
     * @dev mint amount limit per week for raffle mints
     */
    uint64 public sweepStakesMintLimitPerWeek;

    /**
     * @dev mint amount limit per transaction for raffle mints
     */
    uint64 public sweepStakesMintLimitPerTransaction;

    /**
     * @dev fixed total supply of SugartownOrasNFT collection
     */
    uint64 constant public ORAS_TOTAL_SUPPLY = 9999;

    /**
     * @dev fixed guaranteed free mint supply of SugartownOrasNFT collection
     */
    uint64 constant public GUARANTEED_FREE_MINT_SUPPLY = 4150;

    /**
     * @dev fixed non-guaranteed free mint supply of SugartownOrasNFT collection
     */
    uint64 constant public NON_GUARANTEED_FREE_MINT_SUPPLY = 850;

    /**
     * @dev fixed public free mint supply of SugartownOrasNFT collection
     */
    uint64 constant public PUBLIC_FREE_MINT_SUPPLY = 1000;

    /**
     * @dev baseURI field
     *
     * This field is used to override baseURI of our tokens. This field can't be
     * altered once we lock the collection.
     */
    string public baseURIOverride;

    /**
     * @dev mint date fields - in Unix epoch - seconds
     */
    uint256 public guaranteedFreeMintDate;
    uint256 public nonGuaranteedFreeMintDate;
    uint256 public publicMintDate;

    /**
     * @dev tos field
     * 
     * This field is to store Terms of Service link. 
     */
    string public tos;

    /**
     * @dev isSweepStakesMintEnabled field
     * 
     * This field is to store sweep stakes mint enabled flag that indicates if
     * sweep stakes mint function can be executed.
     */
    bool public isSweepStakesMintEnabled;
 
    //-------------------------------------------------------------------------
    // Forte Address Screening related fields
    //-------------------------------------------------------------------------

    /**
     * @dev address screening enabled flag that indicates if screening is enabled
     */
    bool public isAddressScreeningEnabled;

    /**
     * @dev mint request model for off-chain oracle
     */
    struct MintRequest {
        bool processed;
        address account;
        uint64 amount;
    }

    /**
     * @dev stake request model for off-chain oracle
     */
    struct StakeRequest {
        bool processed;
        address account;
        uint256[] tokenIds;
    }

    /**
     * @dev mint count model for storing mint counts of users in different mint phases
     */
    struct MintCounts {
        uint64 guaranteedFreeMintCount;
        uint64 nonGuaranteedFreeMintCount;
        uint64 publicFreeMintCount;
    }

    /**
     * @dev address of the address registry contract we wish to interact with
     */
    address private _address_registry;

    /** 
     * @dev mapping of Request IDs to MintRequest model
     */
    mapping(uint256 => MintRequest) private _mintRequests;

    /** 
     * @dev mapping of Request IDs to StakeRequest model
     */
    mapping(uint256 => StakeRequest) private _stakeRequests;

    /** 
     * @dev token ID to isHold BitMap
     */
    BitMapsUpgradeable.BitMap private _tokenIdToIsHold;

    /** 
     * @dev registration ID returned from the Oracle Service for this
     * receiver Instance.  It is not required to store this on chain
     */
    uint private _registrationId;

    /** 
     * @dev flag to see if the application is registered.  On possible usage
     * for this would be the Openzeppelin "Pausable" contract type but
     * for the purposes of this example we will just hold the value
     */
    bool private _registered;

    /**
     * @dev constructor function
     * 
     * As we are using proxy pattern, there are not any initialization
     * going on in the constructor. Here, we only disable initializers as we don't
     * need to initialize anything after deployment.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev initialize function that initializes the state of the contract
     *
     * In this function, we initialize the state of nft contract.
     */
    function initialize() initializer public {
        __ERC721_init("Sugartown Oras", "ORAS");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();

        unchecked {
            ++_tokenIdCounter; // to make first NFT's token Id 1
        }

        publicMintLimit = 1;

        sweepStakesMintLimitPerWeek = 10; // set weekly raffle mint limit to 10 initially

        sweepStakesMintLimitPerTransaction = 1; // set mint amount limit to 1 initially

        baseURIOverride = "https://nfts.visitsugartown.com/nfts/oras/";

        guaranteedFreeMintDate = 1694613600; // will end at 1694624400
        nonGuaranteedFreeMintDate = 1694628000; // will end at 1694631600
        publicMintDate = 1694635200; // will end at 1694638800

        isSweepStakesMintEnabled = false;

        isAddressScreeningEnabled = true;

        tos = "https://visitsugartown.com/sugartown-terms";
    }

    /**
     * @dev totalSupply function to return current supply of the contract.
     */
    function totalSupply() public view returns (uint256) {
        return uint256(_tokenIdCounter - 1);
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * @dev pause function that updates contract's _paused state
     *
     * When contract is paused, functions with whenNotPaused modifiers can't be executed.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause function that updates contract's _paused state
     *
     * When contract is unpaused, functions with whenNotPaused modifiers can be executed.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev overriden _baseURI function
     * 
     * This function concantinates baseURIOverride field infront of token URIs of NFTs
     * when tokenURI function is called.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURIOverride;
    }

    /**
     * @dev overriden tokenURI function
     * 
     * This function overrides tokenURI by returning temporary token URI before reveal.
     * After collection is revealed, it will return actual token URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    /**
     * @dev overriden _transfer function to include whenNotPaused & nonReentrant modifier.
     */
    function _transfer(
        address from, 
        address to, 
        uint256 tokenId
    ) internal whenNotPaused nonReentrant override {
        super._transfer(from, to, tokenId);
    }

    /**
     * @dev required override by Solidity
     */
    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId,
        uint256 /*batchSize*/
    ) internal whenNotPaused override (ERC721zUpgradeable) {
        if (_tokenIdToIsHold.get(tokenId) != false)
            revert TokenOnHold();
        super._beforeTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Overriden setApprovalForAll function for operator filtering.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Overriden approve function for operator filtering.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Overriden transferFrom function for operator filtering.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Overriden safeTransferFrom function for operator filtering.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Overriden safeTransferFrom function for operator filtering.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev guaranteedFreeMint function
     * @param amount number of mints
     * @param mintSpot mint spot assigned to user in the allowlist
     * @param merkleProof proof hash that 
     *
     * This functions lets users mint NFTs.
     * 
     * CONSTRAINTS:
     * 1) User can do a mint only once
     * 2) Mint amount can't exceed mint spot assigned to the user
     * 3) Caller should prove that they have right mint spot in the allow list.
     * 4) Function can't be executed before guaranteedFreeMintDate.
     * 5) Mint amount should not exceed GUARANTEED_FREE_MINT_SUPPLY
     */
    function guaranteedFreeMint(uint64 amount, uint64 mintSpot, bytes32[] calldata merkleProof) public whenNotPaused {
        uint64 guaranteedFreeMintCount = _userToMintCounts[msg.sender].guaranteedFreeMintCount;

        if (guaranteedFreeMintCount != 0)
            revert UserAlreadyMinted();

        if (amount > mintSpot)
            revert CanNotExceedMintSpot();

        if (!MerkleProofUpgradeable.verifyCalldata(merkleProof, _guaranteedFreeMintMerkleRoot, keccak256(abi.encodePacked(msg.sender, mintSpot))))
            revert InvalidMerkleProof();
        
        if (block.timestamp < guaranteedFreeMintDate || guaranteedFreeMintDate == 0)
            revert MintNotStarted();
        
        if ((_tokenIdCounter - 1) + amount > GUARANTEED_FREE_MINT_SUPPLY)
            revert CanNotExceedSupply();

        unchecked {
            _userToMintCounts[msg.sender].guaranteedFreeMintCount += amount;
        }

        _mintMultiple(msg.sender, amount);
    }

    /**
     * @dev nonGuaranteedFreeMint function
     * @param amount number of mints
     * @param mintSpot mint spot assigned to user in the allowlist
     * @param merkleProof proof hash that 
     *
     * This functions lets users mint NFTs.
     * 
     * CONSTRAINTS:
     * 1) User can do a mint only once
     * 2) Mint amount can't exceed mint spot assigned to the user
     * 3) Caller should prove that they have right mint spot in the allow list.
     * 4) Function can't be executed before nonGuaranteedFreeMintDate.
     * 5) Mint amount should not exceed (GUARANTEED_FREE_MINT_SUPPLY + NON_GUARANTEED_FREE_MINT_SUPPLY)
     */
    function nonGuaranteedFreeMint(uint64 amount, uint64 mintSpot, bytes32[] calldata merkleProof) public whenNotPaused {
        uint64 nonGuaranteedFreeMintCount = _userToMintCounts[msg.sender].nonGuaranteedFreeMintCount;

        if (nonGuaranteedFreeMintCount != 0)
            revert UserAlreadyMinted();

        if (amount > mintSpot)
            revert CanNotExceedMintSpot();

        if (!MerkleProofUpgradeable.verifyCalldata(merkleProof, _nonGuaranteedFreeMintMerkleRoot, keccak256(abi.encodePacked(msg.sender, mintSpot))))
            revert InvalidMerkleProof();
        
        if (block.timestamp < nonGuaranteedFreeMintDate || nonGuaranteedFreeMintDate == 0)
            revert MintNotStarted();

        if ((_tokenIdCounter - 1) + amount > (GUARANTEED_FREE_MINT_SUPPLY + NON_GUARANTEED_FREE_MINT_SUPPLY + PUBLIC_FREE_MINT_SUPPLY)) {
            uint64 mintableAmount = (GUARANTEED_FREE_MINT_SUPPLY + NON_GUARANTEED_FREE_MINT_SUPPLY + PUBLIC_FREE_MINT_SUPPLY) - (_tokenIdCounter - 1);

            if (mintableAmount == 0)
                revert NonGuaranteedNoMoreSupply();

            unchecked {
                _userToMintCounts[msg.sender].nonGuaranteedFreeMintCount += mintableAmount;
            }

            _mintMultiple(msg.sender, mintableAmount);
        } else {
            unchecked {
                _userToMintCounts[msg.sender].nonGuaranteedFreeMintCount += amount;
            }

            _mintMultiple(msg.sender, amount);
        }
    }

    /**
     * @dev publicMint function
     * @param amount number of mints
     *
     * This functions lets users mint NFTs.
     * 
     * CONSTRAINTS:
     * 1) Function can't be executed before publicMintDate.
     * 2) Mint amount should not exceed (GUARANTEED_FREE_MINT_SUPPLY + NON_GUARANTEED_FREE_MINT_SUPPLY + PUBLIC_FREE_MINT_SUPPLY)
     * 3) Mint amount of a particular user can't exceed publicMintLimit.
     * 4) User should pass address screening.
     * 5) Caller can't be a smart contract.
     */
    function publicMint(uint64 amount) public whenNotPaused {
        uint64 publicFreeMintCount = _userToMintCounts[msg.sender].publicFreeMintCount;

        if (block.timestamp < publicMintDate || publicMintDate == 0)
            revert MintNotStarted();

        if ((_tokenIdCounter - 1) + amount > (GUARANTEED_FREE_MINT_SUPPLY + NON_GUARANTEED_FREE_MINT_SUPPLY + PUBLIC_FREE_MINT_SUPPLY))
            revert CanNotExceedSupply();

        if (publicFreeMintCount + amount > publicMintLimit)
            revert MintLimitPerUserExceeded();
        
        if (msg.sender != tx.origin)
            revert ContractTriedToMint();

        bool canProceed;
        uint256 requestResponse;

        if (isAddressScreeningEnabled) {
            (canProceed, requestResponse) = _screenUserAddress(msg.sender);
        } else {
            canProceed = true;
        }

        if (canProceed) {
            unchecked {
                _userToMintCounts[msg.sender].publicFreeMintCount = publicFreeMintCount + amount;
            }

            _mintMultiple(msg.sender, amount);
        } else {
            if (_mintRequests[requestResponse].account != address(0))
                revert ScreeningRequestAlreadyExist();
            
            _mintRequests[requestResponse] = MintRequest(false, msg.sender, amount);
        }
    }

    /**
     * @dev sweepStakesMint function
     * @param amount number of mints
     * @param identifierHash user identifier hash
     * @param signature signature generated for specific user to mint NFTs
     *
     * This functions lets users mint NFTs.
     * 
     * CONSTRAINTS:
     * 1) Sweep stakes mint should be enabled
     * 2) Signature should be valid for the user
     * 3) Signature shouldn't be used before
     * 4) Mint amount can't exceed limit per transaction
     * 5) Mint amount can't exceed fixed total supply
     */
    function sweepStakesMint(uint64 amount, bytes32 identifierHash, bytes calldata signature) public whenNotPaused {
        if (!isSweepStakesMintEnabled)
            revert MintNotStarted();

        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, amount, identifierHash));
        uint256 currentWeek = (block.timestamp / 1 weeks);

        if (recoverSigner(messageHash, signature) != admin())
            revert InvalidSignature();

        if (_signatureToIsUsed[signature])
            revert SignatureAlreadyUsed();

        if (amount > sweepStakesMintLimitPerTransaction)
            revert MintLimitPerTransactionExceeded();

        if ((_tokenIdCounter - 1) + amount > ORAS_TOTAL_SUPPLY)
            revert CanNotExceedSupply();

        if (nftsMintedPerWeek[currentWeek] + amount > sweepStakesMintLimitPerWeek)
            revert CanNotExceedWeeklyRaffleLimit();

        unchecked {
            nftsMintedPerWeek[currentWeek] += amount;
        }
        
        _signatureToIsUsed[signature] = true;

        _mintMultiple(msg.sender, amount);
    }

    /**
     * @dev airDropMint function
     * @param walletAddresses array of wallet addresses in air drop list
     * @param mintAmounts array of mint amounts in air drop list
     *
     * This functions lets owner air drop NFTs.
     * 
     * CONSTRAINTS:
     * 1) Length of wallet address data should match with the length of mint amounts data
     * 2) Can't exceed total supply of the collection
     */
    function airDropMint(address[] calldata walletAddresses, uint64[] calldata mintAmounts) public whenNotPaused onlyOwner {
        if (walletAddresses.length != mintAmounts.length)
            revert AirDropDataMismatch();
        
        for (uint256 i = 0; i < walletAddresses.length;) {
            if ((_tokenIdCounter - 1) + mintAmounts[i] > ORAS_TOTAL_SUPPLY)
                revert CanNotExceedSupply();

            _mintMultiple(walletAddresses[i], mintAmounts[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev lock function that stakes given token ID. Please see {ERC721z}.
     */
    function lock(uint256 tokenId) public virtual whenNotPaused nonReentrant {
        if (_tokenIdToIsHold.get(tokenId) != false)
            revert TokenOnHold();

        bool canProceed;
        uint256 requestResponse;

        if (isAddressScreeningEnabled) {
            (canProceed, requestResponse) = _screenUserAddress(msg.sender);
        } else {
            canProceed = true;
        }
        
        if (canProceed) {
            _stake(tokenId, msg.sender);
        } else {
            if (_tokenIdToStakeOwner[tokenId] != address(0))
                revert TokenAlreadyStaked();

            if (ownerOf(tokenId) != msg.sender)
                revert OnlyOwnerCanStake();

            if (_stakeRequests[requestResponse].account != address(0))
                revert ScreeningRequestAlreadyExist();

            _tokenIdToIsHold.set(tokenId);

            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = tokenId;

            _stakeRequests[requestResponse] = StakeRequest(false, msg.sender, tokenIds);
        }
    }

    /**
     * @dev unlock function that unstakes given token ID. Please see {ERC721z}.
     */
    function unlock(uint256 tokenId) public virtual whenNotPaused nonReentrant {
        _unstake(tokenId, msg.sender);
    }

    /**
     * @dev lockMultiple function that stakes given token IDs. Please see {ERC721z}.
     */
    function lockMultiple(uint256[] calldata tokenIds) public virtual whenNotPaused nonReentrant {
        for (uint256 i = 0; i < tokenIds.length;) {
            if (_tokenIdToIsHold.get(tokenIds[i]) != false)
                revert TokenOnHold();

            unchecked {
                i++;
            }
        }

        bool canProceed;
        uint256 requestResponse;

        if (isAddressScreeningEnabled) {
            (canProceed, requestResponse) = _screenUserAddress(msg.sender);
        } else {
            canProceed = true;
        }
        
        if (canProceed) {
            _stakeMultiple(tokenIds, msg.sender);
        } else {
            if (_stakeRequests[requestResponse].account != address(0))
                revert ScreeningRequestAlreadyExist();
            
            for (uint256 i = 0; i < tokenIds.length;) {
                if (_tokenIdToStakeOwner[tokenIds[i]] != address(0))
                    revert TokenAlreadyStaked();

                if (ownerOf(tokenIds[i]) != msg.sender)
                    revert OnlyOwnerCanStake();

                _tokenIdToIsHold.set(tokenIds[i]);

                unchecked {
                    i++;
                }
            }
            _stakeRequests[requestResponse] = StakeRequest(false, msg.sender, tokenIds);
        }
    }

    /**
     * @dev unlockMultiple function that unstakes given token IDs. Please see {ERC721z}.
     */
    function unlockMultiple(uint256[] calldata tokenIds) public virtual whenNotPaused nonReentrant {
        _unstakeMultiple(tokenIds, msg.sender);
    }

    /**
     * @dev function to withdraw contract balance
     * @param amount amount we want to withdraw
     * @param to target address ETH will be sent to
     */
    function withdraw(uint256 amount, address to) public onlyOwner {
        (bool success, /*bytes memory data*/) = to.call{value: amount}("");
        if (!success)
            revert ETHTransferFailed();
    }

    /**
     * @dev function to withdraw all contract balance
     * @param to target address ETH will be sent to
     */
    function withdrawAll(address to) public onlyOwner {
        (bool success, /*bytes memory data*/) = to.call{value: address(this).balance}("");
        if (!success)
            revert ETHTransferFailed();
    }

    /**
     * @dev setAdmin function that sets the given address as admin.
     */
    function setAdmin(address adminAddress) public onlyOwner {
        _admin = adminAddress;
    }

    /**
     * @dev setGuaranteedFreeMintMerkleRoot sets the merkle tree root for guaranteed free mint
     * @param merkleRoot merkle root of guaranteed mint merkle tree
     */
    function setGuaranteedFreeMintMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        _guaranteedFreeMintMerkleRoot = merkleRoot;
    }

    /**
     * @dev setNonGuaranteedFreeMintMerkleRoot sets the merkle tree root for guaranteed free mint
     * @param merkleRoot merkle root of non-guaranteed mint merkle tree
     */
    function setNonGuaranteedFreeMintMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        _nonGuaranteedFreeMintMerkleRoot = merkleRoot;
    }

    /**
     * @dev setter function for guaranteedFreeMintDate field
     * @param newMintDate new date in Unix epoch
     */
    function setGuaranteedFreeMintDate(uint256 newMintDate) public onlyOwner {
        guaranteedFreeMintDate = newMintDate;
    }

    /**
     * @dev setter function for nonGuaranteedFreeMintDate field
     * @param newMintDate new date in Unix epoch
     */
    function setNonGuaranteedFreeMintDate(uint256 newMintDate) public onlyOwner {
        nonGuaranteedFreeMintDate = newMintDate;
    }

    /**
     * @dev setter function for publicMintDate field
     * @param newMintDate new date in Unix epoch
     */
    function setPublicMintDate(uint256 newMintDate) public onlyOwner {
        publicMintDate = newMintDate;
    }

    /**
     * @dev setter function for publicMintLimit field
     * @param newLimit new public mint limit per wallet
     *
     * CONSTRAINTS:
     * 1) Mint limit can't be zero.
     */
    function setPublicMintLimit(uint64 newLimit) public onlyOwner {
        if (newLimit == 0)
            revert CanNotSetLessThanOne();
        publicMintLimit = newLimit;
    }

    /**
     * @dev setter function for sweep stakes mint enabled flag
     * @param isEnabled new state of sweep stakes mint enabled flag
     */
    function setSweepStakesMintEnabled(bool isEnabled) public onlyOwner {
        isSweepStakesMintEnabled = isEnabled;
    }

    /**
     * @dev setter function for sweepStakesMintLimitPerWeek field
     * @param newLimit new weekly raffle mint limit
     *
     * CONSTRAINTS:
     * 1) Mint limit can't be zero.
     */
    function setSweepStakesMintLimitPerWeek(uint64 newLimit) public onlyOwner {
        if (newLimit == 0)
            revert CanNotSetLessThanOne();
        sweepStakesMintLimitPerWeek = newLimit;
    }

    /**
     * @dev setter function for mint amount limit per transaction
     * @param newLimit new mint limit per transaction
     *
     * CONSTRAINTS:
     * 1) Mint limit can't be zero.
     */
    function setMintLimitPerTransaction(uint64 newLimit) public onlyOwner {
        if (newLimit == 0)
            revert CanNotSetLessThanOne();
        sweepStakesMintLimitPerTransaction = newLimit;
    }

    /**
     * @dev setter function for baseURIOverride field
     * @param uri new baseURI
     */
    function setBaseURI(string calldata uri) public onlyOwner {
        baseURIOverride = uri;
    }

    /**
     * @dev setter function for address screening enabled flag
     * @param isEnabled new state of address screening flag
     */
    function setAddressScreeningEnabled(bool isEnabled) public onlyOwner {
        isAddressScreeningEnabled = isEnabled;
    }

    /**
     * @dev setter function for Terms of Service link
     * @param newLink new Terms of Service link
     */
    function setTOSLink(string calldata newLink) public onlyOwner {
        tos = newLink;
    }

    /**
     * @dev getter function for users' guaranteed free mint count
     * @param user address of user we want to get mint count of
     */
    function getGuaranteedFreeMintCount(address user) public view returns(uint64) {
        return _userToMintCounts[user].guaranteedFreeMintCount;
    }

    /**
     * @dev getter function for users' non-guaranteed free mint count
     * @param user address of user we want to get mint count of
     */
    function getNonGuaranteedFreeMintCount(address user) public view returns(uint64) {
        return _userToMintCounts[user].nonGuaranteedFreeMintCount;
    }

    /**
     * @dev getter function for users' public free mint count
     * @param user address of user we want to get mint count of
     */
    function getPublicMintCount(address user) public view returns(uint64) {
        return _userToMintCounts[user].publicFreeMintCount;
    }

    /**
     * @dev getter function for total staked token count
     */
    function getTotalStakedTokenCount() public view returns(uint256) {
        return _totalStakedTokens;
    }

    /**
     * @dev getter function for users' staked token count
     * @param user address of user we want to get staked token count of
     */
    function getUserStakedTokenCount(address user) public view returns(uint256) {
        return _walletToStakedToken[user];
    }

    /**
     * @dev getter function for stake owner of given token ID
     * @param tokenId token ID that we want to get stake owner of
     */
    function getStakeOwner(uint256 tokenId) public view returns(address) {
        return _tokenIdToStakeOwner[tokenId];
    }

    /**
     * @dev getter function for user's total number of NFTs including staked & unstaked ones
     * @param user address of user that we want to retrieve total holdings count of
     */
    function getUserHoldings(address user) public view returns(uint256) {
        return balanceOf(user) + getUserStakedTokenCount(user);
    }

    /**
     * @dev internal function that talks to address screening oracle to check if user is a bad actor or not.
     * This funciton returns (bool, uint256). Boolean value is the flag indicating that user screening completed
     * on-chain. Second returned integer value is the request response / request ID.
     *
     * @param user address of user that we want to screen
     */
    function _screenUserAddress(address user) internal returns (bool, uint256) {
        (IAddressRegistryV1.ResultsEnum requestState, uint256 requestResponse) = IAddressRegistryV1(_address_registry).check(user);

        if (requestState == IAddressRegistryV1.ResultsEnum.READY) {
            if (requestResponse != 1)
                revert WalletBlocked();

            return (true, requestResponse);

        } else if (requestState == IAddressRegistryV1.ResultsEnum.PROCESSING){
            return (false, requestResponse);
        } else {
            revert ScreeningFailed();
        }
    }

    /**
     * @dev internal function that safe mints an NFT to given address
     * @param to address that will mint the NFT
     * @param amount number of mints
     *
     * This function mints NFT(s) to given address
     */
    function _mintMultiple(address to, uint64 amount) internal nonReentrant {
        unchecked {
            uint64 tempTokenIdCounter = _tokenIdCounter;

            for (uint64 i = 0; i < amount; i++) {
                _safeMint(to, tempTokenIdCounter);

                ++tempTokenIdCounter;
            }

            _tokenIdCounter = tempTokenIdCounter;
        }
    }

    /**
     * @dev internal function that recovers signer from given message hash and signature using ECDSA
     * @param messageHash hash value of the message signed
     * @param signature resulting signature of the sign process
     */
    function recoverSigner(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return ECDSAUpgradeable.recover(messageDigest, signature);
    }

    /**
     * @dev required override for UUPS proxy pattern to funciton properly.
     */
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override
    {
        // no additional requirements rather than onlyOwner modifier in the function signature
    }

    /** 
     * @dev Sets the Address Registry to be used.  This value MUST be a
     * contact address (no user accounts) and NOT the zero address
     * @dev Warning if you call this in a constructor for another contract
     * it will fail. This is a known EVM issue where constructors address are
     * in memory only and the check will fail
     *
     * @param sc the smart contract address to set as a handler for registry functions
     */
    function setAddressRegistry(address sc) external onlyOwner {
        if (!AddressUpgradeable.isContract(sc))
            revert RegistryIsNotAContract();
        _address_registry = sc;
        IAddressRegistryV1(_address_registry).register();
    }

    //-------------------------------------------------------------------------
    // Forte IAddressRegistryReceiver Interface Functions
    //-------------------------------------------------------------------------

    /**
     * @dev This call back would be made by the Oracle (or an oracle approved sender)
     * when the response for an offchain check it is ready.
     */
    function onResponse(
        IAddressRegistryV1.ResultsEnum result,
        uint256 reqID,
        address account,
        bool value
    ) external {
        if (msg.sender != _address_registry)
            revert OnlyAddressRegistry();

        uint64 mintRequestAmount = _mintRequests[reqID].amount;

        if (_mintRequests[reqID].processed == false && mintRequestAmount != 0) {
            if (_mintRequests[reqID].account != account)
                revert AccountDataMismatch();

            // set immediately to true to prevent reentry attack possibilities
            _mintRequests[reqID].processed = true;
            uint64 mintableAmount = (GUARANTEED_FREE_MINT_SUPPLY + NON_GUARANTEED_FREE_MINT_SUPPLY + PUBLIC_FREE_MINT_SUPPLY) - (_tokenIdCounter - 1);

            if (result == IAddressRegistryV1.ResultsEnum.COMPLETE && value && mintableAmount != 0) {
                uint64 amountToMint;

                if (mintableAmount < mintRequestAmount)
                    amountToMint = mintableAmount;
                else
                    amountToMint = mintRequestAmount;

                if (_userToMintCounts[account].publicFreeMintCount + amountToMint > publicMintLimit)
                        revert MintLimitPerUserExceeded();

                unchecked {
                    _userToMintCounts[account].publicFreeMintCount += amountToMint;
                
                    _mintMultiple(account, amountToMint);
                }
            }

        } else if (_stakeRequests[reqID].processed == false && _stakeRequests[reqID].tokenIds.length > 0) {
            if (_stakeRequests[reqID].account != account)
                revert AccountDataMismatch();

            // set immediately to true to prevent reentry attack possibilities
            _stakeRequests[reqID].processed = true;

            if (result == IAddressRegistryV1.ResultsEnum.COMPLETE && value) {
                if (_stakeRequests[reqID].tokenIds.length == 1) {
                    _stake(_stakeRequests[reqID].tokenIds[0], account);
                } else {
                    _stakeMultiple(_stakeRequests[reqID].tokenIds, account);
                }
            }

            for (uint256 i = 0; i < _stakeRequests[reqID].tokenIds.length;) {
                _tokenIdToIsHold.unset(_stakeRequests[reqID].tokenIds[i]);

                unchecked {
                    i++;
                }
            }
        }
    }

    /**
     * @dev Callback made by the offchain oracle when the registration was complete.
     * For this implementation we are just going to cache this information off
     * however it could gate things like mints/transfers/etc if we wanted to ensure
     * that nothing will transaction until registration has completed.
     *
     * @param result of the registration.
     * @param regID identifier of the registration.
     */
    function onRegistration(
        IAddressRegistryV1.ResultsEnum result,
        uint256 regID
    ) external {
        if (msg.sender != _address_registry)
            revert OnlyAddressRegistry();

        if (!_registered && result == IAddressRegistryV1.ResultsEnum.COMPLETE) {
            _registered = true;
            _registrationId = regID;
        }
    }
}