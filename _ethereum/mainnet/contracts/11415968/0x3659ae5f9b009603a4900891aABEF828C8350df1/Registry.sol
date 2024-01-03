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

// File: contracts/registry/Registry.sol

pragma solidity ^0.5.17;




// The registry maintains references to all parts of the system
contract Registry is IRegistry, Ownable {
    event ExchangeAdded(address exchangeAddress);
    event ExchangeRemoved(address exchangeAddress);
    event OracleAdded(address oracle);
    event OracleRemoved(address oracle);
    event VerifierAdded(address verifier);
    event VerifierRemoved(address verifier);
    event LiquidityTokenSnapshotAccessAdded(address accessor);
    event LiquidityTokenSnapshotAccessRemoved(address accessor);
    event StamperAdded(address stamper);
    event StamperRemoved(address stamper);
    event WalletAccessAdded(address accessor);
    event WalletAccessRemoved(address accessor);

    // List of known exchanges
    address[] public exchanges;
    // A mapping of known exchanges
    mapping(address => bool) public exchangeMapping;
    // Whether or not a given address is an oracle
    mapping(address => bool) public isOracle;
    // Whether or not a given address is a verifier
    mapping(address => bool) public isVerifier;
    // Whether or not a given address is a stamper
    mapping(address => bool) public isStamper;
    // Whether or not an address is allowed to take a snapshot of liquidity tokens
    mapping(address => bool) public liquidityTokenSnapshotAccess;
    // Whether or not an address has access to the wallet
    mapping(address => bool) public walletAccessMapping;

    address private exchangeFactoryAddress;
    address private fstTokenAddress;
    address private fsTokenProxyAdminAddress;
    address private incentivesAddress;
    address private liquidityTokenFactoryAddress;
    address private messageProcessorAddress;
    address private replayTrackerAddress;
    address private votingAddress;
    address payable private walletAddress;
    address private wethAddress;

    modifier onlyVotingSystem() {
        require(isVotingSystem(), "Only voting system");
        _;
    }

    modifier onlyOwnerOrVotingSystem() {
        require(isVotingSystem() || isOwner(), "Only owner or voting system");
        _;
    }

    modifier onlyOwnerOrExchangeFactory() {
        require(isExchangeFactory() || isOwner(), "Only owner or exchange factory");
        _;
    }

    modifier onlyOwnerOrExchangeFactoryOrVotingSystem() {
        require(isVotingSystem() || isExchangeFactory() || isOwner(), "Only owner or exchange factory");
        _;
    }

    function isVotingSystem() private view returns (bool) {
        return msg.sender == votingAddress;
    }

    function isExchangeFactory() private view returns (bool) {
        return msg.sender == exchangeFactoryAddress;
    }

    function getVotingAddress() public view returns (address) {
        return votingAddress;
    }

    function setVotingAddress(address _newAddress) public onlyOwner {
        votingAddress = _newAddress;
    }

    function getExchangeFactoryAddress() public view returns (address) {
        return exchangeFactoryAddress;
    }

    function setExchangeFactoryAddress(address _newAddress) public onlyOwner {
        exchangeFactoryAddress = _newAddress;
    }

    function getLiquidityTokenFactoryAddress() public view returns (address) {
        return liquidityTokenFactoryAddress;
    }

    function setLiquidityTokenFactoryAddress(address _newAddress) public onlyOwner {
        liquidityTokenFactoryAddress = _newAddress;
    }

    function getWethAddress() public view returns (address) {
        return wethAddress;
    }

    function setWethAddress(address _newAddress) public onlyOwner {
        wethAddress = _newAddress;
    }

    function getMessageProcessorAddress() public view returns (address) {
        return messageProcessorAddress;
    }

    function setMessageProcessorAddress(address _newAddress) public onlyOwner {
        messageProcessorAddress = _newAddress;
    }

    function getFsTokenAddress() public view returns (address) {
        return fstTokenAddress;
    }

    function setFsTokenAddress(address _newAddress) public onlyOwner {
        fstTokenAddress = _newAddress;
    }

    function getFsTokenProxyAdminAddress() public view returns (address) {
        return fsTokenProxyAdminAddress;
    }

    function setFsTokenProxyAdminAddress(address _newAddress) public onlyOwner {
        fsTokenProxyAdminAddress = _newAddress;
    }

    function getIncentivesAddress() public view returns (address) {
        return incentivesAddress;
    }

    function setIncentivesAddress(address _newAddress) public onlyOwner {
        incentivesAddress = _newAddress;
    }

    function getWalletAddress() public view returns (address payable) {
        return walletAddress;
    }

    function setWalletAddress(address payable _newAddress) public onlyOwner {
        walletAddress = _newAddress;
    }

    function getReplayTrackerAddress() public view returns (address) {
        return replayTrackerAddress;
    }

    function setReplayTrackerAddress(address _newAddress) public onlyOwner {
        replayTrackerAddress = _newAddress;
    }

    function updateExchangeFactoryAddress(address _newAddress) public onlyVotingSystem {
        requireNonZeroAddress(_newAddress);
        exchangeFactoryAddress = _newAddress;
        doFireRegistryUpdateEvent();
    }

    function updateFsTokenAddress(address _newAddress) public onlyVotingSystem {
        requireNonZeroAddress(_newAddress);
        fstTokenAddress = _newAddress;
        doFireRegistryUpdateEvent();
    }

    function updateFsTokenProxyAdminAddress(address _newAddress) public onlyVotingSystem {
        requireNonZeroAddress(_newAddress);
        fsTokenProxyAdminAddress = _newAddress;
        doFireRegistryUpdateEvent();
    }

    function updateIncentivesAddress(address _newAddress) public onlyVotingSystem {
        // We decided to not remove wallet access for the old address to allow for
        // a gradual switch over
        requireNonZeroAddress(_newAddress);
        incentivesAddress = _newAddress;
        doAddLiquidityTokensnapshotAccess(incentivesAddress);
        doFireRegistryUpdateEvent();
    }

    function updateMessageProcessorAddress(address _newAddress) public onlyVotingSystem {
        // We decided to not remove wallet access for the old address to allow for
        // a gradual switch over
        requireNonZeroAddress(_newAddress);
        messageProcessorAddress = _newAddress;
        doAddWalletAccess(_newAddress);
        doFireRegistryUpdateEvent();
    }

    function updateLiquidityTokenFactoryAddress(address _newAddress) public onlyVotingSystem {
        requireNonZeroAddress(_newAddress);
        liquidityTokenFactoryAddress = _newAddress;
        doFireRegistryUpdateEvent();
    }

    function updateReplayTrackerAddress(address _newAddress) public onlyVotingSystem {
        requireNonZeroAddress(_newAddress);
        replayTrackerAddress = _newAddress;
        doFireRegistryUpdateEvent();
    }

    function updateVotingAddress(address _newAddress) public onlyVotingSystem {
        requireNonZeroAddress(_newAddress);
        votingAddress = _newAddress;
        doFireRegistryUpdateEvent();
    }

    function updateWalletAddress(address payable _newAddress) public onlyVotingSystem {
        requireNonZeroAddress(_newAddress);
        walletAddress = _newAddress;
        doFireRegistryUpdateEvent();
    }

    function updateWethAddress(address _newAddress) public onlyVotingSystem {
        requireNonZeroAddress(_newAddress);
        wethAddress = _newAddress;
        doFireRegistryUpdateEvent();
    }

    function fireRegistryUpdateEvent() public onlyOwner {
        doFireRegistryUpdateEvent();
    }

    function doFireRegistryUpdateEvent() private {
        callIfNonZero(replayTrackerAddress);
        callIfNonZero(messageProcessorAddress);
        callIfNonZero(exchangeFactoryAddress);
        callIfNonZero(walletAddress);
        callIfNonZero(incentivesAddress);

        for (uint256 i = 0; i < exchanges.length; i++) {
            callIfNonZero(exchanges[i]);
        }
    }

    function callIfNonZero(address a) private {
        if (a != address(0)) {
            IRegistryUpdateConsumer(a).onRegistryRefresh();
        }
    }

    function hasWalletAccess(address _sender) public view returns (bool) {
        return walletAccessMapping[_sender];
    }

    function addWalletAccess(address _walletAccessor) public onlyOwnerOrVotingSystem {
        doAddWalletAccess(_walletAccessor);
    }

    function doAddWalletAccess(address _walletAccessor) private {
        requireNonZeroAddress(_walletAccessor);
        require(!walletAccessMapping[_walletAccessor], "Already present");
        walletAccessMapping[_walletAccessor] = true;
        emit WalletAccessAdded(_walletAccessor);
    }

    function removeWalletAccess(address _walletAccessor) public onlyOwnerOrExchangeFactoryOrVotingSystem {
        require(walletAccessMapping[_walletAccessor], "No wallet access");
        delete walletAccessMapping[_walletAccessor];
        emit WalletAccessRemoved(_walletAccessor);
    }

    function hasLiquidityTokensnapshotAccess(address _sender) public view returns (bool) {
        return liquidityTokenSnapshotAccess[_sender];
    }

    function addLiquidityTokensnapshotAccess(address _snapshotAccessor) public onlyOwnerOrVotingSystem {
        doAddLiquidityTokensnapshotAccess(_snapshotAccessor);
    }

    function doAddLiquidityTokensnapshotAccess(address _snapshotAccessor) private {
        requireNonZeroAddress(_snapshotAccessor);
        require(!liquidityTokenSnapshotAccess[_snapshotAccessor], "Already present");
        liquidityTokenSnapshotAccess[_snapshotAccessor] = true;
        emit LiquidityTokenSnapshotAccessAdded(_snapshotAccessor);
    }

    function removeLiquidityTokensnapshotAccess(address _snapshotAccessor)
        public
        onlyOwnerOrExchangeFactoryOrVotingSystem
    {
        require(liquidityTokenSnapshotAccess[_snapshotAccessor], "No snapshot access");
        delete liquidityTokenSnapshotAccess[_snapshotAccessor];
        emit LiquidityTokenSnapshotAccessRemoved(_snapshotAccessor);
    }

    function isValidOracleAddress(address oracleAddress) public view returns (bool) {
        return isOracle[oracleAddress];
    }

    function isValidVerifierAddress(address verifierAddress) public view returns (bool) {
        return isVerifier[verifierAddress];
    }

    function isValidStamperAddress(address verifierAddress) public view returns (bool) {
        return isStamper[verifierAddress];
    }

    function addOracle(address _toAdd) public onlyOwnerOrVotingSystem {
        requireNonZeroAddress(_toAdd);
        require(!isOracle[_toAdd], "Already present");
        isOracle[_toAdd] = true;
        emit OracleAdded(_toAdd);
    }

    function removeOracle(address _toRemove) public onlyOwnerOrVotingSystem {
        require(isOracle[_toRemove], "Not an oracle");
        delete isOracle[_toRemove];
        emit OracleRemoved(_toRemove);
    }

    function addVerifier(address _toAdd) public onlyOwnerOrVotingSystem {
        requireNonZeroAddress(_toAdd);
        require(!isVerifier[_toAdd], "Already present");
        isVerifier[_toAdd] = true;
        emit VerifierAdded(_toAdd);
    }

    function removeVerifier(address _toRemove) public onlyOwnerOrVotingSystem {
        require(isVerifier[_toRemove], "Not a verifier");
        delete isVerifier[_toRemove];
        emit VerifierRemoved(_toRemove);
    }

    function addStamper(address _toAdd) public onlyOwnerOrVotingSystem {
        requireNonZeroAddress(_toAdd);
        require(!isStamper[_toAdd], "Already present");
        isStamper[_toAdd] = true;
        emit StamperAdded(_toAdd);
    }

    function removeStamper(address _toRemove) public onlyOwnerOrVotingSystem {
        require(isStamper[_toRemove], "Not a stamper");
        delete isStamper[_toRemove];
        emit StamperRemoved(_toRemove);
    }

    function isExchange(address exchangeAddress) public view returns (bool) {
        return exchangeMapping[exchangeAddress];
    }

    function addExchange(address _exchange) public onlyOwnerOrExchangeFactoryOrVotingSystem {
        requireNonZeroAddress(_exchange);
        require(!exchangeMapping[_exchange], "Already added");
        doAddWalletAccess(_exchange);
        exchanges.push(_exchange);
        exchangeMapping[_exchange] = true;
        emit ExchangeAdded(_exchange);
    }

    function removeExchange(address _exchange) public onlyOwnerOrExchangeFactoryOrVotingSystem {
        require(exchangeMapping[_exchange], "Not an exchange");
        removeWalletAccess(_exchange);

        delete exchangeMapping[_exchange];

        removeExchangeFromArray(_exchange);
        emit ExchangeRemoved(_exchange);
    }

    function removeExchangeFromArray(address exchange) private {
        require(exchanges.length > 0, "No elements");

        int256 index = getIndexOf(exchange);

        require(index >= 0, "Exchange not found");

        // copy last entry into the slot in which we found the address
        exchanges[uint256(index)] = exchanges[exchanges.length - 1];

        // remove last element
        exchanges.pop();
    }

    function getIndexOf(address exchange) private view returns (int256) {
        for (uint256 index = 0; index < exchanges.length; index++) {
            if (exchanges[index] == exchange) {
                return int256(index);
            }
        }

        return -1;
    }

    function requireNonZeroAddress(address a) private pure {
        require(a != address(0), "address must be non zero");
    }

    function getExchanges() public view returns (address[] memory) {
        return exchanges;
    }
}