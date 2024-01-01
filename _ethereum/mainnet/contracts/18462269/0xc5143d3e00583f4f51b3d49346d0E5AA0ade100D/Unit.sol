// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721Upgradeable.sol";
import "./IERC1155.sol";
import "./IEIP2981.sol";
import "./Strings.sol";
import "./IUnit.sol";
import "./Corporation.sol";
import "./Mod.sol";

contract Void2122Unit is ERC721Upgradeable, IUnit {
    uint256 public unitIds;
    uint256 public tokenId;
    uint256 public royaltyAmount;
    address public royalties_recipient;
    address public corporationAddress;
    address public modAddress;
    string public constant contractName = "Void 2122 - Units";
    mapping(uint256 => Unit) public units;
    mapping(uint256 => UnitTemplate) unitTemplates;
    mapping(address => bool) isAdmin;
    string[] uriComponents;

    error Unauthorized();

    function initialize() public initializer {
        __ERC721_init("Void 2122 - Units", "V2122Units");
        unitIds = 1;
        tokenId = 1;
        royaltyAmount = 10;
        royalties_recipient = msg.sender;
        isAdmin[msg.sender] = true;
        uriComponents = [
            'data:application/json;utf8,{"name":"',
            '", "description":"',
            '", "image":"',
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
    ) public view virtual override(ERC721Upgradeable) returns (bool) {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IEIP2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint(address _to, uint256 _unitTemplate) external adminRequired {
        Unit memory _unit = Unit(_unitTemplate, 0, new uint256[](0));
        units[tokenId] = _unit;
        _mint(_to, tokenId);
        tokenId++;
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }

    function toggleAdmin(address _admin) external adminRequired {
        isAdmin[_admin] = !isAdmin[_admin];
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        Unit memory _unit = units[_tokenId];
        UnitTemplate memory _unitTemplate = unitTemplates[_unit.template];
        bytes memory attributes = abi.encodePacked(
            abi.encodePacked(
                '{"trait_type": "Level", "value": "',
                Strings.toString(_unitTemplate.level),
                '"}, {"trait_type": "Generation", "value": "',
                Strings.toString(_unitTemplate.generation),
                "None",
                '"}, {"trait_type": "Model", "value": "',
                _unitTemplate.model,
                '"}, {"trait_type": "Rarity", "value": "',
                _unitTemplate.rarity,
                '"}, {"trait_type": "Total Mods Available", "value": "'
            ),
            abi.encodePacked(
                Strings.toString(_unitTemplate.modSlots),
                '"}, {"trait_type": "Value Top", "value": "',
                Strings.toString(_unitTemplate.values[0]),
                '"}, {"trait_type": "Value Right", "value": "',
                Strings.toString(_unitTemplate.values[1]),
                '"}, {"trait_type": "Value Bottom", "value": "',
                Strings.toString(_unitTemplate.values[2]),
                '"}, {"trait_type": "Value Left", "value": "',
                Strings.toString(_unitTemplate.values[3]),
                '"}'
            )
        );
        bytes memory byteString = abi.encodePacked(
            abi.encodePacked(uriComponents[0], _unitTemplate.name),
            abi.encodePacked(uriComponents[1], _unitTemplate.description),
            abi.encodePacked(uriComponents[2], _unitTemplate.image),
            abi.encodePacked(uriComponents[3], attributes),
            abi.encodePacked(uriComponents[4])
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

    function createUnitTemplate(
        UnitTemplate calldata _unitTemplate
    ) external adminRequired {
        unitTemplates[unitIds] = _unitTemplate;
        unitIds++;
        emit UnitTemplateCreated(_unitTemplate);
    }

    function updateUnitTemplate(
        uint256 _unitId,
        UnitTemplate calldata _unitTemplate
    ) external adminRequired {
        unitTemplates[_unitId] = _unitTemplate;
        emit UnitTemplateUpdated(_unitTemplate);
    }
}
