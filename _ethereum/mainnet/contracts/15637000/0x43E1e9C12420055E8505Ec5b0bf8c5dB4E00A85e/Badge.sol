// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155Upgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./console.sol";
import "./Utils.sol";

contract Badge is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    mapping(uint256 => string) public ipfsHashMap;
    string private _uri;

    event BadgePublished(
        address indexed publisher,
        uint256 indexed badgeId,
        string ipfsHash
    );
    event BadgeClaimed(
        uint256 indexed badgeId,
        address indexed to,
        uint256 amount
    );

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");

    uint256 private constant PUBLISHER_OFFSET_MULTIPLIER = uint256(2)**(256 - 160);
    uint256 private constant PUBLISHER_OFFSET = 256 - 160;
    uint256 private constant PUBLISHER_MASK =  0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF << PUBLISHER_OFFSET;
  
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory _initUri) public initializer {
        __ERC1155_init("");
        __AccessControl_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _uri = _initUri;
    }

    function setMinter(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function setPublisher(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(PUBLISHER_ROLE, account);
    }

    function setURI(string memory _newUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _uri = _newUri;
    }
   
    function publish(
        string memory ipfsHash
    ) public {
        address sender = msg.sender;
        if (getRoleMemberCount(PUBLISHER_ROLE) == 0) {
            _publish(sender, ipfsHash);
        } else if (hasRole(PUBLISHER_ROLE, sender)) {
            _publish(sender, ipfsHash);
        } else {
            revert("publish: Unauthorized");
        }
    }

    function mint(
        address to,
        uint256 badgeId,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        require(balanceOf(to, badgeId) == 0, "mint: already minted");
        _mint(to, badgeId, amount, data);
        emit BadgeClaimed(badgeId, to, amount);
    }

    function uri(uint256 badgeId) public view override returns (string memory) {
        require(wasPublished(badgeId), "uri: this badge id was never published"); 
        return _getFullUri(badgeId);
    }

    function wasPublished(uint256 badgeId) public view returns (bool) {
        console.log(getIpfsHashByBadgeId(badgeId));
        return keccak256(abi.encodePacked(getIpfsHashByBadgeId(badgeId))) != keccak256(abi.encodePacked(""));
    }

    function getIpfsHashByBadgeId(uint256 badgeId)
        public
        view
        returns (string memory)
    {
        return ipfsHashMap[badgeId];
    }

    function getCurrentTokenIdForTest() public view returns (uint256) {
        return _tokenIds.current();
    }

    function _getFullUri(uint256 badgeId) private view returns (string memory) {
        string memory _ipfsHash = getIpfsHashByBadgeId(badgeId);
        return
            string(
                abi.encodePacked(
                    _uri,
                    _ipfsHash
                )
            );
    }

    function version() public pure returns (string memory) {
        return "1";
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function _publish(address publisher, string memory ipfsHash) private {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        // owner (160) / Counter Token ID (96)
        uint256 _badgeId = uint256(uint160(publisher)) * PUBLISHER_OFFSET_MULTIPLIER + // Publisher
            newTokenId; // Counter Token ID
        console.log("Badge ID: %s", _badgeId);
        ipfsHashMap[_badgeId] = ipfsHash;

        emit BadgePublished(
            publisher,
            _badgeId,
            ipfsHash
        );
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        require(
            (from == address(0) && to != address(0)) || (from != address(0) && to == address(0)),
            "Transfer not allowed"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC1155Upgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}