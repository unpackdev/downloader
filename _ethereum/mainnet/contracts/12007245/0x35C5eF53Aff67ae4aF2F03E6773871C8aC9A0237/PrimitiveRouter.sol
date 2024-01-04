// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Router
 * @author  Primitive
 * @notice  Contract to execute Primitive Connector functions.
 * @dev     @primitivefi/v1-connectors@v2.0.0
 */

// Open Zeppelin
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IPrimitiveRouter.sol";

/**
 * @notice  Used to execute calls on behalf of the Router contract.
 * @dev     Changes `msg.sender` context so the Router is not `msg.sender`.
 */
contract Route {
    function executeCall(address target, bytes calldata params) external payable {
        (bool success, bytes memory returnData) = target.call.value(msg.value)(params);
        require(success, "Route: EXECUTION_FAIL");
    }
}

contract PrimitiveRouter is IPrimitiveRouter, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data.
    using SafeMath for uint256; // Reverts on math underflows/overflows.

    // Constants
    address private constant _NO_CALLER = address(0x0); // Default state for `_CALLER`.

    // Events
    event Initialized(address indexed from); // Emmitted on deployment
    event Executed(address indexed from, address indexed to, bytes params);
    event RegisteredOptions(address[] indexed options);
    event RegisteredConnectors(address[] indexed connectors, bool[] registered);

    // State variables
    IRegistry private _registry; // The Primitive Registry which deploys Option clones.
    IWETH private _weth; // Canonical WETH9
    Route private _route; // Intermediary to do connector.call() from.
    address private _CONNECTOR = _NO_CALLER; // If _EXECUTING, the `connector` of the execute call param.
    address private _CALLER = _NO_CALLER; // If _EXECUTING, the orginal `_msgSender()` of the execute call.
    bool private _EXECUTING; // True if the `executeCall` function was called.

    // Whitelisted mappings
    mapping(address => bool) private _registeredConnectors;
    mapping(address => bool) private _registeredOptions;

    /**
     * @notice  A mutex to use during an `execute` call.
     * @dev     Checks to make sure the `_CONNECTOR` in state is the `msg.sender`.
     *          Checks to make sure a `_CALLER` was set.
     *          Fails if this modifier is triggered by an external call.
     *          Fails if this modifier is triggered by calling a function without going through `executeCall`.
     */
    modifier isExec() {
        require(_CONNECTOR == _msgSender(), "Router: NOT_CONNECTOR");
        require(_CALLER != _NO_CALLER, "Router: NO_CALLER");
        require(!_EXECUTING, "Router: IN_EXECUTION");
        _EXECUTING = true;
        _;
        _EXECUTING = false;
    }

    // ===== Constructor =====

    constructor(address weth_, address registry_) public {
        require(address(_weth) == address(0x0), "Router: INITIALIZED");
        _route = new Route();
        _weth = IWETH(weth_);
        _registry = IRegistry(registry_);
        emit Initialized(_msgSender());
    }

    // ===== Pausability =====

    /**
     * @notice  Halts use of `executeCall`, and other functions that change state.
     */
    function halt() external override onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    // ===== Registration =====

    /**
     * @notice  Checks option against Primitive Registry. If from Registry, registers as true.
     *          NOTE: Purposefully does not have `onlyOwner` modifier.
     * @dev     Sets `optionAddresses` to true in the whitelisted options mapping, if from Registry.
     * @param   optionAddresses The array of option addresses to update.
     */
    function setRegisteredOptions(address[] calldata optionAddresses)
        external
        override
        returns (bool)
    {
        uint256 len = optionAddresses.length;
        for (uint256 i = 0; i < len; i++) {
            address option = optionAddresses[i];
            require(isFromPrimitiveRegistry(IOption(option)), "Router: EVIL_OPTION");
            _registeredOptions[option] = true;
        }
        emit RegisteredOptions(optionAddresses);
        return true;
    }

    /**
     * @notice  Allows the `owner` to set whitelisted connector contracts.
     * @dev     Sets `connectors` to `isValid` in the whitelisted connectors mapping.
     * @param   connectors The array of option addresses to update.
     * @param   isValid Whether or not the optionAddress is registered.
     */
    function setRegisteredConnectors(address[] memory connectors, bool[] memory isValid)
        public
        override
        onlyOwner
        returns (bool)
    {
        uint256 len = connectors.length;
        require(len == isValid.length, "Router: LENGTHS");
        for (uint256 i = 0; i < len; i++) {
            address connector = connectors[i];
            bool status = isValid[i];
            _registeredConnectors[connector] = status;
        }
        emit RegisteredConnectors(connectors, isValid);
        return true;
    }

    /**
     * @notice  Checks an option against the Primitive Registry.
     * @param   option The IOption token to check.
     * @return  Whether or not the option was deployed from the Primitive Registry.
     */
    function isFromPrimitiveRegistry(IOption option) internal view returns (bool) {
        return (address(option) ==
            _registry.getOptionAddress(
                option.getUnderlyingTokenAddress(),
                option.getStrikeTokenAddress(),
                option.getBaseValue(),
                option.getQuoteValue(),
                option.getExpiryTime()
            ) &&
            address(option) != address(0));
    }

    // ===== Operations =====

    /**
     * @notice  Transfers ERC20 tokens from the executing `_CALLER` to the executing `_CONNECTOR`.
     * @param   token The address of the ERC20.
     * @param   amount The amount of ERC20 to transfer.
     * @return  Whether or not the transfer succeeded.
     */
    function transferFromCaller(address token, uint256 amount)
        public
        override
        isExec
        whenNotPaused
        returns (bool)
    {
        IERC20(token).safeTransferFrom(
            getCaller(), // Account to pull from
            _msgSender(), // The connector
            amount
        );
        return true;
    }

    /**
     * @notice  Transfers ERC20 tokens from the executing `_CALLER` to an arbitrary address.
     * @param   token The address of the ERC20.
     * @param   amount The amount of ERC20 to transfer.
     * @return  Whether or not the transfer succeeded.
     */
    function transferFromCallerToReceiver(
        address token,
        uint256 amount,
        address receiver
    ) public override isExec whenNotPaused returns (bool) {
        IERC20(token).safeTransferFrom(
            getCaller(), // Account to pull from
            receiver,
            amount
        );
        return true;
    }

    // ===== Execute =====

    /**
     * @notice  Executes a call with `params` to the target `connector` contract from `_route`.
     * @param   connector The Primitive Connector module to call.
     * @param   params The encoded function data to use.
     */
    function executeCall(address connector, bytes calldata params)
        external
        payable
        override
        whenNotPaused
    {
        require(_registeredConnectors[connector], "Router: INVALID_CONNECTOR");
        _CALLER = _msgSender();
        _CONNECTOR = connector;
        _route.executeCall.value(msg.value)(connector, params);
        _CALLER = _NO_CALLER;
        _CONNECTOR = _NO_CALLER;
        emit Executed(_msgSender(), connector, params);
    }

    // ===== Fallback =====

    receive() external payable whenNotPaused {
        assert(_msgSender() == address(_weth)); // only accept ETH via fallback from the WETH contract
    }

    // ===== View =====

    /**
     * @notice  Returns the IWETH contract address.
     */
    function getWeth() public view override returns (IWETH) {
        return _weth;
    }

    /**
     * @notice  Returns the Route contract which executes functions on behalf of this contract.
     */
    function getRoute() public view override returns (address) {
        return address(_route);
    }

    /**
     * @notice  Returns the `_CALLER` which is set to `_msgSender()` during an `executeCall` invocation.
     */
    function getCaller() public view override returns (address) {
        return _CALLER;
    }

    /**
     * @notice  Returns the Primitive Registry contract address.
     */
    function getRegistry() public view override returns (IRegistry) {
        return _registry;
    }

    /**
     * @notice  Returns a bool if `option` is registered or not.
     * @param   option The address of the Option to check if registered.
     */
    function getRegisteredOption(address option) external view override returns (bool) {
        return _registeredOptions[option];
    }

    /**
     * @notice  Returns a bool if `connector` is registered or not.
     * @param   connector The address of the Connector contract to check if registered.
     */
    function getRegisteredConnector(address connector)
        external
        view
        override
        returns (bool)
    {
        return _registeredConnectors[connector];
    }

    /**
     * @notice  Returns the NPM package version and github version of this contract.
     * @dev     For the npm package: @primitivefi/v1-connectors
     *          For the repository: github.com/primitivefinance/primitive-v1-connectors
     * @return  The apiVersion string.
     */
    function apiVersion() public pure override returns (string memory) {
        return "2.0.0";
    }
}
