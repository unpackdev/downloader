// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./SafeMath.sol";
import "./INafter.sol";
import "./INafterMarketAuction.sol";
import "./IMarketplaceSettings.sol";
import "./INafterRoyaltyRegistry.sol";
import "./INafterTokenCreatorRegistry.sol";
/**
 * Nafter core contract.
*/

contract Nafter is ERC1155, Ownable, INafter {
    // Library to overcome overflow
    using SafeMath for uint256;
    struct TokenInfo {
        uint256 tokenId;
        address creator;
        uint256 tokenAmount;
        address[] owners;
        uint8 serviceFee;
        uint256 creationTime;
    }

    struct TokenOwnerInfo {
        bool isForSale;
        uint8 priceType; // 0 for fixed, 1 for Auction dates range, 2 for Auction Infinity
        uint256[] prices;
        uint256[] bids;
        address[] bidders;
    }

    // market auction to set the price
    INafterMarketAuction marketAuction;
    IMarketplaceSettings marketplaceSettings;
    INafterRoyaltyRegistry royaltyRegistry;
    INafterTokenCreatorRegistry tokenCreatorRigistry;

    // mapping of token info
    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(uint256 => mapping(address => TokenOwnerInfo)) public tokenOwnerInfo;

    mapping(uint256 => bool) public tokenIdsAvailable;

    uint256[] public tokenIds;
    uint256 public maxId;

    // Event indicating metadata was updated.
    event AddNewToken(address user, uint256 tokenId);
    event DeleteTokens(address user, uint256 tokenId, uint256 amount);
    event SetURI(string uri);

    constructor(
        string memory _uri
    ) public
    ERC1155(_uri)
    {

    }

    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function creatorOfToken(uint256 _tokenId)
    external
    view override
    returns (address payable) {
        return payable(tokenInfo[_tokenId].creator);
    }

    /**
     * @dev Gets the Service Fee
     * @param _tokenId uint256 ID of the token
     * @return get the service fee
     */
    function getServiceFee(uint256 _tokenId)
    external
    view override
    returns (uint8){
        return tokenInfo[_tokenId].serviceFee;
    }

    /**
     * @dev Gets the price type
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     * @return get the price type
     */
    function getPriceType(uint256 _tokenId, address _owner)
    external
    view override
    returns (uint8){
        return tokenOwnerInfo[_tokenId][_owner].priceType;
    }

    /**
     * @dev Gets the token amount
     * @param _tokenId uint256 ID of the token
     */
    function getTokenAmount(uint256 _tokenId)
    external
    view
    returns (uint256){
        return tokenInfo[_tokenId].tokenAmount;
    }

    /**
     * @dev Gets the is for sale
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getIsForSale(uint256 _tokenId, address _owner)
    external
    override
    view
    returns (bool){
        return tokenOwnerInfo[_tokenId][_owner].isForSale;
    }

    /**
     * @dev Gets the owners
     * @param _tokenId uint256 ID of the token
     */
    function getOwners(uint256 _tokenId)
    external
    override
    view
    returns (address[] memory owners){
        return tokenInfo[_tokenId].owners;
    }

    /**
     * @dev Gets the prices
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getPrices(uint256 _tokenId, address _owner)
    external
    view
    returns (uint256[] memory prices){
        return tokenOwnerInfo[_tokenId][_owner].prices;
    }

    /**
     * @dev Gets the bids
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getBids(uint256 _tokenId, address _owner)
    external
    view
    returns (uint256[] memory bids){
        return tokenOwnerInfo[_tokenId][_owner].bids;
    }

    /**
     * @dev Gets the bidders
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getBidders(uint256 _tokenId, address _owner)
    external
    view
    returns (address[] memory bidders){
        return tokenOwnerInfo[_tokenId][_owner].bidders;
    }

    /**
     * @dev Gets the creation time
     * @param _tokenId uint256 ID of the token
     */
    function getCreationTime(uint256 _tokenId)
    external
    view
    returns (uint256){
        return tokenInfo[_tokenId].creationTime;
    }

    /**
     * @dev get tokenIds length
     */
    function getTokenIdsLength() external override view returns (uint256){
        return tokenIds.length;
    }

    /**
     * @dev get token Id
     * @param _index uint256 index
     */

    function getTokenId(uint256 _index) external override view returns (uint256){
        return tokenIds[_index];
    }
    /**
     * @dev get owner tokens
     * @param _owner address of owner.
     */

    function getOwnerTokens(address _owner) public view returns (TokenInfo[] memory tokens, TokenOwnerInfo[] memory ownerInfo) {

        uint totalValues;
        //calculate totalValues
        for (uint i = 0; i < tokenIds.length; i++) {
            TokenInfo memory info = tokenInfo[tokenIds[i]];
            if (info.owners[info.owners.length - 1] == _owner) {
                totalValues++;
            }
        }

        TokenInfo[] memory values = new TokenInfo[](totalValues);
        TokenOwnerInfo[] memory valuesOwner = new TokenOwnerInfo[](totalValues);
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            TokenInfo memory info = tokenInfo[tokenId];
            if (info.owners[info.owners.length - 1] == _owner) {
                values[i] = info;
                valuesOwner[i] = tokenOwnerInfo[tokenId][_owner];
            }
        }

        return (values, valuesOwner);
    }

    /**
     * @dev get token paging
     * @param _offset offset of the records.
     * @param _limit limits of the records.
     */
    function getTokensPaging(uint _offset, uint _limit) public view returns (TokenInfo[] memory tokens, uint nextOffset, uint total) {
        uint256 tokenInfoLength = tokenIds.length;
        if (_limit == 0) {
            _limit = 1;
        }

        if (_limit > tokenInfoLength - _offset) {
            _limit = tokenInfoLength - _offset;
        }

        TokenInfo[] memory values = new TokenInfo[] (_limit);
        for (uint i = 0; i < _limit; i++) {
            uint256 tokenId = tokenIds[_offset + i];
            values[i] = tokenInfo[tokenId];
        }

        return (values, _offset + _limit, tokenInfoLength);
    }

    /**
     * @dev Checks that the token was owned by the sender.
     * @param _tokenId uint256 ID of the token.
     */
    modifier onlyTokenOwner(uint256 _tokenId) {
        uint256 balance = balanceOf(msg.sender, _tokenId);
        require(balance > 0, "must be the owner of the token");
        _;
    }

    /**
     * @dev Checks that the token was created by the sender.
     * @param _tokenId uint256 ID of the token.
     */
    modifier onlyTokenCreator(uint256 _tokenId) {
        address creator = tokenInfo[_tokenId].creator;
        require(creator == msg.sender, "must be the creator of the token");
        _;
    }

    /**
     * @dev restore data from old contract, only call by owner
     * @param _oldAddress address of old contract.
     * @param _startIndex start index of array
     * @param _endIndex end index of array
     */
    function restore(address _oldAddress, uint256 _startIndex, uint256 _endIndex) external onlyOwner {
        Nafter oldContract = Nafter(_oldAddress);
        uint256 length = oldContract.getTokenIdsLength();
        require(_startIndex < length, "wrong start index");
        require(_endIndex <= length, "wrong end index");

        for (uint i = _startIndex; i < _endIndex; i++) {
            uint256 tokenId = oldContract.getTokenId(i);
            tokenIds.push(tokenId);
            //create seperate functions otherwise it will give stack too deep error
            tokenInfo[tokenId] = TokenInfo(
                tokenId,
                oldContract.creatorOfToken(tokenId),
                oldContract.getTokenAmount(tokenId),
                oldContract.getOwners(tokenId),
                oldContract.getServiceFee(tokenId),
                oldContract.getCreationTime(tokenId)
            );

            address[] memory owners = tokenInfo[tokenId].owners;
            for (uint j = 0; j < owners.length; j++) {
                address owner = owners[j];
                tokenOwnerInfo[tokenId][owner] = TokenOwnerInfo(
                    oldContract.getIsForSale(tokenId, owner),
                    oldContract.getPriceType(tokenId, owner),
                    oldContract.getPrices(tokenId, owner),
                    oldContract.getBids(tokenId, owner),
                    oldContract.getBidders(tokenId, owner)
                );

                uint256 ownerBalance = oldContract.balanceOf(owner, tokenId);
                if (ownerBalance > 0) {
                    _mint(owner, tokenId, ownerBalance, '');
                }
            }
            tokenIdsAvailable[tokenId] = true;
        }
        maxId = oldContract.maxId();
    }

    /**
     * @dev update or mint token Amount only from token creator.
     * @param _tokenAmount token Amount
     * @param _tokenId uint256 id of the token.
     */
    function setTokenAmount(uint256 _tokenAmount, uint256 _tokenId) external onlyTokenCreator(_tokenId) {
        tokenInfo[_tokenId].tokenAmount = tokenInfo[_tokenId].tokenAmount + _tokenAmount;
        _mint(msg.sender, _tokenId, _tokenAmount, '');
    }

    /**
     * @dev update is for sale only from token Owner.
     * @param _isForSale is For Sale
     * @param _tokenId uint256 id of the token.
     */
    function setIsForSale(bool _isForSale, uint256 _tokenId) public onlyTokenOwner(_tokenId) {
        tokenOwnerInfo[_tokenId][msg.sender].isForSale = _isForSale;
    }

    /**
     * @dev update is for sale only from token Owner.
     * @param _priceType set the price type
     * @param _price price of the token
     * @param _startTime start time of bid, pass 0 of _priceType is not 1
     * @param _endTime end time of bid, pass 0 of _priceType is not 1
     * @param _tokenId uint256 id of the token.
     * @param _owner owner of the token
     */
    function putOnSale(uint8 _priceType, uint256 _price, uint256 _startTime, uint256 _endTime, uint256 _tokenId, address _owner) public onlyTokenOwner(_tokenId) {
        if (_priceType == 0) {
            marketAuction.setSalePrice(_tokenId, _price, _owner);
        }
        if (_priceType == 1 || _priceType == 2) {
            marketAuction.setInitialBidPriceWithRange(_price, _startTime, _endTime, _owner, _tokenId);
        }
        tokenOwnerInfo[_tokenId][_owner].isForSale = true;
        tokenOwnerInfo[_tokenId][_owner].priceType = _priceType;
    }

    /**
     * @dev remove token from sale
     * @param _tokenId uint256 id of the token.
     * @param _owner owner of the token
     */
    function removeFromSale(uint256 _tokenId, address _owner) external override {
        uint256 balance = balanceOf(msg.sender, _tokenId);
        require(balance > 0 || msg.sender == address(marketAuction), "must be the owner of the token or sender is market auction");

        tokenOwnerInfo[_tokenId][_owner].isForSale = false;
    }

    /**
     * @dev update price type from token Owner.
     * @param _priceType price type
     * @param _tokenId uint256 id of the token.
     */
    function setPriceType(uint8 _priceType, uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        tokenOwnerInfo[_tokenId][msg.sender].priceType = _priceType;
    }

    /**
     * @dev set marketAuction address to set the sale price
     * @param _marketAuction address of market auction.
     * @param _marketplaceSettings address of market auction.
     */
    function setMarketAddresses(address _marketAuction, address _marketplaceSettings, address _tokenCreatorRigistry, address _royaltyRegistry) external onlyOwner {
        marketAuction = INafterMarketAuction(_marketAuction);
        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
        tokenCreatorRigistry = INafterTokenCreatorRegistry(_tokenCreatorRigistry);
        royaltyRegistry = INafterRoyaltyRegistry(_royaltyRegistry);
    }

    /**
     * @dev update price only from auction.
     * @param _price price of the token
     * @param _tokenId uint256 id of the token.
     * @param _owner address of the token owner
     */
    function setPrice(uint256 _price, uint256 _tokenId, address _owner) external override {
        require(msg.sender == address(marketAuction), "only market auction can set the price");
        TokenOwnerInfo storage info = tokenOwnerInfo[_tokenId][_owner];
        info.prices.push(_price);
    }

    /**
     * @dev update bids only from auction.
     * @param _bid bid Amount
     * @param _bidder bidder address
     * @param _tokenId uint256 id of the token.
     * @param _owner address of the token owner
     */
    function setBid(uint256 _bid, address _bidder, uint256 _tokenId, address _owner) external override {
        require(msg.sender == address(marketAuction), "only market auction can set the price");
        TokenOwnerInfo storage info = tokenOwnerInfo[_tokenId][_owner];
        info.bids.push(_bid);
        info.bidders.push(_bidder);
    }

    /**
     * @dev Adds a new unique token to the supply.
     * @param _tokenAmount total token amount available
     * @param _isForSale if is for sale
     * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infiniite
     * @param _royaltyPercentage royality percentage of creator
     */
    function addNewToken(uint256 _tokenAmount, bool _isForSale, uint8 _priceType, uint8 _royaltyPercentage) public {
        uint256 tokenId = _createToken(msg.sender, _tokenAmount, _isForSale, 0, _priceType, _royaltyPercentage);

        emit AddNewToken(msg.sender, tokenId);
    }

    /**
     * @dev Adds a new unique token to the supply.
     * @param _tokenAmount total token amount available
     * @param _isForSale if is for sale
     * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infiniite
     * @param _royaltyPercentage royality percentage of creator
     * @param _tokenId uint256 ID of the token.
     */
    function addNewTokenWithId(uint256 _tokenAmount, bool _isForSale, uint8 _priceType, uint8 _royaltyPercentage, uint256 _tokenId) public {
        uint256 tokenId = _createTokenWithId(msg.sender, _tokenAmount, _isForSale, 0, _priceType, _royaltyPercentage, _tokenId);

        emit AddNewToken(msg.sender, tokenId);
    }

    /**
     * @dev add token and set the price.
     * @param _price price of the item.
     * @param _tokenAmount total token amount available
     * @param _isForSale if is for sale
     * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infiniite
     * @param _royaltyPercentage royality percentage of creator
     * @param _startTime start time of bid, pass 0 of _priceType is not 1
     * @param _endTime end time of bid, pass 0 of _priceType is not 1
     */
    function addNewTokenAndSetThePrice(uint256 _tokenAmount, bool _isForSale, uint256 _price, uint8 _priceType, uint8 _royaltyPercentage, uint256 _startTime, uint256 _endTime) public {
        uint256 tokenId = getTokenIdAvailable();
        addNewTokenAndSetThePriceWithId(_tokenAmount, _isForSale, _price, _priceType, _royaltyPercentage, _startTime, _endTime, tokenId);
    }

    /**
     * @dev add token and set the price.
     * @param _price price of the item.
     * @param _tokenAmount total token amount available
     * @param _isForSale if is for sale
     * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infiniite
     * @param _royaltyPercentage royality percentage of creator
     * @param _startTime start time of bid, pass 0 of _priceType is not 1
     * @param _endTime end time of bid, pass 0 of _priceType is not 1
     * @param _tokenId uint256 ID of the token.
     */
    function addNewTokenAndSetThePriceWithId(uint256 _tokenAmount, bool _isForSale, uint256 _price, uint8 _priceType, uint8 _royaltyPercentage, uint256 _startTime, uint256 _endTime, uint256 _tokenId) public {
        uint256 tokenId = _createTokenWithId(msg.sender, _tokenAmount, _isForSale, _price, _priceType, _royaltyPercentage, _tokenId);
        putOnSale(_priceType, _price, _startTime, _endTime, tokenId, msg.sender);

        emit AddNewToken(msg.sender, tokenId);
    }

    /**
     * @dev Deletes the token with the provided ID.
     * @param _tokenId uint256 ID of the token.
     * @param _amount amount of the token to delete
     */
    function deleteToken(uint256 _tokenId, uint256 _amount) public onlyTokenOwner(_tokenId) {
        bool activeBid = marketAuction.hasTokenActiveBid(_tokenId, msg.sender);
        uint256 balance = balanceOf(msg.sender, _tokenId);
        //2
        if (activeBid == true)
            require(balance.sub(_amount) > 0, "you have the active bid");
        _burn(msg.sender, _tokenId, _amount);
        DeleteTokens(msg.sender, _tokenId, _amount);
    }

    /**
     * @dev Sets uri of tokens.
     *
     * Requirements:
     *
     * @param _uri new uri .
     */
    function setURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
        emit SetURI(_uri);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
    public
    virtual
    override
    {
        //transfer case
        if (msg.sender != address(marketAuction)) {
            bool activeBid = marketAuction.hasTokenActiveBid(id, from);
            uint256 balance = balanceOf(from, id);
            if (activeBid == true)
                require(balance.sub(amount) > 0, "you have the active bid");
        }
        super.safeTransferFrom(from, to, id, amount, data);
        _setTokenOwner(id, to);
    }

    /**
     * @dev Internal function for setting the token's creator.
     * @param _tokenId uint256 id of the token.
     * @param _owner address of the owner of the token.
     */
    function _setTokenOwner(uint256 _tokenId, address _owner) internal {
        address[] storage owners = tokenInfo[_tokenId].owners;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) //incase owner already exists
                return;
        }
        owners.push(_owner);
    }

    /**
     * @dev Internal function creating a new token.
     * @param _creator address of the creator of the token.
     * @param _tokenAmount total token amount available
     * @param _isForSale if is for sale
     * @param _price price of the token, 0 is for not set the price.
     * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infiniite
     * @param _royaltyPercentage royality percentage of creator
     */
    function _createToken(address _creator, uint256 _tokenAmount, bool _isForSale, uint256 _price, uint8 _priceType, uint8 _royaltyPercentage) internal returns (uint256) {
        uint256 newId = getTokenIdAvailable();
        return _createTokenWithId(_creator, _tokenAmount, _isForSale, _price, _priceType, _royaltyPercentage, newId);
    }

    /**
     * @dev Internal function creating a new token.
     * @param _creator address of the creator of the token.
     * @param _tokenAmount total token amount available
     * @param _isForSale if is for sale
     * @param _price price of the token, 0 is for not set the price.
     * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infiniite
     * @param _royaltyPercentage royality percentage of creator
     * @param _tokenId uint256 token id
     */
    function _createTokenWithId(address _creator, uint256 _tokenAmount, bool _isForSale, uint256 _price, uint8 _priceType, uint8 _royaltyPercentage, uint256 _tokenId) internal returns (uint256) {
        require(tokenIdsAvailable[_tokenId] == false, "token id is already exist");

        tokenIdsAvailable[_tokenId] = true;
        tokenIds.push(_tokenId);

        maxId = maxId > _tokenId ? maxId : _tokenId;

        _mint(_creator, _tokenId, _tokenAmount, '');
        uint8 serviceFee = marketplaceSettings.getMarketplaceFeePercentage();

        tokenInfo[_tokenId] = TokenInfo(
            _tokenId,
            _creator,
            _tokenAmount,
            new address[](0),
            serviceFee,
            block.timestamp);

        tokenInfo[_tokenId].owners.push(_creator);

        tokenOwnerInfo[_tokenId][_creator] = TokenOwnerInfo(
            _isForSale,
            _priceType,
            new uint256[](0),
            new uint256[](0),
            new address[](0));
        tokenOwnerInfo[_tokenId][_creator].prices.push(_price);

        royaltyRegistry.setPercentageForTokenRoyalty(_tokenId, _royaltyPercentage);
        tokenCreatorRigistry.setTokenCreator(_tokenId, msg.sender);

        return _tokenId;
    }

    /**
     * @dev get last token id
     */
    function getLastTokenId() external view returns (uint256){
        return tokenIds[tokenIds.length - 1];
    }

    /**
     * @dev get the token id available
     */
    function getTokenIdAvailable() public view returns (uint256){

        for (uint256 i = 0; i < maxId; i++) {
            if (tokenIdsAvailable[i] == false)
                return i;
        }
        return tokenIds.length;
    }
}

