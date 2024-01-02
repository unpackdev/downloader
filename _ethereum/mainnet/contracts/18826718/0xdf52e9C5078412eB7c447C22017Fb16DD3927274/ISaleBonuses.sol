// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISaleBonuses {
    error SB__ZeroWeight();
    error SB__ZeroAmount();
    error SB__InvalidCategoryId(uint256 _categoryId);
    error SB__NotConditionalProvider(address _address);
    error SB__NotERC721or1155(address _tokenAddress);
    error SB__ArraysNotSameLength();
    error SB__NotOracle();
    error SB__ZeroAddress();
    error SB__MaxDrawsExceeded(uint256 _amount);
    error SB__Unauthorized(address _sender);

    /**
     * @notice Event emitted when a category has its eligibility updated
     * @param _tokenId The token id which the category belongs to
     * @param _categoryId The id of the category
     * @param _provider The address of the eligibility provider
     */
    event CategoryEligibilitySet(
        address _addr,
        uint256 _tokenId,
        uint256 _categoryId,
        address _provider
    );
    /**
     * @notice Event emitted when a category is created
     * @param _id The token id a category has been created for
     * @param _categoryId The id of the new category
     */
    event CategoryCreated(address _addr, uint256 _id, uint256 _categoryId);
    /**
     * @notice Event emitted when a category is deleted
     * @param _id The token id a category has been deleted for
     * @param _categoryId The id of the deleted category
     */
    event CategoryDeleted(address _addr, uint256 _id, uint256 _categoryId);
    /**
     * @notice Event emitted when a categories content amounts are updated
     * @param _id The token id of the token
     * @param _categoryId The category Id of a token
     * @param _amounts Array containing the amounts
     * @param _weights Array containing the weights, corresponding by index.
     */
    event ContentAmountsUpdated(
        address _addr,
        uint256 _id,
        uint256 _categoryId,
        uint256[] _amounts,
        uint256[] _weights
    );
    /**
     * @notice Event emitted when the contents of a category are updated
     * @param _id The token id of the token
     * @param _contentCategory The category Id of a token
     * @param _tokens Array of addresses to the content tokens.
     * @param _ids Tokens ids of contents. Will be ignored if the token is an ERC721
     * @param _amounts Array containing the amounts of each tokens
     * @param _weights Array containing the weights, corresponding by index.
     */
    event ContentsUpdated(
        address _addr,
        uint256 _id,
        uint256 _contentCategory,
        address[] _tokens,
        uint256[] _ids,
        uint256[] _amounts,
        uint256[] _weights
    );

    /**
     * @notice Event emitted when the user gains a reward from opening a pack.
     * @param _token Address of the reward token
     * @param _tokenId The token id of the token
     * @param _amount amount of the token being rewarded
     */
    event RewardGranted(address _token, uint256 _tokenId, uint256 _amount);

    struct ContentCategory {
        uint256 id;
        uint256 contentAmountsTotalWeight;
        uint256 contentsTotalWeight;
        uint256[] contentAmounts;
        uint256[] contentAmountsWeights;
        uint256[] tokenAmounts;
        uint256[] tokenWeights;
        address[] tokens;
        uint256[] tokenIds;
    }

    struct ContentInputs {
        address[] _tokens;
        uint256[] _ids;
        uint256[] _amounts;
        uint256[] _weights;
    }

    struct RequestInputs {
        address user;
        uint256 saleId;
        uint256 openings;
        uint256 randWordsCount;
        uint256[] excludedIds;
        address addr;
    }

    /**
     * @notice Used to create a content category
     * @param _id The token id to create a category for
     * @return _categoryId The new ID of the content category
     *
     * Throws SB__NotGov on non gov call
     *
     * Emits CategoryCreated
     */
    function createContentCategory(address _addr, uint256 _id)
        external
        returns (uint256 _categoryId);

    /**
     * @notice Deletes a content category
     * @param _id The token id
     * @param _contentCategory The content category ID
     *
     * Throws SB__NotGov on non gov call
     * Throws SB__InvalidCategoryId on invalid category ID
     *
     * Emits CategoryDeleted
     */
    function deleteContentCategory(
        address _addr,
        uint256 _id,
        uint256 _contentCategory
    ) external;

    /**
     * @notice Used to get the content categories for a token
     * @param _id The token id
     * @return _categories Array of ContentCategory structs corresponding to the given id
     */
    function getContentCategories(address _addr, uint256 _id)
        external
        view
        returns (ContentCategory[] memory _categories);

    /**
     * @notice Used to edit the content amounts for a content category
     * @param _id The token id of the token
     * @param _contentCategory The category Id of a token
     * @param _amounts Array containing the amounts
     * @param _weights Array containing the weights, corresponding by index.
     *
     * Throws SB__NotGov on non gov call.
     * Throws SB__ZeroWeight on any weight being zero
     * @dev Does not throw anything on zero amounts
     * Throws SB__InvalidCategoryId on invalid category ID
     * Throws SB__ArraysNotSameLength on arrays not being same length
     *
     * Emits ContentAmountsUpdated
     */
    function setContentAmounts(
        address _addr,
        uint256 _id,
        uint256 _contentCategory,
        uint256[] memory _amounts,
        uint256[] memory _weights
    ) external;

    /**
     * @notice Used to edit the contents for a content category
     * @dev _tokens needs to be erc1155 or erc 721 implementing ITrustedMintable
     * @param _id The token id of the token
     * @param _contentCategory The category Id of a token
     *
     * Throws SB__NotGov on non gov call.
     * Throws SB__ZeroWeight on any weight being zero
     * Throws SB__ZeroAmount on any amount being zero
     * Throws SB__InvalidCategoryId on invalid category ID
     * Throws SB__NotERC721or1155 on any address not being an erc1155 or erc721 token
     * Throws SB__ArraysNotSameLength on arrays not being same length
     *
     * Emits ContentsUpdated
     */
    function setContents(
        address _addr,
        uint256 _id,
        uint256 _contentCategory,
        ContentInputs memory contents
    ) external;

    function claimBonusReward(
        uint256 _id,
        uint32 _amount,
        bool _optInConditionals,
        address _recipient
    ) external;
}
