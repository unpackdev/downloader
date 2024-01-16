// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ImplBase.sol";
import "./errors.sol";
import "./polygon.sol";

/**
// @title Native Polygon Bridge Implementation.
// @notice This is the L1 implementation, so this is used when transferring 
// from ethereum to polygon via their native bridge.
// Called by the registry if the selected bridge is Native Polygon.
// @dev Follows the interface of ImplBase. This is only used for depositing POS ERC20 tokens.
// @author Movr Network.
*/
contract NativePolygonImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public rootChainManagerProxy;
    address public erc20PredicateProxy;
    event UpdateRootchainManager(address indexed rootchainManagerAddress);
    event UpdateERC20Predicate(address indexed erc20PredicateAddress);

    /**
    // @notice We set all the required addresses in the constructor while deploying the contract.
    // These will be constant addresses.
    // @dev Please use the Proxy addresses and not the implementation addresses while setting these 
    // @param _registry address of the registry contract that calls this contract
    // @param _rootChainManagerProxy address of the root chain manager proxy on the ethereum chain 
    // @param _erc20PredicateProxy address of the ERC20 Predicate proxy on the ethereum chain.
    */
    constructor(
        address _registry,
        address _rootChainManagerProxy,
        address _erc20PredicateProxy
    ) ImplBase(_registry) {
        rootChainManagerProxy = _rootChainManagerProxy;
        erc20PredicateProxy = _erc20PredicateProxy;
    }

    /**
    // @notice Function to set the root chain manager proxy address.
     */
    function setrootChainManagerProxy(address _rootChainManagerProxy)
        public
        onlyOwner
    {
        rootChainManagerProxy = _rootChainManagerProxy;
        emit UpdateRootchainManager(_rootChainManagerProxy);
    }

    /**
    // @notice Function to set the ERC20 Predicate proxy address.
     */
    function setErc20PredicateProxy(address _erc20PredicateProxy)
        public
        onlyOwner
    {
        erc20PredicateProxy = _erc20PredicateProxy;
        emit UpdateERC20Predicate(_erc20PredicateProxy);
    }

    /**
    // @notice Function responsible for depositing ERC20 tokens from ethereum to 
    //         polygon chain using the POS bridge.
    // @dev Please make sure that the token is mapped before sending it through the native bridge.
    // @param _amount amount to be sent.
    // @param _from sending address.
    // @param _receiverAddress receiving address.
    // @param _token address of the token to be bridged to polygon.
     */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256,
        bytes memory
    ) external payable override onlyRegistry nonReentrant {
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            IRootChainManager(rootChainManagerProxy).depositEtherFor{
                value: _amount
            }(_receiverAddress);
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20 token = IERC20(_token);

        // set allowance for erc20 predicate
        token.safeTransferFrom(_from, address(this), _amount);
        token.safeIncreaseAllowance(erc20PredicateProxy, _amount);

        // deposit into rootchain manager
        IRootChainManager(rootChainManagerProxy).depositFor(
            _receiverAddress,
            _token,
            abi.encodePacked(_amount)
        );
    }
}
