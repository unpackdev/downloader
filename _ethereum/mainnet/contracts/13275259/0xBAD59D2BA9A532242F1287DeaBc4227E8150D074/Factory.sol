pragma solidity >=0.7.5;

import "./IFactory.sol";
import "./Vault.sol";

contract Factory is IFactory {
    /// @notice Returns manager address of a given vault address
    mapping(address => address) public override vaultManager;

    /// @notice Returns vault address of a given manager address
    mapping(address => address) public override managerVault;

    address public override router;
    address public override governance;
    address public override pendingGovernance;

    constructor(address _governance) {
        governance = _governance;
    }

    function createVault(
        address _uniswapPool,
        address _strategyManager,
        uint256 _protocolFee,
        uint256 _strategyFee,
        uint256 _maxCappedLimit
    ) public override onlyGovernance {
        require(
            managerVault[_strategyManager] == address(0),
            "Factory : createVault :: Manager already has a vault"
        );

        Vault newVault = new Vault(
            _uniswapPool,
            _protocolFee,
            _strategyFee,
            _maxCappedLimit
        );

        vaultManager[address(newVault)] = _strategyManager;
        managerVault[_strategyManager] = address(newVault);

        emit VaultCreation(_strategyManager, _uniswapPool, address(newVault));
    }

    function updateManager(address _newManager, address _vault)
        public
        override
        onlyGovernance
    {
        require(
            vaultManager[_vault] != address(0),
            "Factory : updateManager :: Vault does not to exist"
        );
        address oldManager = vaultManager[_vault];
        require(
            managerVault[oldManager] == _vault,
            "Factory : updateManager :: previous manager of vault is corrupted"
        );

        managerVault[oldManager] = address(0);
        managerVault[_newManager] = _vault;
        vaultManager[_vault] = _newManager;

        assert(vaultManager[_vault] != oldManager);
        assert(managerVault[oldManager] == address(0));
    }

    function setRouter(address _router) public override onlyGovernance {
        require(
            _router != address(0),
            "Factory : setRouter :: address cannot be zero"
        );
        router = _router;
    }

    /**
     * @notice Governance address is not updated until the new governance
     * address has called `acceptGovernance()` to accept this responsibility.
     */
    function setGovernance(address _governance)
        external
        override
        onlyGovernance
    {
        pendingGovernance = _governance;
    }

    /**
     * @notice `setGovernance()` should be called by the existing governance
     * address prior to calling this function.
     */
    function acceptGovernance() external override {
        require(
            msg.sender == pendingGovernance,
            "Factory : acceptGovernance :: you need to be pendingGovernance to accept governance"
        );
        emit GovernanceChange(governance, msg.sender);
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(
            governance == msg.sender,
            "Factory : Only governance can send the tx"
        );
        _;
    }
}
