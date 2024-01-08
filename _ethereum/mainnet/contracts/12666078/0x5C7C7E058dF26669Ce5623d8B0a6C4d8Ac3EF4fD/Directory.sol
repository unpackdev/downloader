//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ContextUpgradeable.sol";

import "./console.sol";

import "./Submissions.sol";
import "./Uniquettes.sol";

contract Directory is ContextUpgradeable, Common, Submissions, Uniquettes {
    event SubmissionFunded(
        address indexed operator,
        address indexed collector,
        uint256 indexed tokenId,
        string submissionHash,
        uint256 appreciatedPrice,
        uint256 payment
    );

    mapping(uint256 => string) internal _fundedSubmissionHashByUniquetteTokenId;

    Token private _token;
    Vault private _vault;
    string private _tokensBaseURI;

    function initialize(
        string memory name,
        string memory symbol,
        string memory tokensBaseURI,
        address token,
        address payable vault,
        address payable treasury,
        address payable marketer,
        uint256 protocolFee,
        uint256 minMetadataVersion,
        uint256 currentMetadataVersion,
        uint256 maxPriceAppreciation,
        uint256 submissionDeposit
    ) public initializer {
        __Common_init_unchained(
            protocolFee,
            minMetadataVersion,
            currentMetadataVersion,
            maxPriceAppreciation,
            submissionDeposit
        );
        __Uniquettes_init_unchained(name, symbol, token, vault, treasury, marketer);
        __Submissions_init_unchained(treasury);

        _token = Token(token);
        _vault = Vault(vault);
        _tokensBaseURI = tokensBaseURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNOR_ROLE, _msgSender());
    }

    //
    // Overrides
    //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, Submissions, Uniquettes)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //
    // Customized ERC-721 functions
    //
    function tokenURI(uint256 tokenId) public view virtual override tokenExists(tokenId) returns (string memory) {
        return string(abi.encodePacked(_tokensBaseURI, _fundedSubmissionHashByUniquetteTokenId[tokenId]));
    }

    function setTreasuryAddress(address payable newAddress) public override(Uniquettes, Submissions) isGovernor() {
        Uniquettes.setTreasuryAddress(newAddress);
        Submissions.setTreasuryAddress(newAddress);
    }

    //
    // Unique Directory functions
    //
    function uniquetteGetFundedSubmission(uint256 tokenId) public view virtual returns (string memory) {
        return _fundedSubmissionHashByUniquetteTokenId[tokenId];
    }

    // We must mint a new ERC-721 token for approved submission for a new Uniquette
    function _afterSubmissionApprove(string memory hash) internal virtual override(Submissions) {
        if (_submissions[hash].tokenId > 0) {
            // Skip if there is already a Uniquette for this submission.
            return;
        }

        require(_submissions[hash].status == SubmissionStatus.Approved, "DIRECTORY/SUBMISSION_NOT_APPROVED");

        // Mint the new uniquette into Vault
        uint256 newTokenId = uniquetteMint();

        // Update submission with the new token ID
        _submissions[hash].tokenId = newTokenId;
    }

    function submissionFund(
        address to,
        uint256 tokenId,
        string calldata submissionHash
    )
        public
        payable
        virtual
        tokenExists(tokenId)
        submissionExists(submissionHash)
        submissionIsApproved(submissionHash)
        submissionIsUpToDate(submissionHash)
        nonReentrant
    {
        Submission memory submission = submissionGetByHash(submissionHash);

        {
            require(submission.tokenId == tokenId, "DIRECTORY/INVALID_SUBMISSION_FOR_UNIQUETTE");
            _fundedSubmissionHashByUniquetteTokenId[tokenId] = submissionHash;
            _markSubmissionAsFunded(submissionHash);
        }

        {
            uint256 appreciatedPrice;
            (, appreciatedPrice, , ) = uniquetteTakeOver(_msgSender(), to, tokenId, submission.addedValue);

            _token.mint(submission.author, submission.reward);
            emit SubmissionFunded(_msgSender(), to, tokenId, submissionHash, appreciatedPrice, msg.value);
        }
    }

    function uniquetteCollect(address to, uint256 tokenId) public payable virtual tokenExists(tokenId) nonReentrant {
        require(
            bytes(_fundedSubmissionHashByUniquetteTokenId[tokenId]).length > 0,
            "DIRECTORY/NO_SUBMISSION_FUNDED_FOR_UNIQUETTE"
        );

        uniquetteTakeOver(_msgSender(), to, tokenId, 0);
    }
}
