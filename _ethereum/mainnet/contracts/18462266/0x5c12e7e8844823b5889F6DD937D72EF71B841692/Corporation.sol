// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./IERC1155.sol";
import "./IEIP2981.sol";
import "./Strings.sol";
import "./ICorporation.sol";
import "./console.sol";

contract Void2122Corporation is
    Initializable,
    ERC1155Upgradeable,
    ICorporation
{
    uint256 public corporationIds;
    uint256 public royaltyAmount;
    address public royalties_recipient;
    string public constant contractName = "Void 2122 - Corporations";
    string[] uriComponents;
    mapping(uint256 => Corporation) public corporations;
    mapping(uint256 => mapping(address => bool)) corporationsMembers;
    mapping(address => uint256) memberCorporation;
    mapping(address => bool) isAdmin;

    error InvalidLoots();
    error Unauthorized();

    function initialize() public initializer {
        __ERC1155_init("");
        corporationIds = 1;
        isAdmin[msg.sender] = true;
        royaltyAmount = 10;
        royalties_recipient = msg.sender;
        uriComponents = [
            'data:application/json;utf8,{"name":"',
            '", "description":"',
            '", "image":"',
            '", "animation":"',
            '", "attributes":[',
            "]}"
        ];
    }

    modifier adminRequired() {
        if (!isAdmin[msg.sender]) revert Unauthorized();
        _;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Upgradeable) returns (bool) {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IEIP2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name() public pure returns (string memory) {
        return contractName;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external adminRequired {
        _mint(to, id, amount, "0x0");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external adminRequired {
        _mintBatch(to, ids, amounts, "0x0");
    }

    function burn(uint256 tokenId, uint256 quantity) public {
        _burn(msg.sender, tokenId, quantity);
    }

    function burnBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        _burnBatch(msg.sender, ids, amounts);
    }

    function toggleAdmin(address _admin) external adminRequired {
        isAdmin[_admin] = !isAdmin[_admin];
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        Corporation memory corp = corporations[tokenId];
        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "Active", "value": "',
            corp.active ? "True" : "False",
            '"}, {"trait_type": "Name", "value": "',
            corp.name,
            '"}, {"trait_type": "Id", "value": "',
            Strings.toString(corp.id),
            '"}'
        );
        bytes memory byteString = abi.encodePacked(
            abi.encodePacked(uriComponents[0], corp.name),
            abi.encodePacked(uriComponents[1], corp.description),
            abi.encodePacked(uriComponents[2], corp.image),
            abi.encodePacked(uriComponents[3], corp.animation),
            abi.encodePacked(uriComponents[4], attributes),
            abi.encodePacked(uriComponents[5])
        );
        return string(byteString);
    }

    function setRoyalties(
        address payable _recipient,
        uint256 _royaltyPerCent
    ) external adminRequired {
        royalties_recipient = _recipient;
        royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(
        uint256 salePrice
    ) external view returns (address, uint256) {
        if (royalties_recipient != address(0)) {
            return (royalties_recipient, (salePrice * royaltyAmount) / 100);
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }

    function createCorporation(Corporation calldata _corporation) external {
        Corporation memory corp = _corporation;
        corp.owner = msg.sender;
        corp.active = true;
        corporations[corporationIds] = corp;
        corporationIds++;
        emit CorporationCreated(corp);
    }

    function disbandCorporation(Corporation calldata _corporation) external {
        corporations[_corporation.id].active = false;
        emit CorporationDisbanded(_corporation);
    }

    function addOrRemoveMember(
        uint256 _corporationId,
        address _member
    ) external {
        Corporation memory corp = corporations[_corporationId];
        if (msg.sender != corp.owner) revert Unauthorized();
        if (!corporationsMembers[corp.id][_member]) {
            corporationsMembers[corp.id][_member] = true;
            memberCorporation[_member] = corp.id;
            emit MemberAdded(_member);
        } else {
            corporationsMembers[corp.id][_member] = false;
            memberCorporation[_member] = 0;
            emit MemberRemoved(_member);
        }
    }

    function getPlayerCorporation(
        address player
    ) external view returns (string memory) {
        if (memberCorporation[player] > 0) {
            return corporations[memberCorporation[player]].name;
        }
        return "";
    }
}
