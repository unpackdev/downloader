// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

import "./IConsumables.sol";
import "./ConsumablesState.sol";
import "./IGP.sol";

contract Consumables is Initializable, IConsumables, ConsumablesState {

    function initialize() external initializer {
        ERC1155OnChainBaseUpgradeable.__ERC1155OnChainBase_init();
        ConsumablesState.__ConsumablesState_init();
    }

    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external override whenNotPaused onlyAdminOrOwner {
        _safeTransferFrom(_from, _to, _id, _amount, "");
    }

    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external override whenNotPaused onlyAdminOrOwner {
        _safeBatchTransferFrom(_from, _to, _ids, _amounts, "");
    }

    // Mint a token - any payment / game logic should be handled in the game contract.
    function mint(uint256 typeId, uint256 qty, address recipient) external override whenNotPaused onlyAdminOrOwner {
        require(typeInfo[typeId].mints - typeInfo[typeId].burns + qty <= typeInfo[typeId].maxSupply, "All tokens minted");
        typeInfo[typeId].mints += qty;
        _mint(recipient, typeId, qty, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external whenNotPaused onlyAdminOrOwner {
        _mintBatch(to, ids, amounts, "");
    }

    // Burn a token - any payment / game logic should be handled in the game contract.
    function burn(uint256 typeId, uint256 qty, address burnFrom) external override whenNotPaused onlyAdminOrOwner {
        typeInfo[typeId].burns += qty;
        _burn(burnFrom, typeId, qty);
    }

    function setType(uint256 typeId, uint256 maxSupply) external onlyAdminOrOwner {
        require(typeInfo[typeId].mints <= maxSupply, "max supply too low");
        typeInfo[typeId].maxSupply = maxSupply;
    }

    function getInfoForType(uint256 typeId) external view returns(TypeInfo memory) {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        return typeInfo[typeId];
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        Image memory img = traitData[typeId];
        string memory metadata = string(abi.encodePacked(
            '{"name": "',
            img.name,
            '", "description": "Items earned from within the Wizards & Dragons metaverse. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
            _base64(bytes(_drawSVG(typeId))),
            '", "attributes": []',
            "}"
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            _base64(bytes(metadata))
        ));
    }
}