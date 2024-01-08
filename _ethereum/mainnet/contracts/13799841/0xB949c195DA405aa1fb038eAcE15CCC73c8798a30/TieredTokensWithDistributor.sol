// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MerkleProof.sol";

abstract contract TieredTokensWithDistributor {
    struct TierConfig {
        uint256 minIndexInclusive;
        uint256 index;
        uint256 maxIndexExclusive;
        mapping(address => uint256) allowListNumberMinted;
    }

    bytes32 private _merkleRoot;
    bool public allowListActive;

    uint256 public immutable numberOfTiers;
    mapping(uint256 => TierConfig) private _tiers;

    /**
     * @dev initialize tiered tokens structure with an array of integers
     */
    constructor(uint256[] memory maximumSupplyPerTier) {
        require(maximumSupplyPerTier.length > 0, 'Tiers cannot be empty');

        numberOfTiers = maximumSupplyPerTier.length;

        uint256 tierStartIndex = 0;
        for (uint256 i = 0; i < maximumSupplyPerTier.length; i++) {
            TierConfig storage tier = _tiers[i];
            tier.minIndexInclusive = tierStartIndex;
            tier.index = tierStartIndex;
            tier.maxIndexExclusive = tierStartIndex + maximumSupplyPerTier[i];

            tierStartIndex += maximumSupplyPerTier[i];
        }
    }

    /**
     * @dev emitted when an account has claimed some tokens
     */
    event Claimed(address indexed account, uint256 tierId, uint256 amount);

    /**
     * @dev emitted when the merkle root has changed
     */
    event MerkleRootChanged(bytes32 merkleRoot);

    /**
     * @dev throws when the tier does not exist
     */
    modifier tierExists(uint256 tierId) {
        require(tierId < numberOfTiers, 'Tier does not exist');
        _;
    }

    /**
     * @dev throws when allow list is not active
     */
    modifier isAllowListActive() {
        require(allowListActive, 'Allow list is not active');
        _;
    }

    /**
     * @dev throws when amount to purchase exceeds the capacity
     */
    modifier withinTierLimitForAddress(
        address from,
        uint256 tierId,
        uint256 numberOfTokens,
        uint256 limit
    ) {
        require(
            _tiers[tierId].allowListNumberMinted[from] + numberOfTokens <= limit,
            'Purchase would exceed token limit for address'
        );
        _;
    }

    /**
     * @dev throws when number of tokens exceeds tier supply
     */
    modifier canMintInTier(uint256 tierId, uint256 numberOfTokens) {
        require(
            (_tiers[tierId].index + numberOfTokens) <= _tiers[tierId].maxIndexExclusive,
            'Purchase would exceed maximum supply for tier'
        );
        _;
    }

    /**
     * allow list functions
     */

    /**
     * @dev sets the state of the allow list
     */
    function _setAllowListActive(bool allowListActive_) internal virtual {
        allowListActive = allowListActive_;
    }

    /**
     * @dev sets the merkle root
     */
    function _setAllowList(bytes32 merkleRoot_) internal virtual {
        _merkleRoot = merkleRoot_;

        emit MerkleRootChanged(_merkleRoot);
    }

    /**
     * @dev checks if the claimer has a valid proof
     */
    function onAllowList(address claimer, bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    /**
     * tiered tokens functions
     */

    /**
     * @dev increments the number of tokens in the tier
     */
    function _incrementTokensInTier(uint256 tierId, uint256 numberOfTokens) internal virtual tierExists(tierId) {
        _tiers[tierId].index += numberOfTokens;
    }

    /**
     * @dev returns the current tokens index for the tier
     */
    function _getTokenIndexInTier(uint256 tierId) internal view virtual tierExists(tierId) returns (uint256) {
        return _tiers[tierId].index;
    }

    /**
     * @dev returns the tokens minted for the tier
     */
    function getTotalMintedInTier(uint256 tierId) external view tierExists(tierId) returns (uint256) {
        return _tiers[tierId].index - _tiers[tierId].minIndexInclusive;
    }

    /**
     * @dev returns number of tokens left in the tier
     */
    function getTierSupply(uint256 tierId) external view tierExists(tierId) returns (uint256) {
        return _tiers[tierId].maxIndexExclusive - _tiers[tierId].index;
    }

    /**
     * @dev get total minted (does not take into account burned tokens)
     */
    function totalMinted() external view returns (uint256) {
        uint256 minted = 0;

        for (uint256 tierIndex = 0; tierIndex < numberOfTiers; tierIndex++) {
            minted += _tiers[tierIndex].index - _tiers[tierIndex].minIndexInclusive;
        }

        return minted;
    }

    /**
     * @dev get available to mint in tier
     */
    function numberMintedInTier(uint256 tierId, address from) public view tierExists(tierId) returns (uint256) {
        return _tiers[tierId].allowListNumberMinted[from];
    }


    /**
     * @dev claims a token in a tier
     */
    function _claim(
        address to,
        uint256 tierId,
        uint256 numberOfTokens,
        bytes32[] memory proof
    ) internal virtual tierExists(tierId) {
        require(onAllowList(to, proof), 'Not on allow list');

        _tiers[tierId].allowListNumberMinted[to] += numberOfTokens;

        emit Claimed(to, tierId, numberOfTokens);
    }
}
