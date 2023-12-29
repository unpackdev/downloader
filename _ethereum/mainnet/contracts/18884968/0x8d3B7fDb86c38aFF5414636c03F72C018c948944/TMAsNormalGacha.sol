// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./AccessControl.sol";
import "./IERC721.sol";
import "./IAMTManager.sol";


/**
 * @title TMAsNormalGacha
 * @dev TMAs normal gacha
 */
contract TMAsNormalGacha is AccessControl {
    error ZeroCountError();
    error InsufficientBalanceError();
    error NonTMAsOwnerError();
    error LengthError();
    error CountError();
    
    /**
     * @dev Normal gacha event
     * @param id TMAs id
     * @param count count
     * @param total total
     */
    event NormalGacha(uint256 indexed id, uint256 count, uint256 total);

    enum Layer {
        WeponBack,
        OuterWear,
        Accessory,
        Weapon,
        FaceItem,
        HeadItem,
        Clothes
    }

    struct Gacha {
        uint256 id;
        mapping(Layer => uint32) count;
    }

    IAMTManager public immutable points;
    IERC721 public immutable tmas;

    // layer => max count
    mapping(Layer => uint32) public normalGachaMaxCount;

    // normal gacha cost
    uint256 public normalGachaCost = 100;
    // id => layer => count
    mapping(uint256 => Gacha) public normalGachaCount;

    /**
     * @dev Constructor
     * @param _points AMTManager address
     * @param _tmas TMAs address
     */
    constructor(IAMTManager _points, IERC721 _tmas) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        points = _points;
        tmas = _tmas;
        normalGachaMaxCount[Layer.WeponBack] = 12;
        normalGachaMaxCount[Layer.OuterWear] = 80;
        normalGachaMaxCount[Layer.Accessory] = 50;
        normalGachaMaxCount[Layer.Weapon] = 68;
        normalGachaMaxCount[Layer.FaceItem] = 200;
        normalGachaMaxCount[Layer.HeadItem] = 150;
        normalGachaMaxCount[Layer.Clothes] = 250;
    }

    /**
     * @dev Multiple normal gacha
     * @param id TMAs id
     * @param layers layers
     * @param counts counts
     */
    function multipleNormalGacha(uint256 id, Layer[] calldata layers, uint32[] calldata counts) external {
        if (layers.length != counts.length) revert LengthError();
        if (layers.length == 0) revert LengthError();
        for (uint256 i = 0; i < layers.length; i++) {
            normalGacha(id, layers[i], counts[i]);
        }
    }

    /**
     * @dev Normal gacha
     * @param id TMAs id
     * @param layer layer
     * @param count count
     */
    function normalGacha(uint256 id, Layer layer, uint32 count) public {
        if (count == 0) revert ZeroCountError();
        if (points.amt(msg.sender) < normalGachaCost * count) revert InsufficientBalanceError();
        if (tmas.ownerOf(id) != msg.sender) revert NonTMAsOwnerError();
        if (normalGachaMaxCount[layer] < normalGachaCount[id].count[layer] + count) revert CountError();
        points.use(msg.sender, normalGachaCost * count, 'NormalGacha');
        normalGachaCount[id].count[layer] += count;
        emit NormalGacha(id, count, normalGachaCount[id].count[layer]);
    }

    /**
     * @dev Get count can gacha
     * @param id TMAs id
     * @param layer layer
     * @return count can gacha count
     */
    function countCanGacha(uint256 id, Layer layer) external view returns (uint32) {
        // overflow check
        if (normalGachaMaxCount[layer] < normalGachaCount[id].count[layer]) return 0;
        return normalGachaMaxCount[layer] - normalGachaCount[id].count[layer];
    }

    /**
     * @dev Get layer count
     * @param id TMAs id
     * @param layer layer
     * @return count Layer count
     */
    function getLayerCount(uint256 id, Layer layer) external view returns (uint32) {
        return normalGachaCount[id].count[layer];
    }

    /**
     * @dev Get all layers count
     * @param id TMAs id
     * @return counts All layers count
     */
    function getAllLeyersCount(uint256 id) external view returns (uint32[] memory) {
        uint32[] memory res = new uint32[](7);
        res[0] = normalGachaCount[id].count[Layer.WeponBack];
        res[1] = normalGachaCount[id].count[Layer.OuterWear];
        res[2] = normalGachaCount[id].count[Layer.Accessory];
        res[3] = normalGachaCount[id].count[Layer.Weapon];
        res[4] = normalGachaCount[id].count[Layer.FaceItem];
        res[5] = normalGachaCount[id].count[Layer.HeadItem];
        res[6] = normalGachaCount[id].count[Layer.Clothes];
        return res;
    }

    /**
     * @dev Set normal gacha cost
     * @param _normalGachaCost normal gacha cost
     */
    function setNormalGachaCost(uint256 _normalGachaCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        normalGachaCost = _normalGachaCost;
    }

    /**
     * @dev Set normal gacha max count
     * @param layer layer
     * @param count max count
     */
    function setNormalGachaMaxCount(Layer layer, uint32 count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        normalGachaMaxCount[layer] = count;
    }

    /**
     * @dev Set normal gacha count
     * @param id TMAs id
     * @param layer layer
     * @param count count
     */
    function setNormalGachaCount(uint256 id, Layer layer, uint32 count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        normalGachaCount[id].count[layer] = count;
    }

}

