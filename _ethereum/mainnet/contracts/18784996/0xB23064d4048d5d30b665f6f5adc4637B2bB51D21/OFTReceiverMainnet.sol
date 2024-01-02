// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOFTReceiverV2.sol";
import "./OwnableUpgradeable.sol";
import "./IAuraRouter.sol";
import "./IERC20.sol";
import "./NonblockingLzApp.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract OFTReceiverMainnet is IOFTReceiverV2, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IAuraRouter private constant AURA_ROUTER = IAuraRouter(0xf01dD67Ed9006f13F79ba9DE1a370864ad92b449);

    IERC20 private constant WRAPPED_JONES_AURA = IERC20(0x198d7387Fa97A73F05b8578CdEFf8F2A1f34Cd1F);
    IERC20 private constant AURA = IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);

    uint256 private constant MAX = ~uint256(0);

    address private _oftV2;

    error ZeroAddress();
    error Unauthorized();
    error NotEnoughBalance();

    function init(address _wjAuraOFTV2) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        WRAPPED_JONES_AURA.approve(address(AURA_ROUTER), MAX);
        AURA.approve(address(AURA_ROUTER), MAX);

        if (_wjAuraOFTV2 == address(0)) revert ZeroAddress();

        _oftV2 = _wjAuraOFTV2;
    }

    /**
     * @dev Called by the OFT contract when tokens are received from source chain.
     * @param @null chain id of the source chain.
     * @param @null address of the OFT token contract on the source chain.
     * @param @null The nonce of the transaction on the source chain.
     * @param _caller The address of the account who calls the sendAndCall() on the source chain.
     * @param _amount The amount of tokens to transfer.
     * @param @null Additional data with no specified format.
     */
    function onOFTReceived(uint16, bytes calldata, uint64, bytes32 _caller, uint256 _amount, bytes calldata)
        external
        override
    {
        if (WRAPPED_JONES_AURA.balanceOf(address(this)) < _amount) revert NotEnoughBalance();
        if (msg.sender != _oftV2 && _oftV2 != address(0)) revert Unauthorized();

        // If this was called, we are sure the wjAURA tokens are already transferred to this contract.
        AURA_ROUTER.withdrawRequest(_amount, true, address(bytes20(_caller)));
    }

    /**
     *
     * @param @null
     * @param @null
     * @param @null
     * @param _payload Receive information about user from Arbitrum MultichainHub
     */
    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal nonReentrant {
        (address user, uint256 amount) = abi.decode(_payload, (address, uint256));

        if (AURA.balanceOf(address(this)) < amount) revert NotEnoughBalance();

        try AURA_ROUTER.deposit(amount, true) returns (uint256 received) {
            WRAPPED_JONES_AURA.transfer(user, received);
        } catch {
            AURA.transfer(user, amount);
        }
    }

    function rescueErc20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function updateMsgSender(address _sender) external onlyOwner {
        _oftV2 = _sender;
    }
}
