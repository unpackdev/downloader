
// File: contracts/Atomex.sol

pragma solidity ^0.5.0;

// From file: openzeppelin-contracts/contracts/math/SafeMath.sol
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "SafeMath add wrong value");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath sub wrong value");
        return a - b;
    }
}

// File: openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}

contract Atomex is ReentrancyGuard {
    using SafeMath for uint256;

    enum State { Empty, Initiated, Redeemed, Refunded }

    struct Swap {
        bytes32 hashedSecret;
        address payable initiator;
        address payable participant;
        uint256 refundTimestamp;
        uint256 countdown;
        uint256 value;
        uint256 payoff;
        bool active;
        State state;
    }

    event Initiated(
        bytes32 indexed _hashedSecret,
        address indexed _participant,
        address _initiator,
        uint256 _refundTimestamp,
        uint256 _countdown,
        uint256 _value,
        uint256 _payoff,
        bool _active
    );

    event Added(
        bytes32 indexed _hashedSecret,
        address _sender,
        uint _value
    );

    event Activated(
        bytes32 indexed _hashedSecret
    );

    event Redeemed(
        bytes32 indexed _hashedSecret,
        bytes32 _secret
    );

    event Refunded(
        bytes32 indexed _hashedSecret
    );

    mapping(bytes32 => Swap) public swaps;

    modifier onlyByInitiator(bytes32 _hashedSecret) {
        require(msg.sender == swaps[_hashedSecret].initiator, "sender is not the initiator");
        _;
    }

    modifier isInitiatable(bytes32 _hashedSecret, address _participant, uint256 _refundTimestamp, uint256 _countdown) {
        require(_participant != address(0), "invalid participant address");
        require(swaps[_hashedSecret].state == State.Empty, "swap for this hash is already initiated");
        require(block.timestamp < _refundTimestamp, "refundTimestamp has already come");
        require(_countdown < _refundTimestamp, "countdown exceeds the refundTimestamp");
        _;
    }

    modifier isInitiated(bytes32 _hashedSecret) {
        require(swaps[_hashedSecret].state == State.Initiated, "swap for this hash is empty or already spent");
        _;
    }

    modifier isAddable(bytes32 _hashedSecret) {
        require(block.timestamp < swaps[_hashedSecret].refundTimestamp, "refundTimestamp has already come");
        _;
    }

    modifier isActivated(bytes32 _hashedSecret) {
        require(swaps[_hashedSecret].active, "swap is not active");
        _;
    }

    modifier isNotActivated(bytes32 _hashedSecret) {
        require(!swaps[_hashedSecret].active, "swap is already activated");
        _;
    }

    modifier isRedeemable(bytes32 _hashedSecret, bytes32 _secret) {
        require(block.timestamp < swaps[_hashedSecret].refundTimestamp, "refundTimestamp has already come");
        require(sha256(abi.encodePacked(sha256(abi.encodePacked(_secret)))) == _hashedSecret, "secret is not correct");
        _;
    }

    modifier isRefundable(bytes32 _hashedSecret) {
        require(block.timestamp >= swaps[_hashedSecret].refundTimestamp, "refundTimestamp has not come");
        _;
    }


    function initiate(
        bytes32 _hashedSecret, address payable _participant, uint256 _refundTimestamp,
        uint256 _countdown, uint256 _payoff, bool _active)
        public payable nonReentrant isInitiatable(_hashedSecret, _participant, _refundTimestamp, _countdown)
    {
        swaps[_hashedSecret].value = msg.value.sub(_payoff);
        swaps[_hashedSecret].hashedSecret = _hashedSecret;
        swaps[_hashedSecret].participant = _participant;
        swaps[_hashedSecret].initiator = msg.sender;
        swaps[_hashedSecret].refundTimestamp = _refundTimestamp;
        swaps[_hashedSecret].countdown = _countdown;
        swaps[_hashedSecret].payoff = _payoff;
        swaps[_hashedSecret].active = _active;
        swaps[_hashedSecret].state = State.Initiated;

        emit Initiated(
            _hashedSecret,
            _participant,
            msg.sender,
            _refundTimestamp,
            _countdown,
            msg.value.sub(_payoff),
            _payoff,
            _active
        );
    }

    function add (bytes32 _hashedSecret)
        public payable nonReentrant isInitiated(_hashedSecret) isAddable(_hashedSecret)
    {
        swaps[_hashedSecret].value = swaps[_hashedSecret].value.add(msg.value);

        emit Added(
            _hashedSecret,
            msg.sender,
            swaps[_hashedSecret].value
        );
    }

    function activate (bytes32 _hashedSecret)
        public isInitiated(_hashedSecret) isNotActivated(_hashedSecret) onlyByInitiator(_hashedSecret)
    {
        swaps[_hashedSecret].active = true;

        emit Activated(
            _hashedSecret
        );
    }

    function redeem(bytes32 _hashedSecret, bytes32 _secret)
        public nonReentrant isInitiated(_hashedSecret) isActivated(_hashedSecret) isRedeemable(_hashedSecret, _secret)
    {
        swaps[_hashedSecret].state = State.Redeemed;

        emit Redeemed(
            _hashedSecret,
            _secret
        );

        if (block.timestamp > swaps[_hashedSecret].refundTimestamp.sub(swaps[_hashedSecret].countdown)) {
            swaps[_hashedSecret].participant.transfer(swaps[_hashedSecret].value);
            if (swaps[_hashedSecret].payoff > 0) {
                msg.sender.transfer(swaps[_hashedSecret].payoff);
            }
        }
        else {
            swaps[_hashedSecret].participant.transfer(swaps[_hashedSecret].value.add(swaps[_hashedSecret].payoff));
        }

        delete swaps[_hashedSecret];
    }

    function refund(bytes32 _hashedSecret)
        public isInitiated(_hashedSecret) isRefundable(_hashedSecret)
    {
        swaps[_hashedSecret].state = State.Refunded;

        emit Refunded(
            _hashedSecret
        );

        swaps[_hashedSecret].initiator.transfer(swaps[_hashedSecret].value.add(swaps[_hashedSecret].payoff));

        delete swaps[_hashedSecret];
    }
}
