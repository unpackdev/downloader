// File: contracts/registry/IRegistry.sol

pragma solidity ^0.5.17;

contract IRegistry {
    function getVotingAddress() public view returns (address);

    function getExchangeFactoryAddress() public view returns (address);

    function getWethAddress() public view returns (address);

    function getMessageProcessorAddress() public view returns (address);

    function getFsTokenAddress() public view returns (address);

    function getFsTokenProxyAdminAddress() public view returns (address);

    function getIncentivesAddress() public view returns (address);

    function getWalletAddress() public view returns (address payable);

    function getReplayTrackerAddress() public view returns (address);

    function getLiquidityTokenFactoryAddress() public view returns (address);

    function hasLiquidityTokensnapshotAccess(address sender) public view returns (bool);

    function hasWalletAccess(address sender) public view returns (bool);

    function removeWalletAccess(address _walletAccessor) public;

    function isValidOracleAddress(address oracleAddress) public view returns (bool);

    function isValidVerifierAddress(address verifierAddress) public view returns (bool);

    function isValidStamperAddress(address stamperAddress) public view returns (bool);

    function isExchange(address exchangeAddress) public view returns (bool);

    function addExchange(address _exchange) public;

    function removeExchange(address _exchange) public;

    function updateVotingAddress(address _address) public;
}

// File: contracts/registry/IRegistryUpdateConsumer.sol

pragma solidity ^0.5.17;

// Implemented by objects that need to know about registry updates.
interface IRegistryUpdateConsumer {
    function onRegistryRefresh() external;
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/registry/RegistryHolder.sol

pragma solidity ^0.5.17;



// Holds a reference to the registry
// Eventually Ownership will be renounced
contract RegistryHolder is Ownable {
    address private registryAddress;

    function getRegistryAddress() public view returns (address) {
        return registryAddress;
    }

    // Change the address of registry, if the caller is the voting system as identified by the old
    // registry.
    function updateRegistry(address _newAddress) public {
        require(isOwner() || isVotingSystem(), "Only owner or voting system");
        require(_newAddress != address(0), "Zero address");
        registryAddress = _newAddress;
    }

    function isVotingSystem() private view returns (bool) {
        if (registryAddress == address(0)) {
            return false;
        }
        return IRegistry(registryAddress).getVotingAddress() == msg.sender;
    }
}

// File: contracts/registry/KnowsRegistry.sol

pragma solidity ^0.5.17;




// Base class for objects that need to know about other objects in the system
// This allows us to share modifiers and have a unified way of looking up other objects.
contract KnowsRegistry is IRegistryUpdateConsumer {
    RegistryHolder private registryHolder;

    modifier onlyVotingSystem() {
        require(isVotingSystem(msg.sender), "Only voting system");
        _;
    }

    modifier onlyExchangeFactory() {
        require(isExchangeFactory(msg.sender), "Only exchange factory");
        _;
    }

    modifier onlyExchangeFactoryOrVotingSystem() {
        require(isExchangeFactory(msg.sender) || isVotingSystem(msg.sender), "Only exchange factory or voting");
        _;
    }

    modifier requiresWalletAcccess() {
        require(getRegistry().hasWalletAccess(msg.sender), "requires wallet access");
        _;
    }

    modifier onlyMessageProcessor() {
        require(getRegistry().getMessageProcessorAddress() == msg.sender, "only MessageProcessor");
        _;
    }

    modifier onlyExchange() {
        require(getRegistry().isExchange(msg.sender), "Only exchange");
        _;
    }

    modifier onlyRegistry() {
        require(getRegistryAddress() == msg.sender, "only registry");
        _;
    }

    modifier onlyOracle() {
        require(isValidOracleAddress(msg.sender), "only oracle");
        _;
    }

    modifier requiresLiquidityTokenSnapshotAccess() {
        require(getRegistry().hasLiquidityTokensnapshotAccess(msg.sender), "only incentives");
        _;
    }

    constructor(address _registryHolder) public {
        registryHolder = RegistryHolder(_registryHolder);
    }

    function getRegistryHolder() internal view returns (RegistryHolder) {
        return registryHolder;
    }

    function getRegistry() internal view returns (IRegistry) {
        return IRegistry(getRegistryAddress());
    }

    function getRegistryAddress() internal view returns (address) {
        return registryHolder.getRegistryAddress();
    }

    function isRegistryHolder(address a) internal view returns (bool) {
        return a == address(registryHolder);
    }

    function isValidOracleAddress(address oracleAddress) public view returns (bool) {
        return getRegistry().isValidOracleAddress(oracleAddress);
    }

    function isValidVerifierAddress(address verifierAddress) public view returns (bool) {
        return getRegistry().isValidVerifierAddress(verifierAddress);
    }

    function isValidStamperAddress(address stamperAddress) public view returns (bool) {
        return getRegistry().isValidStamperAddress(stamperAddress);
    }

    function isVotingSystem(address a) public view returns (bool) {
        return a == getRegistry().getVotingAddress();
    }

    function isExchangeFactory(address a) public view returns (bool) {
        return a == getRegistry().getExchangeFactoryAddress();
    }

    function checkNotNull(address a) internal pure returns (address) {
        require(a != address(0), "address must be non zero");
        return a;
    }

    function checkNotNullAP(address payable a) internal pure returns (address payable) {
        require(a != address(0), "address must be non zero");
        return a;
    }
}

// File: contracts/messageProcessor/IReplayTracker.sol

pragma solidity ^0.5.17;

interface IReplayTracker {
    function reserve(uint256 replayNumber) external;
}

// File: contracts/messageProcessor/ReplayTracker.sol

pragma solidity ^0.5.17;



// ReplayTracker ensures that a user interaction number can only be used
// once per user address.
contract ReplayTracker is KnowsRegistry, IReplayTracker {
    mapping(uint256 => bool) private replayNumbers;

    constructor(address registryHolder) public KnowsRegistry(registryHolder) {}

    function isUsed(uint256 replayNumber) public view returns (bool) {
        return replayNumbers[replayNumber];
    }

    function reserve(uint256 replayNumber) public onlyMessageProcessor {
        require(!replayNumbers[replayNumber], "replay");
        replayNumbers[replayNumber] = true;
    }

    function onRegistryRefresh() public onlyRegistry {}
}