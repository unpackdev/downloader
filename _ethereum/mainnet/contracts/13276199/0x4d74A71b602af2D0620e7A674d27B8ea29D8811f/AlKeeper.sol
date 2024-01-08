pragma solidity 0.8.4;

import "./IKeeperCompatibleInterface.sol";
import "./IAlchemist.sol";
import "./ITransmuter.sol";
import "./IVaultAdaptor.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract AlKeeper is IKeeperCompatibleInterface, Ownable {
    using SafeMath for uint256;
    
    enum TASK {
        HARVEST_TRANSMUTER,
        HARVEST_ALCHEMIST,
        FLUSH_ALCHEMIST
    }

    IAlchemist public alchemist;
    ITransmuter public transmuter;
    IERC20 public underlying;
    address public keeperRegistry;

    TASK public nextTask;
    mapping(TASK => uint256) public lastCallForTask;

    bool public paused;

    uint256 public keeperDelay;

    constructor(IAlchemist _alchemist, ITransmuter _transmuter, IERC20 _underlying, address _keeperRegistry) {
        alchemist = _alchemist;
        transmuter = _transmuter;
        underlying = _underlying;
        keeperRegistry = _keeperRegistry;
        nextTask = TASK.HARVEST_TRANSMUTER;
        keeperDelay = 1 days;
    }

    modifier onlyKeeperRegistry() {
        require(msg.sender == keeperRegistry, "caller not keeper registry");
        _;
    }

    function setAlchemist(IAlchemist newAlchemist) external onlyOwner() {
        alchemist = newAlchemist;
    }

    function setTransmuter(ITransmuter newTransmuter) external onlyOwner() {
        transmuter = newTransmuter;
    }

    function setPause(bool pauseState) external onlyOwner() {
        paused = pauseState;
    }

    function setKeeperDelay(uint256 newKeeperDelay) external onlyOwner() {
        keeperDelay = newKeeperDelay;
    }

    function setKeeperRegistry(address _keeperRegistry) external onlyOwner() {
        keeperRegistry = _keeperRegistry;
    }

    function recoverFunds(IERC20 token) external onlyOwner() {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /// @dev check if the nextTask needs to be performed
    ///
    /// Returns FALSE if 1 day has not passed since last call
    /// Returns FALSE if certain economic criteria are not met
    ///
    /// @param checkData input data to check (not used)
    ///
    /// @return upkeepNeeded if upkeep is needed
    /// @return performData the task to perform
    function checkUpkeep(bytes calldata checkData) external view override returns (
        bool upkeepNeeded,
        bytes memory performData
    ) {
        if (!paused && block.timestamp.sub(lastCallForTask[nextTask]) >= keeperDelay) {
            return (true, abi.encode(nextTask));
        } else {
            return (false, abi.encode(0x0));
        }
    }

    /// @dev perform a task that needs upkeep
    ///
    /// @param performData the task to be performed
    function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry() {
        TASK task;
        (task) = abi.decode(performData, (TASK));
        if (!paused && block.timestamp.sub(lastCallForTask[task]) >= keeperDelay) {
            if (task == TASK.HARVEST_TRANSMUTER) {
                harvestTransmuter();
            } else if (task == TASK.HARVEST_ALCHEMIST) {
                harvestAlchemist();
            } else if (task == TASK.FLUSH_ALCHEMIST) {
                flushAlchemist();
            }
        }
    }

    function harvestTransmuter() internal {
        if (!transmuter.pause()) {
            uint256 vaultId = transmuter.vaultCount() - 1;
            address vaultAdaptor = transmuter.getVaultAdapter(vaultId);
            uint256 vaultTotalDep = transmuter.getVaultTotalDeposited(vaultId);
            uint256 totalValue = IVaultAdaptor(vaultAdaptor).totalValue();
            if (totalValue > vaultTotalDep) {
                transmuter.harvest(vaultId);
            }
        }
        nextTask = TASK.HARVEST_ALCHEMIST;
        lastCallForTask[TASK.HARVEST_TRANSMUTER] = block.timestamp;
    }

    function harvestAlchemist() internal {
        if (!alchemist.emergencyExit()) {
            uint256 vaultId = alchemist.vaultCount() - 1;
            address vaultAdaptor = alchemist.getVaultAdapter(vaultId);
            uint256 vaultTotalDep = alchemist.getVaultTotalDeposited(vaultId);
            uint256 totalValue = IVaultAdaptor(vaultAdaptor).totalValue();
            if (totalValue > vaultTotalDep) {
                alchemist.harvest(vaultId);
            }
        }
        nextTask = TASK.FLUSH_ALCHEMIST;
        lastCallForTask[TASK.HARVEST_ALCHEMIST] = block.timestamp;
    }

    function flushAlchemist() internal {
        if (!alchemist.emergencyExit() && underlying.balanceOf(address(alchemist)) > 0) {
            alchemist.flush();
        }
        nextTask = TASK.HARVEST_TRANSMUTER;
        lastCallForTask[TASK.FLUSH_ALCHEMIST] = block.timestamp;
    }
}