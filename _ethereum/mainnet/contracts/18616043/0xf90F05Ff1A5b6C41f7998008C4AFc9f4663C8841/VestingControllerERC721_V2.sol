// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SignatureVerification_V2.sol";
import "./ImportsManager.sol";
import "./IInvestorsNFT.sol";

/// @title Rand.network ERC721 Vesting Controller contract
/// @author @adradr - Adrian Lenard
/// @notice Manages the vesting schedules for Rand investors
/// @dev Interacts with Rand token and Safety Module (SM)

/// VC1: No access role for this address
/// VC2: Not accessible by msg.sender
/// VC3: Signature invalid
/// VC4: tokenId does not exist
/// VC5: Only Investors NFT allowed to call
/// VC6: nftTokenId does not exist
/// VC7: Amount is more than claimable
/// VC8: Amount to be claimed is more than remaining
/// VC9: Recipient cannot be zero address
/// VC10: Amount must be more than zero
/// VC11: Transfer of token is prohibited until investment is totally claimed

contract VestingControllerERC721_V2 is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ImportsManager,
    SignatureVerification_V2
{
    // Events
    event BaseURIChanged(string baseURI);
    event ContractURIChanged(string contractURI);
    event ClaimedAmount(uint256 tokenId, address recipient, uint256 amount);
    event StakedAmountModified(uint256 tokenId, uint256 amount);
    event NewInvestmentTokenMinted(
        VestingInvestment investment,
        uint256 tokenId
    );
    event NewInvestmentTokenMintedWithNFT(
        uint256 nftTokenId,
        uint256 tokenId,
        uint8 nftLevel
    );
    event InvestmentTransferred(address recipient, uint256 amount);
    event RNDTransferred(address recipient, uint256 amount);
    event FetchedRND(uint256 amount);

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringsUpgradeable for uint256;

    string public baseURI;
    uint256 public PERIOD_SECONDS;
    CountersUpgradeable.Counter internal _tokenIdCounter;
    mapping(bytes32 => bool) internal _verifiedSignatures;
    mapping(uint256 => uint256) internal _nftTokenToVCToken; // Mapping to store VC tokenIds to NFT tokenIds

    struct MintParameters {
        address recipient;
        uint256 rndTokenAmount;
        uint256 vestingPeriod;
        uint256 vestingStartTime;
        uint256 cliffPeriod;
    }

    struct VestingInvestment {
        uint256 rndTokenAmount;
        uint256 rndClaimedAmount;
        uint256 rndStakedAmount;
        uint256 vestingPeriod;
        uint256 vestingStartTime;
        uint256 mintTimestamp;
        bool exists;
    }
    mapping(uint256 => VestingInvestment) internal vestingToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initializer allow proxy scheme
    /// @dev for upgradability its necessary to use initialize instead of simple constructor
    /// @param _erc721_name Name of the token like `Rand Vesting Controller ERC721`
    /// @param _erc721_symbol Short symbol like `vRND`
    /// @param _periodSeconds Amount of seconds to set 1 period to like 60*60*24 for 1 day
    /// @param _registry is the address of address registry
    function initialize(
        string calldata _erc721_name,
        string calldata _erc721_symbol,
        uint256 _periodSeconds,
        IAddressRegistry _registry
    ) public initializer {
        __ERC721_init(_erc721_name, _erc721_symbol);
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __ImportsManager_init();

        PERIOD_SECONDS = _periodSeconds;
        REGISTRY = _registry;

        address _multisigVault = REGISTRY.getAddressOf(REGISTRY.MULTISIG());
        _grantRole(DEFAULT_ADMIN_ROLE, _multisigVault);
        _grantRole(PAUSER_ROLE, _multisigVault);
    }

    modifier onlyInvestorOrRand(uint256 tokenId) {
        bool isTokenOwner = ownerOf(tokenId) == _msgSender();
        bool isSM = REGISTRY.getAddressOf(REGISTRY.SAFETY_MODULE()) ==
            _msgSender();
        bool isGov = REGISTRY.getAddressOf(REGISTRY.GOVERNANCE()) ==
            _msgSender();
        require(isTokenOwner || isSM || isGov, "VC1: Only investor or Rand");
        _;
    }

    modifier onlySM() {
        require(
            REGISTRY.getAddressOf(REGISTRY.SAFETY_MODULE()) == _msgSender(),
            "VC2: Not accessible by msg.sender"
        );
        _;
    }

    modifier verifySignature(
        bytes memory signature,
        address recipient,
        uint256 rndAmount,
        uint256 vestingStartTime,
        uint256 vestingPeriod,
        uint256 cliffPeriod,
        uint8 nftLevel,
        uint256 timestamp
    ) {


        require(
            _redeemSignature(
                recipient,
                rndAmount,
                vestingStartTime,
                vestingPeriod,
                cliffPeriod,
                nftLevel,
                timestamp,
                signature,
                REGISTRY.getAddressOf(REGISTRY.VESTING_CONTROLLER_SIGNER())
            ),
            "VC3: Signature invalid"
        );
        _;
    }

    /// @notice View function to get amount of claimable tokens from vested investment token
    /// @dev only accessible by the investor's wallet, the backend address and safety module contract
    /// @param tokenId the tokenId for which to query the claimable amount
    /// @return amounts of tokens an investor is eligible to claim (already vested and unclaimed amount)
    function getClaimableTokens(
        uint256 tokenId
    ) public view onlyInvestorOrRand(tokenId) returns (uint256) {
        return _calculateClaimableTokens(tokenId);
    }

    /// @notice View function to get information about a vested investment token
    /// @dev only accessible by the investor's wallet, the backend address and safety module contract
    /// @param tokenId is the id of the token for which to get info
    /// @return rndTokenAmount is the amount of the total investment
    /// @return rndClaimedAmount amounts of tokens an investor already claimed and received
    /// @return vestingPeriod number of periods the investment is vested for
    /// @return vestingStartTime the timestamp when the vesting starts to kick-in
    /// @return rndStakedAmount the amount of tokens an investor is staking
    function getInvestmentInfo(
        uint256 tokenId
    )
        public
        view
        onlyInvestorOrRand(tokenId)
        returns (
            uint256 rndTokenAmount,
            uint256 rndClaimedAmount,
            uint256 vestingPeriod,
            uint256 vestingStartTime,
            uint256 rndStakedAmount
        )
    {
        require(vestingToken[tokenId].exists, "VC4: tokenId does not exist");
        rndTokenAmount = vestingToken[tokenId].rndTokenAmount;
        rndClaimedAmount = vestingToken[tokenId].rndClaimedAmount;
        vestingPeriod = vestingToken[tokenId].vestingPeriod;
        vestingStartTime = vestingToken[tokenId].vestingStartTime;
        rndStakedAmount = vestingToken[tokenId].rndStakedAmount;
    }

    /// @notice View function to get information about a vested investment token exclusively for the Investors NFT contract
    /// @dev only accessible by the investors NFT contract
    /// @param nftTokenId is the id of the token for which to get info
    /// @return rndTokenAmount is the amount of the total investment
    /// @return rndClaimedAmount amounts of tokens an investor already claimed and received
    function getInvestmentInfoForNFT(
        uint256 nftTokenId
    ) external view returns (uint256 rndTokenAmount, uint256 rndClaimedAmount) {
        require(
            REGISTRY.getAddressOf(REGISTRY.INVESTOR_NFT()) == _msgSender(),
            "VC5: Only Investors NFT allowed to call"
        );
        require(
            _nftTokenToVCToken[nftTokenId] != 0,
            "VC6: nftTokenId does not exist"
        );
        uint256 tokenId = _nftTokenToVCToken[nftTokenId];
        rndTokenAmount = vestingToken[tokenId].rndTokenAmount;
        rndClaimedAmount = vestingToken[tokenId].rndClaimedAmount;
    }

    /// @notice Claim function to withdraw vested tokens
    /// @dev emits ClaimedAmount() and only accessible by the investor's wallet, the backend address and safety module contract
    /// @param tokenId is the id of investment to submit the claim on
    /// @param amount is the amount of vested tokens to claim in the process
    function claimTokens(
        uint256 tokenId,
        uint256 amount
    )
        public
        whenNotPaused
        onlyInvestorOrRand(tokenId)
        whenNotPaused
        nonReentrant
    {
        address recipient = ownerOf(tokenId);
        uint256 claimable = _calculateClaimableTokens(tokenId);
        require(claimable >= amount, "VC7: Amount is more than claimable");
        _addClaimedTokens(amount, tokenId);
        IERC20Upgradeable(REGISTRY.getAddressOf(REGISTRY.RAND_TOKEN()))
            .safeTransfer(recipient, amount);
        emit ClaimedAmount(tokenId, recipient, amount);
    }

    /// @notice Adds claimed amount to the investments
    /// @dev internal function only called by the claimTokens() function
    /// @param amount is the amount of vested tokens to claim in the process
    /// @param tokenId is the id of investment to submit the claim on
    function _addClaimedTokens(uint256 amount, uint256 tokenId) internal {
        VestingInvestment storage investment = vestingToken[tokenId];
        require(
            investment.rndTokenAmount - investment.rndClaimedAmount >= amount,
            "VC8: Amount to be claimed is more than remaining"
        );
        vestingToken[tokenId].rndClaimedAmount += amount;
    }

    /// @notice Calculates the claimable amount as of now for a tokenId
    /// @dev internal function only called by the claimTokens() function
    /// @param tokenId is the id of investment to submit the claim on
    function _calculateClaimableTokens(
        uint256 tokenId
    ) internal view returns (uint256 claimableAmount) {
        require(vestingToken[tokenId].exists, "VC4: tokenId does not exist");
        VestingInvestment memory investment = vestingToken[tokenId];
        // If the vestingStartTime is in the future return zero
        if (block.timestamp < investment.vestingStartTime) {
            claimableAmount = 0;
            return claimableAmount;
        }
        uint256 vestedPeriods;
        unchecked {
            vestedPeriods = block.timestamp - investment.vestingStartTime;
        }

        // If there is still not yet vested periods
        if (vestedPeriods < investment.vestingPeriod) {
            claimableAmount =
                (vestedPeriods * investment.rndTokenAmount) /
                investment.vestingPeriod -
                investment.rndClaimedAmount -
                investment.rndStakedAmount;
        } else {
            // If all periods are vested already
            claimableAmount =
                investment.rndTokenAmount -
                investment.rndClaimedAmount -
                investment.rndStakedAmount;
        }
    }


    /// @notice Mints a token and associates an investment to it and sets tokenURI and also mints an investors NFT
    /// @dev emits NewInvestmentTokenMinted() and only accessible with signature from Rand
    /// @param signature is the signature which is used to verify the minting
    /// @param signatureTimestamp is the expiration timestamp of the signature
    /// @param params is the struct with all the parameters for the investment
    /// @param nftLevel is the level of the NFT to be minted
    /// @return tokenId the id of the minted token on VC
    function mintNewInvestment(
        bytes memory signature,
        uint256 signatureTimestamp,
        MintParameters memory params,
        uint8 nftLevel
    ) public whenNotPaused nonReentrant verifySignature(
            signature,
            params.recipient,
            params.rndTokenAmount,
            params.vestingStartTime,
            params.vestingPeriod,
            params.cliffPeriod,
            nftLevel,
            signatureTimestamp
        )
    returns (uint256 tokenId) {
        // Minting vesting investment inside VC
        tokenId = _mintNewInvestment(signature, signatureTimestamp, params);

        // Minting NFT investment for early investors
        if (nftLevel > 0) {
            uint256 nftTokenId = IInvestorsNFT(
                REGISTRY.getAddressOf(REGISTRY.INVESTOR_NFT())
            ).mintInvestmentNFT(params.recipient, nftLevel - 1);
            // Emit event for the NFT tokenId
            emit NewInvestmentTokenMintedWithNFT(
                nftTokenId,
                tokenId,
                nftLevel - 1
            );

            // Storing the VC tokenId to the corresponding NFT tokenId
            _nftTokenToVCToken[nftTokenId] = tokenId;
        }
    }

    function _mintNewInvestment(
        bytes memory signature,
        uint256 signatureTimestamp,
        MintParameters memory params
    )
        internal returns (uint256 tokenId)
    {
        // Requiring that the recipient is not the zero address
        require(
            params.recipient != address(0),
            "VC9: Recipient cannot be zero address"
        );
        // Fetching RND from Multisig
        _getRND(params.rndTokenAmount);

        // Incrementing token counter and minting new token to recipient
        tokenId = _safeMint(params.recipient);

        // Initializing investment struct and assigning to the newly minted token
        if (params.vestingStartTime == 0) {
            params.vestingStartTime = block.timestamp;
        }
        params.vestingStartTime += params.cliffPeriod;
        params.vestingPeriod = params.vestingPeriod * PERIOD_SECONDS;
        uint256 mintTimestamp = block.timestamp;
        uint256 rndClaimedAmount = 0;
        uint256 rndStakedAmount = 0;
        bool exists = true;

        VestingInvestment memory investment = VestingInvestment(
            params.rndTokenAmount,
            rndClaimedAmount,
            rndStakedAmount,
            params.vestingPeriod,
            params.vestingStartTime,
            mintTimestamp,
            exists
        );

        vestingToken[tokenId] = investment;
        emit NewInvestmentTokenMinted(investment, tokenId);
    }
    
    /// @notice Transfers RND Tokens to non-vesting investor, its used to distribute public sale tokens by backend
    /// @dev emits InvestmentTransferred() and only accessible with signature from Rand
    /// @param recipient is the address to whom the token should be transferred to
    /// @param rndTokenAmount is the amount of the total investment
    function distributeTokens(
        bytes memory signature,
        uint256 signatureTimestamp,
        address recipient,
        uint256 rndTokenAmount
    )
        public
        whenNotPaused
        nonReentrant
        verifySignature(
            signature,
            recipient,
            rndTokenAmount,
            0,
            0,
            0,
            0,
            signatureTimestamp
        )
    {
        require(rndTokenAmount > 0, "VC10: Amount must be more than zero");
        require(
            recipient != address(0),
            "VC9: Recipient cannot be zero address"
        );
        IERC20Upgradeable(REGISTRY.getAddressOf(REGISTRY.RAND_TOKEN()))
            .safeTransferFrom(
                REGISTRY.getAddressOf(REGISTRY.ECOSYSTEM_RESERVE()),
                recipient,
                rndTokenAmount
            );
        emit InvestmentTransferred(recipient, rndTokenAmount);
    }
    
    /// @notice Function for Safety Module to increase the staked RND amount
    /// @dev emits StakedAmountModifier() and only accessible by the Safety Module contract via SM_ROLE
    /// @param tokenId the tokenId for which to increase staked amount
    /// @param amount the amount of tokens to increase staked amount
    function modifyStakedAmount(
        uint256 tokenId,
        uint256 amount
    ) external whenNotPaused onlySM {
        require(vestingToken[tokenId].exists, "VC4: tokenId does not exist");
        vestingToken[tokenId].rndStakedAmount = amount;
        emit StakedAmountModified(tokenId, amount);
    }

    /// @notice Function which allows VC to pull RND funds when minting an investment
    /// @dev emit FetchedRND(), needs allowance from MultiSig on initial RND supply
    /// @param amount of tokens to fetch from the Rand Multisig when minting a new investment
    function _getRND(uint256 amount) internal {
        IERC20Upgradeable(REGISTRY.getAddressOf(REGISTRY.RAND_TOKEN()))
            .safeTransferFrom(
                REGISTRY.getAddressOf(REGISTRY.ECOSYSTEM_RESERVE()),
                address(this),
                amount
            );
        emit FetchedRND(amount);
    }

    /// @notice Simple utility function to get investment tokenId based on an NFT tokenId
    /// @param tokenIdNFT tokenId of the early investor NFT
    /// @return tokenId of the investment
    function getTokenIdOfNFT(
        uint256 tokenIdNFT
    ) public view returns (uint256 tokenId) {
        tokenId = _nftTokenToVCToken[tokenIdNFT];
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _safeMint(address to) internal returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @notice Burn vesting token by admin (avaiable only for DEFAULT_ADMIN_ROLE)
    /// @dev Returns collateral tokens to the caller
    /// @param tokenId to be burned
    function burn(
        uint256 tokenId
    ) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(vestingToken[tokenId].exists, "VC4: tokenId does not exist");

        // Get still vesting tokens
        uint256 rndTokenAmount = vestingToken[tokenId].rndTokenAmount;
        uint256 rndClaimedAmount = vestingToken[tokenId].rndClaimedAmount;
        uint256 rndStakedAmount = vestingToken[tokenId].rndStakedAmount;
        uint256 rndTotalAmount = rndTokenAmount -
            rndClaimedAmount -
            rndStakedAmount;

        // Transfer RND tokens back to the caller
        IERC20Upgradeable(REGISTRY.getAddressOf(REGISTRY.RAND_TOKEN()))
            .transfer(_msgSender(), rndTotalAmount);
        // Burn his investment token
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        bool isClaimedAll;
        if (vestingToken[tokenId].exists) {
            uint256 rndTokenAmount = vestingToken[tokenId].rndTokenAmount;
            uint256 rndClaimedAmount = vestingToken[tokenId].rndClaimedAmount;
            isClaimedAll = rndTokenAmount == rndClaimedAmount;
        }
        require(
            isClaimedAll,
            "VC11: Transfer of token is prohibited until investment is totally claimed"
        );
        super._transfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
