//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ContextUpgradeable.sol";

import "./console.sol";

import "./Common.sol";
import "./Treasury.sol";

contract Submissions is Initializable, ContextUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, Common {
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    enum SubmissionStatus {Pending, Approved, Funded}

    struct Submission {
        address author; // Who must be rewarded for the submission
        uint256 addedValue; // How much value does this submission brings (in "wei")
        uint256 reward; // How many UNQ erc-20 tokens to reward for author
        uint256 metadataVersion; // Version of metadata of the submission
        uint256 tokenId; // Which Uniquette is this submission targeted to upgrade (it is 0 for new Uniquette submissions)
        uint256 parentHash; // Hash of parent when submission is an upgrade for an existing one
        uint256 deposit; // How much author have deposited as submission deposit (to prevent spam)
        SubmissionStatus status;
    }

    event SubmissionCreated(
        address indexed submitter,
        uint256 indexed tokenId,
        string hash,
        uint256 addedValue,
        uint256 deposit
    );
    event SubmissionUpdated(address indexed submitter, string hash, uint256 addedValue);
    event SubmissionApproved(
        address approver,
        address indexed author,
        string hash,
        uint256 reward
    );
    event SubmissionRejected(address approver, address indexed author, string hash);

    Treasury private _treasury;

    mapping(string => Submission) internal _submissions;

    function __Submissions_init(
        address payable treasury
    ) internal initializer {
        __Submissions_init_unchained(treasury);
    }

    function __Submissions_init_unchained(
        address payable treasury
    ) internal initializer {
        _treasury = Treasury(treasury);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNOR_ROLE, _msgSender());
    }

    //
    // Modifiers
    //
    modifier submissionExists(string calldata hash) {
        require(_submissions[hash].author != address(0), "SUBMISSIONS/DOES_NOT_EXIST");
        _;
    }

    modifier submissionIsPending(string calldata hash) {
        require(_submissions[hash].status == SubmissionStatus.Pending, "SUBMISSIONS/NOT_PENDING");
        _;
    }

    modifier submissionIsApproved(string calldata hash) {
        require(_submissions[hash].status == SubmissionStatus.Approved, "SUBMISSIONS/NOT_APPROVED");
        _;
    }

    modifier submissionIsUpToDate(string calldata hash) {
        require(_submissions[hash].metadataVersion >= _minMetadataVersion, "SUBMISSIONS/OUTDATED_METADATA_VERSION");
        _;
    }

    //
    // Generic and standard functions
    //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //
    // Admin functions
    //
    function setTreasuryAddress(address payable newAddress) public virtual isGovernor() {
        _treasury = Treasury(newAddress);
    }

    //
    // Submissions Logic
    //
    function submissionGetByHash(string calldata hash)
        public
        view
        virtual
        submissionExists(hash)
        returns (Submission memory)
    {
        return _submissions[hash];
    }

    function submissionCreate(
        uint256 tokenId,
        string calldata hash,
        uint256 metadataVersion,
        uint256 addedValue
    ) public payable {
        require(_submissions[hash].author == address(0), "SUBMISSIONS/ALREADY_CREATED");
        require(msg.value == _submissionDeposit, "SUBMISSIONS/EXACT_DEPOSIT_REQUIRED");
        require(metadataVersion >= _minMetadataVersion, "SUBMISSIONS/UNSUPPORTED_METADATA_VERSION");

        _submissions[hash].author = _msgSender();
        _submissions[hash].tokenId = tokenId;
        _submissions[hash].metadataVersion = metadataVersion;
        _submissions[hash].addedValue = addedValue;
        //_submissions[hash].reward = calculateReward(addedValue); TODO To be done via price oracles
        _submissions[hash].deposit = msg.value;
        _submissions[hash].status = SubmissionStatus.Pending;

        emit SubmissionCreated(_msgSender(), tokenId, hash, addedValue, msg.value);
    }

    function submissionUpdate(string calldata hash, uint256 tokenId, uint256 addedValue)
        public
        submissionExists(hash)
        submissionIsPending(hash)
        submissionIsUpToDate(hash)
        nonReentrant
    {
        require(
            _submissions[hash].author == _msgSender() || hasRole(GOVERNOR_ROLE, _msgSender()),
            "SUBMISSIONS/NOT_AUTHOR_OR_GOVERNOR"
        );
        _submissions[hash].tokenId = tokenId;
        _submissions[hash].addedValue = addedValue;

        emit SubmissionUpdated(_msgSender(), hash, addedValue);
    }

    function submissionCreateBulk(
        string[] calldata hashes,
        uint256[] calldata metadataVersions,
        uint256[] calldata tokenIds,
        uint256[] calldata addedValues
    ) public payable nonReentrant {
        require(
            hashes.length == metadataVersions.length,
            "Submissions: number of hashes do not match metadataVersions"
        );
        require(hashes.length == tokenIds.length, "Submissions: number of hashes do not match tokenIds");
        require(hashes.length == addedValues.length, "Submissions: number of hashes do not match values");

        for (uint256 i = 0; i < hashes.length; ++i) {
            this.submissionCreate(tokenIds[i], hashes[i], metadataVersions[i], addedValues[i]);
        }
    }

    function _afterSubmissionApprove(string memory hash) internal virtual {}

    function _approveSubmission(
        string calldata hash,
        uint256 rewardOverride
    ) internal virtual submissionExists(hash) submissionIsPending(hash) submissionIsUpToDate(hash) {
        _submissions[hash].reward = rewardOverride;
        _submissions[hash].status = SubmissionStatus.Approved;

        _afterSubmissionApprove(hash);

        emit SubmissionApproved(_msgSender(), _submissions[hash].author, hash, rewardOverride);
    }

    function submissionApprove(
        string calldata hash,
        uint256 rewardOverride
    ) public isGovernor() nonReentrant {
        _approveSubmission(hash, rewardOverride);
    }

    function submissionApproveBulk(
        string[] calldata hashes,
        uint256[] calldata rewards
    ) public isGovernor() nonReentrant {
        require(hashes.length == rewards.length, "Submissions: number of hashes do not match rewards");

        for (uint256 i = 0; i < hashes.length; ++i) {
            _approveSubmission(hashes[i], rewards[i]);
        }
    }

    function submissionReject(string calldata hash)
        public
        isGovernor()
        submissionExists(hash)
        submissionIsPending(hash)
        nonReentrant
    {
        address originalSubmitter = _submissions[hash].author;
        uint256 submissionDeposit = _submissions[hash].deposit;
        delete _submissions[hash];

        // Seize the submit deposit to treasury
        if (submissionDeposit > 0) {
            payable(address(_treasury)).sendValue(submissionDeposit);
        }

        emit SubmissionRejected(_msgSender(), originalSubmitter, hash);
    }

    function _markSubmissionAsFunded(string calldata hash) submissionExists(hash) submissionIsApproved(hash) internal virtual {
        _submissions[hash].status = SubmissionStatus.Funded;
    }
}
