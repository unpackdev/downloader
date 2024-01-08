//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC1155MetadataURIUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./ECDSA.sol";

import "./RoyalPausableUpgradeable.sol";

/**
 @dev Implementation of Royal.io LDA using ERC-1155
 See https://eips.ethereum.org/EIPS/eip-1155

 The `ldaID`s used in this contract are synthetic IDs. The first 128 bits are the
 `tierID` and the last 128 bits are the `tokenID`. This effectively means that:
 `ldaID = (tierID << 128) + tokenID`
 */
contract WaveformRoyal1155LDA is
    ERC1155Upgradeable,
    RoyalPausableUpgradeable
{
    event NewTier(uint128 indexed tierID);
    event TierExhausted(uint128 indexed tierID);

    uint256 constant UPPER_ISSUANCE_ID_MASK = uint256(type(uint128).max) << 128;
    uint256 constant LOWER_TOKEN_ID_MASK = uint256(type(uint128).max);

    string _contractMetadataURI;

    // (tierID) => max supply for this tier
    mapping(uint128 => uint256) private _tierMaxSupply;

    // (tierID) => current supply for this tier. NOTE: See also the comment below _ldasForTier.
    mapping(uint128 => uint256) private _tierCurrentSupply;

    // MAPPINGS FOR MAINTAINING ISSUANCE_ID => LIST OF ADDRESSES HOLDING TOKENS (with repeats)
    // NOTE: These structures allow to enumerate the ldaID[] corresponding to a tierID. The 
    //       addresses must then be looked up from _owners.

    /// @notice (ldaID) => owner's address
    mapping(uint256 => address) private _owners;

    /** @notice (`tierID`) => mapping from `ldaIndexForThisTier` [0..n] (where `n` is the # of LDAs 
     *  associated with this `tierID`). to the `ldaID`. This effectively acts as a map to
     *  a list of ldaIDs for a given tierID.
     *
     *  NOTE: The `ldaIndexForThisTier` is the value stored in the _tierCurrentSupply map.
    */ 
    mapping(uint128 => mapping(uint256 => uint256)) private _ldasForTier;

    // (ldaID) => ldaIndexForThisTier this is only required in order to support remove LDAs from _ldasForTier
    mapping(uint256 => uint256) _ldaIndexesForTier;

    // To prevent duplication of state, we will re-use `_tierCurrentSupply` to act as the index. This means 
    // that if we burn any tokens, then we need to decrement this number.

    // 3lau.eth address
    address public constant signer = 0xD2aff66959ee0E6F92EE02D741071DDB5084Bebb;
    
    // keccak256 Hash of the song .wav file
    bytes32 public constant songHash = 0xaca2578eaf14be9eea15219ddc9b8b464667c5fa2fe56609843ca072371fba1b;
    
    // song hash signed by 3lau.eth
    string public constant signedSongHash = "0x4e41cf6ce03f6542cc5985f075d3c93cf00d3cce1aca1c014123c1f73896207162d4a2b475fa0112adf261a8ff3df99d8263e261a3f715d9a3d4a94924bc04b71b";
    
    function verifySignature(bytes memory _signedSongHash) public pure returns (bool){
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(songHash);
        address messageSigner = ECDSA.recover(messageHash, _signedSongHash);
        return messageSigner == signer;
    }
    
    function verifySignatureAddress(bytes memory _signedSongHash) public pure returns (address){
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(songHash);
        address messageSigner = ECDSA.recover(messageHash, _signedSongHash);
        return messageSigner;
    }

    function initialize(string memory tokenMetadataURI, string memory contractMetadataURI) public initializer {
        __Royal1155LDA_init_unchained(tokenMetadataURI, contractMetadataURI);
    }

    function __Royal1155LDA_init_unchained(string memory tokenURI, string memory contractURI_) internal initializer {
        __RoyalPausableUpgradeable_init();
        __ERC1155_init(tokenURI);
        _contractMetadataURI = contractURI_;
    }

    function updateTokenURI(string calldata newURI) public onlyOwner
    {
        _setURI(newURI);
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }

    function updateContractMetadataURI(string memory newURI) public onlyOwner {
        _contractMetadataURI = newURI;
    }

    /// @dev Check if given tier is currently mintable
    function mintable(uint128 tierID) external view returns (bool) {
        return _tierCurrentSupply[tierID] < _tierMaxSupply[tierID] && this.tierExists(tierID);
    }

    /// @dev Has this tier been initialized?
    function tierExists(uint128 tierID) external view returns (bool) {
        // Check that the map has a set value
        return _tierMaxSupply[tierID] != 0;
    }

    /// @dev Has the given LDA been minted?
    function exists(uint256 ldaID) external view returns (bool) {
        return _owners[ldaID] != address(0);
    }

    /// @dev What address owns the given ldaID?
    function ownerOf(uint256 ldaID) external view returns (address) {
        require(_owners[ldaID] != address(0), "LDA DNE");
        return _owners[ldaID];
    }

    /**
     @dev Create an Tier of an LDA. In order for an LDA to be minted, it must 
     belong to a valid Tier that has not yet reached it's max supply. 
     */
    function createTier(uint128 tierID, uint256 maxSupply) external onlyOwner {
        require(!this.tierExists(tierID), "Tier already exists");
        require(tierID != 0 && maxSupply >= 1, "Invalid tier definition");
        require(_tierCurrentSupply[tierID] == 0 && _tierMaxSupply[tierID] == 0, "Tier exists");
        
        _tierMaxSupply[tierID] = maxSupply;

        emit NewTier(tierID);
        // NOTE: Default value of current supply is already set to be 0
    }

    // TODO: Implement a bulkMintLDAsToOwner as an optimization to bulk mint a shopping cart. 
    //       LDAs from different tiers can be minted together. 

    function mintLDAToOwner(address owner, uint256 ldaID, bytes calldata data) public onlyOwner {
        require(_owners[ldaID] == address(0), "LDA already minted");
        (uint128 tierID,) = _decomposeLDA_ID(ldaID);
        
        // NOTE: This check also implicitly checks that the tier exists as mintable()
        //       is a stricter requirement than exists(). 
        require(this.mintable(tierID), "Tier not mintable");
        // NOTE: Should we include a semaphore 
        // require(_tierCurrentSupply[tierID] < _tierMaxSupply[tierID], "Cannot mint anymore of this tier");

        // Update current supply before minting to prevent reentrancy attacks
        _tierCurrentSupply[tierID] += 1;
        _mint(owner, ldaID, 1, data);

        // Emit the big events
        if (_tierCurrentSupply[tierID] == _tierMaxSupply[tierID]) {
            emit TierExhausted(tierID);
        }
    }

    /**
    @dev Decompose a raw ldaID into it's two composite parts
     */
    function _decomposeLDA_ID(
        uint256 ldaID
    ) internal pure virtual returns (uint128 tierID, uint128 tokenID) {
        tierID = uint128(ldaID >> 128);
        tokenID = uint128(ldaID & LOWER_TOKEN_ID_MASK);
        require(tierID != 0 || tokenID != 0, "Invalid ldaID");    // NOTE: TierID and TokenID > 0 
    }

    // HOOK OVERRIDES 
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Iterate over all LDAs being transferred
        for(uint a; a < ids.length; a++) {
            // Decompose out here as an optimization
            (uint128 tierID,) = _decomposeLDA_ID(ids[a]);
            if (from == address(0)) {
                // This is a mint operation
                // Add this LDA to the `to` address state
                _addTokenToTierTracking(to, ids[a], tierID);

            } else if (from != to) {
                // If this is a transfer to a different address.
                _owners[ids[a]] = to;
            }

            if (to == address(0)) {
                // Remove LDA from being associated with its 
                // TODO: Move this to burn transaction state
                _removeLDAFromTierTracking(from, ids[a], tierID);
            }
        }
    }

    // ENUMERABLE helper functions
    function _addTokenToTierTracking(address to, uint256 ldaID, uint128 tierID) private {
        uint256 ldaIndexForThisTier = _tierCurrentSupply[tierID];
        _ldasForTier[tierID][ldaIndexForThisTier] = ldaID;

        // Track where this ldaID is in the "list"
        _ldaIndexesForTier[ldaID] = ldaIndexForThisTier;

        _owners[ldaID] = to;
    }

    /** 
     * @dev This is a cute little trick I pulled from the OZ implementation of {ERC721Enumerable-_removeTokenFromOwnerEnumeration}.
     * See More: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6f23efa97056e643cefceedf86fdf1206b6840fb/contracts/token/ERC721/extensions/ERC721Enumerable.sol#L118
     */
    function _removeLDAFromTierTracking(address from, uint256 ldaID, uint128 tierID) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastLDAIndex = _tierCurrentSupply[tierID] - 1;
        uint256 tokenIndex = _ldaIndexesForTier[ldaID];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastLDAIndex) {
            uint256 lastLDA_ID = _ldasForTier[tierID][lastLDAIndex];

            _ldasForTier[tierID][tokenIndex] = lastLDA_ID; // Move the last LDA to the slot of the to-delete LDA
            _ldaIndexesForTier[lastLDA_ID] = tokenIndex; // Update the moved LDA's index

        }
        // This also deletes the contents at the last position of the array
        delete _ldaIndexesForTier[ldaID];
        delete _ldasForTier[tierID][lastLDAIndex];

        _owners[ldaID] = from;
    }
}