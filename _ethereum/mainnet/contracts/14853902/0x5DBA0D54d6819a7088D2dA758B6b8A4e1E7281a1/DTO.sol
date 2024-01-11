//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IDTO.sol";

/// @title Decentralized Telecommunication Operator
contract DTO is ERC721Enumerable, Ownable, IDTO {
    using Strings for uint256;

    /// @notice The minimum duration rent
    uint256 public constant MIN_DURATION = 365 days;

    /// @notice Base URI
    string private _uri;

    /// @notice The counter id prefix
    uint256 public counter = 10000000;

    /// @notice Max size prefix
    uint256 public maxSizePrefix = 10;

    /// @notice Price prefix
    uint256 private _salePrice = 100 ether;

    /// @notice The data prefix
    mapping(uint256 => uint256) public prefixPrice;
    mapping(uint256 => address) public prefixOwner;
    mapping(uint256 => string) public prefixName;
    mapping(string => uint256) public prefixId;

    /// @notice The duration rent of number
    mapping(uint256 => uint256) public endRent;

    /// @notice Status of contract
    bool public pause;
    bool public statusPrefix;

    /// @notice Event contract
    event AddPrefix(string prefix_, uint256 prefixId_, uint256 price_);
    event ChangePrice(uint256 id, uint256 price_);
    event MintNumber(uint256 prefixNumber, uint256 duration);

    /**
     * @notice Construct a new contract
     * @param name_ name of contract
     * @param symbol_ symbol
     * @param statusPause status (true/false) contract
     * @param statusPrefix_ status sale prefix
     */ 
    constructor(
        string memory name_,
        string memory symbol_,
        bool statusPause,
        bool statusPrefix_
    ) ERC721(name_, symbol_) {
        pause = statusPause;
        statusPrefix = statusPrefix_;
    }

    modifier checkPause() {
        require(pause, "Error: Contract paused");
        _;
    }

    modifier pausePrefix() {
        require(statusPrefix, "Error: Mint Prefix paused");
        _;
    }

    /**
     * @notice set base URI
     * @param uri_ The string with URI
     */
    function setBaseURI(string memory uri_) external override onlyOwner {
        _uri = uri_;
    }

    /**
     * @notice set start or end contract
     * @param status_ bool value
     */
    function setPause(bool status_) external override onlyOwner {
        pause = status_;
    }

    /**
     * @notice set start or end sale prefix
     * @param status bool value
     */
    function setPausePrefix(bool status) external override onlyOwner {
        statusPrefix = status;
    }

    /**
     * @notice set cost of prefix
     * @param price uint256 price prefix
     */
    function setSalePrice(uint256 price) external override onlyOwner {
        _salePrice = price;
    }

    /**
     * @notice set size prefix
     * @param size number symbol in Prefix
     */
    function setMaxSizePrefix(uint256 size) external override onlyOwner {
        maxSizePrefix = size;
    }

    /**
     * @notice add Prefix Owner contract
     * @param prefix_ prefix name
     * @param price prefix price
     * @return prefix Id
     */
    function addPrefixOwner(string memory prefix_, uint256 price)
        external
        override
        onlyOwner
        checkPause
        pausePrefix
        returns (uint256)
    {
        return _addPrefix(prefix_, price, msg.sender);
    }

    /**
     * @notice payable function add Prefix
     * @param prefix_ prefix name
     * @param price prefix price
     * @return prefix Id
     */
    function addPrefix(string memory prefix_, uint256 price)
        external
        payable
        override
        checkPause
        pausePrefix
        returns (uint256)
    {
        require(msg.value >= _salePrice, "Error: incorrect value price");
        uint256 id = _addPrefix(prefix_, price, msg.sender);

        (bool success, ) = payable(owner()).call{value: msg.value}("");

        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );

        return id;
    }

    /**
     * @notice change owner prefix
     * @param prefix prefix name
     * @param newAddress new address of owner
     */
    function changeOwnerPrerix(string memory prefix, address newAddress)
        external
        override
    {
        require(
            prefixOwner[prefixId[prefix]] == msg.sender,
            "Error: You don`t owner this prefix"
        );
        prefixOwner[prefixId[prefix]] = newAddress;
    }

    /**
     * @notice set Price Number in Prefix
     * @param id prefix Id
     * @param price number price
     */
    function changePrice(uint256 id, uint256 price)
        external
        override
        checkPause
    {
        require(
            prefixOwner[id] == msg.sender,
            "Error: You aren`t owner this Prefix"
        );
        prefixPrice[id] = price;
        emit ChangePrice(id, price);
    }

    /**
     * @notice set new rent duration
     * @param prefixNumber token ID
     * @param duration new rent
     */
    function reRent(uint256 prefixNumber, uint256 duration)
        external
        payable
        override
        checkPause
    {
        require(duration >= MIN_DURATION, "Error: duration incorrect");
        uint256 lenNumber = bytes(prefixNumber.toString()).length;
        uint256 prefix_ = prefixNumber / 10**(lenNumber - 8);
        require(
            msg.value >= (prefixPrice[prefix_] * duration) / MIN_DURATION,
            "Error: incorrect value price"
        );
        endRent[prefixNumber] += duration;

        (bool success, ) = payable(prefixOwner[prefix_]).call{value: msg.value}(
            ""
        );
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @notice register new Number
     * @param prefixNumber token ID
     * @param duration new rent
     */
    function registerNumber(uint256 prefixNumber, uint256 duration)
        external
        payable
        override
        checkPause
    {
        require(
            block.timestamp > endRent[prefixNumber],
            "Error: Rent don`t end"
        );
        require(duration >= MIN_DURATION, "Error: duration incorrect");

        uint256 lenNumber = bytes(prefixNumber.toString()).length;
        uint256 prefix_ = prefixNumber / 10**(lenNumber - 8);
        require(prefixOwner[prefix_] != address(0), "Error: incorrect prefix");
        require(lenNumber - 8 < 11, "Error: incorrect length number");
        require(
            msg.value >= (prefixPrice[prefix_] * duration) / MIN_DURATION,
            "Error: incorrect value price"
        );

        endRent[prefixNumber] = block.timestamp + duration;

        if (_exists(prefixNumber)) {
            // Name was previously owned, and expired
            _burn(prefixNumber);
        }

        _safeMint(msg.sender, prefixNumber);

        emit MintNumber(prefixNumber, duration);

        (bool success, ) = payable(prefixOwner[prefix_]).call{value: msg.value}(
            ""
        );
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @notice get base URI
     * @return String value equals base URI with metadata
     */
    function baseURI() public view override returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice get base URI
     * @return String value equals base URI with metadata
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /**
     * @notice check prefix name for spaces
     * @param _base prefix name
     * @param _value checking value
     * @param _offset start value check
     * @return bool status checking
     */
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        require(_valueBytes.length == 1, "Error in indexOf");

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice internal function add Prefix
     * @param prefix_ prefix name
     * @param price prefix price
     * @param userAddress address prefix Owner
     * @return return prefix Id
     */
    function _addPrefix(
        string memory prefix_,
        uint256 price,
        address userAddress
    ) internal returns (uint256) {
        require(bytes(prefix_).length > 0, "Error: Empty string");
        require(
            bytes(prefix_).length < maxSizePrefix,
            "Error: This prefix bigest"
        );
        require(_indexOf(prefix_, " ", 0), "Error: Prefix contains a space");
        require(prefixId[prefix_] < 100000000, "This prefix busy");
        require(counter < 100000000, "Error: end prefix counter");

        prefixPrice[counter] = price;
        prefixOwner[counter] = userAddress;
        prefixName[counter] = prefix_;
        prefixId[prefix_] = counter;

        counter++;

        emit AddPrefix(prefix_, counter - 1, price);

        return counter - 1;
    }
}
