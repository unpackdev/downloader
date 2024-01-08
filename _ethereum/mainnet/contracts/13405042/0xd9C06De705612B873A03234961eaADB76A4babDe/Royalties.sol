//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract Royalties is Ownable {
    // Libraries
    using SafeMath for uint256;

    // royalty owners to their balances
    // Owner => Collateral address => balance
    mapping(address => uint256) internal royalties_;
    // old address to new address
    mapping(address => address) internal addressForwarding_;

    event DepositReceived(
        address indexed depositor,
        address indexed receiver,
        uint256 amount
    );

    event Withdraw(address indexed withdrawer, uint256 amount);

    event AddressUpdated(
        address indexed originalCreatorAddress,
        address indexed oldAddress,
        address indexed newAddress
    );

    constructor() Ownable() {}

    function getBalance(address _user) external view returns (uint256) {
        if (addressForwarding_[_user] != address(0)) {
            return royalties_[addressForwarding_[_user]];
        } else {
            return royalties_[_user];
        }
    }

    function init() external view returns (bool) {
        return true;
    }

    /**
     * @param   _to Origional address of creator. Even if the users address has
     *          been updated, this address MUST remain as the original creator
     *          address
     * @param   _amount Amount being deposited
     * @notice  msg.sender MUST approve this contract address as spender for the
     *          `_amount`. Will set the forwarding address if it has not been
     *          set
     */
    function deposit(address _to, uint256 _amount) external payable {
        // Withdrawing the collateral from sender to this contract
        require(msg.value >= _amount, "ROY: Fatal: Value mismatch");
        // If the `_to` (creator) address has address forwarding
        if (addressForwarding_[_to] != address(0)) {
            // Saving the royalties balance to the forwarding address
            royalties_[addressForwarding_[_to]] = royalties_[
                addressForwarding_[_to]
            ]
            .add(_amount);
        } else {
            // Saving the addresses balance
            royalties_[_to] = royalties_[_to].add(_amount);
        }

        emit DepositReceived(msg.sender, _to, _amount);
    }

    /**
     * @param   _amount Amount of collateral to withdraw
     * @notice  If a forwarding address has been set, the msg.sender address
     *          will not be checked for balances, but the original address will.
     *          Will revert if `_amount` is more than stored balance.
     */
    function withdraw(uint256 _amount) external {
        require(royalties_[msg.sender] >= _amount, "Amount more than balance");
        // Removing amount from balance
        royalties_[msg.sender] = royalties_[msg.sender].sub(_amount);
        // Sending user amount
        (bool success, ) = msg.sender.call{value: _amount}("");
        // Ensuring transfer succeeded
        require(success, "Transfer failed.");

        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @param   _amount The amount of collateral the owner wants to withdraw
     * @notice  Will revert is msg.sender is not owner
     */
    function withdrawSystem(uint256 _amount) external onlyOwner() {
        require(royalties_[address(0)] >= _amount, "Amount more than balance");
        // Removing amount from balance
        royalties_[address(0)] = royalties_[address(0)].sub(_amount);
        // Sending user amount
        (bool success, ) = msg.sender.call{value: _amount}("");
        // Ensuring transfer succeeded
        require(success, "Transfer failed.");

        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @param   _originalCreatorAddress Address listed as creator on tokens
     * @param   _oldAddress Address of their previous address (if the creator
     *          has lost their address for the first time, this is the 0x
     *          address)
     * @param   _newAddress The address of the new wallet
     * @notice  If the old address is still the creator of tokens, the royalties
     *          will still be sent to the old creator address. As such, the
     *          `_originalCreatorAddress` MUST ALWAYS be the address listed as
     *          the creator of the tokens
     */
    function updateAddress(
        address _originalCreatorAddress,
        address _oldAddress,
        address _newAddress
    ) external onlyOwner() {
        // Checks if `_newAddress` has existing royalties
        uint256 existingRoyalties = royalties_[_newAddress];
        // If this is the first time the user has lost their account
        if (_oldAddress == address(0)) {
            // Setting the old address to forward to the new address
            addressForwarding_[_originalCreatorAddress] = _newAddress;
            // Migrating storage of the old address to the new address
            royalties_[_newAddress] = royalties_[_originalCreatorAddress];
            // Adding any existing royalties back
            if (existingRoyalties != 0) {
                royalties_[_newAddress] = royalties_[_newAddress].add(
                    existingRoyalties
                );
            }
            // Deleting the old addresses storage
            delete royalties_[_originalCreatorAddress];
        } else {
            // Setting the old address to forward to the new address
            addressForwarding_[_originalCreatorAddress] = _newAddress;
            addressForwarding_[_oldAddress] = _newAddress;
            // Migrating storage of the old address to the new address
            royalties_[_newAddress] = royalties_[_oldAddress];
            if (existingRoyalties != 0) {
                royalties_[_newAddress] = royalties_[_newAddress].add(
                    existingRoyalties
                );
            }
            // Deleting the old addresses storage
            delete royalties_[_oldAddress];
        }

        emit AddressUpdated(_originalCreatorAddress, _oldAddress, _newAddress);
    }
}
