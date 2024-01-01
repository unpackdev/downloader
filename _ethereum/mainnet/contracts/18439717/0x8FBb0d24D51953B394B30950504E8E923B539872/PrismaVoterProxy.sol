// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IDeposit.sol";
import "./ITokenLocker.sol";
import "./ITokenMinter.sol";
import "./IERC20.sol";


contract PrismaVoterProxy {

    address public immutable prisma;
    address public immutable escrow;
    uint256 public constant MAX_LOCK_WEEKS = 52;

    address public owner;
    address public pendingOwner;
    address public operator;
    address public depositor;
    
    event SetPendingOwner(address indexed _address);
    event OwnerChanged(address indexed _address);
    
    constructor(address _prisma, address _veprisma){
        owner = msg.sender;
        prisma = _prisma;
        escrow = _veprisma;
        IERC20(prisma).approve(escrow, type(uint256).max);
    }

    function getName() external pure returns (string memory) {
        return "PrismaVoterProxy";
    }

    //set next owner
    function setPendingOwner(address _po) external {
        require(msg.sender == owner, "!auth");
        pendingOwner = _po;
        emit SetPendingOwner(_po);
    }

    //claim ownership
    function acceptPendingOwner() external {
        require(msg.sender == pendingOwner, "!p_owner");

        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnerChanged(owner);
    }

    function setOperator(address _operator) external {
        require(msg.sender == owner, "!auth");
        require(operator == address(0) || IDeposit(operator).isShutdown() == true, "needs shutdown");
        
        //require isshutdown interface
        require(IDeposit(_operator).isShutdown() == false, "no shutdown interface");
        
        operator = _operator;
    }

    function setDepositor(address _depositor) external {
        require(msg.sender == owner, "!auth");

        depositor = _depositor;
    }

    function lock(uint256 _value) external returns(bool){
        require(msg.sender == depositor, "!auth");
        ITokenLocker(escrow).lock(address(this), _value, MAX_LOCK_WEEKS);
        return true;
    }

    function freeze() external{
        require(msg.sender == depositor, "!auth");
        ITokenLocker(escrow).freeze();
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory) {
        require(msg.sender == operator,"!auth");

        (bool success, bytes memory result) = _to.call{value:_value}(_data);

        return (success, result);
    }

}