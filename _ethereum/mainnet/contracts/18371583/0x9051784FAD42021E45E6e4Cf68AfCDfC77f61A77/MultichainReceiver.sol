//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./NonblockingLzApp.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IAuraRouter.sol";
import "./ILayerZeroEndpoint.sol";

contract MultichainReceiver is NonblockingLzApp, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public constant AURA = IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20 public constant wjAURA = IERC20(0x198d7387Fa97A73F05b8578CdEFf8F2A1f34Cd1F);

    IAuraRouter public router;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    function initialize(address _endpoint, address _router) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        router = IAuraRouter(_router);
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    PUBLIC                                  */
    /* -------------------------------------------------------------------------- */

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
        public
        payable
        override
    {
        super.retryMessage(_srcChainId, _srcAddress, _nonce, _payload);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    PRIVATE                                 */
    /* -------------------------------------------------------------------------- */
    function _nonblockingLzReceive(
        uint16, /*_srcChainId*/
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal override nonReentrant {
        // use assembly to extract the address from the bytes memory parameter
        address sendBackToAddress;
        assembly {
            sendBackToAddress := mload(add(_srcAddress, 20))
        }

        // decode deposit msg
        (address _user, uint256 _amount, bool _deposit) = abi.decode(_payload, (address, uint256, bool));

        if (_deposit) {
            if (AURA.balanceOf(address(this)) < _amount) {
                revert OutOfFunds();
            }

            AURA.approve(address(router), _amount);

            try router.deposit(_amount, true) returns (uint256 shares) {
                wjAURA.transfer(_user, shares);
            } catch {
                AURA.safeDecreaseAllowance(address(router), _amount);
                AURA.transfer(_user, _amount);
            }
        } else {
            if (wjAURA.balanceOf(address(this)) < _amount) {
                revert OutOfFunds();
            }

            wjAURA.approve(address(router), _amount);

            // Add User
            try router.withdrawRequest(_amount, true, _user) {}
            catch {
                wjAURA.safeDecreaseAllowance(address(router), _amount);
                wjAURA.transfer(_user, _amount);
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY OWNER                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyOwner {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.transfer(_to, assetBalance);
            }

            unchecked {
                ++i;
            }
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            (bool sent,) = payable(_to).call{value: nativeBalance}("");
            if (!sent) {
                revert FailSendETH();
            }
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    function updateRouter(address _router) external onlyOwner {
        router = IAuraRouter(_router);
    }

    function updateLayerZeroEndpoint(address _endpoint) external onlyOwner {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error OutOfFunds();
    error FailSendETH();
}
