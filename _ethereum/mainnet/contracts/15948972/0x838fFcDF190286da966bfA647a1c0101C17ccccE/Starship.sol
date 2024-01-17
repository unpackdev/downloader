// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/**
 *__/\\\______________/\\\_____/\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\___
 * _\/\\\_____________\/\\\___/\\\\\\\\\\\\\___/\\\///////\\\___\/\\\/////////\\\_
 *  _\/\\\_____________\/\\\__/\\\/////////\\\_\/\\\_____\/\\\___\/\\\_______\/\\\_
 *   _\//\\\____/\\\____/\\\__\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/__
 *    __\//\\\__/\\\\\__/\\\___\/\\\\\\\\\\\\\\\_\/\\\//////\\\____\/\\\/////////____
 *     ___\//\\\/\\\/\\\/\\\____\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________
 *      ____\//\\\\\\//\\\\\_____\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________
 *       _____\//\\\__\//\\\______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\_____________
 *        ______\///____\///_______\///________\///__\///________\///__\///______________
 **/

// Openzeppelin
import "./ERC721EnumerableUpgradeable.sol";
import "./Strings.sol";

// helpers
import "./WarpBaseUpgradeable.sol";

// interfaces
import "./IMarketPlace.sol";
import "./IStarship.sol";

/** Pioneer index is 11 */

contract Starship is IStarship, ERC721EnumerableUpgradeable, WarpBaseUpgradeable {
    using Strings for uint256;

    address public starshipControl;
    address public marketPlace;
    string public baseUri;

    mapping(address => bool) callers;
    mapping(uint256 => bool) pioneer;

    /** ======== Modifiers ======== */
    modifier onlyCallers() {
        require(callers[msg.sender], 'Must be a caller');
        _;
    }

    /** ======== Init ======== */
    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC721_init(_name, _symbol);
        __WarpBase_init();
    }

    /**
     *  @notice allow mint for bond
     *  @param _to address
     *  @param _tokenId uint256
     */
    function mint(
        address _to,
        uint256 _tokenId,
        bool _isPioneer
    ) external override onlyCallers {
        require(_exists(_tokenId) == false, 'Token already exists');

        if (_isPioneer) pioneer[_tokenId] = _isPioneer;

        _mint(_to, _tokenId);
    }

    /**
     *  @notice allow mint for bond
     *  @param _tokenId uint256
     */
    function burn(uint256 _tokenId) external override onlyCallers {
        require(_exists(_tokenId), 'Token does not exists');

        _burn(_tokenId);
    }

    /** @notice external function for existent token */
    function exists(uint256 _tokenId) external view override returns (bool) {
        return _exists(_tokenId);
    }

    /** @notice external function for existent token */
    function isPioneer(uint256 _tokenId) external view override returns (bool) {
        return pioneer[_tokenId];
    }

    /** ===== setters ====== */

    /** @notice setStarships */
    function setMarketplace(address _address) external onlyOwner {
        marketPlace = _address;
    }

    /** @notice set base uri */
    function setBaseUri(string memory _uri) external onlyOwner {
        baseUri = _uri;
    }

    /** @notice set caller */
    function setCaller(address caller, bool isCaller) external onlyOwner {
        callers[caller] = isCaller;
    }

    /** @notice manager transfer ship */
    function managerTransfer(
        uint256 shipId,
        address from,
        address to
    ) external onlyOwner {
        _safeTransfer(from, to, shipId, '');
    }

    /** ====== Before token transfer ====== */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // Can not transfer pioneer ships.
        require(!pioneer[tokenId], 'TRANSFER: Pioneer ships can not be transferred');

        // Let the partsMarket know the part has been transferred
        if (from != address(0) && marketPlace != address(0)) {
            IMarketPlace(marketPlace).delistShip(tokenId);
        }
    }

    /** ===== Token URI ===== */

    /** @dev tokenUri */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, IStarship)
        returns (string memory)
    {
        require(_exists(tokenId), 'Token does not exist');

        return string(abi.encodePacked(baseUri, tokenId.toString()));
    }
}
