pragma solidity >0.6.1 <0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";

interface BullrunBabesCoordinatorI {
    function draw() external payable;

    function tradeUp(uint256[] memory tokens) external payable;

    struct CardView {
        uint256 id;
        uint256 serial;
        string cid;
        uint256 tier;
        uint256 cardTypeId;
        uint256 currentSerialForType;
    }

    function getAllocations() external view returns (uint256[][] memory);

    function getCard(uint256 id) external view returns (CardView memory);

    function getPrice(uint256 reserve) external view returns (uint256);

    event CardAllocated(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 serial,
        uint256 cardTypeId,
        uint256 tier,
        string cid,
        bytes32 indexed queryId
    );
}

interface BullrunBabesCoordinatorIAdmin is BullrunBabesCoordinatorI {
    function getOracleGasFee() external view returns (uint256, uint256);

    function setOracleGasFee(uint256 _gas, uint256 _fee) external;

    function cancelRandom(bytes32 _queryId, bool refundOracleFees)
        external
        payable;

    function checkInflight(bytes32[] memory _queryIds)
        external
        view
        returns (bytes32[] memory);

    function withdraw() external payable;

    event RandomInitiated(bytes32 indexed queryId);
    event RandomReceived(bytes32 indexed queryId);
}

interface BullrunBabesOracleI {
    function setCoordinator(address _coordinator) external;

    function _init_random() external payable returns (bytes32);

    event RandomInitiated(bytes32 indexed queryId);
    event RandomReceived(bytes32 indexed queryId);
}

interface BullrunBabesOracleIAdmin is BullrunBabesOracleI {
    function getGasPriceAndGas() external view returns (uint256, uint256);

    function setGasPriceAndGas(uint256 _gasPrice, uint256 _gas) external;
}

interface BullrunBabesTokenI is IERC721, IERC721Metadata, IERC721Enumerable {}
