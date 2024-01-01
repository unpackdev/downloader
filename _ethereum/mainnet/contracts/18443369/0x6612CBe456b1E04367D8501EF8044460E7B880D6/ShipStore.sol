pragma solidity ^0.8.18;

import "./IERC721Receiver.sol";
import "./Interfaces.sol";

contract ShipStore {
    IAzimuth public azimuthContract;

    constructor(IAzimuth _azimuthContract) {
        azimuthContract = _azimuthContract;
    }

    ShipStack[] public shipStacks;
    struct ShipStack {
        address owner; // 0 indicates the stack has not been initialized
        address operator;
        address depositor;
        uint price;
        address exclusiveBuyer; // if not 0x0, this is the only address that can buy ships from this stack
        address payable revenueRecipient;
        bool deployed; // has the operator called deployStack yet?
        uint32[] ships;
    }

    function prepStack(address _owner, address _operator, address _depositor, address payable _revenueRecipient)
        external
        returns (uint stackId)
    {
        require(_operator != address(0), "can't set operator 0x0");

        // implicitly returns
        stackId = shipStacks.length;

        ShipStack memory stack;
        stack.owner = _owner;
        stack.operator = _operator;
        stack.depositor = _depositor;
        stack.revenueRecipient = _revenueRecipient;
        
        shipStacks.push(stack);
    }

    // onlyOwner funcs
    function setOwner(uint _stackId, address _owner)
        external
        onlyStackOwner(_stackId)
    {
        _setOwner(_stackId, _owner);
    }
    function setOperator(uint _stackId, address _operator)
        external
        onlyStackOwner(_stackId)
    {
        _setOperator(_stackId, _operator);
    }
    function setRevenueRecipient(uint _stackId, address payable _revenueRecipient)
        public
        onlyStackOwner(_stackId)
    {
        _setRevenueRecipient(_stackId, _revenueRecipient);
    }

    // onlyOperator funcs
    function setDepositor(uint _stackId, address _depositor)
        external
        onlyStackOperator(_stackId)
    {
        _setDepositor(_stackId, _depositor);
    }
    function deployStack(uint _stackId, uint _price, address _exclusiveBuyer)
        external
        onlyStackOperator(_stackId)
    {
        ShipStack storage stack = shipStacks[_stackId];
        require(!stack.deployed, "stack already deployed");

        _setPrice(_stackId, _price);
        _setExclusiveBuyer(_stackId, _exclusiveBuyer);
        stack.deployed = true;
    }
    function setPrice(uint _stackId, uint _price)
        external
        onlyStackOperator(_stackId)
    {
        _setPrice(_stackId, _price);
    }
    function setExclusiveBuyer(uint _stackId, address _exclusiveBuyer)
        public
        onlyStackOperator(_stackId)
    {
        _setExclusiveBuyer(_stackId, _exclusiveBuyer);
    }

    // internal setters
    function _setOwner(uint _stackId, address _owner) internal {
        shipStacks[_stackId].owner = _owner;
    }
    function _setOperator(uint _stackId, address _operator) internal {
        shipStacks[_stackId].operator = _operator;
    }
    function _setDepositor(uint _stackId, address _depositor) internal {
        shipStacks[_stackId].depositor = _depositor;
    }
    function _setRevenueRecipient(uint _stackId, address payable _revenueRecipient) internal {
        shipStacks[_stackId].revenueRecipient = _revenueRecipient;
    }
    function _setPrice(uint _stackId, uint _price) internal {
        shipStacks[_stackId].price = _price;
    }
    function _setExclusiveBuyer(uint _stackId, address _exclusiveBuyer) internal {
        shipStacks[_stackId].exclusiveBuyer = _exclusiveBuyer;
    }

    modifier onlyStackOwner(uint _stackId) {
        requireValidStackId(_stackId);
        require(msg.sender == shipStacks[_stackId].owner, "msg.sender != owner");
        _;
    }

    modifier onlyStackOperator(uint _stackId) {
        requireValidStackId(_stackId);
        require(msg.sender == shipStacks[_stackId].operator, "msg.sender != operator");
        _;
    }

    modifier onlyStackDepositor(uint _stackId) {
        requireValidStackId(_stackId);
        require(msg.sender == shipStacks[_stackId].depositor, "msg.sender != depositor");
        _;
    }

    function requireValidStackId(uint _stackId)
        internal
        view
    {
        require(_stackId < shipStacks.length, "Invalid _stackId");
    }

    function getStackInfo(uint _stackId)
        external
        view
        returns(
            address owner,
            address operator,
            uint price,
            address onlyBuyerIfSet,
            address payable revenueRecipientIfSet,
            uint numShips
        )
    {
        requireValidStackId(_stackId);

        return(
            shipStacks[_stackId].owner,
            shipStacks[_stackId].operator,
            shipStacks[_stackId].price,
            shipStacks[_stackId].exclusiveBuyer,
            shipStacks[_stackId].revenueRecipient,
            shipStacks[_stackId].ships.length
        );
    }

    // This contract must be approved to send each id (i.e. by calling setApprovalForAll)
    // additionally, msg.sender must be approved to send (perhaps by simply being the owner) as defined by azimuthContract.canTransfer
    function depositShips(uint _stackId, uint32[] calldata _ids)
        external
        onlyStackDepositor(_stackId)
    {
        ShipStack storage shipStack = shipStacks[_stackId];

        IEcliptic ecliptic = IEcliptic(azimuthContract.owner());
        for (uint i; i<_ids.length;) {
            require(azimuthContract.canTransfer(_ids[i], msg.sender), "msg.sender can't transfer point");

            ecliptic.transferPoint(_ids[i], address(this), false);
            shipStack.ships.push(_ids[i]);

            unchecked { i ++ ;}
        }
    }

    function recallShips(uint _stackId, uint _amount, address _recipient, bool breach)
        external
        onlyStackDepositor(_stackId)
    {
        ShipStack storage shipStack = shipStacks[_stackId];

        require(_amount <= shipStack.ships.length, "Not that many ships in that stack");

        IEcliptic ecliptic = IEcliptic(azimuthContract.owner());
        for (uint i = 0; i < _amount;) {
            ecliptic.transferPoint(shipStack.ships[shipStack.ships.length - 1], _recipient, breach);
            shipStack.ships.pop();

            unchecked { i ++ ;}
        }
    }

    event ShipBought(uint indexed stackId, address indexed recipient);

    function buyShip(uint _stackId, address _recipient)
        external
        payable
        returns(uint32 shipId)
    {
        requireValidStackId(_stackId);
        require(shipStacks[_stackId].deployed, "Ship stack not deployed");

        ShipStack storage shipStack = shipStacks[_stackId];

        require(msg.value == shipStack.price, "Incorrect ether amount included");
        require(shipStack.ships.length > 0, "Stack has no ships");
        
        if (shipStack.exclusiveBuyer != address(0)) {
            require(msg.sender == shipStack.exclusiveBuyer, "buyer not approved");
        }

        shipId = shipStack.ships[shipStack.ships.length - 1];

        IEcliptic ecliptic = IEcliptic(azimuthContract.owner());
        ecliptic.transferPoint(shipId, _recipient, false);
        
        shipStack.ships.pop();

        (bool success,) = shipStack.revenueRecipient.call{value: msg.value}("");
        require(success, "failed to forward revenue");

        emit ShipBought(_stackId, _recipient);
    }
}