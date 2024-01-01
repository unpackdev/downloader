// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./IFeeStructure.sol";

/*
        
 ________      _______       _______       ________      ________      
|\   ____\    |\  ___ \     |\  ___ \     |\   ____\    |\   ____\     
\ \  \___|    \ \   __/|    \ \   __/|    \ \  \___|    \ \  \___|_    
 \ \  \  ___   \ \  \_|/__   \ \  \_|/__   \ \  \  ___   \ \_____  \   
  \ \  \|\  \   \ \  \_|\ \   \ \  \_|\ \   \ \  \|\  \   \|____|\  \  
   \ \_______\   \ \_______\   \ \_______\   \ \_______\    ____\_\  \ 
    \|_______|    \|_______|    \|_______|    \|_______|   |\_________\
                                                           \|_________|
                                                                       
                                    
*/

/// @title GEEGS
/// @author rektt (https://twitter.com/aceplxx)

contract Geegs is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721Upgradeable,
    EIP712Upgradeable
{
    using AddressUpgradeable for address payable;
    using ECDSAUpgradeable for bytes32;
    /* ========== STORAGE ========== */

    /// @notice STATUS
    //  0 = created
    //  1 = accepted
    //  2 = pending release
    //  3 = completed
    //  4 = dispute
    //  5 = resolved
    //  6 = burned
    //  7 = incomplete //pending

    enum STATUS {
        CREATED,
        ACCEPTED,
        COMPLETED,
        DISPUTE,
        RESOLVED,
        BURNED
    }

    enum MINT {
        WHITELIST,
        EARLYACCESS,
        PUBLIC
    }

    struct Document {
        address talent;
        address hirer;
        uint256 wage;
        STATUS status;
        uint256 disputedAt;
        uint256 platformFee;
    }

    struct ExperienceBadge {
        bytes32 jobTitle;
        bytes32 hirer;
        bool verified;
    }

    /// @notice RESOLVER
    //  payableA = talent
    //  payableB = hirer

    struct Resolver {
        uint256 id;
        uint256 payableA;
        uint256 payableB;
        bytes signatureA;
        bytes signatureB;
    }

    string public baseURI;
    address public feeWallet;
    uint256 public gracePeriod;
    uint256 public whitelistPrice;
    uint256 public eaPrice;
    uint256 public publicPrice;
    bool public paused;
    bool public restrictedOperator;

    bytes32 public whitelistRoot;
    bytes32 public eaRoot;

    IFeeStructure public feeStructure;

    mapping(uint256 => uint256) public transferAllowance;
    mapping(uint256 => Document) public documents;
    mapping(uint256 => ExperienceBadge) public exps;
    mapping(bytes => bool) public usedSignature;
    mapping(address => bool) public operators;
    mapping(uint256 => bool) public sbt;

    uint256 public nextTokenId;

    // Domain
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    // Structs
    bytes32 private constant ACCEPT_DOCUMENT_TYPEHASH =
        keccak256(
            "AcceptDocument(address talent,address hirer,uint256 docId,uint256 wage)"
        );

    bytes32 private constant DISPUTE_TYPEHASH =
        keccak256("RaiseDispute(address delegator,uint256 id)");

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        string memory baseURI_,
        address _feeStructure
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init("Employment Contract", "GEEGS");
        __EIP712_init("Employment Contract", "1.0");

        baseURI = baseURI_;
        feeStructure = IFeeStructure(_feeStructure);
    }

    /* ========== MODIFIERS ========== */

    modifier mintCompliance(uint256 wage) {
        require(wage > 0, "Bad mints");
        _;
    }

    modifier notPaused() {
        require(!paused, "marketplace halted!");
        _;
    }

    modifier transferrable(uint256 tokenId) {
        if (sbt[tokenId]) require(transferAllowance[tokenId] > 0, "Soul bound");
        _;
    }

    /* ========== EVENTS ========== */
    event TecCreated(uint256 indexed jobId, uint256 offChainId, uint256 amount);
    event Accepted(uint256 indexed jobId, uint256 amount);
    event PendingRelease(uint256 indexed id);
    event Completed(uint256 indexed id, uint256 indexed paidWage);
    event Dispute(uint256 indexed id, address indexed raiser);
    event Resolved(
        uint256 indexed id,
        uint256 indexed payableA,
        uint256 indexed payableB
    );

    event PastMint(uint256 indexed jobId, uint256 offChainId);
    event PastVerified(uint256 indexed jobId);

    /* ========== ERRORS ========== */
    error Unauthorized();
    error InvalidSignature();
    error NoSignature();
    error BadStatus();
    error Insufficient();

    /* ========== OWNER FUNCTIONS ========== */

    function setFeeWallet(address wallet) external onlyOwner {
        feeWallet = wallet;
    }

    function setFeeStructure(address _feeStructure) external onlyOwner {
        feeStructure = IFeeStructure(_feeStructure);
    }

    function setGracePeriod(uint256 daysNo) external onlyOwner {
        gracePeriod = daysNo * 1 days;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function setPrice(
        uint256 whitelist_,
        uint256 ea_,
        uint256 public_
    ) external onlyOwner {
        whitelistPrice = whitelist_;
        eaPrice = ea_;
        publicPrice = public_;
    }

    function setRoot(bytes32 whitelist_, bytes32 ea_) external onlyOwner {
        whitelistRoot = whitelist_;
        eaRoot = ea_;
    }

    function setOperator(
        address[] calldata _operators,
        bool status
    ) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++) {
            operators[_operators[i]] = status;
        }
    }

    function toggleOperator() external onlyOwner {
        restrictedOperator = !restrictedOperator;
    }

    /* ========== PUBLIC MUTATIVE FUNCTIONS ========== */

    /// @notice public mint function
    /// @param doc document struct
    /// pending: mark completion with grace period
    /// instant refund of wages and platform fees upon cancellation of the TECs, tecs can only be cancelled before another party signing
    function createDocument(
        Document calldata doc,
        uint256 offChainId
    ) external payable mintCompliance(doc.wage) notPaused {
        if (doc.status != STATUS.CREATED) revert BadStatus();
        uint256 feeBasis;
        unchecked {
            (uint256 fees, uint256 basis) = feeStructure.calculateFee(
                doc.wage,
                doc.platformFee
            );
            feeBasis = basis;
            if (msg.value < doc.wage) revert Insufficient();
        }
        uint256 _next = nextTokenId;
        documents[_next] = doc;
        documents[_next].platformFee = feeBasis;
        nextTokenId++;
        _mint(msg.sender, _next);
        approve(doc.talent, _next);
        emit TecCreated(_next, offChainId, doc.wage);
    }

    function mintPastExperience(
        bytes32 jobTitle_,
        bytes32 hirer_,
        bytes32[] calldata merkleProof_,
        bool requestToVerify_,
        uint256 offChainId,
        MINT type_
    ) external payable notPaused {
        if (requestToVerify_) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (
                type_ == MINT.WHITELIST &&
                !(MerkleProofUpgradeable.verify(
                    merkleProof_,
                    whitelistRoot,
                    leaf
                ) && msg.value == whitelistPrice)
            ) {
                revert Unauthorized();
            }
            if (
                type_ == MINT.EARLYACCESS &&
                !(MerkleProofUpgradeable.verify(merkleProof_, eaRoot, leaf) &&
                    msg.value == eaPrice)
            ) {
                revert Unauthorized();
            }
            if (type_ == MINT.PUBLIC && msg.value != publicPrice) {
                revert Unauthorized();
            }
            (bool success, bytes memory data) = payable(feeWallet).call{
                value: msg.value
            }("");
            if (!success)
                assembly {
                    revert(add(0x20, data), mload(data))
                }
        }

        exps[nextTokenId] = ExperienceBadge(jobTitle_, hirer_, false);
        _mint(msg.sender, nextTokenId);
        emit PastMint(nextTokenId, offChainId);
        nextTokenId++;
    }

    function verifyPastExperience(
        uint256 tokenId
    ) external notPaused onlyOwner {
        ExperienceBadge storage badge = exps[tokenId];
        if (badge.verified) revert BadStatus();
        badge.verified = true;
        emit PastVerified(tokenId);
    }

    function burn(uint256 jobId) external {
        Document storage doc = documents[jobId];
        if (msg.sender != doc.hirer) revert Unauthorized();
        if (doc.status > STATUS.CREATED) revert BadStatus();
        doc.status = STATUS.BURNED;
        _burn(jobId);

        (bool success, bytes memory data) = payable(msg.sender).call{
            value: doc.wage
        }("");
        if (!success)
            assembly {
                revert(add(0x20, data), mload(data))
            }
    }

    /// @notice public acceptance function
    /// @param jobId document id
    /// @param signature ECDSA signature for doc acceptance
    function acceptDocument(uint256 jobId, bytes memory signature) external {
        Document storage doc = documents[jobId];
        if (restrictedOperator)
            require(
                operators[msg.sender] || msg.sender == doc.talent,
                "Unauthorized"
            );
        if (usedSignature[signature]) revert InvalidSignature();
        usedSignature[signature] = true;

        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ACCEPT_DOCUMENT_TYPEHASH,
                    doc.talent,
                    doc.hirer,
                    jobId,
                    doc.wage
                )
            )
        ).recover(signature);
        require(signer == doc.talent, "Invalid signature");
        doc.status = STATUS.ACCEPTED;

        transferFrom(doc.hirer, doc.talent, jobId);
        sbt[jobId] = true;

        unchecked {
            (uint256 fees, uint256 basis) = feeStructure.calculateFee(
                doc.wage,
                doc.platformFee
            );
            (bool success, bytes memory data) = payable(feeWallet).call{
                value: fees
            }("");
            if (!success)
                assembly {
                    revert(add(0x20, data), mload(data))
                }
        }

        emit Accepted(jobId, doc.wage);
    }

    function markComplete(uint256 id, STATUS status) external {
        Document storage doc = documents[id];
        uint256 payout;
        unchecked {
            (uint256 fees, uint256 basis) = feeStructure.calculateFee(
                doc.wage,
                doc.platformFee
            );
            payout = doc.wage - fees;
        }
        if (doc.status >= STATUS.COMPLETED) revert BadStatus();
        if (msg.sender != doc.hirer) revert Unauthorized();
        doc.status = STATUS.COMPLETED;
        payable(doc.talent).sendValue(payout);
        emit Completed(id, doc.wage);
    }

    function dispute(uint256 id) external {
        Document storage doc = documents[id];
        if (doc.status >= STATUS.COMPLETED) revert BadStatus();
        if (msg.sender != doc.talent && msg.sender != doc.hirer)
            revert Unauthorized();
        doc.status = STATUS.DISPUTE;
        doc.disputedAt = block.timestamp;
        emit Dispute(id, msg.sender);
    }

    function resolveDispute(Resolver calldata resolver) external {
        Document storage doc = documents[resolver.id];
        bytes memory signatureA = resolver.signatureA;
        bytes memory signatureB = resolver.signatureB;
        if (doc.status < STATUS.DISPUTE || doc.status > STATUS.DISPUTE)
            revert BadStatus();
        _checkAndMark([signatureA, signatureB]);
        _validateParties(
            [signatureA, signatureB],
            [doc.talent, doc.hirer],
            resolver.id
        );
        doc.status = STATUS.RESOLVED;
        _resolve(resolver, [doc.talent, doc.hirer], doc.wage);
    }

    function resolveProlongedDispute(Resolver calldata resolver) external {
        Document storage doc = documents[resolver.id];
        if (doc.status < STATUS.DISPUTE || doc.status > STATUS.DISPUTE)
            revert BadStatus();
        if (doc.disputedAt + gracePeriod > block.timestamp)
            revert Unauthorized();
        bytes memory signature;
        if (resolver.signatureA.length != 0) {
            signature = resolver.signatureA;
        } else if (resolver.signatureB.length != 0) {
            signature = resolver.signatureB;
        } else revert NoSignature();

        if (usedSignature[signature]) revert InvalidSignature();
        usedSignature[signature] = true;

        address signer = _hashTypedDataV4(
            keccak256(abi.encode(DISPUTE_TYPEHASH, msg.sender, resolver.id))
        ).recover(signature);

        if (signer != doc.talent && signer != doc.hirer)
            revert InvalidSignature();
        doc.status = STATUS.RESOLVED;
        _resolve(resolver, [doc.talent, doc.hirer], doc.wage);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _validateParties(
        bytes[2] memory signatures,
        address[2] memory parties,
        uint256 docId
    ) internal view {
        address signerA = _hashTypedDataV4(
            keccak256(abi.encode(DISPUTE_TYPEHASH, msg.sender, docId))
        ).recover(signatures[0]);
        address signerB = _hashTypedDataV4(
            keccak256(abi.encode(DISPUTE_TYPEHASH, msg.sender, docId))
        ).recover(signatures[1]);

        if (signerA != parties[0] || signerB != parties[1])
            revert InvalidSignature();
    }

    function _checkAndMark(bytes[2] memory signatures) internal {
        if (usedSignature[signatures[0]] || !usedSignature[signatures[1]])
            revert InvalidSignature();
        usedSignature[signatures[0]] = true;
        usedSignature[signatures[1]] = true;
    }

    function _resolve(
        Resolver calldata resolver,
        address[2] memory parties,
        uint256 wage
    ) internal {
        uint256 fees = feeStructure.calculateDisputeFee(wage);
        require(
            fees + resolver.payableA + resolver.payableB == wage,
            "Invalid amount"
        );
        if (resolver.payableA > 0) {
            (bool success, bytes memory data) = payable(parties[0]).call{
                value: resolver.payableA
            }("");
            if (!success)
                assembly {
                    revert(add(0x20, data), mload(data))
                }
        }
        if (resolver.payableB > 0) {
            (bool success, bytes memory data) = payable(parties[1]).call{
                value: resolver.payableB
            }("");
            if (!success)
                assembly {
                    revert(add(0x20, data), mload(data))
                }
        }
        (bool success, bytes memory data) = payable(msg.sender).call{
            value: fees
        }("");
        if (!success)
            assembly {
                revert(add(0x20, data), mload(data))
            }

        emit Resolved(resolver.id, resolver.payableA, resolver.payableB);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Internal function to get the chain ID (needed for EIP-712)
    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /* ========== OVERRIDE FUNCTIONS ========== */

    function approve(
        address operator,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) transferrable(tokenId) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) transferrable(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Upgradeable) transferrable(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
