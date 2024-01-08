// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ENSReverseRegistration.sol";
import "./MerkleProof.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./MulticallUpgradeable.sol";
import "./ERC721DeckUpgradeable.sol";
import "./Whitelisted.sol";
import "./WithPayment.sol";


contract Raccoons is
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC721DeckUpgradeable,
    MulticallUpgradeable,
    WithPayment,
    Whitelisted
{
    uint256 public  price;
    uint256 public  limit;
    string  private baseURI;

    mapping(bytes32 => mapping(address => uint256)) public minted;

    event Sale(bytes32 whitelistRoot, uint256 price, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer
    {}

    function initialize(
        string memory __name,
        string memory __symbol,
        uint256       __length,
        string memory __baseUri
    )
    public
        initializer()
    {
        __Ownable_init();
        __ERC721_init(__name, __symbol);
        __ERC721Deck_init(__length);

        baseURI = __baseUri;

        _setWhitelist(0x000000000000000000000000000000000000000000000000000000000000dead);
    }

    /**
    * Lazy-minting
    */
    function mintAdmin(address to, uint256 count)
    external
        onlyRemaining(count)
        onlyOwner()
    {
        for (uint256 i = 0; i < count; ++i) {
            _mint(to);
        }
    }

    function mint(uint256 count, uint256 quota, bytes32[] calldata proof)
    external payable
        onlyRemaining(count + limit)
        withPayment(count * price, payable(owner()))
        onlyWhitelisted(keccak256(abi.encodePacked(_msgSender(), quota)), proof)
    {
        if (quota > 0) {
            uint256 amount = minted[getWhitelist()][_msgSender()] += count;
            require(amount <= quota, 'Whitelist quota reached');
        }

        for (uint256 i = 0; i < count; ++i) {
            _mint(_msgSender());
        }
    }

    /**
    * Admin operations: ens reverse registration
    */
    function startSale(bytes32 whitelistRoot, uint256 amount, uint256 unitPrice)
    external
        onlyOwner()
    {
        _setWhitelist(whitelistRoot);
        price = unitPrice;
        limit = remaining() > amount ? remaining() - amount : 0;
        emit Sale(whitelistRoot, price, amount);
    }

    function setName(address ensRegistry, string calldata ensName)
    external
        onlyOwner()
    {
        ENSReverseRegistration.setName(ensRegistry, ensName);
    }

    function setBaseURI(string calldata newBaseURI)
    external
        onlyOwner()
    {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseURI;
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721DeckUpgradeable) {
        super._burn(tokenId);
    }
}
