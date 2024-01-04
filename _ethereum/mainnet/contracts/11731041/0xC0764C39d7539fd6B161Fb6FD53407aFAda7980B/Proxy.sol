pragma solidity <=0.5.4;

contract Ownable {

    string public contractName;
    address public owner;
    address public manager;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event ManagerChanged(address indexed previousManager, address indexed newManager);

    constructor() internal {
        owner = msg.sender;
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyManager(bytes32 managerName) {
        require(msg.sender == manager, "Ownable: caller is not the manager");
        _;
    }


    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0), "Ownable: new owner is the zero address");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function setManager(address _manager) public onlyOwner {
        require(_manager != address(0), "Ownable: new manager is the zero address");
        emit ManagerChanged(manager, _manager);
        manager = _manager;
    }

    function setContractName(bytes32 _contractName) internal {
        contractName = string(abi.encodePacked(_contractName));
    }

}

interface IOwnable {

    function contractName() external view returns (string memory);

}

contract Proxy is Ownable {

    bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

    event ImplementationChanged(address indexed previousValue, address indexed newValue);

    constructor(address _implementation) public {
        setImplementation(_implementation);
    }

    function setImplementation(address _implementation) public onlyOwner {
        require(_implementation != address(0), "Proxy: new implementation is the zero address");
        contractName = IOwnable(_implementation).contractName();

        emit ImplementationChanged(implementation(), _implementation);
        bytes32 solt = IMPLEMENTATION_SLOT;
        assembly {
            sstore(solt, _implementation)
        }
    }

    function implementation() public view returns (address _implementation) {
        bytes32 solt = IMPLEMENTATION_SLOT;
        assembly {
            _implementation := sload(solt)
        }
    }

    function() external payable {
        _fallback(implementation());
    }

    function _fallback(address _implementation) private {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

}