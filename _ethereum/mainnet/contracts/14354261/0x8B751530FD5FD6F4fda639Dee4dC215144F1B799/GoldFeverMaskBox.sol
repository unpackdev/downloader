//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./AccessControlMixin.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";
import "./GoldFeverItem.sol";

import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract GoldFeverMaskBox is
    ERC721,
    ReentrancyGuard,
    AccessControlMixin,
    IERC721Receiver,
    ERC721Holder
{
    GoldFeverItem gfi;
    using Counters for Counters.Counter;
    Counters.Counter private _boxIds;

    constructor(address admin, address gfiContract_)
        public
        ERC721("GFMaskBox", "GFMB")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        gfi = GoldFeverItem(gfiContract_);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    uint256[] private maskShapesPool;
    uint256[] private maskMaterialsPool;
    uint256[] private otherMaskElementsPool;

    event MaskBoxCreated(uint256 indexed boxId, address owner);
    event MaskBoxOpened(uint256 indexed boxId, uint256[] allMaskPartIds);

    function createBoxes(
        uint256[] memory maskShapes,
        uint256[] memory maskMaterials,
        uint256[] memory otherMaskElements
    ) public onlyAdmin {
        require(maskShapes.length > 0, "Must have at least 1 mask blueprint");
        require(
            maskMaterials.length == maskShapes.length,
            "Must have same number of mask materials as mask blueprints"
        );
        require(
            maskShapes.length * 4 == otherMaskElements.length,
            "Must have 4 other mask parts for each mask"
        );
        uint256 numBoxes = maskShapes.length;

        for (uint256 i = 0; i < numBoxes; i++) {
            _boxIds.increment();
            uint256 boxId = _boxIds.current();
            _mint(msg.sender, boxId);
            emit MaskBoxCreated(boxId, msg.sender);
        }

        // transfer ownership of mask blueprints to the mask box
        for (uint256 i = 0; i < maskShapes.length; i++) {
            gfi.safeTransferFrom(msg.sender, address(this), maskShapes[i]);
            maskShapesPool.push(maskShapes[i]);
        }
        // transfer ownership of mask materials to the mask box
        for (uint256 i = 0; i < maskMaterials.length; i++) {
            gfi.safeTransferFrom(msg.sender, address(this), maskMaterials[i]);
            maskMaterialsPool.push(maskMaterials[i]);
        }
        // transfer ownership of other mask parts to the mask box
        for (uint256 i = 0; i < otherMaskElements.length; i++) {
            gfi.safeTransferFrom(
                msg.sender,
                address(this),
                otherMaskElements[i]
            );
            otherMaskElementsPool.push(otherMaskElements[i]);
        }
    }

    // open and burn box
    function openBox(uint256 boxId) public {
        require(msg.sender == ownerOf(boxId), "Only owner can open box");
        uint256[] memory allMaskPartIds = new uint256[](6);
        uint256 rnd_shape = _random(maskShapesPool.length);

        gfi.safeTransferFrom(
            address(this),
            msg.sender,
            maskShapesPool[rnd_shape]
        );
        allMaskPartIds[0] = maskShapesPool[rnd_shape];
        maskShapesPool[rnd_shape] = maskShapesPool[maskShapesPool.length - 1];
        maskShapesPool.pop();

        uint256 rnd_material = _random(maskMaterialsPool.length);
        gfi.safeTransferFrom(
            address(this),
            msg.sender,
            maskMaterialsPool[rnd_material]
        );
        allMaskPartIds[1] = maskMaterialsPool[rnd_material];
        maskMaterialsPool[rnd_material] = maskMaterialsPool[
            maskMaterialsPool.length - 1
        ];
        maskMaterialsPool.pop();

        for (uint256 i = 0; i < 4; i++) {
            uint256 rnd_element = _random(otherMaskElementsPool.length);
            gfi.safeTransferFrom(
                address(this),
                msg.sender,
                otherMaskElementsPool[rnd_element]
            );
            allMaskPartIds[i + 2] = otherMaskElementsPool[rnd_element];
            otherMaskElementsPool[rnd_element] = otherMaskElementsPool[
                otherMaskElementsPool.length - 1
            ];
            otherMaskElementsPool.pop();
        }

        _burn(boxId);
        emit MaskBoxOpened(boxId, allMaskPartIds);
    }

    function _random(uint256 number) private view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            ) % number;
    }
}
