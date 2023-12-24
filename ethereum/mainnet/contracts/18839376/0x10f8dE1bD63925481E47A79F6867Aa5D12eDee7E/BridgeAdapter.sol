// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; 

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./IXERC20.sol";
import "./IXERC20Lockbox.sol";

// Parent class to abstract xERC20 management.
contract BridgeAdapter is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    
    // Addresses needed
    IERC20 public GOA;
    IXERC20 public xGOA;
    IXERC20Lockbox public lockbox;
    uint256 private nonce;

    struct Error {
        uint256 chainId;
        address user; 
        uint256 amount;
    }

    // Map Error events for retry. 
    mapping (uint256 => Error) public errors;

    // Events
    event BridgedOut(uint256 indexed dstChainId, address indexed bridgeUser, address indexed tokenReceiver, uint256 amount);
    event BridgedIn(uint256 indexed srcChainId, address indexed tokenReceiver, uint256 amount);
    event BridgeError(uint256 indexed errorId, address indexed user, uint256 amount, uint256 timestamp);

    error NoErrorFound();

    /**@notice Initialize the bridge
     * @param _goa GOA token address
     * @param _xgoa xGOA token address
     * @param _lockbox xGOA lockbox address
     */
    function initialize(
        IERC20 _goa,
        IXERC20 _xgoa, 
        IXERC20Lockbox _lockbox,
        address[] calldata 
    ) public virtual initializer {
        __Ownable_init(msg.sender);
        GOA = _goa;
        xGOA = _xgoa;
        lockbox = _lockbox;

        if (address(lockbox) != address(0)) {
            GOA.safeIncreaseAllowance(address(lockbox), type(uint).max);
            IERC20(address(xGOA)).safeIncreaseAllowance(address(lockbox), type(uint).max);
        }
    }

    /**@notice Bridge Out Funds
     * @param _dstChainId Destination chain id 
     * @param _amount Amount of GOA to bridge out
     * @param _to Address to receive funds on destination chain
     */
    function bridge(uint256 _dstChainId, uint256 _amount, address _to) external virtual payable {
        _bridge(msg.sender, _dstChainId, _amount, _to);
    }

    function _bridge(address _user, uint256 _dstChainId, uint256 _amount, address _to) internal virtual {
        _bridgeOut(_user, _amount);

        emit BridgedOut(_dstChainId, _user, _to, _amount);
    }

    function _bridgeOut(address _user, uint256 _amount) internal virtual {
        if (address(lockbox) != address(0)) {
            GOA.safeTransferFrom(_user, address(this), _amount);
            lockbox.deposit(_amount);
            xGOA.burn(address(this), _amount);
        } else xGOA.burn(_user, _amount);
    }

    function _bridgeIn(uint256 _chainId, address _user, uint256 _amount) internal virtual {
        try xGOA.mint(address(this), _amount) {
            if (address(lockbox) != address(0)) {
                lockbox.withdraw(_amount);
                GOA.safeTransfer(_user, _amount);
            } else IERC20(address(xGOA)).safeTransfer(_user, _amount); 
            emit BridgedIn(_chainId, _user, _amount);  
        } catch {
            uint256 _nonce = nonce;
            errors[_nonce] = Error(_chainId, _user, _amount);
            nonce++;
            emit BridgeError(_nonce, _user, _amount, block.timestamp);
        }
    }

   /**@notice Retry a failed bridge in
    * @param _errorId Id of error to retry
    */
    function retry(uint256 _errorId) external {
        Error memory _error = errors[_errorId];
        delete errors[_errorId];

        if (_error.user == address(0)) revert NoErrorFound();

        _bridgeIn(_error.chainId, _error.user, _error.amount);
    }

    /**@notice Estimate bridge cost
     * @param _dstChainId Destination chain id
     * @param _amount Amount of GOA to bridge out
     * @param _to Address to receive funds on destination chain
     */
    function bridgeCost(uint256 _dstChainId, uint256 _amount, address _to) external virtual view returns (uint256 gasCost) {
        _dstChainId; _amount; _to;
        return 0;
    }
}