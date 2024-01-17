// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PaymentSplitterUpgradeable.sol";
import "./console.sol";


/// @custom:security-contact manuel.salinardi@gmail.com
contract CryptoMadonne is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, PaymentSplitterUpgradeable {
    using StringsUpgradeable for uint256;

    uint256 public finalMaxSupply;
    uint256 public currentMaxSupply;
    uint256 public maxMintPerAddress;
    uint256 public maxMintAmount;
    uint256 public dropCount;

    uint256 public costWhiteListed;
    uint256 public costAllowListed;
    uint256 public costPublic;

    bool public allowPublic;

    address[] public whiteListed;
    address[] public allowListed;

    mapping(address => uint256) public addressMintedBalance;

    struct DropBaseURL {
        uint256 fromTokenId;
        uint256 toTokenId;
        string baseURI;
    }

    DropBaseURL[] public _dropBaseURLs;

    //#region INTERNALS

//    function _etherToWei(uint valueEther) internal pure returns (uint) {
//        return valueEther*(10**18);
//    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] memory _payees,
        uint256[] memory _shares,
        string memory _baseURI
    ) initializer public {
        __ERC721_init("CryptoMadonne", "HC");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __PaymentSplitter_init(_payees, _shares);

        _dropBaseURLs.push(DropBaseURL(1, 1_000, _baseURI));

        finalMaxSupply = 10_000;
        currentMaxSupply = 1_000;
        allowPublic = true;
        maxMintPerAddress = 5;
        maxMintAmount = 100;

        dropCount = 0;

        costWhiteListed = 0.10 ether;
        costAllowListed = 0.11 ether;
        costPublic = 0.12 ether;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(address from, address to, uint256 _tokenId) internal whenNotPaused override {
        super._afterTokenTransfer(from, to, _tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    //#endregion INTERNALS

    //#region PUBLIC

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isWhiteListed(address _user) public view returns (bool) {
        for (uint i = 0; i < whiteListed.length; i++) {
            if (whiteListed[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isAllowListed(address _user) public view returns (bool) {
        for (uint i = 0; i < allowListed.length; i++) {
            if (allowListed[i] == _user) {
                return true;
            }
        }
        return false;
    }

//    function mintTo(address recipient) public returns (uint256) {
//        _tokenIdCounter.increment();
//        uint256 tokenId = _tokenIdCounter.current();
//        _safeMint(recipient, tokenId);
//        return tokenId;
//    }

    function _getCostPerAddress(address _account, bool _isWhiteListed, bool _isAllowListed) internal view returns (uint256) {
        if (_account == owner()) return 0;
        uint256 cost = costPublic;
        if (dropCount == 0 || _isWhiteListed) {
            cost = costWhiteListed;
        } else if (_isAllowListed) {
            cost = costAllowListed;
        }
        return cost;
    }

    function getCostPerAddress(address _account) public view returns (uint256) {
        bool _isWhiteListed = isWhiteListed(_account);
        bool _isAllowListed = isAllowListed(_account);
        return _getCostPerAddress(msg.sender, _isWhiteListed, _isAllowListed);
    }

    function mint(uint256 _mintAmount) public whenNotPaused payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(supply + _mintAmount <= currentMaxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            require(addressMintedBalance[msg.sender] + _mintAmount <= maxMintPerAddress, "max mint per address exceeded");
            bool _isWhiteListed = isWhiteListed(msg.sender);
            bool _isAllowListed = isAllowListed(msg.sender);
            bool isPublic = _isWhiteListed == false && _isAllowListed == false;
            if (allowPublic == false) {
                require(isPublic == false, "public mint is not allowed");
            }
            uint256 cost = _getCostPerAddress(msg.sender, _isWhiteListed, _isAllowListed);
            uint256 expectedCost = cost * _mintAmount;
            require(msg.value == expectedCost, string(abi.encodePacked("Wrong transaction value, expected: ", expectedCost.toString(), ", actual: ", msg.value.toString())));
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI;
        for (uint i = 0; i < _dropBaseURLs.length; i++) {
            DropBaseURL memory dropBaseURL = _dropBaseURLs[i];
            if (tokenId >= dropBaseURL.fromTokenId && tokenId <= dropBaseURL.toTokenId) {
                baseURI = dropBaseURL.baseURI;
                break;
            }
        }
        require(bytes(baseURI).length > 0, "Empty baseURI");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    //#endregion PUBLIC


    //#region OWNER

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function drop1(
        address[] calldata _whiteListed,
        address[] calldata _allowListed
    ) public onlyOwner {
        dropCount = 1;
        whiteListed = _whiteListed;
        allowListed = _allowListed;
    }

    function drop(
        string memory _baseURI,
        uint256 _supply,
        address[] calldata _whiteListed,
        address[] calldata _allowListed,
        uint256 _costWhiteListed,
        uint256 _costAllowListed,
        uint256 _costPublic
    ) public onlyOwner {
        dropCount++;
        uint256 firstTokenId = currentMaxSupply + 1;
        currentMaxSupply = currentMaxSupply + _supply;
        whiteListed = _whiteListed;
        allowListed = _allowListed;
        costWhiteListed = _costWhiteListed;
        costAllowListed = _costAllowListed;
        costPublic = _costPublic;
        require(currentMaxSupply < finalMaxSupply, "exceeded finalMaxSupply");
        _dropBaseURLs.push(DropBaseURL(firstTokenId, currentMaxSupply, _baseURI));
    }

    function setCosts(
        uint256 _costWhiteListed,
        uint256 _costAllowListed,
        uint256 _costPublic
    ) public onlyOwner {
        costWhiteListed = _costWhiteListed;
        costAllowListed = _costAllowListed;
        costPublic = _costPublic;
    }

    function withdrawsAll() public onlyOwner {
        withdrawsPayee1();
        withdrawsPayee2();
    }

    function withdrawsPayee1() public onlyOwner {
        release(payable(payee(0)));
    }

    function withdrawsPayee2() public onlyOwner {
        release(payable(payee(1)));
    }

    function releasedPerAccount(address account) public view onlyOwner returns (uint256) {
        return released(account);
    }

    function setMaxMintPerAddress(uint256 value) public onlyOwner {
        maxMintPerAddress = value;
    }

    /// @dev Sets the base token URI prefix.
//    function setBaseURI(string memory __baseURI) public onlyOwner {
//        baseURI = __baseURI;
//    }

    function allowPublicMint() public onlyOwner {
        allowPublic = true;
    }

    function notAllowPublicMint() public onlyOwner {
        allowPublic = false;
    }


    function setWhiteListAddresses(address[] calldata _users) public onlyOwner {
        delete whiteListed;
        whiteListed = _users;
    }

    function setAllowListAddresses(address[] calldata _users) public onlyOwner {
        delete allowListed;
        allowListed = _users;
    }

    //#endregion OWNER
}
