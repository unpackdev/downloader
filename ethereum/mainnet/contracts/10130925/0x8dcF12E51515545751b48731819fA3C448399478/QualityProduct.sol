pragma solidity 0.6.6;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        }
    }
}

contract QualityProduct is Owned {
    enum TrackingStatus { Uninitialised, InProgress, Completed }

    struct TimestampedProduct {
        bytes32 product_hash;
        uint256 timestamp;
    }

    struct TimestampedTracking {
        bytes32 tracking_hash;
        uint256 timestamp;
        TrackingStatus status;
    }

    string public name;

    TimestampedProduct public product;

    bytes32[] public tracking_identifiers;
    mapping (bytes32 => TimestampedTracking) public trackings;
    mapping (bytes32 => bytes32) public lot_to_tracking;

    constructor(string memory _name, bytes32 _product_hash) public onlyOwner {
        name = _name;
        setProduct(_product_hash);
    }

    function setProduct(bytes32 _product_hash) public onlyOwner {
        product = TimestampedProduct(_product_hash, now);
    }

    function setTracking(bytes32 _identifier, bytes32 _tracking_hash, TrackingStatus _status) public onlyOwner {
        require(_identifier != 0);
        require(_tracking_hash != 0);
        require(_status != TrackingStatus.Uninitialised);

        if (trackings[_identifier].status == TrackingStatus.Uninitialised) {
            tracking_identifiers.push(_identifier);
        }

        trackings[_identifier] = TimestampedTracking(_tracking_hash, now, _status);
    }

    function setLotTracking(bytes32 _lot_identifier, bytes32 _tracking_identifier) public onlyOwner {
        require(_lot_identifier != 0);
        require(trackings[_tracking_identifier].status == TrackingStatus.Completed);

        lot_to_tracking[_lot_identifier] = _tracking_identifier;
    }
}