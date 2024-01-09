// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PaymentSplitable.sol";

contract Presaleable is PaymentSplitable {
    // presale state
    address public constant SENTINEL_ADDRESS = address(0x1); // last address for linked list

    mapping(address => address) public presaleWhitelist; // addresses that are whitelisted for presale
    uint256 public whitelistCount; // total whitelist addresses
    uint256 public presaleReservedTokens; // number of tokens reserved for presale
    uint256 public presaleMaxHolding; // number of tokens a collector can hold during presale
    uint256 public presalePrice; // price of token during presale
    uint256 public presaleStartTime; // presale start timestamp

    event WhitelistAdded(address indexed addedAddress); // emitted when new address is added to whitelist
    event WhitelistRemoved(address indexed removedAddress); // emitted when a address is remove from whitelist

    modifier presaleAllowed() {
        require(isPresaleAllowed(), "PR:001");
        _;
    }

    /**
     * @dev setup presale details including whitelist
     * @param _presaleReservedTokens number of NFTs reserved for presale
     * @param _presalePrice price per NFT token during presale
     * @param _presaleStartTime presale start timestamp
     * @param _presaleWhitelist array of addresses that are whitelisted for presale
     */
    function setupPresale(
        uint256 _presaleReservedTokens,
        uint256 _presalePrice,
        uint256 _presaleStartTime,
        uint256 _presaleMaxHolding,
        address[] memory _presaleWhitelist
    ) internal {
        if (_presaleStartTime != 0) {
            require(_presaleReservedTokens != 0, "PR:002");
            require(_presaleStartTime > block.timestamp, "PR:003");
            require(_presaleMaxHolding != 0, "PR:004");
            presaleReservedTokens = _presaleReservedTokens;
            presalePrice = _presalePrice;
            presaleStartTime = _presaleStartTime;
            presaleMaxHolding = _presaleMaxHolding;
            if (!(_presaleWhitelist.length == 0)) {
                _presaleWhitelistBatch(_presaleWhitelist);
            }
        }
    }

    /**
     * @dev add whitelist for presale in batch
     * @param _whitelists array of address that needs to be added to presale whitelist
     */
    function presaleWhitelistBatch(address[] memory _whitelists)
        public
        onlyOwner
        presaleAllowed
    {
        _presaleWhitelistBatch(_whitelists);
    }

    /**
     * @dev add an address to presale whitelist
     * @param _whitelistAddress address that needs to be whitelisted for presale
     */
    function addWhitelist(address _whitelistAddress)
        external
        onlyOwner
        presaleAllowed
    {
        address sentinel_address = SENTINEL_ADDRESS;
        if (whitelistCount == 0) {
            presaleWhitelist[sentinel_address] = sentinel_address;
        }
        whitelistCount++;
        require(
            _whitelistAddress != address(0) &&
                _whitelistAddress != sentinel_address &&
                _whitelistAddress != address(this),
            "PR:005"
        );
        require(presaleWhitelist[_whitelistAddress] == address(0), "PR:006");
        presaleWhitelist[_whitelistAddress] = presaleWhitelist[
            sentinel_address
        ];
        presaleWhitelist[sentinel_address] = _whitelistAddress;
        emit WhitelistAdded(_whitelistAddress);
    }

    /**
     * @dev remove an address from presale whitelist
     * @param _prevWhitelistAddress whitelist address that pointed to the address to be removed in the linked list
     * @param _removeWhitelistAddress address to be removed from whitelist
     */
    function removeWhitelist(
        address _prevWhitelistAddress,
        address _removeWhitelistAddress
    ) external onlyOwner presaleAllowed {
        require(
            _removeWhitelistAddress != address(0) &&
                _removeWhitelistAddress != SENTINEL_ADDRESS,
            "PR:005"
        );
        require(
            presaleWhitelist[_prevWhitelistAddress] == _removeWhitelistAddress,
            "PR:007"
        );
        whitelistCount--;
        presaleWhitelist[_prevWhitelistAddress] = presaleWhitelist[
            _removeWhitelistAddress
        ];
        presaleWhitelist[_removeWhitelistAddress] = address(0);
        emit WhitelistRemoved(_removeWhitelistAddress);
    }

    /**
     * @dev setup presale start time
     * @param _newPresaleStartTime new presale start time
     */
    function setPresaleStartTime(uint256 _newPresaleStartTime)
        external
        onlyOwner
    {
        require(
            _newPresaleStartTime > block.timestamp &&
                _newPresaleStartTime != presaleStartTime,
            "PR:008"
        );
        presaleStartTime = _newPresaleStartTime;
    }

    /**
     * @dev buy token during presale
     */
    function presaleBuy()
        external
        payable
        virtual
        whenNotPaused
        presaleAllowed
    {
        require(isPresaleActive(), "PR:009");
        require(msg.value == presalePrice, "PR:010");
        require(
            isPresaleWhitelisted() ? isWhitelisted(msg.sender) : true,
            "PR:011"
        );
        require(balanceOf(msg.sender) + 1 <= presaleMaxHolding, "PR:012");
        _manufacture(msg.sender);
    }

    /**
     * @dev buy tokens in quantity during presale
     * @param _quantity number of tokens to buy
     */
    function presaleBuy(uint256 _quantity)
        external
        payable
        whenNotPaused
        presaleAllowed
    {
        require(isPresaleActive(), "PR:009");
        require(
            isPresaleWhitelisted() ? isWhitelisted(msg.sender) : true,
            "PR:011"
        );
        require(tokensCount + _quantity <= presaleReservedTokens, "PR:013");
        require(msg.value == (presalePrice * _quantity), "PR:010");
        require(_quantity <= maxPurchase, "PR:014");
        require(
            balanceOf(msg.sender) + _quantity <= presaleMaxHolding,
            "PR:012"
        );
        _manufacture(msg.sender, _quantity);
    }

    /**
     * @dev get all the whitelistsed address for whitelist
     * @return _array array of addresses that re whitelisted for presale
     */
    function getPresaleWhitelists()
        external
        view
        presaleAllowed
        returns (address[] memory)
    {
        address[] memory _array = new address[](whitelistCount);
        address currentWhitelist = presaleWhitelist[SENTINEL_ADDRESS];
        uint256 index;
        while (currentWhitelist != SENTINEL_ADDRESS) {
            _array[index] = currentWhitelist;
            currentWhitelist = presaleWhitelist[currentWhitelist];
            index++;
        }
        return _array;
    }

    /**
     * @dev check if an address is whitelist or not
     * @param _address address that needs to be checked if whitelisted for presale or not
     * @return a boolean value, if true, address is whitelisted for presale
     */
    function isWhitelisted(address _address) public view returns (bool) {
        return
            _address != SENTINEL_ADDRESS &&
            presaleWhitelist[_address] != address(0);
    }

    /**
     * @dev check if presale is allowed
     * @return a bool, if true, presale is allowed and exists
     */
    function isPresaleAllowed() public view returns (bool) {
        return presaleReservedTokens > 0;
    }

    /**
     * @dev check if presale is whitelisted or not
     * @return a bool, if true, presale is whitelisted
     */
    function isPresaleWhitelisted() public view returns (bool) {
        return isPresaleAllowed() && whitelistCount != 0;
    }

    /**
     * @dev check if presale is active or not
     * @return a bool, if true, presale is active
     */
    function isPresaleActive() public view returns (bool) {
        return
            block.timestamp > presaleStartTime &&
            tokensCount < presaleReservedTokens &&
            block.timestamp < publicSaleStartTime;
    }

    /**
     * @dev private method to add whitelist in batch
     * @param _whitelists array of addresses
     */
    function _presaleWhitelistBatch(address[] memory _whitelists) private {
        address currentWhitelistAddress = SENTINEL_ADDRESS;
        if (whitelistCount == 0) {
            presaleWhitelist[currentWhitelistAddress] = currentWhitelistAddress;
        }
        whitelistCount += _whitelists.length;
        for (uint256 i; i < _whitelists.length; i++) {
            address whitelistAddress = _whitelists[i];
            require(
                whitelistAddress != address(0) &&
                    whitelistAddress != currentWhitelistAddress &&
                    whitelistAddress != address(this) &&
                    whitelistAddress != SENTINEL_ADDRESS,
                "PR:005"
            );
            require(presaleWhitelist[whitelistAddress] == address(0), "PR:006");
            presaleWhitelist[whitelistAddress] = presaleWhitelist[
                currentWhitelistAddress
            ];
            presaleWhitelist[currentWhitelistAddress] = whitelistAddress;
            currentWhitelistAddress = whitelistAddress;
        }
    }
}
