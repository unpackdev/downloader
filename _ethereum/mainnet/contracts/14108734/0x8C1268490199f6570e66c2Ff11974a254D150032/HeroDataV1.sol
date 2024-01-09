// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./IERC20.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ISNWHero.sol";
import "./ISNWSkillCard.sol";
import "./ISkillCardData.sol";

contract HeroDataV1 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // lib
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // struct
    struct BaseData {
        string name;
        string job;
        uint32 rank;
        uint32 level;
        uint32 gen;
    }
    struct AppearData {
        uint32 part1;
        uint32 part2;
        uint32 part3;
        uint32 part4;
        uint32 part5;
    }
    struct PropData {
        uint32 strength;
        uint32 dexterity;
        uint32 constitution;
        uint32 intelligence;
        uint32 strengthGrow;
        uint32 dexterityrow;
        uint32 constitutionrow;
        uint32 intelligencerow;
    }

    // constant
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant SIGN_ROLE = keccak256("SIGN_ROLE");
    bytes32 public constant EDIT_ROLE = keccak256("EDIT_ROLE");
    bytes32 public constant LEARN_SKILL_TYPEHASH =
        keccak256(
            "learnSkill(uint256 heroTokenID,uint256 skillTokenID,uint256 replaceSkill,uint256 deadline)"
        );
    bytes32 public constant CHANGE_NAME_TYPEHASH =
        keccak256(
            "changeName(uint256 heroTokenID,string newName,uint256 deadline)"
        );

    // store
    bytes32 public DOMAIN_SEPARATOR;
    ISNWHero public heroAddress;
    ISNWSkillCard public skillAddress;
    ISkillCardData public skillDataAddress;

    mapping(uint256 => BaseData) public baseDatas;
    mapping(uint256 => AppearData) public appearDatas;
    mapping(uint256 => PropData) public propDatas;
    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private _heroSkills;

    // event
    event UploadData(uint256 indexed tokenID);
    event LearnSkill(
        address indexed user,
        uint256 indexed heroTokenID,
        uint256 indexed skillTokenID
    );
    event ChangeName(
        address indexed user,
        uint256 indexed tokenID,
        string oldName,
        string newName
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address hero,
        address skillCard,
        address skillCardData
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(SIGN_ROLE, msg.sender);
        _setupRole(EDIT_ROLE, msg.sender);

        heroAddress = ISNWHero(hero);
        skillAddress = ISNWSkillCard(skillCard);
        skillDataAddress = ISkillCardData(skillCardData);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("HeroData")),
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

    function learnSkill(
        uint256 heroTokenID,
        uint256 skillTokenID,
        uint256 replaceSkill,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) public {
        require(block.timestamp <= deadline, "Signature expired");
        require(msg.sender == heroAddress.ownerOf(heroTokenID), "no hero");
        require(msg.sender == skillAddress.ownerOf(skillTokenID), "no skill");

        // sign
        bytes32 structHash = keccak256(
            abi.encode(
                LEARN_SKILL_TYPEHASH,
                address(msg.sender),
                heroTokenID,
                skillTokenID,
                replaceSkill,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        _checkRole(SIGN_ROLE, ecrecover(digest, v, r, s));

        // learn skill
        skillAddress.forceBurn(skillTokenID);
        _heroSkills[heroTokenID].add(skillTokenID);

        if (replaceSkill > 0) {
            _heroSkills[heroTokenID].remove(replaceSkill);
        }

        // event
        emit LearnSkill(msg.sender, heroTokenID, skillTokenID);
    }

    function getHeroSkills(uint256 tokenID)
        public
        view
        returns (uint256[] memory result)
    {
        result = _heroSkills[tokenID].values();
    }

    function changeName(
        uint256 tokenID,
        string calldata newName,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) public {
        require(block.timestamp <= deadline, "Signature expired");
        require(msg.sender == heroAddress.ownerOf(tokenID), "no hero");

        // sign
        bytes32 structHash = keccak256(
            abi.encode(
                CHANGE_NAME_TYPEHASH,
                address(msg.sender),
                tokenID,
                keccak256(bytes(newName)),
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        _checkRole(SIGN_ROLE, ecrecover(digest, v, r, s));

        // change name
        string memory oldName = baseDatas[tokenID].name;
        baseDatas[tokenID].name = newName;

        // event
        emit ChangeName(msg.sender, tokenID, oldName, newName);
    }

    function uploadData(
        uint256 tokenID,
        string[] calldata strParam,
        uint32[] calldata param,
        uint256 deadline
    ) public onlyRole(EDIT_ROLE) {
        require(block.timestamp < deadline, "expired");

        baseDatas[tokenID].name = strParam[0];
        baseDatas[tokenID].job = strParam[1];
        baseDatas[tokenID].rank = param[0];
        baseDatas[tokenID].level = param[1];
        baseDatas[tokenID].gen = param[2];

        appearDatas[tokenID].part1 = param[3];
        appearDatas[tokenID].part2 = param[4];
        appearDatas[tokenID].part3 = param[5];
        appearDatas[tokenID].part4 = param[6];
        appearDatas[tokenID].part5 = param[7];

        propDatas[tokenID].strength = param[8];
        propDatas[tokenID].dexterity = param[9];
        propDatas[tokenID].constitution = param[10];
        propDatas[tokenID].intelligence = param[11];
        propDatas[tokenID].strengthGrow = param[12];
        propDatas[tokenID].dexterityrow = param[13];
        propDatas[tokenID].constitutionrow = param[14];
        propDatas[tokenID].intelligencerow = param[15];

        if (_heroSkills[tokenID].length() <= 0){
            forceLearnSkill(tokenID, strParam[2], param[16], param[17], deadline);
        }

        emit UploadData(tokenID);
    }

    function forceLearnSkill(
        uint256 heroTokenID,
        string calldata name,
        uint256 rank,
        uint256 level,
        uint256 deadline
    ) public onlyRole(EDIT_ROLE) {
        require(block.timestamp <= deadline, "Signature expired");

        address owner = heroAddress.ownerOf(heroTokenID);
        uint256 skillTokenID = skillAddress.safeMint(owner);

        // upload skill data
        skillDataAddress.uploadData(skillTokenID, name, rank, level, deadline);

        // learn skill
        skillAddress.forceBurn(skillTokenID);
        _heroSkills[heroTokenID].add(skillTokenID);

        // event
        emit LearnSkill(msg.sender, heroTokenID, skillTokenID);
    }
}
