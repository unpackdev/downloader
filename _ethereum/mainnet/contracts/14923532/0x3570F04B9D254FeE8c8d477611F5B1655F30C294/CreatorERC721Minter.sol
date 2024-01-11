// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC

/// @title: CreatorERC721Minter
/// @author: unrealaccelerator.io

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./ERC165Checker.sol";

import "./SignatureEvaluator.sol";
import "./Provisioner.sol";
import "./AccessControlAdmin.sol";
import "./ICreatorMintableERC721.sol";
import "./ICreatorMinterERC721.sol";

contract CreatorERC721Minter is
    AccessControlAdmin,
    ReentrancyGuard,
    SignatureEvaluator,
    Provisioner,
    ICreatorMinterERC721
{
    enum MintPhase {
        paused,
        publicMint
    }

    struct Creation {
        uint256 price;
        string cid;
        bytes32 nameHash;
        bytes32 dnaHash;
    }

    error InvalidTokenContract();
    error InvalidAddress();
    error WrongEtherAmount();
    error InvalidSignature();
    error MintPhaseAlreadySet(MintPhase phase);
    error InvalidMintPrice();
    error InsufficentSupply();
    error MintPaused();
    error NoContracts();
    error CIDAlreadyUsed();
    error NameAlreadyUsed();
    error DnaAlreadyUsed();

    event MintPhaseSet(MintPhase phase);
    event Mint(string tokenMetadataCID);

    ICreatorMintableERC721 public tokenContract;

    MintPhase public phase = MintPhase.paused;
    bool public signatureRequired = true;
    bool public supplyLimitRequired; //default to false
    uint256 public supplyLimit;
    mapping(address => uint256) public minterCount;
    mapping(string => bool) public usedCID;
    mapping(bytes32 => bool) public usedName;
    mapping(bytes32 => bool) public usedDna;

    constructor(
        address mintable,
        address signer,
        address administrator,
        address[] memory payees,
        uint256[] memory shares
    )
        SignatureEvaluator(signer)
        Provisioner(payees, shares)
        AccessControlAdmin()
    {
        setTokenContract(mintable);
        if (signer == address(0)) revert InvalidAddress();
        if (administrator == address(0)) revert InvalidAddress();
        AccessControlAdmin._grantRole(DEFAULT_ADMIN_ROLE, administrator);
    }

    /**
     * @dev mint to an account
     */
    function mint(
        address to,
        Creation memory creation_,
        string memory nonce,
        bytes memory signature
    ) external payable callerIsUser onlyActiveSale nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        if (creation_.price != msg.value) revert WrongEtherAmount();
        // make sure the image id is unique
        if (usedCID[creation_.cid]) revert CIDAlreadyUsed();
        usedCID[creation_.cid] = true;
        // make sure the name is unique
        if (usedName[creation_.nameHash]) revert NameAlreadyUsed();
        usedName[creation_.nameHash] = true;
        // make sure the dna is unique
        if (usedDna[creation_.dnaHash]) revert DnaAlreadyUsed();
        usedDna[creation_.dnaHash] = true;
        uint256 amount = 1;
        if (
            supplyLimitRequired &&
            (tokenContract.totalSupply() + amount > supplyLimit)
        ) revert InsufficentSupply();
        if (
            signatureRequired &&
            !SignatureEvaluator._validateSignature(
                abi.encodePacked(
                    _msgSender(),
                    nonce,
                    amount,
                    creation_.price,
                    creation_.cid
                ),
                signature
            )
        ) revert InvalidSignature();
        unchecked {
            minterCount[_msgSender()] += 1; // for claims
        }
        tokenContract.mint(to, creation_.cid);
        emit Mint(creation_.cid);
    }

    /**
     * @dev Admin mint to an account
     */
    function adminMint(address to, string memory tokenMetadataCID)
        external
        onlyAuthorized
    {
        tokenContract.mint(to, tokenMetadataCID);
    }

    /**
     * @dev Set the mintable token contract
     */
    function setTokenContract(address tokenContract_) public onlyAuthorized {
        if (
            !ERC165Checker.supportsInterface(
                tokenContract_,
                type(ICreatorMintableERC721).interfaceId
            )
        ) revert InvalidTokenContract();
        tokenContract = ICreatorMintableERC721(tokenContract_);
    }

    /**
     * @dev Flag to control all minting
     */
    function setMintingPaused() external onlyAuthorized {
        phase = MintPhase.paused;
    }

    /**
     * @dev Flag to control Public minting
     */
    function startPublicMint() external onlyAuthorized {
        if (phase == MintPhase.publicMint) revert MintPhaseAlreadySet(phase);
        phase = MintPhase.publicMint;
        emit MintPhaseSet(phase);
    }

    /**
     * @dev Get the total tokens minted from the mintable contract
     * @notice See {ICreatorMintableERC721-totalMinted}
     */
    function totalMinted() external view returns (uint256) {
        return tokenContract.totalSupply();
    }

    /**
     * @dev Flag to control signature gated minting.
     */
    function setSignatureRequired(bool _signatureRequired)
        external
        onlyAuthorized
    {
        signatureRequired = _signatureRequired;
    }

    /**
     * @dev Flag to control signature gated minting.
     */
    function setSupplyLimit(uint256 _supplyLimit) external onlyAuthorized {
        supplyLimitRequired = true;
        supplyLimit = _supplyLimit;
    }

    /**
     * @dev Set the signer. {See SignatureEvaluator-_setSigner}
     */
    function setSigner(address _signer) external onlyAuthorized {
        SignatureEvaluator._addSigner(_signer);
    }

    /**
     * @dev {See IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlAdmin, IERC165)
        returns (bool)
    {
        return
            AccessControlAdmin.supportsInterface(interfaceId) ||
            type(ICreatorMinterERC721).interfaceId == interfaceId;
    }

    /**
     * @dev Modifier to check that the caller is a user
     */
    modifier callerIsUser() {
        if (tx.origin != _msgSender()) revert NoContracts();
        _;
    }

    /**
     * @dev Modifier to check for active sale
     */
    modifier onlyActiveSale() {
        validateActiveSale();
        _;
    }

    function validateActiveSale() private view {
        if (phase == MintPhase.paused) revert MintPaused();
    }
}
