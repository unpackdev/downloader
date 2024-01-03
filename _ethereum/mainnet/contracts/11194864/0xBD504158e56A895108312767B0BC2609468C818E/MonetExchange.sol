pragma solidity =0.5.16;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC1155.sol";

contract MonetExchange {
    using SafeMath for uint256;

    address public tokenCard;
    address public tokenMonet;
    
    bytes4 private constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    uint256 public fee = 2;  // 0.2%
    address public feeTo;
    address public feeToSetter;
    
    uint256 private _nextId;
    mapping(uint256 => Order) internal _orders;

    struct Order {
        uint256 id;
        uint256 num;
        uint256 price;
        address owner;
        uint256 status;
        uint256 direction;
    }

    constructor(address card, address monet) public {
        tokenCard = card;
        tokenMonet = monet;
        feeTo = msg.sender;
        feeToSetter = msg.sender;
    }

    // VIEW

    // PRIVATE
    function _transferFromCards(address _from, address _to, uint256 _id, uint256 _value) private {
        IERC1155(tokenCard).safeTransferFrom(_from, _to, _id, _value, bytes(''));
    }

    function _transferFromMonet(address _from, address _to, uint256 _value) private {
        require(IERC20(tokenMonet).transferFrom(_from, _to, _value), 'transferFrom fail');
    }

    function _transfer(address _to, uint256 _value) private {
        require(IERC20(tokenMonet).transfer(_to, _value), 'transfer fail');
    }

    // EXTERNAL
    function trade(uint256 orderId, uint256 num) external {
        Order storage order = _orders[orderId];
        require(order.id != 0 && order.status == 0, 'order is empty');
        require(order.owner != msg.sender, 'order owner is caller');
        require(order.num >= num, 'order num is less');
        if (order.direction == 0) {
            uint256 feeAmount = num.mul(order.price).mul(2).div(1000);
            if (feeAmount > 0 && feeTo != address(0)) _transfer(feeTo, feeAmount);
            _transfer(msg.sender, num.mul(order.price));
            _transferFromCards(msg.sender, order.owner, order.id, num);
        } else {
            uint256 feeAmount = num.mul(order.price).mul(2).div(1000);
            if (feeAmount > 0 && feeTo != address(0)) _transferFromMonet(msg.sender, feeTo, feeAmount);
            _transferFromCards(address(this), msg.sender, order.id, num);
            _transferFromMonet(msg.sender, order.owner, num.mul(order.price));
        }
        order.num = order.num.sub(num);
        if (order.num == 0) {
            order.status = 1;
        }
        emit Trade(msg.sender, orderId, num);
    }

    function revoke(uint256 orderId) external {
        Order storage order = _orders[orderId];
        require(order.id != 0 && order.status == 0, 'order is empty');
        require(order.owner == msg.sender, 'caller is not the order owner');
        if (order.direction == 0) {
            uint256 amount = order.num.mul(order.price).mul(1002).div(1000);
            _transfer(msg.sender, amount);
        } else {
            _transferFromCards(address(this), msg.sender, order.id, order.num);
        }
        order.status = 2;
        emit Revoke(msg.sender, orderId);
    }

    function placeOrder(uint256 id, uint256 num, uint256 price, uint256 direction) external generateId {
        require(_nextId > 0, 'order id generate fail');
        require(direction < 2, 'direction is error');
        if (direction == 0) {
            uint256 amount = num.mul(price).mul(1002).div(1000);
            _transferFromMonet(msg.sender, address(this), amount);
        } else {
            _transferFromCards(msg.sender, address(this), id, num);
        }
        _orders[_nextId] = Order(id, num, price, msg.sender, 0, direction);
        emit PlaceOrder(msg.sender, _nextId, id, num, price, direction);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    // IERC1155TokenReceiver
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4){
        return ERC1155_RECEIVED_VALUE;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns(bytes4){
        return ERC1155_BATCH_RECEIVED_VALUE;
    }

    // MODIFIER
    modifier generateId() {
        _nextId = _nextId.add(1);

        _;
    }

    // EVENT
    event Trade(address indexed sender, uint256 indexed orderId, uint256 num);
    event Revoke(address indexed sender, uint256 indexed orderId);
    event PlaceOrder(address indexed sender, uint256 orderId, uint256 id, uint256 num, uint256 price, uint256 direction);
}
