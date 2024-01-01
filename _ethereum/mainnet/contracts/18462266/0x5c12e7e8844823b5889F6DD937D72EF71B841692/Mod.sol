// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155Upgradeable.sol";
import "./IERC1155.sol";
import "./IEIP2981.sol";
import "./Strings.sol";
import "./IMod.sol";

contract Void2122Mod is ERC1155Upgradeable, IMod {
    uint256 public modIds;
    uint256 public royaltyAmount;
    address public royalties_recipient;
    string public constant contractName = "Void 2122 - Mods";
    mapping(uint256 => Mod) public mods;
    mapping(address => bool) isAdmin;
    string[] uriComponents;

    error Unauthorized();

    function initialize() public initializer {
        __ERC1155_init("");
        modIds = 1;
        royaltyAmount = 10;
        royalties_recipient = msg.sender;
        isAdmin[msg.sender] = true;
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

    function burnBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        _burnBatch(msg.sender, ids, amounts);
    }

    function burn(uint256 tokenId, uint256 quantity) public {
        _burn(msg.sender, tokenId, quantity);
    }

    function toggleAdmin(address _admin) external adminRequired {
        isAdmin[_admin] = !isAdmin[_admin];
    }

    function uri(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        Mod memory mod = mods[_tokenId];
        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "Top Bonus", "value": "',
            Strings.toString(mod.bonus[0]),
            '"}, {"trait_type": "Right Bonus", "value": "',
            Strings.toString(mod.bonus[1]),
            '"}, {"trait_type": "Bottom Bonus", "value": "',
            Strings.toString(mod.bonus[2]),
            '"}, {"trait_type": "Left Bonus", "value": "',
            Strings.toString(mod.bonus[3]),
            '"}'
        );
        bytes memory byteString = abi.encodePacked(
            abi.encodePacked(uriComponents[0], mod.name),
            abi.encodePacked(uriComponents[1], mod.description),
            abi.encodePacked(uriComponents[2], mod.image),
            abi.encodePacked(uriComponents[3], mod.animation),
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

    function getModBonus(
        uint256 _tokenId
    ) external view returns (uint256[4] memory) {
        Mod memory mod = mods[_tokenId];
        return mod.bonus;
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

    function createMod(Mod calldata _mod) external {
        mods[modIds] = _mod;
        modIds++;
        emit ModCreated(_mod);
    }
}
