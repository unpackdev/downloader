// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./ECDSA.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";

contract SidusDutchAuction is AccessControl, Pausable {
    mapping(address => bool) public signers;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    event buy(address indexed user, uint itemId, uint amount);

    address public paymentKeeper;
    mapping(uint => bool) public items;
    bytes32 public constant PAUSEMODE_ROLE = keccak256("PAUSEMODE_ROLE");

    constructor(address keeper) {
        paymentKeeper = keeper;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSEMODE_ROLE, msg.sender);
    }

    function setSigner(
        address signer,
        bool isValid
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signers[signer] = isValid;
    }

    /// @param payType 1 for eth, 2 for token
    /// @param amount  amount in eth or tokens
    /// @param itemId id of nft
    /// @param tokenAddress address of token
    /// @param signature signature
    function buyItem(
        uint payType,
        uint amount,
        uint itemId,
        address tokenAddress,
        bytes calldata signature
    ) external payable whenNotPaused {
       // require(!items[itemId], "other user has bought this item");
        bytes32 _msgForSign = keccak256(
            abi.encode(payType, amount, itemId, msg.sender, tokenAddress)
        ).toEthSignedMessageHash();
        require(signers[_msgForSign.recover(signature)], "bad signer");
        if (payType == 1) {
            // eth
            require(msg.value == amount, "not enought eth");
            payable(paymentKeeper).transfer(msg.value);
        } else if (payType == 2) {
            //token
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                paymentKeeper,
                amount
            );
        } else {
            revert("bad payType");
        }
        items[itemId] = true;
        emit buy(msg.sender, itemId, amount);
    }

    function pauseOn() external whenNotPaused onlyRole(PAUSEMODE_ROLE) {
        _pause();
    }

    function pauseOff() external whenPaused onlyRole(PAUSEMODE_ROLE) {
        _unpause();
    }

    function changeKeeper(address newKeeper) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paymentKeeper = newKeeper;
    }
}
