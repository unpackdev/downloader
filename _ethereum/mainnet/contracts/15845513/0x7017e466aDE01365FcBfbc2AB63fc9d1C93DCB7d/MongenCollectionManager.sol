//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./IMongenCollection.sol";

contract MongenCollectionManager is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address payable;

    LimitSaleInfo public whitelistSaleInfo;
    LimitSaleInfo public preSaleInfo;
    PublicSaleInfo public publicSaleInfo;
    uint256 public totalSupply;
    uint256 public limitMintPerAddress;
    uint256 public totalMinted;
    bool private mintStart;
    uint256 private total;
    address public MongenCollectionAddress;

    mapping(address => bool) public isWhitelist;
    mapping(address => bool) public isPresales;
    mapping(address => uint256) public mintedByAddress;
    mapping(address => bool) public withdrawPermission;

    struct LimitSaleInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 totalSupply;
        uint256 price;
        uint256 totalMinted;
    }

    struct PublicSaleInfo {
        uint256 startTime;
        uint256 totalSupply;
        uint256 price;
        uint256 totalMinted;
    }

    function initialize(
        uint256 _totalSupply,
        uint256 _limitMintPerAddress,
        address _mongenCollectionAddress
    ) public initializer {
        totalSupply = _totalSupply;
        limitMintPerAddress = _limitMintPerAddress;
        MongenCollectionAddress = _mongenCollectionAddress;
        __Ownable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier isStartMint() {
        require(mintStart, "mint-not-start");
        _;
    }

    modifier isWithdrawPermission() {
        require(withdrawPermission[msg.sender], "no-withdraw-permission");
        _;
    }

    function whiteListMint()
        external
        payable
        whenNotPaused
        isStartMint
        nonReentrant
    {
        require(
            mintedByAddress[msg.sender] < limitMintPerAddress,
            "address-mint-over-limit"
        );
        require(
            whitelistSaleInfo.totalMinted < whitelistSaleInfo.totalSupply,
            "over-limit-presale-minted"
        );
        require(totalMinted < totalSupply, "mint-over-limit");
        require(
            whitelistSaleInfo.startTime <= block.timestamp &&
                whitelistSaleInfo.endTime >= block.timestamp,
            "not-in-mint-time"
        );
        require(isWhitelist[msg.sender], "not-in-whitelist");
        uint256 price = whitelistSaleInfo.price;
        require(price <= msg.value, "Insufficient-balance");
        mintedByAddress[msg.sender] = mintedByAddress[msg.sender].add(1);
        totalMinted = totalMinted.add(1);
        whitelistSaleInfo.totalMinted = whitelistSaleInfo.totalMinted.add(1);
        IMongenCollection(MongenCollectionAddress).mint(msg.sender, 1);
    }

    function presalesMint()
        external
        payable
        whenNotPaused
        isStartMint
        nonReentrant
    {
        require(
            mintedByAddress[msg.sender] < limitMintPerAddress,
            "address-mint-over-limit"
        );
        require(totalMinted < totalSupply, "mint-over-limit");
        require(
            preSaleInfo.totalMinted < preSaleInfo.totalSupply,
            "over-limit-presale-minted"
        );
        require(
            preSaleInfo.startTime <= block.timestamp &&
                preSaleInfo.endTime >= block.timestamp,
            "not-in-mint-time"
        );
        require(isPresales[msg.sender], "not-in-presales");
        uint256 price = preSaleInfo.price;
        require(price <= msg.value, "Insufficient-balance");
        mintedByAddress[msg.sender] = mintedByAddress[msg.sender].add(1);
        totalMinted = totalMinted.add(1);
        preSaleInfo.totalMinted = preSaleInfo.totalMinted.add(1);
        IMongenCollection(MongenCollectionAddress).mint(msg.sender, 1);
    }

    function publicMint()
        external
        payable
        whenNotPaused
        isStartMint
        nonReentrant
    {
        require(
            mintedByAddress[msg.sender] < limitMintPerAddress,
            "address-mint-over-limit"
        );
        require(
            publicSaleInfo.totalMinted < publicSaleInfo.totalSupply,
            "over-limit-public-minted"
        );
        require(totalMinted < totalSupply, "mint-over-limit");
        require(
            publicSaleInfo.startTime <= block.timestamp,
            "not-in-mint-time"
        );
        uint256 price = publicSaleInfo.price;
        require(price <= msg.value, "Insufficient-balance");
        mintedByAddress[msg.sender] = mintedByAddress[msg.sender].add(1);
        totalMinted = totalMinted.add(1);
        publicSaleInfo.totalMinted = publicSaleInfo.totalMinted.add(1);
        IMongenCollection(MongenCollectionAddress).mint(msg.sender, 1);
    }

    function addWhitelistAddress(address[] calldata listAddress)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < listAddress.length; index++) {
            isWhitelist[listAddress[index]] = true;
        }
    }

    function removeWhitelistAddress(address[] calldata listAddress)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < listAddress.length; index++) {
            isWhitelist[listAddress[index]] = false;
        }
    }

    function addPresalesAddress(address[] calldata listAddress)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < listAddress.length; index++) {
            isPresales[listAddress[index]] = true;
        }
    }

    function removePresalesAddress(address[] calldata listAddress)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < listAddress.length; index++) {
            isPresales[listAddress[index]] = true;
        }
    }

    function updateTotalSupply(uint256 _totalSupply) external onlyOwner {
        totalSupply = _totalSupply;
    }

    function updateLimitMintPerAddress(uint256 limit) external onlyOwner {
        limitMintPerAddress = limit;
    }

    function updateMongenCollectionAddress(address _address) external onlyOwner {
        MongenCollectionAddress = _address;
    }

    function startMint() external onlyOwner {
        mintStart = true;
    }

    function updateWhitelistSaleInfo(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalSupply,
        uint256 _price
    ) external onlyOwner {
        require(_price > 0 && _totalSupply > 0, "invalid-number");
        require(
            _endTime > _startTime && _startTime > block.timestamp,
            "invalid-time"
        );
        total = total.add(_totalSupply).sub(whitelistSaleInfo.totalSupply);
        require(total < totalSupply, "over-total");
        LimitSaleInfo memory newSaleInfo;
        newSaleInfo.startTime = _startTime;
        newSaleInfo.endTime = _endTime;
        newSaleInfo.totalSupply = _totalSupply;
        newSaleInfo.price = _price;
        newSaleInfo.totalMinted = whitelistSaleInfo.totalMinted;
        whitelistSaleInfo = newSaleInfo;
    }

    function updatePreSaleInfo(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalSupply,
        uint256 _price
    ) external onlyOwner {
        require(_price > 0 && _totalSupply > 0, "invalid-number");
        require(
            _endTime > _startTime && _startTime > block.timestamp,
            "invalid-time"
        );
        total = total.add(_totalSupply).sub(preSaleInfo.totalSupply);
        require(total < totalSupply, "over-total");
        LimitSaleInfo memory newSaleInfo;
        newSaleInfo.startTime = _startTime;
        newSaleInfo.endTime = _endTime;
        newSaleInfo.totalSupply = _totalSupply;
        newSaleInfo.price = _price;
        newSaleInfo.totalMinted = preSaleInfo.totalMinted;
        preSaleInfo = newSaleInfo;
    }

    function updatePublicSale(uint256 _price, uint256 _startTime)
        external
        onlyOwner
    {
        require(_price > 0, "invalid-price");
        require(_startTime > block.timestamp, "invalid-time");
        PublicSaleInfo memory newSaleInfo;
        newSaleInfo.price = _price;
        newSaleInfo.startTime = _startTime;
        newSaleInfo.totalSupply = totalSupply
            .sub(whitelistSaleInfo.totalSupply)
            .sub(preSaleInfo.totalSupply);
        newSaleInfo.totalMinted = publicSaleInfo.totalMinted;
        publicSaleInfo = newSaleInfo;
    }

    function updateWithdrawPermission(address _address, bool _status)
        external
        onlyOwner
    {
        withdrawPermission[_address] = _status;
    }

    function withdrawFunds(address payable _beneficiary)
        external
        isWithdrawPermission
    {
        require(_beneficiary != address(0), "invalid-address");
        _beneficiary.transfer(address(this).balance);
    }
}
