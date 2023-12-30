// File: node_modules\openzeppelin-solidity\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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

// File: contracts\Barocheck.sol

//solium-disable linebreak-style
pragma solidity ^0.5.8;


contract Barocheck is Ownable {

    string public constant name = "Barocheck";
    struct DataInfo {
        address sender;
        string dataHash;
    }
    mapping(string => DataInfo) internal data;

    constructor() public {
        creator = msg.sender;
    }

    //creator
    address public creator;

    function write(
        string memory key,        
        string memory dataHash
    )
      public
      returns (bool)
    {
        if (keccak256(abi.encodePacked((data[key].dataHash))) != keccak256(abi.encodePacked(("")))) return false;
        if (msg.sender != owner() && msg.sender != creator) return false;
        
        data[key] = DataInfo(msg.sender, dataHash);

        return true;
    }

    function readDataHash(string memory key) public view returns (string memory) {
        return data[key].dataHash;
    }

    function readSender(string memory key) public view returns (address) {
        return data[key].sender;
    }
}