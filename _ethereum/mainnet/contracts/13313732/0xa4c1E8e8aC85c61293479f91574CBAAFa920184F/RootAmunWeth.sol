//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

interface IRootChainManager {
    function exit(bytes calldata inputData) external;
}

/// @title This is a token that is used to allow transfering a token on ethereum under any address
/// @author Timo
/// @notice Needs to deploy under same address on ethereum
contract RootAmunWeth is ERC20 {
    using SafeERC20 for IERC20;
    bool public isSingleExit = false;
    address public immutable underlying;
    address public immutable predicateProxy;
    IRootChainManager public immutable rootChainManager;

    constructor(
        string memory name,
        string memory symbol,
        address _underlying,
        address _predicateProxy,
        address _rootChainManager
    ) ERC20(name, symbol) {
        require(
            _predicateProxy != address(0),
            "new predicateProxy is the zero address"
        );
        require(
            _underlying != address(0),
            "new underlying is the zero address"
        );
        require(
            _rootChainManager != address(0),
            "new rootChainManager is the zero address"
        );

        rootChainManager = IRootChainManager(_rootChainManager);
        underlying = _underlying;
        predicateProxy = _predicateProxy;
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
            IERC20(underlying).safeTransfer(recipient, balance);
            require(
                IERC20(underlying).balanceOf(address(this)) == 0,
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
        require(msg.sender == predicateProxy, "ONLY_PREDICATE_PROXY");
    }
}
