// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Address.sol";
import "./ERC165Checker.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";

import "./ICrossDomainMessenger.sol";
import "./IKromaMintableERC20.sol";

/**
 * @custom:upgradeable
 * @title USDCBridge
 * @notice USDCBridge is a base contract for the L1 and L2 USDC specific bridges. It handles
 *         the core bridging logic, including escrowing tokens that are native to the local chain
 *         and minting/burning tokens that are native to the remote chain.
 */
contract USDCBridge is Pausable {
    using SafeERC20 for IERC20;
    
    /**
     * @notice Messenger contract on this domain.
     */
    ICrossDomainMessenger public immutable MESSENGER;

    /**
     * @notice Corresponding bridge on the other domain.
     */
    USDCBridge public immutable OTHER_BRIDGE;

    /**
     * @notice Mapping that stores deposits for a given pair of local and remote tokens.
     */
    mapping(address => mapping(address => uint256)) public deposits;

    /**
     * @notice Reserve extra slots (to a total of 50) in the storage layout for future upgrades.
     *         A gap size of 49 was chosen here, so that the first slot used in a child contract
     *         would be a multiple of 50.
     */
    uint256[49] private __gap;

    /**
     * @notice Emitted when an ERC20 bridge is initiated to the other chain.
     *
     * @param localToken  Address of the ERC20 on this chain.
     * @param remoteToken Address of the ERC20 on the remote chain.
     * @param from        Address of the sender.
     * @param to          Address of the receiver.
     * @param amount      Amount of the ERC20 sent.
     * @param extraData   Extra data sent with the transaction.
     */
    event ERC20BridgeInitiated(
        address indexed localToken,
        address indexed remoteToken,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @notice Emitted when an ERC20 bridge is finalized on this chain.
     *
     * @param localToken  Address of the ERC20 on this chain.
     * @param remoteToken Address of the ERC20 on the remote chain.
     * @param from        Address of the sender.
     * @param to          Address of the receiver.
     * @param amount      Amount of the ERC20 sent.
     * @param extraData   Extra data sent with the transaction.
     */
    event ERC20BridgeFinalized(
        address indexed localToken,
        address indexed remoteToken,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @notice Only allow EOAs to call the functions. Note that this is not safe against contracts
     *         calling code within their constructors, but also doesn't really matter since we're
     *         just trying to prevent users accidentally depositing with smart contract wallets.
     */
    modifier onlyEOA() {
        require(
            !Address.isContract(msg.sender),
            "USDCBridge: function can only be called from an EOA"
        );
        _;
    }

    /**
     * @notice Ensures that the caller is a cross-chain message from the other bridge.
     */
    modifier onlyOtherBridge() {
        require(
            msg.sender == address(MESSENGER) &&
                MESSENGER.xDomainMessageSender() == address(OTHER_BRIDGE),
            "USDCBridge: function can only be called from the other bridge"
        );
        _;
    }

    /**
     * @param _messenger   Address of CrossDomainMessenger on this network.
     * @param _otherBridge Address of the other USDCBridge contract.
     */
    constructor(address payable _messenger, address payable _otherBridge) {
        MESSENGER = ICrossDomainMessenger(_messenger);
        OTHER_BRIDGE = USDCBridge(_otherBridge);
    }

    /**
     * @notice Returns the full semver contract version.
     *
     * @return Semver contract version as a string.
     */
    function version() external pure returns(string memory) {
        return "1.0.0";
    }

    /**
     * @notice Sends ERC20 tokens to the sender's address on the other chain. Note that if the
     *         ERC20 token on the other chain does not recognize the local token as the correct
     *         pair token, the ERC20 bridge will fail and the tokens will be returned to sender on
     *         this chain.
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _amount      Amount of local tokens to deposit.
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function bridgeERC20(
        address _localToken,
        address _remoteToken,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) public onlyEOA whenNotPaused {
        _initiateBridgeERC20(
            _localToken,
            _remoteToken,
            msg.sender,
            msg.sender,
            _amount,
            _minGasLimit,
            _extraData
        );
    }

    /**
     * @notice Sends ERC20 tokens to a receiver's address on the other chain. Note that if the
     *         ERC20 token on the other chain does not recognize the local token as the correct
     *         pair token, the ERC20 bridge will fail and the tokens will be returned to sender on
     *         this chain.
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _to          Address of the receiver.
     * @param _amount      Amount of local tokens to deposit.
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) public whenNotPaused {
        _initiateBridgeERC20(
            _localToken,
            _remoteToken,
            msg.sender,
            _to,
            _amount,
            _minGasLimit,
            _extraData
        );
    }

    /**
     * @notice Finalizes an ERC20 bridge on this chain. Can only be triggered by the other
     *         USDCBridge contract on the remote chain.
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _from        Address of the sender.
     * @param _to          Address of the receiver.
     * @param _amount      Amount of the ERC20 being bridged.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function finalizeBridgeERC20(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _extraData
    ) public onlyOtherBridge {
        if (_isKromaMintableERC20(_localToken)) {
            require(
                _isCorrectTokenPair(_localToken, _remoteToken),
                "USDCBridge: wrong remote token for Kroma Mintable ERC20 local token"
            );

            IKromaMintableERC20(_localToken).mint(_to, _amount);
        } else {
            deposits[_localToken][_remoteToken] = deposits[_localToken][_remoteToken] - _amount;
            IERC20(_localToken).safeTransfer(_to, _amount);
        }

        emit ERC20BridgeFinalized(_localToken, _remoteToken, _from, _to, _amount, _extraData);
    }

    /**
     * @notice Sends ERC20 tokens to a receiver's address on the other chain.
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _to          Address of the receiver.
     * @param _amount      Amount of local tokens to deposit.
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function _initiateBridgeERC20(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes memory _extraData
    ) internal {
        if (_isKromaMintableERC20(_localToken)) {
            require(
                _isCorrectTokenPair(_localToken, _remoteToken),
                "USDCBridge: wrong remote token for Kroma Mintable ERC20 local token"
            );

            IKromaMintableERC20(_localToken).burn(_from, _amount);
        } else {
            IERC20(_localToken).safeTransferFrom(_from, address(this), _amount);
            deposits[_localToken][_remoteToken] = deposits[_localToken][_remoteToken] + _amount;
        }

        emit ERC20BridgeInitiated(_localToken, _remoteToken, _from, _to, _amount, _extraData);

        MESSENGER.sendMessage(
            address(OTHER_BRIDGE),
            abi.encodeWithSelector(
                this.finalizeBridgeERC20.selector,
                // Because this call will be executed on the remote chain, we reverse the order of
                // the remote and local token addresses relative to their order in the
                // finalizeBridgeERC20 function.
                _remoteToken,
                _localToken,
                _from,
                _to,
                _amount,
                _extraData
            ),
            _minGasLimit
        );
    }

    /**
     * @notice Checks if a given address is a KromaMintableERC20. Not perfect, but good enough.
     *         Just the way we like it.
     *
     * @param _token Address of the token to check.
     *
     * @return True if the token is a KromaMintableERC20.
     */
    function _isKromaMintableERC20(address _token) internal view returns (bool) {
        return ERC165Checker.supportsInterface(_token, type(IKromaMintableERC20).interfaceId);
    }

    /**
     * @notice Checks if the "other token" is the correct pair token for the KromaMintableERC20.
     *
     * @param _mintableToken KromaMintableERC20 to check against.
     * @param _otherToken    Pair token to check.
     *
     * @return True if the other token is the correct pair token for the KromaMintableERC20.
     */
    function _isCorrectTokenPair(address _mintableToken, address _otherToken)
        internal
        view
        returns (bool)
    {
        return _otherToken == IKromaMintableERC20(_mintableToken).REMOTE_TOKEN();
    }
}
