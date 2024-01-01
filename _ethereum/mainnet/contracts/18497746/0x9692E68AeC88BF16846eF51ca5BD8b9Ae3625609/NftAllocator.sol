//SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Clones.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721A.sol";

import "./Types.sol";
import "./Venture.sol";

import "./SignatureValidation.sol";

/**
* @title NftAllocator
* @notice With this contract you can invest and claim a nft
*/
contract NftAllocator is Initializable, OwnableUpgradeable, ERC721A__IERC721Receiver, ReentrancyGuardUpgradeable {

    struct TokensAllocated {
        /// @notice the account that claimed the tokens
        address account;
        /// @notice the amount of tokens allocation claimed
        uint256 claimed;
        /// @notice the amount of tokens allocation unclaimed
        uint256 unclaimed;
    }

    /// @notice The address where Jubi fees will be sent
    address public jubiFundsAddress;

    /// @notice The Jubi fee amount
    uint256 public jubiFee;

    /// @notice The funds a venture will get per investment
    uint256 public ventureFunds;

    /// @notice which nft investors will be claiming
    IERC721A public nft;

    /// @notice the Venture that manages this contract
    Venture public venture;

    /// @notice The name used to identify this Allocator in Dapps
    string public name;

    /// @notice Is the allocator open
    bool public isOpen;

    /// @notice price to pay for nft
    uint256 public nftPrice;

    /// @notice max number of nft to sale
    uint256 public tokensForAllocation;

    /// @notice merkle root that captures all valid invite codes
    bytes32 public inviteCodesMerkleRoot;

    /// @notice Hashed domain separator as per EIP721
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice Data hash of the signed terms of this allocator
    bytes32 public termsHash;

    /// @notice the URL where the terms of this allocator can be found
    string public termsUrl;

    /// @notice The signature of the token allocations terms by the venture's representative
    /// signature is for ALL invite codes and the entire token allocation, and counts as counter signature for each purchase
    bytes public ventureSignature;

    /// @notice maps invitesCodes => TokensAllocated
    mapping(bytes32 => TokensAllocated) public invitesAllocation;

    /// @notice all address in this mapping have invested in this allocator, No is the number of active claims in this allocator
    mapping(address => uint256) public pendingClaims;

    /// @notice number of investors
    uint256 public investmentsCount;

    /// @notice number of investors which have NOT collected their nft
    uint256 public totalUnclaimed;

    /// @notice A list of tokenIds received by this contract
    mapping(uint256 => uint256) public tokenIds;
    /// @notice The total of `tokenIds`
    uint256 public tokenIdsLength;
    /// @notice The next token id from `tokenIds` to be claimed
    uint256 public nextTokenId;

    /**
    * @notice This event is emitted an investment is made
    * @param account The account that invested
    * @param investment The amount that was invested
    */
    event Investment(address indexed account, uint256 investment, uint256 numTokens, bytes signature, bytes ventureSignature);

    /**
    * @notice This event is emitted after an nft was claimed
    * @param account The account that claimed
    * @param tokenId The nft id that was claimed
    */
    event Claimed(address indexed account, uint256 indexed tokenId);

    /**
    * @notice This event is emitted after an investment and no nft where available for claim
    * @param account The account that invested
    * @param ventureFunds The amount that are hold by this contract until NFt is claimed
    * @param pending The number of pending claims added to `account`
    */
    event PendingClaim(address indexed account, uint256 ventureFunds, uint256 pending);

    /**
    * @notice This event is emitted a nft is transferred to this contract
    * @param tokenId The transferred nft tokenId
    */
    event NftReceived(uint256 indexed tokenId);

    /**
    * @notice This event is emitted when an `admin` migrates the venture that manages this allocator
    * from `oldVenture` to `newVenture`
    * @param oldVenture The venture that is been deprecated
    * @param newVenture The venture that is assigned as the new manager
    * @param admin The admin account that perform the migration
    */
    event VentureMigrated(address indexed oldVenture, address indexed newVenture, address admin);

    /**
     * @dev Emitted when the allocator is closed.
     * @param account The account that closed the allocator.
     */
    event AllocatorClosed(address account);

    /**
     * @dev Emitted when an NFT contract is set for an account.
     * @param nft The address of the NFT contract.
     * @param account The address of the account.
     */
    event NFTSet(address nft, address account);

    /**
    * @notice Initializes a NftAllocator with `config`.
    * @param _jubiFundsAddress The address where Jubi funds will be sent
    * @param _jubiFeePercent The fee Jubi will be charging
    * @param _config The config to initialize the NftAllocator
    */
    function initialize(address _jubiFundsAddress, Types.Fraction memory _jubiFeePercent, Types.NftAllocatorConfig memory _config, address _founder) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_config.venture.owner());
        jubiFundsAddress = _jubiFundsAddress;
        nft = _config.nft;
        venture = _config.venture;
        nftPrice = _config.nftPrice;
        tokensForAllocation = _config.tokensForAllocation;
        inviteCodesMerkleRoot = _config.inviteCodesMerkleRoot;
        jubiFee = nftPrice * _jubiFeePercent.num / _jubiFeePercent.den;
        ventureFunds = nftPrice - jubiFee;
        isOpen = true;
        name = _config.name;

        bytes32 founderDomain = SignatureUtil.hashDomain( SignatureUtil.EIP712Domain({
            name : name,
            version : '1',
            chainId : block.chainid,
            verifyingContract : _founder
        }));

        SignatureUtil.SignatureData memory signatureData = SignatureUtil.SignatureData({
            signer: _founder,
            termsUrl: _config.signatureStore.termsUrl,
            termsHash: _config.signatureStore.termsHash,
            numTokens: _config.tokensForAllocation,
            tokenPrice: _config.nftPrice,
            hurdle: 0,
            releaseScheduleStartTimeStamp: 0,
            tokenLockDuration: 0,
            releaseDuration: 0,
            inviteCode: _config.signatureStore.config.inviteCode
        });
        bool isSignatureValid = SignatureUtil.verifySignature(founderDomain, signatureData, _config.signatureStore.config.signature);
        require(isSignatureValid, "NFTAllocator: Invalid signature");

        termsUrl = _config.signatureStore.termsUrl;
        termsHash = _config.signatureStore.termsHash;
        ventureSignature = _config.signatureStore.config.signature;

        DOMAIN_SEPARATOR = SignatureUtil.hashDomain( SignatureUtil.EIP712Domain({
        name : name,
        version : '1',
        chainId : block.chainid,
        verifyingContract : address(this)
        }));

    }

    /**
    * @notice Makes an investment in this allocator
    * @param numTokens The number of tokens to invest
    * @param inviteCode The invite code to access this investment
    * @param merkleProof The proof to verify the invite code `inviteCode` is correct
    *
    * Emits a {Investment} event.
    * May emit a {Claimed} event.
    * May emit a {PendingClaim} event.
    */

  function invest(uint256 numTokens, uint256 minAllowedTokens, uint256 maxAllowedTokens, bytes32 inviteCode, bytes32[] calldata merkleProof, bytes memory signature) external nonReentrant {
        require(tokensForAllocation > investmentsCount, "NftAllocator: Closed, goal reached");
        require(tokensForAllocation >= investmentsCount + numTokens, "NftAllocator: Investment will exceed tokens allocation");
        require(numTokens != 0, "NftAllocator: min 1 token to invest");
        require(MerkleProof.verify(merkleProof, inviteCodesMerkleRoot, keccak256(abi.encode(inviteCode, minAllowedTokens, maxAllowedTokens))), "NftAllocator: Invalid invite code");
        require(invitesAllocation[inviteCode].account == msg.sender || invitesAllocation[inviteCode].account == address(0), "NftAllocator: only one wallet per invite code");
        require(numTokens >= minAllowedTokens || (invitesAllocation[inviteCode].claimed + invitesAllocation[inviteCode].unclaimed) >= minAllowedTokens, "NftAllocator: can not invest less than minimum");
        require(numTokens <= maxAllowedTokens && (invitesAllocation[inviteCode].claimed + invitesAllocation[inviteCode].unclaimed + numTokens) <= maxAllowedTokens, "NftAllocator: can not invest more than maximum");
        require(isOpen, "NftAllocator: Closed");

        invitesAllocation[inviteCode].account = msg.sender;
        totalUnclaimed += numTokens;

        //TODO allow hurdle and schedule for NFTs
        SignatureUtil.SignatureData memory signatureData = SignatureUtil.SignatureData({
            signer: msg.sender,
            termsUrl: termsUrl,
            termsHash: termsHash,
            numTokens: numTokens,
            tokenPrice: nftPrice,
            hurdle: 0,
            releaseScheduleStartTimeStamp: 0,
            tokenLockDuration: 0,
            releaseDuration: 0,
            inviteCode: inviteCode
        });
        bool isSignatureValid = SignatureUtil.verifySignature(DOMAIN_SEPARATOR, signatureData, signature);
        require(isSignatureValid, "NFTAllocator: Invalid signature");

        if (address(nft) != address(0) && nft.balanceOf(address(this)) >= totalUnclaimed && (tokenIdsLength - nextTokenId) >= numTokens) {
            totalUnclaimed -= numTokens;
            invitesAllocation[inviteCode].claimed += uint128(numTokens);
            for (uint256 i; i < numTokens;) {
                nft.safeTransferFrom(address(this), msg.sender, tokenIds[nextTokenId]);
                emit Claimed(msg.sender, tokenIds[nextTokenId]);
                unchecked {
                    i++;
                    nextTokenId++;
                }
            }
        } else {
            pendingClaims[msg.sender] += numTokens;
            invitesAllocation[inviteCode].unclaimed += numTokens;
            emit PendingClaim(msg.sender, ventureFunds, numTokens);
        }

        investmentsCount += numTokens;
        SafeERC20.safeTransferFrom(venture.treasuryToken(), msg.sender, venture.fundsAddress(), ventureFunds * numTokens);
        SafeERC20.safeTransferFrom(venture.treasuryToken(), msg.sender, jubiFundsAddress, jubiFee * numTokens);

        emit Investment(msg.sender, nftPrice * numTokens, numTokens, signature, ventureSignature);
    }

    /**
    * @notice Claims a nft with id `tokenId`
    * @param numToClaim The number of token to be claim by `msg.sender`
    * Emits a {Claimed} event.
    */
    function claim(uint256 numToClaim) external nonReentrant {
        require(address(nft) != address(0), "NftAllocator: No nft token assigned to allocator");
        require(numToClaim != 0, "NftAllocator: min 1 token to claim");
        require(pendingClaims[msg.sender] != 0, "NftAllocator: no active claim");
        require(pendingClaims[msg.sender] >= numToClaim, "NftAllocator: trying to claim more than allowed");
        uint256 contractNftBalance = nft.balanceOf(address(this));
        require(contractNftBalance >= totalUnclaimed, "NftAllocator: Not enough claimable nft");

        totalUnclaimed -= numToClaim;
        pendingClaims[msg.sender] -= numToClaim;

        for (uint256 i; i < numToClaim;) {
            nft.safeTransferFrom(address(this), msg.sender, tokenIds[nextTokenId]);
            emit Claimed(msg.sender, tokenIds[nextTokenId]);

            unchecked {
                i++;
                nextTokenId++;
            }
        }


    }

    /**
    * @notice Closes this allocator, as consequence investments are DISABLED
    */
    function close() external {
        require(venture.isAdminOrAllocatorManager(msg.sender), "NftAllocator: only allocator manager can close allocator");
        isOpen = false;
        emit AllocatorClosed(msg.sender);
    }

    /**
    * @notice Sets the nft to `_nft`. Can only be called once.
    */
    function setNft(IERC721A _nft) external {
        require(venture.isAdminOrAllocatorManager(msg.sender), "NftAllocator: only allocator manager can set nft");
        require(address(nft) == address(0), "NftAllocator: Token is already set");
        require(address(_nft) != address(0), "NftAllocator: Token address invalid");
        nft = _nft;
        emit NFTSet(address(_nft), msg.sender);
    }

    /**
    * @notice Migrates current venture to a new venture manager `_newVenture`
    * @param _newVenture The new venture manager for this allocator
    */
    function migrateVenture(address _newVenture) external {
        require(_newVenture != address(0), "NftAllocator: invalid new venture");
        Venture newVenture = Venture(_newVenture);
        require(newVenture != venture, "NftAllocator: Can not update to same venture");
        require(venture.isAdmin(msg.sender), "NftAllocator: only venture admin can update allocator");
        require(newVenture.isAdmin(msg.sender), "NftAllocator: only venture admin can update allocator");
        address oldVenture = address(venture);
        venture = newVenture;
        emit VentureMigrated(oldVenture, address(newVenture), msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) override external returns (bytes4) {
        require(msg.sender == address(nft), "NftAllocator: Invalid nft received");
        emit NftReceived(tokenId);
        tokenIds[tokenIdsLength] = tokenId;
        unchecked {tokenIdsLength++;}

        return ERC721A__IERC721Receiver.onERC721Received.selector;
    }
}
