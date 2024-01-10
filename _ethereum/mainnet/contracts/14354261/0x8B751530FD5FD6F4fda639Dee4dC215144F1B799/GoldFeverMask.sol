//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./AccessControlMixin.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";
import "./GoldFeverItem.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./GoldFeverItemType.sol";
import "./GoldFeverNativeGold.sol";
import "./Strings.sol";
import "./console.sol";

contract GoldFeverMask is
    ERC721,
    ReentrancyGuard,
    AccessControlMixin,
    IERC721Receiver,
    ERC721Holder
{
    bytes32 public constant FORGED = keccak256("FORGED");
    uint256 private forgeMaskFee;
    uint256 private unforgeMaskFee;
    uint256 private purchaseMaskCost;
    uint256 private commissionRate;
    uint256 private nglFromCollectedFee = 0;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _maskIds;

    GoldFeverItem gfi;
    GoldFeverNativeGold ngl;
    address public itemTypeContract;

    constructor(
        address admin,
        address gfiContract_,
        address nglContract_,
        address itemTypeContract_
    ) public ERC721("GFMask", "GFM") {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        gfi = GoldFeverItem(gfiContract_);
        itemTypeContract = itemTypeContract_;
        ngl = GoldFeverNativeGold(nglContract_);
        uint256 decimals = ngl.decimals();
        forgeMaskFee = 3 * (10**decimals);
        unforgeMaskFee = 3 * (10**decimals);
        purchaseMaskCost = 10 * (10**decimals);
        commissionRate = 1;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    struct Mask {
        uint256 id;
        address owner;
        bytes32 status;
        uint256 maskShape;
        uint256 maskMaterial;
        uint256 topElement;
        uint256 frontElement;
        uint256 scratches;
        uint256 paintOver;
    }

    mapping(uint256 => Mask) public idToMask;

    event MaskForged(
        uint256 id,
        address owner,
        uint256 maskShapeTypeId,
        uint256 maskMaterialTypeId,
        uint256 topElementTypeId,
        uint256 frontElementTypeId,
        uint256 scratchesTypeId,
        uint256 paintOverTypeId
    );
    event MaskUnforged(uint256 id);
    event MaskPurchased(uint256 id);

    function forgeMask(
        uint256 maskShape,
        uint256 maskMaterial,
        uint256 topElement,
        uint256 frontElement,
        uint256 scratches,
        uint256 paintOver
    ) public nonReentrant {
        require(maskShape > 0, "Need at least one shape");
        require(maskMaterial > 0, "Need at least one material");

        require(
            IGoldFeverItemType(itemTypeContract).getItemType(maskShape) >=
                231010 &&
                IGoldFeverItemType(itemTypeContract).getItemType(maskShape) <=
                231024,
            "Invalid mask shape"
        );

        require(
            IGoldFeverItemType(itemTypeContract).getItemType(maskMaterial) >=
                231110 &&
                IGoldFeverItemType(itemTypeContract).getItemType(
                    maskMaterial
                ) <=
                231124,
            "Invalid mask material"
        );

        require(
            (IGoldFeverItemType(itemTypeContract).getItemType(topElement) >=
                231210 &&
                IGoldFeverItemType(itemTypeContract).getItemType(topElement) <=
                231224) ||
                IGoldFeverItemType(itemTypeContract).getItemType(topElement) ==
                0,
            "Invalid top element"
        );

        require(
            (IGoldFeverItemType(itemTypeContract).getItemType(frontElement) >=
                231310 &&
                IGoldFeverItemType(itemTypeContract).getItemType(
                    frontElement
                ) <=
                231325) ||
                IGoldFeverItemType(itemTypeContract).getItemType(
                    frontElement
                ) ==
                0,
            "Invalid front element"
        );

        require(
            (IGoldFeverItemType(itemTypeContract).getItemType(scratches) >=
                231410 &&
                IGoldFeverItemType(itemTypeContract).getItemType(scratches) <=
                231424) ||
                IGoldFeverItemType(itemTypeContract).getItemType(scratches) ==
                0,
            "Invalid scratches"
        );

        require(
            (IGoldFeverItemType(itemTypeContract).getItemType(paintOver) >=
                231510 &&
                IGoldFeverItemType(itemTypeContract).getItemType(paintOver) <=
                231526) ||
                IGoldFeverItemType(itemTypeContract).getItemType(paintOver) ==
                0,
            "Invalid paintOver"
        );
        uint256 maskId = parseInt(
            string(
                abi.encodePacked(
                    zeroPadNumber(
                        (
                            IGoldFeverItemType(itemTypeContract).getItemType(
                                maskShape
                            )
                        ) % 10000
                    ),
                    zeroPadNumber(
                        (
                            IGoldFeverItemType(itemTypeContract).getItemType(
                                maskMaterial
                            )
                        ) % 10000
                    ),
                    zeroPadNumber(
                        (
                            IGoldFeverItemType(itemTypeContract).getItemType(
                                topElement
                            )
                        ) % 10000
                    ),
                    zeroPadNumber(
                        (
                            IGoldFeverItemType(itemTypeContract).getItemType(
                                frontElement
                            )
                        ) % 10000
                    ),
                    zeroPadNumber(
                        (
                            IGoldFeverItemType(itemTypeContract).getItemType(
                                scratches
                            )
                        ) % 10000
                    ),
                    zeroPadNumber(
                        (
                            IGoldFeverItemType(itemTypeContract).getItemType(
                                paintOver
                            )
                        ) % 10000
                    )
                )
            )
        );

        require(
            idToMask[maskId].status != FORGED,
            "This Mask Type Is Already Forged By Other User"
        );

        gfi.safeTransferFrom(msg.sender, address(this), maskShape);
        gfi.safeTransferFrom(msg.sender, address(this), maskMaterial);
        if (IGoldFeverItemType(itemTypeContract).getItemType(topElement) != 0) {
            gfi.safeTransferFrom(msg.sender, address(this), topElement);
        }
        if (
            IGoldFeverItemType(itemTypeContract).getItemType(frontElement) != 0
        ) {
            gfi.safeTransferFrom(msg.sender, address(this), frontElement);
        }
        if (IGoldFeverItemType(itemTypeContract).getItemType(scratches) != 0) {
            gfi.safeTransferFrom(msg.sender, address(this), scratches);
        }
        if (IGoldFeverItemType(itemTypeContract).getItemType(paintOver) != 0) {
            gfi.safeTransferFrom(msg.sender, address(this), paintOver);
        }

        _mint(msg.sender, maskId);

        idToMask[maskId] = Mask(
            maskId,
            msg.sender,
            FORGED,
            maskShape,
            maskMaterial,
            topElement,
            frontElement,
            scratches,
            paintOver
        );

        uint256 adminEarn = (forgeMaskFee * commissionRate) / 100;
        ngl.transferFrom(msg.sender, address(this), adminEarn);
        ngl.burnFrom(msg.sender, forgeMaskFee - adminEarn);
        nglFromCollectedFee += adminEarn;

        emit MaskForged(
            maskId,
            msg.sender,
            IGoldFeverItemType(itemTypeContract).getItemType(maskShape),
            IGoldFeverItemType(itemTypeContract).getItemType(maskMaterial),
            IGoldFeverItemType(itemTypeContract).getItemType(topElement),
            IGoldFeverItemType(itemTypeContract).getItemType(frontElement),
            IGoldFeverItemType(itemTypeContract).getItemType(scratches),
            IGoldFeverItemType(itemTypeContract).getItemType(paintOver)
        );
    }

    function unforgeMask(uint256 maskId) public nonReentrant {
        require(idToMask[maskId].status == FORGED, "Mask is not forged");

        address owner = ownerOf(maskId);
        require(msg.sender == owner, "Only owner can unforge");

        gfi.safeTransferFrom(address(this), owner, idToMask[maskId].maskShape);
        gfi.safeTransferFrom(
            address(this),
            owner,
            idToMask[maskId].maskMaterial
        );
        if (idToMask[maskId].topElement != 0) {
            gfi.safeTransferFrom(
                address(this),
                owner,
                idToMask[maskId].topElement
            );
        }
        if (idToMask[maskId].frontElement != 0) {
            gfi.safeTransferFrom(
                address(this),
                owner,
                idToMask[maskId].frontElement
            );
        }
        if (idToMask[maskId].scratches != 0) {
            gfi.safeTransferFrom(
                address(this),
                owner,
                idToMask[maskId].scratches
            );
        }
        if (idToMask[maskId].paintOver != 0) {
            gfi.safeTransferFrom(
                address(this),
                owner,
                idToMask[maskId].paintOver
            );
        }

        delete idToMask[maskId];
        _burn(maskId);
        uint256 adminEarn = (unforgeMaskFee * commissionRate) / 100;
        ngl.transferFrom(msg.sender, address(this), adminEarn);
        ngl.burnFrom(msg.sender, unforgeMaskFee - adminEarn);
        nglFromCollectedFee += adminEarn;
        emit MaskUnforged(maskId);
    }

    function parseInt(string memory _value) public pure returns (uint256 _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint256 j = 1;
        for (
            uint256 i = _bytesValue.length - 1;
            i >= 0 && i < _bytesValue.length;
            i--
        ) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48) * j;
            j *= 10;
        }
    }

    function zeroPadNumber(uint256 value) public pure returns (string memory) {
        if (value < 10) {
            return string(abi.encodePacked("000", value.toString()));
        } else if (value < 100) {
            return string(abi.encodePacked("00", value.toString()));
        } else if (value < 1000) {
            return string(abi.encodePacked("0", value.toString()));
        } else {
            return value.toString();
        }
    }

    function updateForgeMaskFee(uint256 _fee) public nonReentrant onlyAdmin {
        require(_fee > 0, "Fee must be greater than 0");
        forgeMaskFee = _fee;
    }

    function updateUnforgeMaskFee(uint256 _fee) public nonReentrant onlyAdmin {
        require(_fee > 0, "Fee must be greater than 0");
        unforgeMaskFee = _fee;
    }

    function updatePurchaseMaskCost(uint256 _cost)
        public
        nonReentrant
        onlyAdmin
    {
        require(_cost > 0, "Purchase cost must be greater than 0");
        purchaseMaskCost = _cost;
    }

    function withdrawCollectedFee() public nonReentrant onlyAdmin {
        ngl.transfer(msg.sender, nglFromCollectedFee);
        nglFromCollectedFee = 0;
    }

    function getForgeMaskFee() public view returns (uint256) {
        return forgeMaskFee;
    }

    function getUnforgeMaskFee() public view returns (uint256) {
        return unforgeMaskFee;
    }

    function getPurchaseMaskCost() public view returns (uint256) {
        return purchaseMaskCost;
    }

    function purchaseMask(uint256 maskId) public nonReentrant {
        address owner = ownerOf(maskId);
        require(msg.sender == owner, "Only owner can purchase");
        require(
            idToMask[maskId].status == FORGED,
            "Mask is not forged or already purchased"
        );

        uint256 adminEarn = (purchaseMaskCost * commissionRate) / 100;

        ngl.transferFrom(owner, address(this), adminEarn);
        ngl.burnFrom(owner, purchaseMaskCost - adminEarn);
        nglFromCollectedFee += adminEarn;
        emit MaskPurchased(maskId);
    }

    function setCommissionRate(uint256 _rate) public nonReentrant onlyAdmin {
        require(_rate > 0, "Commission rate must be greater than 0");
        commissionRate = _rate;
    }

    function getCommissionRate() public view returns (uint256) {
        return commissionRate;
    }
}
