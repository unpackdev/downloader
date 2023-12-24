/**
 *Submitted for verification at basescan.org on 2023-08-31
*/

// File: contracts/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// File: contracts/FriendtechShares.sol



pragma solidity >=0.8.2 <0.9.0;


// TODO: Events, final pricing model, 

contract FriendShares_io is Ownable {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent = 50000000000000000;
    uint256 public subjectFeePercent = 50000000000000000;
    mapping(address => uint256) public subjectFeePercentMapping;
    mapping(address => uint256) public protocolFeePercentMapping;
    uint256 public maxFeePercent = 100000000000000000;


    event Trade(address trader, address subject, bool isBuy, uint256 shareAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 supply);

    // SharesSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;

    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
    uint256 sum1 = supply == 0 ? 0 : (supply - 1) * supply * (2 * (supply - 1) + 1) / 6;
    uint256 sum2 = (supply == 0 && amount == 1) ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
    return (sum2 - sum1) * 1 ether / 16000;
    }

    function getBuyPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
    uint256 adjustedSupply = (sharesSupply[sharesSubject] == 0) ? 1 : sharesSupply[sharesSubject];
    return getPrice(adjustedSupply, amount);
    }

    function getSellPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
    return getPrice(sharesSupply[sharesSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(sharesSubject, amount);
        uint256 protocolFeeCalc = protocolFeePercentMapping[sharesSubject] == 0 ? protocolFeePercent : protocolFeePercentMapping[sharesSubject];
        uint256 protocolFee = price * protocolFeeCalc / 1 ether;
        uint256 subjectFeeCalc = subjectFeePercentMapping[sharesSubject] == 0 ? subjectFeePercent : subjectFeePercentMapping[sharesSubject];
        uint256 subjectFee = price * subjectFeeCalc / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function getSellPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject, amount);
        uint256 protocolFeeCalc = protocolFeePercentMapping[sharesSubject] == 0 ? protocolFeePercent : protocolFeePercentMapping[sharesSubject];
        uint256 protocolFee = price * protocolFeeCalc / 1 ether;
        uint256 subjectFeeCalc = subjectFeePercentMapping[sharesSubject] == 0 ? subjectFeePercent : subjectFeePercentMapping[sharesSubject];
        uint256 subjectFee = price * subjectFeeCalc / 1 ether;
       return price - protocolFee - subjectFee;
    } 

    function buyShares(address sharesSubject, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        if (supply == 0) {
        // Reserve the first share for the sharesSubject 
        sharesBalance[sharesSubject][sharesSubject] = 1;
        sharesSupply[sharesSubject] = 1;
        supply = 1;  
        }
        uint256 price = getBuyPrice(sharesSubject, amount);
        uint256 protocolFeeCalc = protocolFeePercentMapping[sharesSubject] == 0 ? protocolFeePercent : protocolFeePercentMapping[sharesSubject];
        uint256 protocolFee = price * protocolFeeCalc / 1 ether;
        uint256 subjectFeeCalc = subjectFeePercentMapping[sharesSubject] == 0 ? subjectFeePercent : subjectFeePercentMapping[sharesSubject];
        uint256 subjectFee = price * subjectFeeCalc / 1 ether;
        require(msg.value >= price + protocolFee + subjectFee, "Insufficient payment");
        sharesBalance[sharesSubject][msg.sender] += amount;
        sharesSupply[sharesSubject] += amount;
        emit Trade(msg.sender, sharesSubject, true, amount, price, protocolFee, subjectFee, supply + amount);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2, "Unable to send funds");
    }


    function sellShares(address sharesSubject, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > amount, "Cannot sell the last share");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFeeCalc = protocolFeePercentMapping[sharesSubject] == 0 ? protocolFeePercent : protocolFeePercentMapping[sharesSubject];
        uint256 protocolFee = price * protocolFeeCalc / 1 ether;
        uint256 subjectFeeCalc = subjectFeePercentMapping[sharesSubject] == 0 ? subjectFeePercent : subjectFeePercentMapping[sharesSubject];
        uint256 subjectFee = price * subjectFeeCalc / 1 ether;
        require(sharesBalance[sharesSubject][msg.sender] >= amount, "Insufficient shares");
        sharesBalance[sharesSubject][msg.sender] = sharesBalance[sharesSubject][msg.sender] - amount;
        sharesSupply[sharesSubject] = supply - amount;
        emit Trade(msg.sender, sharesSubject, false, amount, price, protocolFee, subjectFee, supply - amount);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

    function setFeePercentForSubject(uint256 _feePercent) public {
        require(_feePercent <= maxFeePercent, "Fee percent cannot be greater than the maximum allowed");
        subjectFeePercentMapping[msg.sender] = _feePercent;
    }

    function setcustomprotocolFeePercent(uint256 _feePercent, address sharesSubject) public onlyOwner {
        require(_feePercent <= maxFeePercent, "Fee percent cannot be greater than the maximum allowed");
        protocolFeePercentMapping[sharesSubject] = _feePercent;
    }

    function setMaxFeePercent(uint256 _newMaxFeePercent) public onlyOwner {
        maxFeePercent = _newMaxFeePercent;
    }



    function claimShare() public {
    uint256 supply = sharesSupply[msg.sender];
    require(supply == 0, "First share already claimed");
    sharesBalance[msg.sender][msg.sender] = 1;
    sharesSupply[msg.sender] = 1;
    supply = 1;  

    emit Trade(msg.sender, msg.sender, true, 1, 0, 0, 0, supply);
    }



}