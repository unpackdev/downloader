// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721WithPermitUpgradable.sol";
import "./IDeNFT.sol";

contract DeNFT is ERC721WithPermitUpgradable, IDeNFT {
    using StringsUpgradeable for uint256;

    /* ========== STATE VARIABLES ========== */

    mapping(uint256 => string) private _tokenURIs;

    string private _baseURIValue;

    address minter;
    address deNFTBridge;

    /* ========== ERRORS ========== */

    error MinterBadRole();
    error ZeroAddress();
    error WrongLengthOfArguments();

    /* ========== MODIFIER ========== */

    modifier onlyMinter() {
        if (minter != msg.sender) revert MinterBadRole();
        _;
    }

    /* ========== EVENTS ========== */

    event MinterTransferred(address indexed previousMinter, address indexed newMinter);

    /* ========== CONSTRUCTOR  ========== */

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address minter_,
        address deNFTBridge_
    ) public initializer {
        if (deNFTBridge_ == address(0) || minter_ == address(0)) revert ZeroAddress();
        __DeNFT_init(name_, symbol_, baseURI_, minter_, deNFTBridge_);
    }

    function __DeNFT_init(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address minter_,
        address deNFTBridge_
    ) internal initializer {
        __ERC721WithPermitUpgradable_init(name_, symbol_);
        __ERC721WithPermitUpgradable_init_unchained(baseURI_, minter_, deNFTBridge_);
    }

    function __ERC721WithPermitUpgradable_init_unchained(
        string memory baseURI_,
        address minter_,
        address deNFTBridge_
    ) internal initializer {
        minter = minter_;
        _baseURIValue = baseURI_;
        deNFTBridge = deNFTBridge_;
    }

    /* ========== PUBLIC METHODS  ========== */

    /// @dev Issues a new token
    /// @param _to new Token's owner
    /// @param _tokenId new Token's id
    /// @param _tokenUri new Token's id
    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenUri
    ) external override onlyMinter {
        _tokenURIs[_tokenId] = _tokenUri;
        _safeMint(_to, _tokenId);
    }

    /// @dev Issues multiple objects at once, taking each object's ID and URI
    /// @dev from the given arrays, and transfers each object to the sender
    function mintMany(
         uint[] memory _tokenIds, string[] memory _tokenUris
    ) external  onlyMinter {
        mintMany(msg.sender, _tokenIds, _tokenUris);
    }

    /// @dev Issues multiple objects at once, taking each object's ID and URI
    /// @dev from the given arrays, and transfers each object to the given recipient
    function mintMany(
        address _to,
        uint256[] memory _tokenIds,
        string[] memory _tokenUris
    ) public onlyMinter {
        if (_tokenIds.length != _tokenUris.length) revert WrongLengthOfArguments();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            _tokenURIs[tokenId] = _tokenUris[i];
            _safeMint(_to, tokenId);
        }
    }

    /// @dev Issues multiple objects at once, taking each object's ID, URI and
    /// @dev desirable recipient @dev from the given arrays
    function mintMany(
        address[] memory _to,
        uint256[] memory _tokenIds,
        string[] memory _tokenUris
    ) external onlyMinter {
        if (_tokenIds.length != _to.length || _tokenIds.length != _tokenUris.length)
            revert WrongLengthOfArguments();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            _tokenURIs[tokenId] = _tokenUris[i];
            _safeMint(_to[i], tokenId);
        }
    }

    function transferMinter(address nextMinter) external onlyMinter {
        emit MinterTransferred(minter, nextMinter);
        minter = nextMinter;
    }

    /// @dev Gives away minter rights to the deBridge NFT gate
    /// @dev to make this collection's NFT objects natively transferrable to
    /// @dev and from chains supported by deBridge.
    function giveawayToDeNFTBridge() external onlyMinter {
        emit MinterTransferred(minter, deNFTBridge);
        minter = deNFTBridge;
    }

    /// @dev Destroys the existing token
    /// @param _tokenId Id of token
    function burn(uint256 _tokenId) public virtual override {
        // code from @openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );

        _burn(_tokenId);

        // code from @openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol
        if (bytes(_tokenURIs[_tokenId]).length != 0) {
            delete _tokenURIs[_tokenId];
        }
    }

    /* ========== VIEWS  ========== */

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    /**
     * Actual implementation taken from openzeppelin's /contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }
}
