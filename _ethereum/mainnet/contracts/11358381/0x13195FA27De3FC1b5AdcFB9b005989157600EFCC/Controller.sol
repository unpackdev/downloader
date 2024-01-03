// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./IController.sol";
import "./IVault.sol";
import "./IStrategy.sol";
import "./AccessControl.sol";

contract Controller is IController, AccessControl {
    using SafeMath for uint;

    bytes32 public constant override ADMIN_ROLE = keccak256(abi.encodePacked("ADMIN"));
    bytes32 public constant override HARVESTER_ROLE =
        keccak256(abi.encodePacked("HARVESTER"));

    address public override admin;
    address public override treasury;

    constructor(address _treasury) public {
        require(_treasury != address(0), "treasury = zero address");

        admin = msg.sender;
        treasury = _treasury;

        _grantRole(ADMIN_ROLE, admin);
        _grantRole(HARVESTER_ROLE, admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    modifier isCurrentStrategy(address _strategy) {
        address vault = IStrategy(_strategy).vault();
        /*
        Check that _strategy is the current strategy used by the vault.
        */
        require(IVault(vault).strategy() == _strategy, "!strategy");
        _;
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "admin = zero address");

        _revokeRole(ADMIN_ROLE, admin);
        _revokeRole(HARVESTER_ROLE, admin);

        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(HARVESTER_ROLE, _admin);

        admin = _admin;
    }

    function setTreasury(address _treasury) external override onlyAdmin {
        require(_treasury != address(0), "treasury = zero address");
        treasury = _treasury;
    }

    function grantRole(bytes32 _role, address _addr) external override onlyAdmin {
        require(_role == ADMIN_ROLE || _role == HARVESTER_ROLE, "invalid role");
        _grantRole(_role, _addr);
    }

    function revokeRole(bytes32 _role, address _addr) external override onlyAdmin {
        require(_role == ADMIN_ROLE || _role == HARVESTER_ROLE, "invalid role");
        _revokeRole(_role, _addr);
    }

    function setStrategy(
        address _vault,
        address _strategy,
        uint _min
    ) external override onlyAuthorized(ADMIN_ROLE) {
        IVault(_vault).setStrategy(_strategy, _min);
    }

    function invest(address _vault) external override onlyAuthorized(HARVESTER_ROLE) {
        IVault(_vault).invest();
    }

    function harvest(address _strategy)
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(HARVESTER_ROLE)
    {
        IStrategy(_strategy).harvest();
    }

    function skim(address _strategy)
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(HARVESTER_ROLE)
    {
        IStrategy(_strategy).skim();
    }

    modifier checkWithdraw(address _strategy, uint _min) {
        address vault = IStrategy(_strategy).vault();
        address token = IVault(vault).token();

        uint balBefore = IERC20(token).balanceOf(vault);
        _;
        uint balAfter = IERC20(token).balanceOf(vault);

        require(balAfter.sub(balBefore) >= _min, "withdraw < min");
    }

    function withdraw(
        address _strategy,
        uint _amount,
        uint _min
    )
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(HARVESTER_ROLE)
        checkWithdraw(_strategy, _min)
    {
        IStrategy(_strategy).withdraw(_amount);
    }

    function withdrawAll(address _strategy, uint _min)
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(HARVESTER_ROLE)
        checkWithdraw(_strategy, _min)
    {
        IStrategy(_strategy).withdrawAll();
    }

    function exit(address _strategy, uint _min)
        external
        override
        isCurrentStrategy(_strategy)
        onlyAuthorized(ADMIN_ROLE)
        checkWithdraw(_strategy, _min)
    {
        IStrategy(_strategy).exit();
    }
}
