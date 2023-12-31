// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "./ISwap.sol";
import "./SafeERC20.sol";
import "./Context.sol";

contract PlasticHeroBridge is Context {
    using SafeERC20 for IERC20;

    mapping(string => bool) public filledPHTx;

    address public owner;
    address public superAdmin;
    address public tokenAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SuperAdminChanged(address indexed previousSuperAdmin, address indexed newSuperAdmin);
    event SwapStarted(
        address indexed bep20Addr,
        address indexed fromAddr,
        uint256 amount,
        string userName,
        string PHAddress
    );
    event SwapFilled(address indexed bep20Addr, string PHTxHash, address indexed toAddress, uint256 amount);
    event tokenAddressUpdated(address crrTokenAddr, address newTokenAdd);

    constructor(address super_Admin, address token_Address) {
        owner = msg.sender;
        superAdmin = super_Admin;
        tokenAddress = token_Address;
    }

    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * Throws if called transferOwnership by any account other than the super admin.
     */
    modifier onlySuperAdmin() {
        require(superAdmin == _msgSender(), "Super Admin: caller is not the super admin");
        _;
    }

    /**
     * Leaves the contract without owner. It will not be possible to call
     * `onlySuperAdmin` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlySuperAdmin {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlySuperAdmin {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * Change Super Admin of the contract to a new account (`newSuperAdmin`).
     * Can only be called by the current super admin.
     */
    function changeSuperAdmin(address newSuperAdmin) public onlySuperAdmin {
        require(newSuperAdmin != address(0), "Super Admin: new super admin is the zero address");
        emit SuperAdminChanged(superAdmin, newSuperAdmin);
        superAdmin = newSuperAdmin;
    }

    /**
     * Update token address
     * Can only be called by the current super admin.
     */
    function changeTokenAddress(address newTokenAddress) public onlyOwner {
        emit tokenAddressUpdated(tokenAddress, newTokenAddress);
        tokenAddress = newTokenAddress;
    }

    /**
     * fill Swap between
     */
    function fillSwap(
        string memory requestSwapTxHash,
        address toAddress,
        uint256 amount
    ) external onlyOwner returns (bool) {
        require(!filledPHTx[requestSwapTxHash], "tx filled already");
        require(tokenAddress != address(0x0), "token address not defined");
        require(amount > 0, "Amount should be greater than 0");

        ISwap(tokenAddress).mint(toAddress, amount);
        filledPHTx[requestSwapTxHash] = true;
        emit SwapFilled(tokenAddress, requestSwapTxHash, toAddress, amount);

        return true;
    }

    /**
     * swap token
     */
    function swapToken(
        uint256 amount,
        string calldata userName,
        string calldata phAddress
    ) external returns (bool) {
        require(tokenAddress != address(0x0), "token address not defined");
        require(amount > 0, "Amount should be greater than 0");

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        ISwap(tokenAddress).burn(amount);

        emit SwapStarted(tokenAddress, msg.sender, amount, userName, phAddress);
        return true;
    }
}
