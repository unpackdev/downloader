pragma solidity ^0.5.8;

// openzeppelin-solidity@2.5.1 from NPM

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

contract AccessList is Ownable {

    string private __identifier;
    mapping(address => bool) private accessList;

    event WalletEnabled(address indexed wallet);
    event WalletDisabled(address indexed wallet);

    constructor(string memory _identifier) public {
        __identifier = _identifier;
    }

    function enableWallet(address _wallet)
        public
        onlyOwner
        {
            require(_wallet != address(0), "Invalid wallet");
            accessList[_wallet] = true;
            emit WalletEnabled(_wallet);
    }

    function disableWallet(address _wallet)
        public
        onlyOwner
        {
            accessList[_wallet] = false;
            emit WalletDisabled(_wallet);
    }

    function enableWalletList(address[] calldata _walletList)
        external
        onlyOwner {
            for(uint i = 0; i < _walletList.length; i++) {
                enableWallet(_walletList[i]);
            }
    }

    function disableWalletList(address[] calldata _walletList)
        external
        onlyOwner {
            for(uint i = 0; i < _walletList.length; i++) {
                disableWallet(_walletList[i]);
            }
    }

    function checkEnabled(address _wallet)
        external
        view
        returns (bool) {
            return accessList[_wallet];
    }

    function checkEnabled(address _wallet1, address _wallet2)
        external
        view
        returns (bool) {
            return accessList[_wallet1] && accessList[_wallet2];
    }

    function checkEnabled(address _wallet1, address _wallet2, address _wallet3)
        external
        view
        returns (bool) {
            return accessList[_wallet1] && accessList[_wallet2] && accessList[_wallet3];
    }

    function identifier()
        external
        view 
        returns (string memory) {
            return __identifier;
        }

}

contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Authorizable: Address is not authorized");
        _;
    }

    event AddressEnabled(address enabledAddress);
    event AddressDisabled(address disabledAddress);

    function enableAddress(address _address) public onlyOwner {
        authorized[_address] = true;
        emit AddressEnabled(_address);
    }

    function disableAddress(address _address) public onlyOwner {
        authorized[_address] = false;
        emit AddressDisabled(_address);
    }

    function isAuthorized(address _address) public view returns (bool) {
        return authorized[_address];
    }

}

contract OneSignRegistry is Authorizable {

    AccessList public accessList;

    event AccessListSet(address accessList);
    event DocumentRegistered(string issuer, string documentHash, address sender);
    event DocumentRegistered(address issuer, string documentHash, address sender);

    /**
     * @dev Adds or updates this contract's access list
     * @param _accessList the access list address
     */
    function setupAccessList(address _accessList)
        external
        onlyAuthorized {
            if (_accessList == address(0)) revert("Invalid access list address");
            accessList = AccessList(_accessList);
            emit AccessListSet(_accessList);
    }

    /**
     * @dev Registers a file on behalf of _issuer
     * @param _issuer issuer ID
     * @param _documentHash hash of the document
     */
    function registerFile(string calldata _issuer, string calldata _documentHash) external {
        require(accessList.checkEnabled(msg.sender), "AccessList: address not authorized");
        emit DocumentRegistered(_issuer, _documentHash, msg.sender);
    }

    /**
     * @dev Registers a file for msg.sender
     * @param _documentHash hash of the document
     */
    function registerFile(string calldata _documentHash) external {
        require(accessList.checkEnabled(msg.sender), "AccessList: address not authorized");
        emit DocumentRegistered(msg.sender, _documentHash, msg.sender);
    }

}