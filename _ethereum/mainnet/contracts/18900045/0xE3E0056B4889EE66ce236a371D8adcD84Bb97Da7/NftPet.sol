// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC1155Upgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./ERC1155URIStorageUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract NftPet is
    Initializable,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC1155URIStorageUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 private _tokenIdCounter;

    string public name;
    string public symbol;

    error ArrayLengthMismatch();
    error TokenDoesNotExists();

    event UpdatedURIs(uint256[] tokenId, string[] newUri);
    event UpdatedDefaultRoyalty(address receiver, uint256 feeNumerator);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _initialOwner,
        string[] memory _tokenUris,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) public initializer {
        // __ERC1155_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();
        __Ownable_init(_initialOwner);
        name = _name;
        symbol = _symbol;

        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
        // Minting tokens
        _mintBatch(_initialOwner, _tokenUris);
    }

    function adminMint(
        address to,
        uint256 amount,
        string memory tokenUri
    ) external onlyOwner {
        uint256 tokenId = _incrementTokenId();
        _setURI(tokenId, tokenUri);
        _mint(to, tokenId, amount, "");
    }

    function updateURI(
        uint256[] memory tokenIds,
        string[] memory newUris
    ) external onlyOwner {
        if (tokenIds.length != newUris.length) {
            revert ArrayLengthMismatch();
        }
        uint256 lengthOfTokens = tokenIds.length;
        for (uint256 itr = 0; itr < lengthOfTokens; itr++) {
            if (!exists(tokenIds[itr])) {
                revert TokenDoesNotExists();
            }
            _setURI(tokenIds[itr], newUris[itr]);
        }

        emit UpdatedURIs(tokenIds, newUris);
    }

    function updateDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit UpdatedDefaultRoyalty(receiver, feeNumerator);
    }

    function getLatestTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function _mintBatch(address to, string[] memory tokenUris) internal {
        uint256 tokenUrisLength = tokenUris.length;
        uint256[] memory ids = new uint256[](tokenUrisLength);
        uint256[] memory values = new uint256[](tokenUrisLength);

        uint256 tokenAmounts = 998;
        uint8 itr = 0;
        while (itr < tokenUrisLength) {
            ids[itr] = _incrementTokenId();
            values[itr] = tokenAmounts;
            _setURI(ids[itr], tokenUris[itr]);
            itr++;
        }

        _mintBatch(to, ids, values, "");
    }

    function _incrementTokenId() internal returns (uint256) {
        return ++_tokenIdCounter;
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155SupplyUpgradeable, ERC1155Upgradeable) {
        super._update(from, to, ids, values);
    }

    function uri(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
        returns (string memory)
    {
        return super.uri(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC2981Upgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
