//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";

interface IRootChainManager {
    function exit(bytes calldata inputData) external;
}

/// @title This is a token that is used to allow transfering a token on ethereum under any address
/// @author Timo
/// @notice Needs to deploy under same address on ethereum
contract RootAmunWeth is ERC20Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bool public isSingleExit;
    address public underlying;
    address public predicateProxy;
    address public etherPredicateProxy;
    IRootChainManager public rootChainManager;

    function initialize(
        string memory name,
        string memory symbol,
        address _underlying,
        address _predicateProxy,
        address _etherPredicateProxy,
        address _rootChainManager
    ) public initializer {
        require(
            _predicateProxy != address(0),
            "new predicateProxy is the zero address"
        );
        require(
            _etherPredicateProxy != address(0),
            "new etherPredicateProxy is the zero address"
        );
        require(
            _underlying != address(0),
            "new underlying is the zero address"
        );
        require(
            _rootChainManager != address(0),
            "new rootChainManager is the zero address"
        );
        __ERC20_init(name, symbol);
        isSingleExit = false;
        rootChainManager = IRootChainManager(_rootChainManager);
        underlying = _underlying;
        predicateProxy = _predicateProxy;
        etherPredicateProxy = _etherPredicateProxy;
    }

    modifier canMint() {
        require(isSingleExit, "INVALID_MINT");
        _;
    }

    /// @notice This sends eth to user via amun weth
    /// @param inputDataWeth the hash of the bridge exit of weth to amun weth
    /// @param inputDataAmunWeth the hash of the bridge exit of amun weth
    function exit(
        bytes calldata inputDataWeth,
        bytes calldata inputDataAmunWeth
    ) external {
        isSingleExit = true;
        rootChainManager.exit(inputDataWeth);
        rootChainManager.exit(inputDataAmunWeth);
        isSingleExit = false;

        address recipient = _msgSender();
        uint256 balance = this.balanceOf(recipient);
        _burn(recipient, balance);

        if (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE == underlying) {
            payable(recipient).transfer(balance);
            require(address(this).balance == 0, "INVALID_EXIT");
        } else {
            IERC20Upgradeable(underlying).safeTransfer(recipient, balance);
            require(
                IERC20Upgradeable(underlying).balanceOf(address(this)) == 0,
                "INVALID_EXIT"
            );
        }
        require(this.totalSupply() == 0, "INVALID_EXIT");
    }

    function mint(address recipient, uint256 amount) external canMint {
        require(msg.sender == predicateProxy, "ONLY_PREDICATE_PROXY");
        _mint(recipient, amount);
    }

    receive() external payable canMint {
        require(msg.sender == etherPredicateProxy, "ONLY_ETHER_PREDICATE_PROXY");
    }
}
