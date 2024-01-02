// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ILeetCollective.sol";
import "./ILeetCollectiveRenderer.sol";
import "./LeetERC721.sol";

import "./Ownable.sol";
import "./IERC721.sol";
import "./LibString.sol";
import "./Base64.sol";

contract LeetCollective is ERC721L, ILeetCollective, Ownable {
    string private constant DESCRIPTION =
        "1337 is a collective of web3 creators and builders dedicated to furthering CC0 culture and pushing onchain boundaries";

    struct Member {
        uint16 role;
        uint16 token;
        int16 skull;
        string name;
        string bio;
    }

    struct Role {
        string name;
        string color;
    }

    mapping(address => Member) public members;
    mapping(uint256 => Role) private _roles;

    bool private _isOpen = false;

    address private _renderer;
    address private _skulls;

    error GetLostNoob();
    error MemberAlreadyExists();
    error MemberDoesNotExist();
    error RoleAlreadyExists();
    error RoleDoesNotExist();
    error NotOpen();
    error TransfersDisabled();

    constructor(address renderer, address skulls) ERC721L("1337 Collective", "1337C", DESCRIPTION) {
        _renderer = renderer;
        _skulls = skulls;

        _roles[532] = Role("532", "#00FF00");
        _roles[1337] = Role("force", "#00FFFF");
        _roles[9357] = Role("fren", "#0000FF");
        _roles[200] = Role("skull", "#FF0000");
        _roles[202] = Role("noob", "#FFFFFF");
        _roles[1393] = Role("legend", "#FFFF00");
        _roles[403] = Role("banhammered", "#000000");
    }

    modifier serOrOwner() {
        require(owner() == msg.sender || members[msg.sender].role == 532);
        _;
    }

    // ======== ILeetCollective methods ========

    function nameOf(address member) external view returns (string memory) {
        return members[member].name;
    }

    function roleOf(address member) external view returns (uint16) {
        return members[member].role;
    }

    function roleNameOf(address member) external view returns (string memory) {
        return _roles[members[member].role].name;
    }

    // ======== Team Member methods ========

    function addMember(address member, string memory name, uint16 role) external serOrOwner {
        if (members[member].role != 0) revert MemberAlreadyExists();
        if (keccak256(abi.encodePacked(_roles[role].name)) == keccak256(abi.encodePacked(""))) {
            revert RoleDoesNotExist();
        }

        string memory invitor;
        if (owner() == msg.sender) {
            invitor = "the Owner";
        } else {
            invitor = string.concat("532", members[msg.sender].name);
        }
        string memory bio = string.concat(
            name,
            " was invited to the 1337 Collective by ",
            invitor,
            " in block #",
            LibString.toString(block.number),
            ". They have not set their own Bio!"
        );

        uint256 tokenId = _mint(member);
        members[member] = Member(role, uint16(tokenId), -1, name, bio);
    }

    /*
    * @notice Enroll in the 1337 Collective as a skull holder
    */
    function enroll(string memory name, string memory bio, uint256 skull) external {
        if (members[msg.sender].role != 0) revert MemberAlreadyExists();
        if (IERC721(_skulls).ownerOf(skull) != msg.sender) revert NotTokenOwner();

        uint256 tokenId = _mint(msg.sender);
        // Safe to cast skull to int16 as skull collection only has 7331 tokens
        members[msg.sender] = Member(uint16(uint256(200)), uint16(tokenId), int16(uint16(skull)), name, bio);
    }

    /*
    * @notice Join the 1337 Collective without being a skull holder
    */
    function join(string memory name, string memory bio) external {
        if (!_isOpen) revert NotOpen();
        if (members[msg.sender].role != 0) revert MemberAlreadyExists();
        uint256 tokenId = _mint(msg.sender);
        members[msg.sender] = Member(uint16(uint256(202)), uint16(tokenId), -1, name, bio);
    }

    function changeRole(address member, uint16 role) external serOrOwner {
        if (members[member].role == 0) revert MemberDoesNotExist();
        if (keccak256(abi.encodePacked(_roles[role].name)) == keccak256(abi.encodePacked(""))) {
            revert RoleDoesNotExist();
        }

        members[member].role = role;
    }

    function changeMyName(string memory newName) external {
        uint16 role = members[msg.sender].role;
        if (role == 0 || role == 403) revert GetLostNoob();

        members[msg.sender].name = newName;
    }

    function changeMySkull(uint256 skull) external {
        uint16 role = members[msg.sender].role;
        if (role == 0 || role == 403) revert GetLostNoob();
        if (IERC721(_skulls).ownerOf(skull) != msg.sender) revert NotTokenOwner();

        if (members[msg.sender].role == 202) {
            members[msg.sender].role = 200;
        }

        // Safe to case skull to int16 as skull collection only has 7331 tokens
        members[msg.sender].skull = int16(uint16(skull));
    }

    function changeMyBio(string memory newBio) external {
        uint16 role = members[msg.sender].role;
        if (role == 0 || role == 403) revert GetLostNoob();

        members[msg.sender].bio = newBio;
    }

    /*
    * @notice Returns a json listing all members
    */
    function membersJson() external view returns (string memory) {
        if (ERC721L.totalSupply() == 0) {
            return "{}";
        }

        uint256 i;
        address memberAddr;
        Member memory member;
        string memory json = '{"members":[';
        while (i < ERC721L.totalSupply()) {
            memberAddr = ERC721L.ownerOf(i);
            member = members[memberAddr];
            json = string.concat(json, '{"name":"', member.name, '","role":"', _roles[member.role].name, '","skull":"');

            if (member.skull >= 0) {
                json = string.concat(json, LibString.toString(member.skull));
            } else {
                json = string.concat(json, "null");
            }
            json = string.concat(json, '"}');

            ++i;
            if (i < ERC721L.totalSupply()) {
                json = string.concat(json, ",");
            }
        }
        json = string.concat(json, "]}");
        return json;
    }

    function memberInfo(address member) external view returns (string memory, string memory, string memory, int16) {
        Member memory m = members[member];
        return (m.name, _roles[m.role].name, m.bio, m.skull);
    }

    function membersInfo(address[] calldata memberAddresses)
        external
        view
        returns (string[] memory, string[] memory, string[] memory, int16[] memory)
    {
        string[] memory names = new string[](memberAddresses.length);
        string[] memory roles = new string[](memberAddresses.length);
        string[] memory bios = new string[](memberAddresses.length);
        int16[] memory skulls = new int16[](memberAddresses.length);
        for (uint256 i = 0; i < memberAddresses.length; ++i) {
            Member memory m = members[memberAddresses[i]];
            names[i] = m.name;
            roles[i] = _roles[m.role].name;
            bios[i] = m.bio;
            skulls[i] = m.skull;
        }
        return (names, roles, bios, skulls);
    }

    // ======== Role management ==========

    function addRole(uint16 role, string calldata name, string calldata color) external serOrOwner {
        if (keccak256(abi.encodePacked(_roles[role].name)) != keccak256(abi.encodePacked(""))) {
            revert RoleDoesNotExist();
        }

        _roles[role] = Role(name, color);
    }

    function changeRoleName(uint16 role, string calldata name) external serOrOwner {
        if (keccak256(abi.encodePacked(_roles[role].name)) == keccak256(abi.encodePacked(""))) {
            revert RoleDoesNotExist();
        }

        _roles[role].name = name;
    }

    function changeRoleColor(uint16 role, string calldata color) external serOrOwner {
        if (keccak256(abi.encodePacked(_roles[role].name)) == keccak256(abi.encodePacked(""))) {
            revert RoleDoesNotExist();
        }

        _roles[role].color = color;
    }

    function setOpen(bool isOpen) external serOrOwner {
        _isOpen = isOpen;
    }

    // ======== Optimized overrides ==========

    function balanceOf(address owner) public view override returns (uint256) {
        return members[owner].role == 0 ? 0 : 1;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index != 0) revert IndexOutOfBounds();
        return members[owner].token;
    }

    // ======== Renderer contract ==========

    function setRenderer(address renderer) external serOrOwner {
        _renderer = renderer;
    }

    // ======== Functionality overrides ==========

    function transferFrom(address, address, uint256) public pure override(ERC721L) {
        revert TransfersDisabled();
    }

    function safeTransferFrom(address, address, uint256) public pure override(ERC721L) {
        revert TransfersDisabled();
    }

    function memberURI(address member) public view virtual returns (string memory metadata) {
        return tokenURI(members[member].token);
    }

    function tokenURI(uint256 tokenId) public view override(IERC721Metadata) returns (string memory metadata) {
        address owner = ownerOf(tokenId);
        Member memory member = members[owner];
        Role memory role = _roles[member.role];

        return ILeetCollectiveRenderer(_renderer).render(
            owner, member.name, member.bio, role.color, role.name, uint256(uint16(member.skull))
        );
    }
}
