//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IERC20Burnable is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

contract BridgeWALETH is AccessControl, ReentrancyGuard, Ownable {
    IERC20Burnable public acceptedToken;
    uint256 public swapFee;
    bool public paused;
    mapping(uint256 => bool) public chainSupported;

    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    event SwapTo(address from, address to, uint256 amount, uint256 to_chain);
    event Withdraw(address reception, uint256 amount);
    event SwapFeeUpdated(uint256 _swapFee);
    event MintFor(address to, uint256 amount);

    constructor(IERC20Burnable _acceptedToken, uint256 _swapFee) {
        acceptedToken = _acceptedToken;
        swapFee = _swapFee;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setChainSupported(uint256 chainId, bool isSupported)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        chainSupported[chainId] = isSupported;
    }

    function swapTo(
        address to,
        uint256 amount,
        uint256 to_chain
    ) external payable nonReentrant {
        require(chainSupported[to_chain], "Bridge: chain not supported");
        require(!paused, "Bridges: paused");
        require(msg.value == swapFee, "Bridge: invalid fee");

        acceptedToken.burn(msg.sender, amount);

        emit SwapTo(msg.sender, to, amount, to_chain);
    }

    function mintFor(address to, uint256 amount)
        external
        onlyRole(SERVER_ROLE)
        nonReentrant
    {
        require(to != address(0), "Bridge: invalid address");
        acceptedToken.mint(to, amount);

        emit MintFor(to, amount);
    }

    function setSwapFee(uint256 _swapFee) external onlyRole(CONTROLLER_ROLE) {
        require(swapFee != _swapFee, "Bridge: invalid fee");
        swapFee = _swapFee;

        emit SwapFeeUpdated(_swapFee);
    }
}
