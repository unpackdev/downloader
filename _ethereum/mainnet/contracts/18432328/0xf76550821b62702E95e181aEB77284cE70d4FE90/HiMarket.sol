// SPDX-License-Identifier: MIT

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



pragma solidity >=0.8.2 <0.9.0;

contract HiMarket is Ownable {
    address public protocolFeeDestination = 0xd45DCFa9b6136C24c80578B50Ff793E374F3F427;
    address public protocolFeeDestination2 = 0x8a8Cf648e6A7325AaE25bEfD04FF2a2cb29B0A16;
    uint256 public protocolFeePercentBuy = 50000000000000000;
    uint256 public protocolFeePercentSell = 50000000000000000;
    mapping(address => uint256) public subjectFeePercent;
    mapping(address => uint256) public holderFeePercent;
    uint256 public subjectFeeMax = 100000000000000000;
    mapping(address => mapping(address => uint256)) public sharesBalance;
    mapping(address => uint256) public sharesSupply;

    event Transfer(address trader,address subject, address from, uint256 isBuy, uint256 shareAmount, uint256 ethAmount, uint256 subjectEthAmount, uint256 supply , uint256 holderFee);

    //SET
    function setFeeDestination(address _feeDestination, address _feeDestination2) public onlyOwner {
        protocolFeeDestination = _feeDestination;
        protocolFeeDestination2 = _feeDestination2;
    }

    function setProtocolFeePercent(uint256 _feePercentBuy,uint256 _feePercentSell) public onlyOwner {
        protocolFeePercentBuy = _feePercentBuy;
        protocolFeePercentSell = _feePercentSell;
    }

    function setSubjectFeePercentMax(uint256 _feePercent) public onlyOwner {
        subjectFeeMax = _feePercent;

    }

    function setSubjectFeePercent(uint256 _feePercent, uint256 _feeHolderPercent) public {
        require(sharesSupply[msg.sender] > 0,"No own");
        require(_feePercent + _feeHolderPercent<=subjectFeeMax, "Max Fee Error");
        subjectFeePercent[msg.sender]=_feePercent;
        holderFeePercent[msg.sender]=_feeHolderPercent;
    }

    
    function firstShare(uint256 subjectFee_, uint256 holderFee_) public payable {
    require(subjectFee_+holderFee_<=subjectFeeMax, "Max Fee Error");
    require(sharesSupply[msg.sender]==0,"You already have an account subject");
    sharesBalance[msg.sender][msg.sender] = 1;
    sharesSupply[msg.sender]=1;
    subjectFeePercent[msg.sender]=subjectFee_;
    holderFeePercent[msg.sender]=holderFee_;
    emit Transfer(msg.sender, msg.sender, 0x0000000000000000000000000000000000000000, 1, 1, 0, 0, 1, 0);
    }

    function transferShare(address shareAddress, uint256 amount, address to) public {
        require(sharesBalance[shareAddress][msg.sender]>=amount);
        if (to==0x0000000000000000000000000000000000000000) {
            (bool success, ) = protocolFeeDestination.call{value: getPrice(sharesBalance[shareAddress][0x0000000000000000000000000000000000000000],amount)}("");
            require(success, "Unable to send funds"); 
        }
        sharesBalance[shareAddress][msg.sender] = sharesBalance[shareAddress][msg.sender] - amount;
        sharesBalance[shareAddress][to] = sharesBalance[shareAddress][to] + amount;
        emit Transfer(msg.sender, shareAddress, to, 3, amount, 0, 0, sharesSupply[shareAddress], 0);
    }
     

    //GET
    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000;
    }

    function getBuyPrice(address shareAddress, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[shareAddress], amount);
    }

    function getSellPrice(address shareAddress, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[shareAddress] - amount, amount);
    }

    function getBuyPriceAfterFee(address shareAddress, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(shareAddress, amount);
        uint256 protocolFee = price * protocolFeePercentBuy / 1 ether;
        uint256 subjectFee = price * subjectFeePercent[shareAddress] / 1 ether;
        uint256 holderFee = price * holderFeePercent[shareAddress] / 1 ether;
        return price + protocolFee + subjectFee + holderFee;
    }

    function getSellPriceAfterFee(address shareAddress, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(shareAddress, amount);
        uint256 protocolFee = price * protocolFeePercentSell / 1 ether;
        uint256 subjectFee = price * subjectFeePercent[shareAddress] / 1 ether;
        uint256 holderFee = price * holderFeePercent[shareAddress] / 1 ether;
        return price - protocolFee - subjectFee - holderFee;
    }

    //TRADE
    function buyShares(address shareAddress, uint256 amount) public payable {
        uint256 supply = sharesSupply[shareAddress];
        require(supply > 0, "Supply > 0");
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercentBuy / 1 ether;
        uint256 subjectFee = price * subjectFeePercent[shareAddress] / 1 ether;
        uint256 holderFee = price * holderFeePercent[shareAddress] / 1 ether;
        require(msg.value >= price + protocolFee + subjectFee + holderFee, "Insufficient payment");
        sharesBalance[shareAddress][msg.sender] = sharesBalance[shareAddress][msg.sender] + amount;
        sharesSupply[shareAddress] = supply + amount;
        emit Transfer(msg.sender, shareAddress, 0x0000000000000000000000000000000000000000 , 1, amount, price, subjectFee, supply + amount, holderFee);
        (bool success, ) = shareAddress.call{value: subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: holderFee+protocolFee}("");
        require(success && success2, "Unable to send funds"); 
    }

    function sellShares(address shareAddress, uint256 amount) public payable {
        uint256 supply = sharesSupply[shareAddress];
        require(supply > amount, "Cannot sell the last share");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercentSell / 1 ether;
        uint256 subjectFee = price * subjectFeePercent[shareAddress] / 1 ether;
        uint256 holderFee = price * holderFeePercent[shareAddress] / 1 ether;
        require(sharesBalance[shareAddress][msg.sender] >= amount, "Insufficient shares");
        sharesBalance[shareAddress][msg.sender] = sharesBalance[shareAddress][msg.sender] - amount;
        sharesSupply[shareAddress] = supply - amount;
        emit Transfer(msg.sender, shareAddress, 0x0000000000000000000000000000000000000000, 2, amount, price, subjectFee, supply - amount, holderFee);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee - holderFee}(""); 
        (bool success2, ) = shareAddress.call{value: subjectFee}("");
        (bool success3, ) = protocolFeeDestination2.call{value: holderFee+protocolFee}("");
        require(success1 && success2 && success3, "Unable to send funds"); 

    }
}