// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title BatchTransferHelper
 *
 * @notice Allows the owner to batch transfer the tokens.
 */
contract BatchTransferHelper is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public transferOperator; // Address to manage the Transfers
    event Received(address, uint);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Modifiers
    modifier onlyOperator(address _sender) {
        require(
            transferOperator[_sender] == true,
            "Only operator can call this function."
        );
        _;
    }

    function batchTransferNative(address[] calldata _transferList,
        uint256[] calldata _safeAmount
    ) external nonReentrant onlyOperator(msg.sender) {
        uint256 length = _transferList.length;
        require(_transferList.length == _safeAmount.length, "Length not match");
        for (uint i = 0; i < length; i++) {
            
            address recipient = payable(_transferList[i]);
            (bool success, ) = recipient.call{value: _safeAmount[i]}("");
            require(success, "Failed to send Token");
        }
    }

    function batchTransferToken(IERC20 token, address[] calldata _transferList,
        uint256[] calldata _safeAmount
    ) external nonReentrant onlyOperator(msg.sender) {
        uint256 length = _transferList.length;
        require(_transferList.length == _safeAmount.length, "Length not match");
        for (uint i = 0; i < length; i++) {
            
            address recipient = _transferList[i];
            uint256 amount = _safeAmount[i];
            token.safeTransfer(recipient, amount);
        }
    }

    /********************** Only Owner function ***********************/
    function updateOperator(
        address operator,
        bool allow
    ) external onlyOwner {
        require(operator != address(0), "Send to zero address");
        transferOperator[operator] = allow;
    }

    function recoverToken(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(recipient != address(0), "Send to zero address");
        token.safeTransfer(recipient, amount);
    }

    function recoverNative(
        uint256 safeAmount,
        address _recipient
    ) external onlyOwner {
        require(_recipient != address(0), "Send to zero address");
        address recipient = payable(_recipient);
        (bool success, ) = recipient.call{value: safeAmount}("");
        require(success, "Failed to send Token");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }
}
