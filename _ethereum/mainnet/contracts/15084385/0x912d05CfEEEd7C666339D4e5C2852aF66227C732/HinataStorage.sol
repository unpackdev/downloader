// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC1155PresetMinterPauserUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract HinataStorage is
    Initializable,
    ERC1155PresetMinterPauserUpgradeable,
    IERC1155ReceiverUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Collection {
        address owner;
        uint256 royaltyFee;
        uint256 royalty;
    }

    address public hinata;
    address public weth;
    mapping(address => mapping(uint256 => bool)) public allowedIds;

    string public baseURI;
    mapping(uint256 => string) public uris;
    mapping(uint256 => address) public artists;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Ownable: caller is not the owner");
        _;
    }

    function initialize(
        address[] memory owners,
        address _hinata,
        address _weth
    ) public initializer {
        __ERC1155PresetMinterPauser_init("");
        __UUPSUpgradeable_init();

        hinata = _hinata;
        weth = _weth;

        for (uint256 i = 0; i < owners.length; ++i) {
            _setupRole(DEFAULT_ADMIN_ROLE, owners[i]);
        }
        grantRole(MINTER_ROLE, hinata);
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    modifier onlyArtist() {
        require(hasRole(MINTER_ROLE, msg.sender), "Ownable: caller is not the artist");
        _;
    }

    function addArtist(address _user) public {
        grantRole(MINTER_ROLE, _user);
    }

    function addArtists(address[] calldata _users) external {
        uint256 len = _users.length;
        for (uint256 i; i < len; i += 1) {
            addArtist(_users[i]);
        }
    }

    function allowTokenIdsForArtist(
        address _user,
        uint256[] calldata _tokenIds,
        bool[] calldata _approved
    ) external onlyAdmin {
        require(_tokenIds.length == _approved.length, "Hinata: INVALID_ARGUMENTS");

        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; i += 1) {
            allowedIds[_user][_tokenIds[i]] = _approved[i];
        }
    }

    function removeArtist(address _user) public {
        revokeRole(MINTER_ROLE, _user);
    }

    function removeArtists(address[] calldata _users) external {
        uint256 len = _users.length;
        for (uint256 i; i < len; i += 1) {
            removeArtist(_users[i]);
        }
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

    function mintArtistNFT(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyArtist {
        if (artists[id] == address(0)) artists[id] = msg.sender;
        require(artists[id] == msg.sender, "Hinata: NOT_OWNER");
        mint(msg.sender, id, amount, data);
    }

    function mintBatchArtistNFT(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) external onlyArtist {
        for (uint256 i; i < ids.length; i += 1) {
            if (artists[ids[i]] == address(0)) artists[ids[i]] = msg.sender;
            require(artists[ids[i]] == msg.sender, "Hinata: NOT_OWNER");
        }
        mintBatch(msg.sender, ids, amounts, data);
    }

    function mintAirdropNFT(
        address receiver,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        require(hinata == msg.sender);
        mint(receiver, id, amount, data);
    }

    function setBaseURI(string memory baseURI_) external onlyAdmin {
        baseURI = baseURI_;
    }

    function setURI(uint256 id, string memory uri_) external onlyAdmin {
        uris[id] = uri_;
    }

    function uri(uint256 id) public view override returns (string memory) {
        if (bytes(uris[id]).length > 0) return uris[id];
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}
