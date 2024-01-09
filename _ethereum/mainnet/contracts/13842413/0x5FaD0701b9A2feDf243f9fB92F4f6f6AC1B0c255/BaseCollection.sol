// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract BaseCollection is Ownable, Pausable, ERC721Enumerable {
    string public constant VERSION = "0.1.0"; // contract version

    //constants
    uint256 public maximumTokens; // total number of tokens.
    uint16 public maxPurchase; // maximum tokens a user can buy per transaction
    uint16 public maxHolding; // maximum tokens a user can hold
    string private _name; // overriden ERC721 _name property, name of collection
    string private _symbol; // overriden ERC721 _symbol property, symbol of collection

    uint256 public tokensCount; // token IDs counter
    uint256 public startingTokenIndex; // starting index of token ID, this si settled to support reserving tokens

    // public sale state
    uint256 public price; // price per token
    uint256 public publicSaleStartTime; // public sale start time, if zero, public sale starts right after presale.
    string public projectURI; // Base URI for project assets
    string public loadingURI; // Base URI for loading URI
    string public metadata; // ipfs hash that stores metadata of the project

    constructor() ERC721("", "") {}

    /**
     * @dev setup sale and other details
     * @param name_ name of the collection
     * @param symbol_ symbol of the collection
     * @param _admin address of admin of the project
     * @param _maximumTokens maximum number of NFTs
     * @param _maxPurchase maximum number of NFTs that can be bought in once transaction
     * @param _maxHolding maximum number of NFTs a user can hold
     * @param _price price per NFT token during public sale.
     * @param _publicSaleStartTime public sale start timestamp
     * @param _loadingURI URI for project media and assets
     */
    function setupBaseCollection(
        string memory name_,
        string memory symbol_,
        address _admin,
        uint256 _maximumTokens,
        uint16 _maxPurchase,
        uint16 _maxHolding,
        uint256 _price,
        uint256 _publicSaleStartTime,
        string memory _loadingURI
    ) internal {
        require(_admin != address(0), "BC:001");
        require(_maximumTokens != 0, "BC:002");
        require(
            _maximumTokens >= _maxHolding && _maxHolding >= _maxPurchase,
            "BC:003"
        );
        _name = name_;
        _symbol = symbol_;
        _transferOwnership(_admin);
        maximumTokens = _maximumTokens;
        maxPurchase = _maxPurchase;
        maxHolding = _maxHolding;
        price = _price;
        publicSaleStartTime = _publicSaleStartTime;
        loadingURI = _loadingURI;
    }

    /**
     * @dev set metadata of the project
     * @param _metadata ipfs hash or CID of the metadata
     */
    function setMetadata(string memory _metadata) external {
        // can only be invoked before setup or by owner after setup
        require(!isSetupComplete() || msg.sender == owner(), "BC:004");
        require(bytes(_metadata).length != 0, "BC:005");
        metadata = _metadata;
    }

    /**
     * @dev set new public sale start time
     * @param _newPublicSaleStartTime new timestamp of public sale start time
     */
    function setPublicSaleStartTime(uint256 _newPublicSaleStartTime)
        external
        onlyOwner
    {
        require(
            _newPublicSaleStartTime > block.timestamp &&
                _newPublicSaleStartTime != publicSaleStartTime,
            "BC:006"
        );
        publicSaleStartTime = _newPublicSaleStartTime;
    }

    /**
     * @dev pause the collection, using OpenZeppelin's Pausable.sol
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev unpause the collection, using OpenZeppelin's Pausable.sol
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev public buy a single token
     */
    function buy() external payable virtual whenNotPaused {
        require(isSaleActive(), "BC:007");
        require(msg.value == price, "BC:008");
        require(balanceOf(msg.sender) + 1 <= maxHolding, "BC:009");
        _manufacture(msg.sender);
    }

    /**
     * @dev public buy tokens in quantity
     * @param _quantity number of tokens to buy
     */
    function buy(uint256 _quantity) external payable virtual whenNotPaused {
        require(isSaleActive(), "BC:010");
        require(msg.value == (price * _quantity), "BC:011");
        require(_quantity <= maxPurchase, "BC:012");
        require(balanceOf(msg.sender) + _quantity <= maxHolding, "BC:013");
        _manufacture(msg.sender, _quantity);
    }

    /**
     * @dev checks if public sale is active or not
     * @return boolean
     */
    function isSaleActive() public view returns (bool) {
        return
            block.timestamp >= publicSaleStartTime &&
            tokensCount + startingTokenIndex != maximumTokens;
    }

    /**
     * @dev override, to return base uri based
     * @return base uri string
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return projectURI;
    }

    /**
     * @dev override, to return name of collection
     * @return name of collection
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev override, to return symbol of collection
     * @return symbol of collection
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev internal method to manage the minting of tokens
     * @param _buyer address of receiver of minted token
     */
    function _manufacture(address _buyer) internal {
        uint256 currentTokenId = tokensCount + startingTokenIndex;
        tokensCount++;
        _safeMint(_buyer, currentTokenId + 1);
    }

    /**
     * @dev internal method to manage the minting of tokens in quantity
     * @param _buyer address of receiver of minted token
     * @param _quantity number of tokens to mint
     */
    function _manufacture(address _buyer, uint256 _quantity) internal {
        uint256 currentTokenId = tokensCount + startingTokenIndex;
        require(currentTokenId + _quantity <= maximumTokens, "BC:014");
        uint256 newTokensCount = currentTokenId + _quantity;
        tokensCount += _quantity;
        for (
            currentTokenId;
            currentTokenId < newTokensCount;
            currentTokenId++
        ) {
            _safeMint(_buyer, currentTokenId + 1);
        }
    }

    /**
     * @dev checks if setup is complete
     * @return boolean
     */
    function isSetupComplete() public view virtual returns (bool) {
        return maximumTokens != 0 && publicSaleStartTime != 0;
    }

    /**
     * @dev get array of tokens that are bought or holded by a user
     * @return array of token IDs
     */
    function getAllTokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);
        if (balance == 0) {
            return new uint256[](balance);
        } else {
            uint256[] memory tokenList = new uint256[](balance);
            for (uint256 i; i < balance; i++) {
                tokenList[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokenList;
        }
    }
}
