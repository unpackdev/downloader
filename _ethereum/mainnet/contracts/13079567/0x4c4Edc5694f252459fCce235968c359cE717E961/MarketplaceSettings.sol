// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IMarketplaceSettings.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./INafter.sol";

/**
 * @title MarketplaceSettings Settings governing the marketplace fees.
 */
contract MarketplaceSettings is Ownable, AccessControl, IMarketplaceSettings {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////////////////////
    // Constants
    /////////////////////////////////////////////////////////////////////////

    bytes32 public constant TOKEN_MARK_ROLE = "TOKEN_MARK_ROLE";

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Max wei value within the marketplace
    uint256 private maxValue;

    // Min wei value within the marketplace
    uint256 private minValue;

    // Percentage fee for the marketplace, 3 == 3%
    uint8 private marketplaceFeePercentage;

    // Mapping of ERC1155 contract to the primary sale fee. If primary sale fee is 0 for an origin contract then primary sale fee is ignored. 1 == 1%
    uint8 private primarySaleFees;

    // Mapping of ERC1155 contract to mapping of token ID to whether the token has been sold before.
    mapping(uint256 => bool) private soldTokens;

    //where market fund sends
    address public wallet;
    /////////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Initializes the contract maxValue, minValues, and marketplaceFeePercentage to default settings.
     *      Also, sets the roles for the contract to the owner.
     */
    constructor() public {
        maxValue = 2 ** 254;
        // 2 ^ 254 is max amount, prevents any overflow issues.

        minValue = 1000;
        // all amounts must be greater than 1000 Wei.

        marketplaceFeePercentage = 3;
        // 3% marketplace fee on all txs.

        _setupRole(AccessControl.DEFAULT_ADMIN_ROLE, owner());
        grantRole(TOKEN_MARK_ROLE, owner());
    }

    /////////////////////////////////////////////////////////////////////////
    // grantMarketplaceMarkTokenAccess
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Grants a marketplace contract access to marke
     * @param _account address of the account that can perform the token mark role.
     */
    function grantMarketplaceAccess(address _account) external {
        require(
            hasRole(AccessControl.DEFAULT_ADMIN_ROLE, msg.sender),
            "grantMarketplaceAccess::Must be admin to call method"
        );
        grantRole(TOKEN_MARK_ROLE, _account);
    }

    /////////////////////////////////////////////////////////////////////////
    // getMarketplaceMaxValue
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMaxValue() external view override returns (uint256) {
        return maxValue;
    }

    /////////////////////////////////////////////////////////////////////////
    // setMarketplaceMaxValue
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set the maximum value of the marketplace settings.
     * @param _maxValue uint256 maximum wei value.
     */
    function setMarketplaceMaxValue(uint256 _maxValue) external onlyOwner {
        maxValue = _maxValue;
    }

    /////////////////////////////////////////////////////////////////////////
    // getMarketplaceMinValue
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMinValue() external view override returns (uint256) {
        return minValue;
    }

    /////////////////////////////////////////////////////////////////////////
    // setMarketplaceMinValue
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set the minimum value of the marketplace settings.
     * @param _minValue uint256 minimum wei value.
     */
    function setMarketplaceMinValue(uint256 _minValue) external onlyOwner {
        minValue = _minValue;
    }

    /////////////////////////////////////////////////////////////////////////
    // getMarketplaceFeePercentage
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the marketplace fee percentage.
     * @return uint8 wei fee.
     */
    function getMarketplaceFeePercentage()
    external
    view
    override
    returns (uint8)
    {
        return marketplaceFeePercentage;
    }

    /////////////////////////////////////////////////////////////////////////
    // setMarketplaceFeePercentage
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set the marketplace fee percentage.
     * Requirements:

     * - `_percentage` must be <= 100.
     * @param _percentage uint8 percentage fee.
     */
    function setMarketplaceFeePercentage(uint8 _percentage) external onlyOwner {
        require(
            _percentage <= 100,
            "setMarketplaceFeePercentage::_percentage must be <= 100"
        );
        marketplaceFeePercentage = _percentage;
    }

    /////////////////////////////////////////////////////////////////////////
    // calculateMarketplaceFee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Utility function for calculating the marketplace fee for given amount of wei.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateMarketplaceFee(uint256 _amount)
    external
    view
    override
    returns (uint256)
    {
        return _amount.mul(marketplaceFeePercentage).div(100);
    }

    /////////////////////////////////////////////////////////////////////////
    // getERC1155ContractPrimarySaleFeePercentage
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the primary sale fee percentage for a specific ERC1155 contract.
     * @return uint8 wei primary sale fee.
     */
    function getERC1155ContractPrimarySaleFeePercentage()
    external
    view
    override
    returns (uint8)
    {
        return primarySaleFees;
    }

    /**
     * @dev restore data from old contract, only call by owner
     * @param _oldAddress address of old contract.
     * @param _oldNafterAddress get the token ids from the old nafter contract.
     * @param _startIndex start index of array
     * @param _endIndex end index of array
     */
    function restore(address _oldAddress, address _oldNafterAddress, uint256 _startIndex, uint256 _endIndex) external onlyOwner {
        MarketplaceSettings oldContract = MarketplaceSettings(_oldAddress);
        INafter oldNafterContract = INafter(_oldNafterAddress);

        uint256 length = oldNafterContract.getTokenIdsLength();
        require(_startIndex < length, "wrong start index");
        require(_endIndex <= length, "wrong end index");

        for (uint i = _startIndex; i < _endIndex; i++) {
            uint256 tokenId = oldNafterContract.getTokenId(i);
            soldTokens[tokenId] = oldContract.hasTokenSold(tokenId);
        }

        maxValue = oldContract.getMarketplaceMaxValue();
        minValue = oldContract.getMarketplaceMinValue();
        marketplaceFeePercentage = oldContract.getMarketplaceFeePercentage();
        primarySaleFees = oldContract.getERC1155ContractPrimarySaleFeePercentage();
    }

    /////////////////////////////////////////////////////////////////////////
    // setERC1155ContractPrimarySaleFeePercentage
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set the primary sale fee percentage for a specific ERC1155 contract.

     * Requirements:
     *
     * - `_contractAddress` cannot be the zero address.
     * - `_percentage` must be <= 100.

     * @param _percentage uint8 percentage fee for the ERC1155 contract.
     */
    function setERC1155ContractPrimarySaleFeePercentage(
        uint8 _percentage
    ) external onlyOwner {
        require(
            _percentage <= 100,
            "setERC1155ContractPrimarySaleFeePercentage::_percentage must be <= 100"
        );
        primarySaleFees = _percentage;
    }

    /////////////////////////////////////////////////////////////////////////
    // calculatePrimarySaleFee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Utility function for calculating the primary sale fee for given amount of wei
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculatePrimarySaleFee(uint256 _amount)
    external
    view
    override
    returns (uint256)
    {
        return _amount.mul(primarySaleFees).div(100);
    }

    /////////////////////////////////////////////////////////////////////////
    // hasTokenSold
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Check whether the ERC1155 token has sold at least once.
     * @param _tokenId uint256 token ID.
     * @return bool of whether the token has sold.
     */
    function hasTokenSold(uint256 _tokenId)
    external
    view
    override
    returns (bool)
    {
        return soldTokens[_tokenId];
    }

    /////////////////////////////////////////////////////////////////////////
    // markERC1155TokenAsSold
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Mark a token as sold.

     * Requirements:
     *
     * - `_contractAddress` cannot be the zero address.

     * @param _tokenId uint256 token ID.
     * @param _hasSold bool of whether the token should be marked sold or not.
     */
    function markERC1155Token(
        uint256 _tokenId,
        bool _hasSold
    ) external override {
        require(
            hasRole(TOKEN_MARK_ROLE, msg.sender),
            "markERC1155Token::Must have TOKEN_MARK_ROLE role to call method"
        );
        soldTokens[_tokenId] = _hasSold;
    }

    /////////////////////////////////////////////////////////////////////////
    // markTokensAsSold
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Function to set an array of tokens for a contract as sold, thus not being subject to the primary sale fee, if one exists.
     * @param _tokenIds uint256[] array of token ids.
     */
    function markTokensAsSold(
        uint256[] calldata _tokenIds
    ) external {
        require(
            hasRole(TOKEN_MARK_ROLE, msg.sender),
            "markERC1155Token::Must have TOKEN_MARK_ROLE role to call method"
        );
        // limit to batches of 2000
        require(
            _tokenIds.length <= 2000,
            "markTokensAsSold::Attempted to mark more than 2000 tokens as sold"
        );

        // Mark provided tokens as sold.
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            soldTokens[_tokenIds[i]] = true;
        }
    }
}
