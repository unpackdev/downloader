//SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./ERC721AUpgradeable.sol";
import "./TomodachiSigner.sol";

contract TTMint is
    ERC721AUpgradeable,
    TomodachiSigner,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    string public baseTokenURI;

    uint8 public maxWhiteListMintForEach;
    uint8 public maxReserveMintForEach;
    uint8 public maxPublicMintForEach;

    uint256 public MAX_SUPPLY;
    uint256 public OwnerCap;
    uint256 public whiteListCap;

    uint256 public whiteListPriceForEach;
    uint256 public reserveListPriceForEach;
    uint256 public publicMintPriceForEach;

    uint256 public whiteListStartTime;

    address public designatedSigner;

    address payable public treasure;

    uint256 public whiteListMinted;
    uint256 public reserveListMinted;
    uint256 public publicMinted;
    uint256 public ownerMinted;

    uint256 public whiteListEndTime;
    uint256 public reserveListEndTime;

    mapping(address => uint256) public whiteListSpotBought;
    mapping(address => uint256) public publicMintSpotBought;
    mapping(address => uint256) public reserveListSpotBought;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only wallet can call function");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 epochTime_,
        address payable treasure_,
        address designatedSigner_
    ) public initializer {
        require(epochTime_ >= block.timestamp, "Invalid start time");
        require(treasure_ != address(0), "Invalid treasure address");
        require(
            designatedSigner_ != address(0),
            "Invalid designated signer address"
        );

        __ERC721A_init(name_, symbol_);
        __Ownable_init();
        __ReentrancyGuard_init();
        __TomodachiSigner_init();

        maxWhiteListMintForEach = 2;
        maxReserveMintForEach = 1;
        maxPublicMintForEach = 2;

        MAX_SUPPLY = 7777;
        OwnerCap = 100;
        whiteListCap = 6000;

        whiteListEndTime = 12 hours;
        reserveListEndTime = 6 hours;

        whiteListStartTime = epochTime_;
        reserveListEndTime = epochTime_ + whiteListEndTime + reserveListEndTime;
        whiteListEndTime += epochTime_;

        treasure = treasure_;
        designatedSigner = designatedSigner_;
        whiteListPriceForEach = 0.085 ether;
        reserveListPriceForEach = 0.085 ether;
        publicMintPriceForEach = 0.12 ether;
    }

    function ownerMint(uint256 _amount) external onlyOwner {
        require(_amount + ownerMinted <= OwnerCap, "Owner Mint Limit Exceeded");
        require(
            _amount + totalSupply() <= MAX_SUPPLY,
            "Max Supply Limit Exceeded"
        );
        ownerMinted += _amount;
        _mint(_msgSender(), _amount);
    }

    function whiteListMint(WhiteList memory _whitelist, uint256 _amount)
        external
        payable
        nonReentrant
    {
        require(
            whiteListStartTime <= block.timestamp &&
                block.timestamp < whiteListEndTime,
            "WhiteList Mint Period Over"
        );
        require(getSigner(_whitelist) == designatedSigner, "Invalid Signature");
        require(
            _whitelist.userAddress == _msgSender(),
            "Not A Whitelisted Address"
        );
        require(
            whiteListMinted + _amount <= whiteListCap,
            "WhiteList Spot Ended"
        );
        require(
            _amount + whiteListSpotBought[_whitelist.userAddress] <=
                maxWhiteListMintForEach,
            "Max WhiteList Spot Bought"
        );
        require(!_whitelist.isReserveList, "Reserve List Spot Bought");
        require(
            msg.value == _amount * whiteListPriceForEach,
            "Pay Exact Amount"
        );
        whiteListMinted += _amount;
        whiteListSpotBought[_whitelist.userAddress] += _amount;

        _mint(_whitelist.userAddress, _amount);
    }

    function reserveListMint(WhiteList memory _whitelist, uint256 _amount)
        external
        payable
        nonReentrant
    {
        require(
            whiteListEndTime <= block.timestamp &&
                block.timestamp < reserveListEndTime,
            "Not ReserveList Mint Period"
        );
        require(
            whiteListMinted < whiteListCap,
            "Reserve items are all sold in whitelist sale"
        );
        require(getSigner(_whitelist) == designatedSigner, "Invalid Signature");
        require(
            _whitelist.userAddress == _msgSender(),
            "Not A Whitelisted Address"
        );
        require(
            reserveListMinted + _amount <= whiteListCap - whiteListMinted,
            "ReserveList Spot Ended"
        );
        require(
            _amount + reserveListSpotBought[_msgSender()] <=
                maxReserveMintForEach,
            "Max Reserve Mint Spot Bought"
        );
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "Max Supply Limit Exceed"
        );
        require(_whitelist.isReserveList, "Is Whitelist");
        require(msg.value == reserveListPriceForEach, "Pay Exact Amount");

        reserveListSpotBought[_whitelist.userAddress] += _amount;
        reserveListMinted += _amount;

        _mint(_whitelist.userAddress, _amount);
    }

    function publicMint(uint256 _amount) external payable onlyEOA nonReentrant {
        require(
            block.timestamp >= reserveListEndTime ||
                (whiteListEndTime <= block.timestamp &&
                    whiteListMinted == whiteListCap),
            "ReserveList Mint Period Not over"
        );
        require(
            _amount + publicMintSpotBought[_msgSender()] <=
                maxPublicMintForEach,
            "Max Public Mint Spot Bought"
        );
        require(totalSupply() + _amount <= MAX_SUPPLY, "Public Mint all sold");
        require(
            msg.value == publicMintPriceForEach * _amount,
            "Pay Exact Amount"
        );

        publicMintSpotBought[_msgSender()] += _amount;
        publicMinted += _amount;

        _mint(_msgSender(), _amount);
    }

    ///@dev withdraw funds from contract to treasure
    function withdraw() external onlyOwner {
        require(treasure != address(0), "Treasure address not set");
        treasure.transfer(address(this).balance);
    }

    ///@dev Setters
    function setWhiteListStartTime(uint256 _epochTime) external onlyOwner {
        require(_epochTime >= block.timestamp, "StartTime is already over");
        whiteListStartTime = _epochTime;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(bytes(baseURI_).length > 0, "Invalid base URI");
        baseTokenURI = baseURI_;
    }

    function setTreasure(address _treasure) external onlyOwner {
        require(_treasure != address(0), "Invalid address for signer");
        treasure = payable(_treasure);
    }

    function setDesignatedSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address for signer");
        designatedSigner = _signer;
    }

    /////////////////
    /// Set Price ///
    /////////////////

    function setPublicMintPriceForEach(uint256 _price) external onlyOwner {
        publicMintPriceForEach = _price;
    }

    function setWhitelistPriceForEach(uint256 _price) external onlyOwner {
        whiteListPriceForEach = _price;
    }

    function setReserveListPriceForEach(uint256 _price) external onlyOwner {
        reserveListPriceForEach = _price;
    }

    ///////////////
    /// Set Max ///
    ///////////////

    function setMaxWhiteListMintForEach(uint8 _amount) external onlyOwner {
        maxWhiteListMintForEach = _amount;
    }

    function setMaxReserveListMintForEach(uint8 _amount) external onlyOwner {
        maxReserveMintForEach = _amount;
    }

    function setMaxPublicMintForEach(uint8 _amount) external onlyOwner {
        maxPublicMintForEach = _amount;
    }

    function setMAX_SUPPLY(uint256 amount) external onlyOwner {
        MAX_SUPPLY = amount;
    }

    function setOwnerCap(uint256 amount) external onlyOwner {
        OwnerCap = amount;
    }

    function setWhiteListCap(uint256 amount) external onlyOwner {
        whiteListCap = amount;
    }

    ///@dev Toggle contract pause
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    ///@dev set whitelist endtime
    function setWhiteListEndTime(uint256 _time) external onlyOwner {
        require(block.timestamp < _time, "Timestamp is already over");
        whiteListEndTime = _time;
    }

    ///@dev set reservelist endtime
    function setReserveListEndTime(uint256 _time) external onlyOwner {
        require(block.timestamp < _time, "Timestamp is already over");
        reserveListEndTime = _time;
    }

    ///@dev Override Function
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
