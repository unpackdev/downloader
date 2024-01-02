// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";

/**
 * @title PastelSmartMintDrop
 *
 */

contract BobbyOrrDrop is
    Initializable,
    UUPSUpgradeable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    string public baseURI;
    uint256 public price;
    address public primaryWallet;
    uint256 public royaltiesPercentage;
    uint32 public maxSupply;
    uint8 public stage; // 1 => FanClub, 2 => PrivateSale, 3 => PublicSale
    uint8 public maxPurchaseableCount;
    string[] public cascadeUrls;

    mapping(uint256 => bool) public isFanClubSmartmint;
    mapping(uint256 => bool) public isWhitelistedSmartmint;
    mapping(uint256 => uint8) public hasUserMintedSmartmint;

    mapping(address => bool) public isFanClubAddress;
    mapping(address => bool) public isWhitelistedAddress;
    mapping(address => uint8) public hasUserMintedAddress;

    event Minted(address indexed _to, uint256 _userId, uint256 _tokenId);
    event BaseURIChanged(string _uri);

    uint256 private nextTokenId;
    bool private initialized;

    modifier onlyValidToken(uint256 _tokenId) {
        require(_exists(_tokenId), "Invalid token id");
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint32 _maxSupply,
        uint8 _maxPurchaseableCount,
        uint256 _royaltiesPercentage,
        string memory _baseTokenURI,
        address _primaryWallet
    ) public initializer {
        require(!initialized, "Already initialized");
        require(_primaryWallet != address(0), "Invalid primary, or pastel wallet address");
        require(_royaltiesPercentage < 10000, "Invalid royalties");

        __ERC721_init(_name, _symbol);
        __Ownable_init();
        baseURI = _baseTokenURI;
        primaryWallet = _primaryWallet;

        maxSupply = _maxSupply;
        maxPurchaseableCount = _maxPurchaseableCount;
        royaltiesPercentage = _royaltiesPercentage;
        nextTokenId = 1;
        initialized = true;
        stage = 0;
    }

    function initCascadeUrls(string[] memory _cascadeUrls) public onlyOwner {
        require(_cascadeUrls.length == maxSupply, "Invalid cascade ids");

        cascadeUrls = _cascadeUrls;
    }

    function getCascadeUrl(uint256 _tokenId) public view returns (string memory) {
        require(_tokenId > 0 && _tokenId < maxSupply, "Invalid token Id");

        return cascadeUrls[_tokenId];
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function mint(uint256 _userId, address _to, uint256 _quantity) external payable nonReentrant {
        require(
            _quantity <= maxPurchaseableCount && _quantity > 0,
            "Users can only mint from one to three tokens at a time"
        );
        require(stage > 0, "Not started minting yet");
        bool isAddress = _userId == 0;

        if (stage == 1) {
            require(
                isFanClubSmartmint[_userId] || (isAddress && isFanClubAddress[msg.sender]),
                "You are not a fan club user, you are unable to mint during this stage"
            );
        } else if (stage == 2) {
            require(
                isWhitelistedSmartmint[_userId] || (isAddress && isWhitelistedAddress[msg.sender]),
                "You are not a FCFS user, you are unable to mint during this stage"
            );
        }
        require(
            isAddress
                ? hasUserMintedAddress[msg.sender] + _quantity <= maxPurchaseableCount
                : hasUserMintedSmartmint[_userId] + _quantity <= maxPurchaseableCount,
            "You are not able to purchase those tokens"
        );
        require(msg.value == price * _quantity, "Insufficient price");

        for (uint256 i = 0; i < _quantity; i++) {
            require(nextTokenId < maxSupply + 1, "No available tokens");
            _safeMint(msg.sender, nextTokenId);

            if (isAddress) {
                hasUserMintedAddress[msg.sender]++;
            } else {
                hasUserMintedSmartmint[_userId]++;
            }

            emit Minted(msg.sender, _userId, nextTokenId);

            nextTokenId += 1;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMaxSupply(uint8 _maxSupply) external onlyOwner {
        require(_maxSupply > nextTokenId, "Invalid maxSupply updating request");

        maxSupply = _maxSupply;
    }

    function setMaxPurchaseableCount(uint8 _maxPurchaseableCount) external onlyOwner {
        maxPurchaseableCount = _maxPurchaseableCount;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;

        emit BaseURIChanged(_uri);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPrimaryWallet(address _primaryWallet) external onlyOwner {
        require(_primaryWallet != address(0), "Invalid primary wallet address");

        primaryWallet = _primaryWallet;
    }

    function setStage(uint8 _stage, uint256 _price) external onlyOwner {
        require(_stage < 4 && _stage > 0 && _stage > stage, "Invalid stage");

        stage = _stage;
        price = _price;
    }

    function setFanClubSmartmintUsers(uint256[] memory _fanClubUsers) external onlyOwner {
        for (uint256 i = 0; i < _fanClubUsers.length; i++) {
            isFanClubSmartmint[_fanClubUsers[i]] = true;
        }
    }

    function setWhiteListSmartmintUsers(uint256[] memory _whiteListUsers) external onlyOwner {
        for (uint256 i = 0; i < _whiteListUsers.length; i++) {
            isWhitelistedSmartmint[_whiteListUsers[i]] = true;
        }
    }

    function setFanClubAddresses(address[] memory _fanClubAddresses) external onlyOwner {
        for (uint256 i = 0; i < _fanClubAddresses.length; i++) {
            isFanClubAddress[_fanClubAddresses[i]] = true;
        }
    }

    function setWhiteListAddresses(address[] memory _whiteListAddresses) external onlyOwner {
        for (uint256 i = 0; i < _whiteListAddresses.length; i++) {
            isWhitelistedAddress[_whiteListAddresses[i]] = true;
        }
    }

    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() external view returns (uint256) {
        return nextTokenId - 1;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        require(_exists(_tokenId), "Invalid token id");
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 10000;
        return (primaryWallet, _royalties);
    }

    function withdraw() external onlyOwner nonReentrant {
        require(
            address(this).balance > 0 && primaryWallet != address(0),
            "No funds to withdraw, or invalid wallet address to send."
        );

        payable(primaryWallet).transfer(address(this).balance);

        address payable to = payable(msg.sender);
        require(to != address(0), "Invalid recipient address");
        AddressUpgradeable.sendValue(to, address(this).balance);
    }
}
