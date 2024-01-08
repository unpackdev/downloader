// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";

/// @custom:security-contact security@afraidlabs.com
contract NFTYToken is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 public initialPrice;
    uint256 public renewalPrice;
    uint256 public constant TOKEN_MAXIMUM = 256;

    bool public purchasable;

    string public baseURI;

    address private constant A = 0xaCeeA607D0e1140d4D1f698FaCb440C674b856a3;
    address private constant B = 0x69827Bf658898541380f78e0FBaF920ff020203b;

    mapping(uint256 => uint256) public tokenExpiry;

    CountersUpgradeable.Counter private _tokenCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() external initializer {
        __ERC721_init("NFTYToken", "NFTY");
        __Ownable_init();
        __UUPSUpgradeable_init();

        initialPrice = 2 ether;
        renewalPrice = 0.5 ether;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _isExpired(uint256 tokenId) internal view returns (bool) {
        return block.timestamp > tokenExpiry[tokenId];
    }

    function _isTransferrable(uint256 tokenId) internal view returns (bool) {
        return
            (!_isExpired(tokenId) &&
                (tokenExpiry[tokenId] - block.timestamp > 1 weeks)) ||
            msg.sender == owner();
    }

    function setURI(string calldata newuri) external onlyOwner {
        baseURI = newuri;
    }

    function setInitialPrice(uint256 price) external onlyOwner {
        initialPrice = price;
    }

    function setRenewalPrice(uint256 price) external onlyOwner {
        renewalPrice = price;
    }

    function toggleSale() external onlyOwner {
        purchasable = !purchasable;
    }

    function batchIssue(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            _tokenCounter.increment();
            _mint(addresses[i], _tokenCounter.current());
        }
    }

    function batchUpdateExpiry(uint256[][] calldata data) external onlyOwner {
        for (uint256 i; i < data.length; i++) {
            tokenExpiry[data[i][0]] = data[i][1];
        }
    }

    function purchase() external payable {
        uint256 supply = _tokenCounter.current();
        require(purchasable, "NFTYToken: Sale is not live");
        require(msg.value >= initialPrice, "NFTYToken: Invalid ether amount");
        require(
            supply + 1 <= TOKEN_MAXIMUM,
            "NFTYToken: Exceeds supply maximum"
        );

        _tokenCounter.increment();

        uint256 tokenId = supply + 1;
        tokenExpiry[tokenId] = block.timestamp + 30 days;
        _safeMint(msg.sender, tokenId);
    }

    function renew(uint256 tokenId) external payable {
        require(_exists(tokenId), "NFTYToken: Token does not exist");
        require(msg.value >= renewalPrice, "NFTYToken: Invalid ether amount");

        if (_isExpired(tokenId)) {
            tokenExpiry[tokenId] = block.timestamp + 30 days;
        } else {
            tokenExpiry[tokenId] += 30 days;
        }
    }

    function expiryTime(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "NFTYToken: Token does not exist");

        return tokenExpiry[tokenId];
    }

    function setExpiryTime(uint256 tokenId, uint256 time) external onlyOwner {
        require(_exists(tokenId), "NFTYToken: Token does not exist");

        tokenExpiry[tokenId] = time;
    }

    function withdrawBalance() external onlyOwner {
        uint256 share = address(this).balance / 2;

        (bool a, ) = A.call{value: share}("");
        (bool b, ) = B.call{value: share}("");

        require(a && b, "NFTYToken: Failed to withdraw");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        if (from != address(0) || to != address(0)) {
            require(
                _isTransferrable(tokenId),
                "NFTYToken: Token must have at least 1 week remaining"
            );
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
