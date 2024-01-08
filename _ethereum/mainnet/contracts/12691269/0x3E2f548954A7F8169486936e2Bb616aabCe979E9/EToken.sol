// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./SafeERC20.sol";
import "./ERC20.sol";

import "./IEToken.sol";
import "./ControllerMixin.sol";

contract EToken is ControllerMixin, ERC20, IEToken {
    using SafeERC20 for IERC20;

    address immutable public ePool;

    event RecoveredToken(address token, uint256 amount);

    modifier onlyEPool {
        require(msg.sender == ePool, "EToken: not EPool");
        _;
    }

    constructor(
        IController _controller,
        string memory name,
        string memory symbol,
        address _ePool
    ) ControllerMixin(_controller) ERC20(name, symbol) {
        ePool = _ePool;
    }

        /**
     * @notice Returns the address of the current Aggregator which provides the exchange rate between TokenA and TokenB
     * @return Address of aggregator
     */
    function getController() external view override returns (address) {
        return address(controller);
    }

    /**
     * @notice Updates the Controller
     * @dev Can only called by an authorized sender
     * @param _controller Address of the new Controller
     * @return True on success
     */
    function setController(address _controller) external override onlyDao("EToken: not dao") returns (bool) {
        _setController(_controller);
        return true;
    }

    /**
     * @notice Mints new EToken
     * @dev Can only be called by the registered EPool
     * @param account Address of recipient
     * @param amount Amount to mint
     * @return True on Success
     */
    function mint(address account, uint256 amount) external override onlyEPool returns (bool) {
        _mint(account, amount);
        return true;
    }

    /**
     * @notice Burns EToken
     * @dev Can only be called by the registered EPool
     * @param account Address of accounts to burn EToken from
     * @param amount Amount to burn
     * @return True on Success
     */
    function burn(address account, uint256 amount) external override onlyEPool returns (bool) {
        _burn(account, amount);
        return true;
    }

    /**
     * @notice Recovers untracked amounts
     * @dev Can only called by an authorized sender
     * @param token Address of the token
     * @param amount Amount to recover
     * @return True on success
     */
    function recover(IERC20 token, uint256 amount) external override onlyDao("EToken: not dao") returns (bool) {
        token.safeTransfer(msg.sender, amount);
        emit RecoveredToken(address(token), amount);
        return true;
    }
}
