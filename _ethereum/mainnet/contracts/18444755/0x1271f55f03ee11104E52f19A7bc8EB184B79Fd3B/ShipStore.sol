pragma solidity ^0.8.18;

import "./IERC721Receiver.sol";
import "./Interfaces.sol";

/// @title ShipStore contract
/// @notice Allows anyone to create and manage any number of ShipStacks, and for other users to purchase ships from these stacks.
/// @author Logan Brutsche
contract ShipStore {
    IAzimuth public azimuthContract;

    /// @param _azimuthContract The address of the azimuth contract.
    constructor(IAzimuth _azimuthContract) {
        azimuthContract = _azimuthContract;
    }

    ShipStack[] public shipStacks;

    /// @notice Struct to represent a ship stack.
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

    /// @notice Prepare a ShipStack to be deployed later
    /// @param _owner The owner of the stack. Can change operator and revenueRecipient, and transfer ownership
    /// @param _operator The address that will be allowed to deploy and manage the stack.
    /// @param _revenueRecipient The address to which revenue from pill sales will be sent.
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

    /// @notice Set a new owner for a specific stack.
    /// @param _stackId The ID of the stack.
    /// @param _owner The new owner's address.
    /// @dev The caller must be the current owner.
    function setOwner(uint _stackId, address _owner)
        external
        onlyStackOwner(_stackId)
    {
        _setOwner(_stackId, _owner);
    }
    /// @notice Set a new operator for a specific stack.
    /// @param _stackId The ID of the stack.
    /// @param _operator The new operator's address.
    /// @dev The caller must be the current owner.
    function setOperator(uint _stackId, address _operator)
        external
        onlyStackOwner(_stackId)
    {
        _setOperator(_stackId, _operator);
    }
    /// @notice Sets the revenue recipient for a ship stack at shipStacks[msg.sender][_stackId].
    /// @dev Stack must be initialized.
    /// @param _stackId The identifier of the ship stack.
    /// @param _revenueRecipient The address to receive the revenue.
    function setRevenueRecipient(uint _stackId, address payable _revenueRecipient)
        public
        onlyStackOwner(_stackId)
    {
        _setRevenueRecipient(_stackId, _revenueRecipient);
    }

    // onlyOperator funcs

    /// @notice Sets the depositor for a ship stack.
    /// @dev Stack must be initialized.
    /// @dev Only callable by operator
    /// @param _stackId The identifier of the ship stack.
    /// @param _depositor The address allowed to deposit ships.
    function setDepositor(uint _stackId, address _depositor)
        external
        onlyStackOperator(_stackId)
    {
        _setDepositor(_stackId, _depositor);
    }
    /// @notice Deploy a stack with specified properties.
    /// @param _stackId The ID of the stack.
    /// @param _price The price for the stack.
    /// @param _exclusiveBuyer If set, only this address can buy a ship from this stack.
    /// @dev The caller must be the current operator.
    /// @dev Throws if the stack is already deployed.
    /// @dev Throws if the stack has not been prepped via prepStack.
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
    /// @notice Sets the price for a ship stack.
    /// @dev Stack must be initialized.
    /// @dev Only callable by the stack operator.
    /// @param _stackId The identifier of the ship stack.
    /// @param _price The new price for the ship stack.
    function setPrice(uint _stackId, uint _price)
        external
        onlyStackOperator(_stackId)
    {
        _setPrice(_stackId, _price);
    }
    /// @notice Sets exclusive buyer for a ship stack.
    /// @dev Stack must be initialized.
    /// @dev Only callable by the stack operator.
    /// @param _stackId The identifier of the ship stack.
    /// @param _exclusiveBuyer The address of the exclusive buyer.
    function setExclusiveBuyer(uint _stackId, address _exclusiveBuyer)
        public
        onlyStackOperator(_stackId)
    {
        _setExclusiveBuyer(_stackId, _exclusiveBuyer);
    }

    // internal setters

    /// @notice Internal function to set the owner of a stack.
    /// @param _stackId The ID of the stack.
    /// @param _owner The new owner address.
    function _setOwner(uint _stackId, address _owner) internal {
        shipStacks[_stackId].owner = _owner;
    }
    /// @notice Internal function to set the operator of a stack.
    /// @param _stackId The ID of the stack.
    /// @param _operator The new operator address.
    function _setOperator(uint _stackId, address _operator) internal {
        shipStacks[_stackId].operator = _operator;
    }
    /// @notice Internal function to set the depositor of a stack.
    /// @param _stackId The ID of the stack.
    /// @param _depositor The new depositor address.
    function _setDepositor(uint _stackId, address _depositor) internal {
        shipStacks[_stackId].depositor = _depositor;
    }
    /// @notice Internal function to set the revenue recipient of a stack.
    /// @param _stackId The ID of the stack.
    /// @param _revenueRecipient The new revenue recipient address.
    function _setRevenueRecipient(uint _stackId, address payable _revenueRecipient) internal {
        shipStacks[_stackId].revenueRecipient = _revenueRecipient;
    }
    /// @notice Internal function to set the price of a stack.
    /// @param _stackId The ID of the stack.
    /// @param _price The new price.
    function _setPrice(uint _stackId, uint _price) internal {
        shipStacks[_stackId].price = _price;
    }
    /// @notice Internal function to set the exclusive buyer of a stack.
    /// @param _stackId The ID of the stack.
    /// @param _exclusiveBuyer The new value of exclusiveBuyer.
    function _setExclusiveBuyer(uint _stackId, address _exclusiveBuyer) internal {
        shipStacks[_stackId].exclusiveBuyer = _exclusiveBuyer;
    }

    /// @notice Modifier to ensure only the stack owner can call the function.
    /// @param _stackId The ID of the stack.
    modifier onlyStackOwner(uint _stackId) {
        requireValidStackId(_stackId);
        require(msg.sender == shipStacks[_stackId].owner, "msg.sender != owner");
        _;
    }

    /// @notice Modifier to ensure only the stack operator can call the function.
    /// @param _stackId The ID of the stack.
    modifier onlyStackOperator(uint _stackId) {
        requireValidStackId(_stackId);
        require(msg.sender == shipStacks[_stackId].operator, "msg.sender != operator");
        _;
    }

    /// @notice Modifier to ensure only the stack depositor can call the function.
    /// @param _stackId The ID of the stack.
    modifier onlyStackDepositor(uint _stackId) {
        requireValidStackId(_stackId);
        require(msg.sender == shipStacks[_stackId].depositor, "msg.sender != depositor");
        _;
    }

    /// @notice Internal function to validate the given stack ID.
    /// @param _stackId The ID of the stack to validate.
    /// @dev Throws if the stack ID is out of range.
    function requireValidStackId(uint _stackId)
        internal
        view
    {
        require(_stackId < shipStacks.length, "Invalid _stackId");
    }
    
    /// @notice Retrieve information about a specific ship stack.
    /// @param _stackId The ID of the ship stack.
    /// @dev Stack must be initialized.
    /// @return owner The owner of the ship stack.
    /// @return operator The operator authorized for the ship stack.
    /// @return price The price to buy a ship.
    /// @return onlyBuyerIfSet If not the zero address, only this address can buy from this stack.
    /// @return revenueRecipient Address where revenue is forwarded.
    /// @return numShips The number of ships in this stack.
    function getStackInfo(uint _stackId)
        external
        view
        returns(
            address owner,
            address operator,
            uint price,
            address onlyBuyerIfSet,
            address payable revenueRecipient,
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

    /// @notice Deposits ships into a ship stack.
    /// @dev This contract must be approved to send each id (i.e. by calling setApprovalForAll)
    /// @dev msg.sender must be approved to send each id as defined by azimuthContract.canTransfer
    /// @param _stackId The identifier of the ship stack.
    /// @param _ids The array of ship IDs to deposit.
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

    /// @notice Recalls ships from a ship stack.
    /// @dev Stack must be initialized.
    /// @param _stackId The identifier of the ship stack.
    /// @param _amount The number of ships to recall.
    /// @param _recipient The recipient of the recalled ships.
    /// @param breach Whether to breach the ship.
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

    /// @notice Event emitted when a ship is bought.
    /// @param stackId The ID of the ship stack.
    /// @param recipient The address receiving the ship.
    event ShipBought(uint indexed stackId, address indexed recipient);

    /// @notice Allows a user to buy a ship from a specific stack.
    /// @dev Checks for sufficient Ether and permissions before executing the purchase.
    /// @param _stackId The ID of the ship stack.
    /// @param _recipient The address to which the bought ship will be sent.
    /// @return shipId The ID of the bought ship.
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