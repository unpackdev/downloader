/**
Author: Loopring Foundation (Loopring Project Ltd)
*/

pragma solidity ^0.6.6;


contract AddressSet {
    struct Set
    {
        address[] addresses;
        mapping (address => uint) positions;
        uint count;
    }
    mapping (bytes32 => Set) private sets;

    function addAddressToSet(
        bytes32 key,
        address addr,
        bool maintainList
        ) internal
    {
        Set storage set = sets[key];
        require(set.positions[addr] == 0, "ALREADY_IN_SET");
        
        if (maintainList) {
            require(set.addresses.length == set.count, "PREVIOUSLY_NOT_MAINTAILED");
            set.addresses.push(addr);
        } else {
            require(set.addresses.length == 0, "MUST_MAINTAIN");
        }

        set.count += 1;
        set.positions[addr] = set.count;
    }

    function removeAddressFromSet(
        bytes32 key,
        address addr
        )
        internal
    {
        Set storage set = sets[key];
        uint pos = set.positions[addr];
        require(pos != 0, "NOT_IN_SET");

        delete set.positions[addr];
        set.count -= 1;

        if (set.addresses.length > 0) {
            address lastAddr = set.addresses[set.count];
            if (lastAddr != addr) {
                set.addresses[pos - 1] = lastAddr;
                set.positions[lastAddr] = pos;
            }
            set.addresses.pop();
        }
    }

    function removeSet(bytes32 key)
        internal
    {
        delete sets[key];
    }

    function isAddressInSet(
        bytes32 key,
        address addr
        )
        internal
        view
        returns (bool)
    {
        return sets[key].positions[addr] != 0;
    }

    function numAddressesInSet(bytes32 key)
        internal
        view
        returns (uint)
    {
        Set storage set = sets[key];
        return set.count;
    }

    function addressesInSet(bytes32 key)
        internal
        view
        returns (address[] memory)
    {
        Set storage set = sets[key];
        require(set.count == set.addresses.length, "NOT_MAINTAINED");
        return sets[key].addresses;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
    
    constructor()
        public
    {
        owner = msg.sender;
    }

    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    
    
    
    function transferOwnership(
        address newOwner
        )
        public
        virtual
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

contract Claimable is Ownable
{
    address public pendingOwner;

    
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    
    
    function transferOwnership(
        address newOwner
        )
        public
        override
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

interface WalletRegistry {
    function registerWallet(address wallet) external;
    function isWalletRegistered(address addr) external view returns (bool);
    function numOfWallets() external view returns (uint);
}

contract WalletRegistryImpl is Claimable, AddressSet, WalletRegistry
{
    bytes32 internal constant WALLET = keccak256("__WALLET__");

    address internal factory;

    event WalletRegistered      (address indexed wallet);
    event WalletFactoryUpdated  (address indexed factory);

    modifier onlyFactory()
    {
        require(msg.sender == factory, "FACTORY_UNAUTHORIZED");
        _;
    }

    constructor() public Claimable() {}

    function setWalletFactory(address _factory)
        external
        onlyOwner
    {
        require(_factory != address(0), "ZERO_ADDRESS");
        factory = _factory;
        emit WalletFactoryUpdated(factory);
    }

    function registerWallet(address wallet)
        external
        override
        onlyFactory
    {
        addAddressToSet(WALLET, wallet, false);
        emit WalletRegistered(wallet);
    }

    function isWalletRegistered(address addr)
        public
        view
        override
        returns (bool)
    {
        return isAddressInSet(WALLET, addr);
    }

    function numOfWallets()
        public
        view
        override
        returns (uint)
    {
        return numAddressesInSet(WALLET);
    }
}