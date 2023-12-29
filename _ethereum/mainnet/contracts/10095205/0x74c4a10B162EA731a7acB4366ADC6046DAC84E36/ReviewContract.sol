pragma solidity ^0.4.24;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title ReviewStorage
 * @dev The ReviewStorage contract has an  .
 */
contract ReviewStorage {

    mapping (string => bool) internal  clientReviews;
    string[] public indexReview;

    event NewReviewHash(string _reviewHash, uint256 _createdTime);

    /**
     * @dev Returns whether this hash exists or not.
     * @param _hashReview Verifiable hash.
     */
    function getExistingReview(string _hashReview) public view returns(bool) {
        if (clientReviews[_hashReview] == true) {
            return true;
        }
        else
            return false;
    }

    /**
    * @dev Returns hash by index.
    * @param _index  Verifiable index.
    */
    function getReviewHash(uint256 _index) public view returns(string) {
        require(_index < indexReview.length, "Index hasn't exist");
        return indexReview[_index];
    }

    /**
     * @dev Returns the number of saved hashes.
    */
    function totalHashes() public view returns(uint256) {
        return indexReview.length;
    }
}

/**
 * @title ReviewContract
 * @dev The ReviewContract contract has an   .
 */
contract ReviewContract is Ownable, ReviewStorage {

    /**
    * @dev The ReviewContract constructor
    */
    constructor () public { }


    /**
     * @dev Saves the hash to storage if it doesn't already exist
     * @param _reviewHash  Verifiable hash.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function addNewReviewHash(string  _reviewHash) public onlyOwner {
        require(!getExistingReview(_reviewHash), "Index hasn't exist");
        clientReviews[_reviewHash] = true;
        indexReview.push(string(_reviewHash));
        emit NewReviewHash(_reviewHash, now);
    }

    /**
     * @dev Fullback call
     */
    function () public payable {
        revert("Contract cannot be funded");
    }
}