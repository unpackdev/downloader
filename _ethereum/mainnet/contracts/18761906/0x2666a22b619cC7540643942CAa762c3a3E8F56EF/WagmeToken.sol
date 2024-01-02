pragma solidity ^0.8.22;

import "./ERC20Upgradeable.sol";
import "./AccessControlDefaultAdminRulesUpgradeable.sol";
import "./Initializable.sol";
import "./IWagmeToken.sol";

contract WagmeToken is IWagmeToken, Initializable, ERC20Upgradeable, AccessControlDefaultAdminRulesUpgradeable {

    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    mapping(bytes32 => bool) private mintIds;
    mapping(bytes32 => bool) private burnIds;

    modifier idempotentMint(bytes32 idempotencyKey) {
        if (mintIds[idempotencyKey]) {
            revert IdempotencyKeyAlreadyExist(idempotencyKey);
        }
        _;
        mintIds[idempotencyKey] = true;
    }

    modifier idempotentBurn(bytes32 idempotencyKey) {
        if (burnIds[idempotencyKey]) {
            revert IdempotencyKeyAlreadyExist(idempotencyKey);
        }
        _;
        burnIds[idempotencyKey] = true;
    }

    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        __ERC20_init(name, symbol);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address account, uint256 amount) external onlyRole(SERVICE_ROLE) {
        _mint(account, amount);
    }

    function mint(bytes32 idempotencyKey, address account, uint256 amount) external
    onlyRole(SERVICE_ROLE) idempotentMint(idempotencyKey) {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyRole(SERVICE_ROLE) {
        _burn(account, amount);
    }

    function burn(bytes32 idempotencyKey, address account, uint256 amount) external
    onlyRole(SERVICE_ROLE) idempotentBurn(idempotencyKey) {
        _burn(account, amount);
    }
}
