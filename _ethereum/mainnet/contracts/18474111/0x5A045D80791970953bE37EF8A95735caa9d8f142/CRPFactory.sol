// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
import "./RightsManager.sol";
import "./SmartPoolManager.sol";
import "./Logs.sol";

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

// Imports
abstract contract IConfigurableRightsPool {
    struct PoolParams {
        string poolTokenSymbol;
        string poolTokenName;
        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        SmartPoolManager.Etypes etype;
    }

    struct CrpParams {
        uint initialSupply;
        uint collectPeriod;
        SmartPoolManager.Period period;
    }

    function setController(address owner) external virtual;

    function init(
        address factoryAddress,
        IConfigurableRightsPool.PoolParams calldata poolParams,
        RightsManager.Rights calldata rights
    ) external virtual;

    function initHandle(address[] memory owners, uint[] memory ownerPercentage) external virtual;
}

interface IUserVault {
    function setPoolParams(address pool, SmartPoolManager.KolPoolParams memory kolPoolParams) external;
}

interface ICRPFactory {
    function isCrp(address addr) external view returns (bool);
}
// Contracts

/**
 * @author Desyn Labs
 * @title Configurable Rights Pool Factory - create parameterized smart pools
 * @dev Rights are held in a corresponding struct in ConfigurableRightsPool
 *      Index values are as follows:
 *                            by default, it is off on initialization and can only be turned on
 *      4: canWhitelistLPs - if set, only whitelisted addresses can join pools
 *                           (enables private pools with more than one LP)
 *      5: canChangeCap - can change the BSP cap (max # of pool tokens)
 */
contract CRPFactory is Logs {
    // State variables

    // Keep a list of all Configurable Rights Pools
    mapping(address => bool) private _isCrp;

    // Event declarations

    // Log the address of each new smart pool, and its creator
    event LogNewCrp(address indexed caller, address indexed pool);
    event LOG_USER_VAULT(address indexed vault, address indexed caller);
    event LOG_MIDDLEWARE(address indexed middleware, address indexed caller);

    event AddCRPFactory(address caller, address indexed factory);
    event RemoveCRPFactory(address caller, address indexed factory);

    uint private counters;

    bytes public bytecodes;
    address private _blabs = msg.sender;
    address public userVault;

    address[] public CRPFactorys;

    // constructor(bytes memory _bytecode) public {
    //     bytecodes = _bytecode;
    //     _blabs = msg.sender;
    // }

    function createPool(IConfigurableRightsPool.PoolParams calldata poolParams) internal returns (address base) {
        bytes memory bytecode = bytecodes;
        bytes memory deploymentData = abi.encodePacked(bytecode, abi.encode(poolParams.poolTokenSymbol, poolParams.poolTokenName));
        bytes32 salt = keccak256(abi.encodePacked(counters++));
        assembly {
            base := create2(0, add(deploymentData, 32), mload(deploymentData), salt)
            if iszero(extcodesize(base)) {
                revert(0, 0)
            }
        }
    }

    // Function declarations
    /**
     * @notice Create a new CRP
     * @dev emits a LogNewCRP event
     * @param factoryAddress - the BFactory instance used to create the underlying pool
     * @param poolParams - struct containing the names, tokens, weights, balances, and swap fee
     * @param rights - struct of permissions, configuring this CRP instance (see above for definitions)
     */
    function newCrp(
        address factoryAddress,
        IConfigurableRightsPool.PoolParams calldata poolParams,
        RightsManager.Rights calldata rights,
        SmartPoolManager.KolPoolParams calldata kolPoolParams,
        address[] memory owners,
        uint[] memory ownerPercentage
    ) external returns (IConfigurableRightsPool) {
        // require(poolParams.constituentTokens.length >= DesynConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");

        // Arrays must be parallel

        address crp = createPool(poolParams);
        emit LogNewCrp(msg.sender, crp);

        _isCrp[crp] = true;
        IConfigurableRightsPool(crp).init(factoryAddress, poolParams, rights);
        IUserVault(userVault).setPoolParams(crp, kolPoolParams);
        // The caller is the controller of the CRP
        // The CRP will be the controller of the underlying Core BPool
        IConfigurableRightsPool(crp).setController(msg.sender);
        IConfigurableRightsPool(crp).initHandle(owners, ownerPercentage);

        return IConfigurableRightsPool(crp);
    }

    modifier onlyBlabs() {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        _;
    }

    function setUserVault(address newVault) external onlyBlabs {
        userVault = newVault;
        emit LOG_USER_VAULT(newVault, msg.sender);
    }

    function setByteCodes(bytes memory _bytecodes) external onlyBlabs _logs_ {
        bytecodes = _bytecodes;
    }

    /**
     * @notice Check to see if a given address is a CRP
     * @param addr - address to check
     * @return boolean indicating whether it is a CRP
     */
    function isCrp(address addr) external view returns (bool) {
        if(_isCrp[addr]) return _isCrp[addr];
        
        for(uint i=0; i<CRPFactorys.length; i++){
            if(ICRPFactory(CRPFactorys[i]).isCrp(addr)) return true;
        }
    }

    /**
     * @notice add CRPFactory
     * @param _crpFactory CRPFactory address
     * @dev add CRPFactory
     */
    function addCRPFactory(address _crpFactory) external onlyBlabs {
        require(_crpFactory != address(this),"ERR_CAN_NOT_ADD_SELF");
        uint len = CRPFactorys.length;

        for(uint i=0; i<len; i++){
            require(CRPFactorys[i] != _crpFactory, "ERR_HAS_BEEN_ADDED");
        }
        CRPFactorys.push(_crpFactory);
        emit AddCRPFactory(msg.sender, _crpFactory);
    }

    /**
     * @notice remove CRPFactory
     * @param _crpFactory CRPFactory address
     * @dev remove CRPFactory
     */
    function removeCRPFactory(address _crpFactory) external onlyBlabs  {
        uint len = CRPFactorys.length;
        for(uint i=0; i<len; i++){
            if(CRPFactorys[i] == _crpFactory){
                CRPFactorys[i] = CRPFactorys[len-1];
                CRPFactorys.pop();
                emit RemoveCRPFactory(msg.sender, _crpFactory);
                break;
            }
        }
    }
}
