// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IBridgeable.sol";

contract WGAT is ERC20Upgradeable, AccessControlUpgradeable, IBridgeable {
    address public constant BRIDGE_ADDRESS = address(0xdead);
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE");
    mapping(uint256 => bytes) public data;
    ERC20 gat;
    bool extended;

    function initialize(address gatAddress) public initializer {
        __AccessControl_init();
        __ERC20_init("Wrapped GAT", "WGAT");
        __Coin_init_unchained(gatAddress);
    }

    function __Coin_init_unchained(address gatAddress) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        if (gatAddress != address(0)) {
            gat = ERC20(gatAddress);
        }
    }

    function deposit(uint256 amount) external {
        gat.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        gat.transfer(msg.sender, amount);
    }

    function extendSupply(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_getChainID() == 56, "Wrong chain");
        require(!extended, "Already extended");
        extended = true;
        _mint(account, 1000000 * (10**18));
    }

    function grantBridgeRole(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(BRIDGE_ROLE, account);
    }

    function revokeBridgeRole(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(BRIDGE_ROLE, account);
    }

    function bridgeLeave(
        address owner,
        uint256 value,
        uint32 chainId
    ) external override onlyRole(BRIDGE_ROLE) returns (bytes memory) {
        bytes memory resp = bytes("");
        _burn(owner, value);
        return resp;
    }

    function bridgeEnter(
        address owner,
        uint256 value,
        uint32 chainId,
        bytes memory _data
    ) external override onlyRole(BRIDGE_ROLE) {
        _mint(owner, value);
    }

    function name() public pure override returns (string memory) {
        return "Game Ace Token Extended";
    }

    function symbol() public pure override returns (string memory) {
        return "GATe";
    }

    function _getChainID() internal view returns (uint32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return uint32(id);
    }
}
