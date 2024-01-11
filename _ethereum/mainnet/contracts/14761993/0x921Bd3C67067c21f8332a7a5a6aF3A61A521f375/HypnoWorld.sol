// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

/**
 * @title HypnoWorld smart contract
 * @author Asimov Collective
 * @custom:security-contact tech@asimovcollective.com
 */
contract HypnoWorld is ERC721A, Pausable, Ownable, ReentrancyGuard {

    /**
     * @dev Minting has 3 Stages:
     *  UNSTARTED: Contract has been deployed, but minting has not begun
     *  LIVE: Minting of assets is live (both whitelist and public paid minting)
     *  FINISHED: Minting is over, forever
     *
     * These stages will advance in the listed order, no stage will be skipped,
     * i.e. the stage will advance exactly one step in a single transaction
     * and once FINISHED is reached, the stage will never change again. See
     * advanceStage()
     *
     */
    enum MintStage { UNSTARTED, LIVE, FINISHED }

    error MaxMintPerBatchExceeded();  // when the quantity of mint is > MAX_MINTS_PER_BATCH
    error InvalidQuantityMint();  // when the quantity of mint is otherwise invalid i.e. 0
    error InvalidFee();  // when the value sent to mint is < MINT_FEE during public mint
    error InvalidMintingStage(MintStage currentContractStage, MintStage requiredStage);  // when the function requires the contract to be in a different stage of minting
    error NoMoreMintStages();  // when the final stage is reached and a request to advance the stage is made
    error InvalidUpdateToFinalizedCollection();  // when collection update is attempted on finalized collection
    error CollectionNotRevealed();  // when collection is not revealed but function requires it
    error IdenticalURI();  // when the new base uri doesnt differ from the existing
    error InvalidProof();  // when an invalid merkle proof is given
    error InvalidWhitelistClaimQuantity();  // when an invalid quantity of tokens are claimed for whitelisted minting
    error MaxWhitelistClaims(address claimer);  // when a whitelist claim is attempted more than once

    /**
     * @dev mapping from address to whether or not whitelist claim has been made
     * from the given address. An address can only ever claim one token through
     * no fee whitelist minting
     */
    mapping(address => bool) public whitelistClaimed;

    /// @dev whether baseURI has been updated, revealing the collection metadata
    bool public collectionRevealed;

    uint8 constant MAX_MINTS_PER_BATCH = 5;
    uint64 constant MINT_FEE = .05 ether;

    address private immutable treasury;

    string private _baseURIData = "ipfs://QmX8YGs6VFPUidmS3s8GT9FT9F9Aq7TNX4MpMGP8hzEPcE";
    MintStage private _mintStage;

    bytes32 private _whitelistRootHash;

    bool private _collectionFinalized;

    /**
     * @dev Emitted when the collection base URI is updated. Collection will be
     * updated after the IRL event takes place and media is recorded on IPFS
     */
    event CollectionRevealed(string _baseTokenURI);

    /**
     * @dev Emitted when the collection is finalized, meaning the base URI can
     * can no longer be updated
     */
    event CollectionFinalized();

    /**
     * @dev Emitted when the whitelist is updated
     */
    event WhitelistUpdated(bytes32 newWhitelistRootHash);

    /**
     * @dev Emitted when the contract minting stage advances
     */
    event MintStageAdvanced(MintStage newStage);

    /**
     * @dev Modifier that checks that contract is live for minting
     */
    modifier whenMintStage(MintStage stage) {
        _checkStage(stage);
        _;
    }

    constructor(
        address _treasury
    )
        ERC721A("HypnoWorld", "IRL")
    {
        treasury = _treasury;
        _mintStage = MintStage.UNSTARTED;
        _collectionFinalized = false;
        collectionRevealed = false;
    }

    /**
     * Mint a single token, one time, if sender is on the whitelist and minting
     * is LIVE
     * @dev Please generate proof in real time as needed using the publically
     * available whitelist hosted at https://world.hypno.com
     * @param _merkleProof A valid hex encoded proof validating caller is on the whitelist
     *
     * Requirements:
     *
     * - The caller must on the whitelist
     * - Minting must be live i.e. mintStage == MintStage.LIVE
     */
    function whitelistMint(bytes32[] calldata _merkleProof) external nonReentrant whenNotPaused whenMintStage(MintStage.LIVE) {
        // Whitelist can only mint once
        if (whitelistClaimed[_msgSender()]) revert MaxWhitelistClaims(_msgSender());
        // Check sender is on whitelist via provided proof
        if (!checkWhitelistValidity(_merkleProof, _msgSender())) revert InvalidProof();
        // If private whitelist mint, update claim data
        whitelistClaimed[_msgSender()] = true;
        // Mint one token for whitelist claim
        _safeMint(_msgSender(), 1);
    }

    /**
     * Mint `quantity` tokens when minting is LIVE with `MINT_FEE * quantity`
     * ETH required as payment
     * @param quantity Number of tokens to mint - must be <= 5
     *
     * Requirements:
     *
     * - The caller must include `MINT_FEE * quantity` ETH in value
     * - Minting must be live i.e. mintStage == MintStage.LIVE
     */
    function mint(uint256 quantity) external payable nonReentrant whenNotPaused whenMintStage(MintStage.LIVE) {
        uint256 feeAmount = quantity * MINT_FEE;
        if(quantity > MAX_MINTS_PER_BATCH) revert MaxMintPerBatchExceeded();
        if(quantity == 0) revert InvalidQuantityMint();
        if(msg.value != feeAmount) revert InvalidFee();

        _safeTransferETH(treasury, feeAmount);
        _safeMint(_msgSender(), quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();

        if (!collectionRevealed) return baseURI_;
        return string(abi.encodePacked(baseURI_, Strings.toString(tokenId)));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIData;
    }

    /**
     * Internal function used to transfer ETH
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "Unable to Transfer ETH, Recipient May Have Reverted");
        return success;
    }

    /**
     * Pause all operations on contract that could change state
     *
     * Requirements:
     *
     * - The caller must the contract owner
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * Unpause all operations on contract that could change state
     *
     * Requirements:
     *
     * - The caller must the contract owner
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal whenNotPaused override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @dev Custom mint stage & baseURI update logic below

    /**
     * Check that contract mint stage is at the specified target stage
     * @param targetStage MintStage that contract should be in
     */
    function _checkStage(MintStage targetStage) internal view {
        if (mintStage() != targetStage) {
            revert InvalidMintingStage(mintStage(), targetStage);
        }
    }

    /**
     * Getter function for contract MintStage
     * @return MintStage value contract is currently set to
     */
    function mintStage() public view returns (MintStage) {
        return _mintStage;
    }

    /**
     * Advances the stage of the contract to the next. Always advances only
     * one stage, from UNSTARTED to LIVE, and from LIVE to FINISHED. Reverts
     * if stage is already at FINISHED
     *
     * Requirements:
     *
     * - The caller must the contract owner
     * - Minting cannot be finished i.e. mintStage != MintStage.FINISHED
     */
    function advanceStage(MintStage intendedNewStage) external onlyOwner whenNotPaused {
        if (mintStage() == MintStage.FINISHED) {
            revert NoMoreMintStages();
        }
        else if (mintStage() == MintStage.UNSTARTED) {
            require(intendedNewStage == MintStage.LIVE, "Incorrect New Stage. Function May Have Been Called More Than Once");
            _mintStage = MintStage.LIVE;
            emit MintStageAdvanced(_mintStage);
        } else if (mintStage() == MintStage.LIVE) {
            require(intendedNewStage == MintStage.FINISHED, "Incorrect New Stage. Function May Have Been Called More Than Once");
            _mintStage = MintStage.FINISHED;
            emit MintStageAdvanced(_mintStage);
        } else {
            revert('Invalid MintState');
        }
    }

    /**
     * Checks that account is on the whitelist by using the given Merkle Tree
     * Proof encapsulating all hashes between the account address and the tree
     * root node.
     * @dev See @openzeppelin/contract/utils/cryptography/MerkleTree for
     * more information, and see merkletreejs for tooling and information on
     * generating Merkle Trees and proofs
     * @param _merkleProof Proving address is a part of the whitelist consisting
     * of all hashes between the given account address leaf node and the root
     * packed as a bytes32 array
     * @param account Address to check for membership on whitelist
     * @return bool true iff proof is valid and account is on the whitelist
     */
    function checkWhitelistValidity(bytes32[] memory _merkleProof, address account) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(_merkleProof, _whitelistRootHash, leaf);
    }

    /**
     * Update whitelist rootHash
     * @param _newWhitelistRootHash the new root hash of the Merkle tree generated
     * from the whitelist
     *
     * Requirements:
     *
     * - The caller must the contract owner
     */
    function updateWhitelistRoot(bytes32 _newWhitelistRootHash) external onlyOwner whenNotPaused {
        if (_newWhitelistRootHash != _whitelistRootHash) {
            _whitelistRootHash = _newWhitelistRootHash;
            emit WhitelistUpdated(_newWhitelistRootHash);
        }
    }

    /**
     * Getter for the finalization status of the collection. Once finalized
     * the baseURI for the token metadata cannot be updated ever again
     * @return bool True iff collection is finalized permanently
     */
    function collectionFinalized() public view returns (bool) {
        return _collectionFinalized;
    }

    /**
     * Finalize the collection locking the baseURI for all token metadata
     * permanently
     * @dev can only be called when minting is permanently over ensuring that
     * metadata will not be locked in if new tokens can still be created
     *
     * Requirements:
     *
     * - The caller must the contract owner
     * - Minting must be finished i.e. mintStage == MintStage.FINISHED
     */
    function finalizeCollection() public onlyOwner whenMintStage(MintStage.FINISHED) whenNotPaused {
        if (!collectionRevealed) {
            revert CollectionNotRevealed();
        }
        _collectionFinalized = true;
        emit CollectionFinalized();
    }

    /**
     * Update the baseURI of the contract to the given value
     * @dev the baseURI is the common root to tall token URIs
     * @param newBaseURI the new value for the root or base URI of all token IDs
     *
     * Requirements:
     *
     * - The caller must the contract owner
     * - Minting must be finished i.e. mintStage == MintStage.FINISHED
     */
    function updateBaseURI(string memory newBaseURI) public onlyOwner whenMintStage(MintStage.FINISHED) whenNotPaused {
        if (collectionFinalized()) {
            revert InvalidUpdateToFinalizedCollection();
        } else if (keccak256(abi.encodePacked(_baseURI())) == keccak256(abi.encodePacked(newBaseURI))) {
            revert IdenticalURI();
        }
        if (!collectionRevealed) collectionRevealed = true;
        _baseURIData = newBaseURI;
        emit CollectionRevealed(newBaseURI);
    }

    /// @dev custom ERC721 extensions because base is 721A

    // ERC721 Burnable

    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);  // 721A takes approval check parameter which should be true for publically accessible burn fn
    }


    /**
     * @dev Withdraws ETH from Contract to `recipient` with an amount
     * `amount` is denoted in WEI
     *
     * Requirements
     *
     * - The caller must be contract owner
     */
    function withdrawAmountToAddress(address payable recipient, uint amount) external onlyOwner {
        require(amount > 0 && amount <= address(this).balance, "Invalid Amount");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "unable to withdraw, recipient may have reverted");
    }

    /**
     * @dev Withdraws ERC20 from contract to address
     *
     */
    function withdrawERC20ToAddress(address recipient, address contractAddress) external onlyOwner {
        IERC20 ERC20 = IERC20(contractAddress);
        ERC20.transferFrom(address(this), recipient, ERC20.balanceOf(address(this)));
    }

}
