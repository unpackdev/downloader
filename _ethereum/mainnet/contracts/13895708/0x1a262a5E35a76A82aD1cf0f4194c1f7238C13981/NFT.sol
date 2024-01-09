// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./IERC20.sol";

contract NFT is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    uint256 public cost;

    uint128 public maxPerTx;
    uint128 public maxMintAmount;
    uint256 public publicMintStartTime;

    IERC20 token;
    address private tokenRecipient;

    string public baseURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint256 _cost,
        uint128 _maxPerTx,
        uint128 _maxMintAmount,
        uint256 _mintStart,
        address _token,
        address _tokenRecipient
    ) public initializer {
        __ERC721_init("Society of Snowmen", "SOS");
        __ERC721Enumerable_init();
        __Ownable_init();

        publicMintStartTime = _mintStart;
        cost = _cost;
        maxMintAmount = _maxMintAmount;
        maxPerTx = _maxPerTx;
        token = IERC20(_token);
        tokenRecipient = _tokenRecipient;
    }

    /////////////////////////////////////////////////////////////
    // MINTING
    /////////////////////////////////////////////////////////////
    function mint(uint256 _mintAmount) public {
        uint256 supply = _tokenIdCounter.current();
        require(block.timestamp > publicMintStartTime, "mint locked");
        require(_mintAmount > 0, "amount must be >0");
        require(_mintAmount <= maxPerTx, "amount must < max");
        require(supply + _mintAmount <= maxMintAmount, "sold out!");

        token.transferFrom(msg.sender, tokenRecipient, cost * _mintAmount);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _mint(msg.sender, tokenId);
        }
    }

    function safeMint(address to) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    /////////////////////////////////////////////////////////////
    // ADMIN
    /////////////////////////////////////////////////////////////
    function withdraw() public onlyOwner {
        require(
            payable(owner()).send(address(this).balance),
            "could not withdraw"
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPublicMintStartTime(uint88 _time) public onlyOwner {
        publicMintStartTime = _time;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setRecipient(address _recipient) public onlyOwner {
        tokenRecipient = _recipient;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
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
