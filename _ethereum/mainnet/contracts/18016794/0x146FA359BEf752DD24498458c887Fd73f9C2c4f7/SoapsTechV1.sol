/**
Welcome to the Soaps Tech.

Website: https://soaps.tech/
Telegram: https://t.me/soapstech
X: https://x.com/soapstech

*/

// SPDX-License-Identifier: MIT

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract SoapsTechV1 is Ownable {
    address public protocolFeeRecipient;
    uint256 public protocolFeeRate;
    uint256 public roomFeeRate;
    uint256 public priceRate;

    constructor() {
        protocolFeeRecipient = msg.sender;
        priceRate = 16_000;
        roomFeeRate = 100_000_000_000_000_000;
        protocolFeeRate = 100_000_000_000_000_000;
    }

    event Trade(
        address trader,
        address room,
        bool isBuy,
        uint256 keyAmount,
        uint256 ethAmount,
        uint256 protocolEthAmount,
        uint256 subjectEthAmount,
        uint256 supply
    );

    // Key => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public poolKey;

    // Key => Supply
    mapping(address => uint256) public supplyKey;

    function setFeeRecipient(address _feeRecipient) public onlyOwner {
        protocolFeeRecipient = _feeRecipient;
    }

    function setProtocolFeeRate(uint256 _feeRate) public onlyOwner {
        protocolFeeRate = _feeRate;
    }

    function setRoomFeeRate(uint256 _feeRate) public onlyOwner {
        roomFeeRate = _feeRate;
    }

    function setPriceRate(uint256 _priceRate) public onlyOwner {
        priceRate = _priceRate;
    }

    function getPrice(
        uint256 supply,
        uint256 amount
    ) public view returns (uint256) {
        uint256 sum1 = supply == 0
            ? 0
            : ((supply - 1) * (supply) * (2 * (supply - 1) + 1)) / 6;
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : ((supply - 1 + amount) *
                (supply + amount) *
                (2 * (supply - 1 + amount) + 1)) / 6;
        uint256 summation = sum2 - sum1;
        return (summation * 1 ether) / priceRate;
    }

    function getBuyPrice(
        address keyOwner,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(supplyKey[keyOwner], amount);
    }

    function getSellPrice(
        address keyOwner,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(supplyKey[keyOwner] - amount, amount);
    }

    function getBuyPriceAfterFee(
        address keyOwner,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getBuyPrice(keyOwner, amount);
        uint256 protocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 roomFee = (price * roomFeeRate) / 1 ether;
        return price + protocolFee + roomFee;
    }

    function getSellPriceAfterFee(
        address keyOwner,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getSellPrice(keyOwner, amount);
        uint256 protocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 roomFee = (price * roomFeeRate) / 1 ether;
        return price - protocolFee - roomFee;
    }

    function buyKeys(address keyOwner, uint256 amount) public payable {
        uint256 supply = supplyKey[keyOwner];
        require(
            supply > 0 || keyOwner == msg.sender,
            "Only the key' room can buy the first key"
        );
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 roomFee = (price * roomFeeRate) / 1 ether;
        require(
            msg.value >= price + protocolFee + roomFee,
            "Insufficient payment"
        );
        poolKey[keyOwner][msg.sender] = poolKey[keyOwner][msg.sender] + amount;
        supplyKey[keyOwner] = supply + amount;
        emit Trade(
            msg.sender,
            keyOwner,
            true,
            amount,
            price,
            protocolFee,
            roomFee,
            supply + amount
        );
        (bool success1, ) = protocolFeeRecipient.call{value: protocolFee}("");
        (bool success2, ) = keyOwner.call{value: roomFee}("");
        require(success1 && success2, "Unable to send funds");
    }

    function sellKeys(address keyOwner, uint256 amount) public payable {
        uint256 supply = supplyKey[keyOwner];
        require(supply > amount, "Cannot sell the last key");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 roomFee = (price * roomFeeRate) / 1 ether;
        require(poolKey[keyOwner][msg.sender] >= amount, "Insufficient keys");
        poolKey[keyOwner][msg.sender] = poolKey[keyOwner][msg.sender] - amount;
        supplyKey[keyOwner] = supply - amount;
        emit Trade(
            msg.sender,
            keyOwner,
            false,
            amount,
            price,
            protocolFee,
            roomFee,
            supply - amount
        );
        (bool success1, ) = msg.sender.call{
            value: price - protocolFee - roomFee
        }("");
        (bool success2, ) = protocolFeeRecipient.call{value: protocolFee}("");
        (bool success3, ) = keyOwner.call{value: roomFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }
}
