// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
/// @custom:security-contact thomasjbrown@gmail.com
contract ERC721Custom is
Initializable,
ERC721Upgradeable,
ERC721URIStorageUpgradeable,
PausableUpgradeable,
OwnableUpgradeable,
ERC721BurnableUpgradeable,
UUPSUpgradeable,
ReentrancyGuard
{
    using Strings for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    string private baseURI;
    uint public maxOfferCount = 905;                  // Max # NFTs to be added
    uint public offerCount;                     // Index of the current buyable NFT in that type. offCount=0 means no NFT is left in that type
    mapping(address => bool) public userList;  // user Address-to-claimable-amount mapping
    bool public requireWhitelist = true;        // If require whitelist
    mapping(address => bool) public whitelist;  // whitelist users Address-to-claimable-amount mapping

    function initialize(string memory _name, string memory _symbol)
    public
    initializer
    {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract.');
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function setRequireWhitelist(bool _requireWhitelist) public onlyOwner {
        requireWhitelist = _requireWhitelist;
    }

    function safeMint() public callerIsUser nonReentrant {
        require(!requireWhitelist || (requireWhitelist && whitelist[msg.sender]), "whitelisting for external users is disabled");
        require(!userList[msg.sender], "Allow only to purchase an NFT");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxOfferCount, "Reached maxOfferCount");
        _tokenIdCounter.increment();
        userList[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
        offerCount++;
    }


    function setWhitelist(address _whitelisted) public onlyOwner {
        whitelist[_whitelisted] = true;
    }

    function setWhitelistBatch(address[] calldata _whitelisted) public onlyOwner {
        for (uint i = 0; i < _whitelisted.length; i++) {
            whitelist[_whitelisted[i]] = true;
        }
    }

    function changeBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
    {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        string memory uriSuffix = Strings.toString(tokenId);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, uriSuffix)) : '';
    }
    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback() external {
        revert();
    }
}
