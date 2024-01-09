// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./IERC20.sol";
import "./ISNWSkillCard.sol";

contract SkillCardDataV1 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // lib
    using AddressUpgradeable for address;

    // struct
    struct CardData{
        string name;
        uint256 rank;
        uint256 level;
    }

    // constant
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant SIGN_ROLE = keccak256("SIGN_ROLE");
    bytes32 public constant EDIT_ROLE = keccak256("EDIT_ROLE");

    // store
    bytes32 public DOMAIN_SEPARATOR;
    ISNWSkillCard public skillCardAddress;
    mapping(uint256 => CardData) public cardDatas;

    // event
    event UploadData(uint256 indexed tokenID);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address skillCard
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(SIGN_ROLE, msg.sender);
        _setupRole(EDIT_ROLE, msg.sender);

        skillCardAddress = ISNWSkillCard(skillCard);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SkillCardData")),
                keccak256(bytes("1.0")),
                block.chainid,
                address(this)
            )
        );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function uploadData(uint256 tokenID, string calldata name, uint256 rank, uint256 level, uint256 deadline) public onlyRole(EDIT_ROLE){
        require(block.timestamp < deadline, "expired");

        cardDatas[tokenID].name = name;
        cardDatas[tokenID].rank = rank;
        cardDatas[tokenID].level = level;

        emit UploadData(tokenID);
    }
}
