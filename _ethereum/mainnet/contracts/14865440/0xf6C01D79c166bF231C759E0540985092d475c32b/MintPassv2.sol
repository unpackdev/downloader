// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract MintPassV2 is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    uint16 public MAX_MEMBERS;
    uint64 public PRICE;
    address payable public DAO;

    CountersUpgradeable.Counter private _tokenIdCounter;

    event Rug(uint256 amount);
    event DAOChanged(address newDAO);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("MintPass", "PASS");
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        MAX_MEMBERS = 420;
        PRICE = 420 * 10**14;
        DAO = payable(0x8c9Abd867B7773586dB8882f03EF72b6CA36Ec6b);
        _initialMint();
    }

    receive() external payable {
        mint();
    }

    function mint() public payable returns (uint256) {
        require(msg.value == PRICE, "Minting price is incorrect");
        require(
            _tokenIdCounter.current() < MAX_MEMBERS,
            "Maximum number of members reached"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    function rug() external {
        uint256 balance = address(this).balance;
        address payable to = payable(DAO);
        to.transfer(address(this).balance);
        emit Rug(balance);
    }

    function setDAO(address newDAO) public onlyOwner {
        DAO = payable(newDAO);
        emit DAOChanged(DAO);
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "ipfs://bafyreieg3dt3zhbyxvttmabbqkyjxmwwr6wn6ohmv3vgzxcsus2k2ndgsy/metadata.json";
    }

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        return _baseURI();
    }

    function _initialMint() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

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

    function version() public pure returns (uint) {
        return 2;
    }
}
