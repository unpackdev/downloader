//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./ERC20.sol";
import "./AccessControlMixin.sol";
import "./IChildToken.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";
import "./ERC20Burnable.sol";

contract GoldFeverNativeGold is
    ERC20,
    ERC20Burnable,
    IChildToken,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    constructor(
        address childChainManager
    ) public ERC20("Gold Fever Native Gold", "NGL") {
        _setupContractId("GoldFeverNativeGold");
        _setupRole(DEPOSITOR_ROLE, childChainManager);
        _initializeEIP712("Gold Fever Native Gold");
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        view
        override
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData)
        external
        override
        only(DEPOSITOR_ROLE)
    {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}
