// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IPublicSaleProxyFactory.sol";
import "./PublicSaleProxy.sol";
import "./AccessibleCommon.sol";
import "./IVaultFactory.sol";
import "./IEventLog.sol";


/// @title A factory that creates a PublicSaleProxy
contract PublicSaleProxyFactory is AccessibleCommon, IPublicSaleProxyFactory {

    event CreatedPublicSaleProxy(address contractAddress, string name);

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "PublicSaleProxyFactory: zero");
        _;
    }
    struct ContractInfo {
        address contractAddress;
        string name;
    }

    /// @dev Total number of contracts created
    uint256 public totalCreatedContracts ;

    uint256 public minTOS;
    uint256 public maxTOS;

    address public tonAddress;
    address public wtonAddress;
    address public sTOSAddress;
    address public tosAddress;
    address public uniRouterAddress;

    address public vaultFactory;
    address public logEventAddress;

    address public publicLogic;    
    address public upgradeAdmin;
    
    uint256 public tier1;
    uint256 public tier2;
    uint256 public tier3;
    uint256 public tier4;

    uint256 public delayTime;

    /// @dev Contract information by index
    mapping(uint256 => ContractInfo) public createdContracts;

    /// @dev constructor of PublicSaleProxyFactory
    constructor() {
        totalCreatedContracts = 0;

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
        upgradeAdmin = msg.sender;
    }

    /// @inheritdoc IPublicSaleProxyFactory
    /// @notice _logic = PublicSale, _owner = contract admin
    /// saleAddress[0] = _saleTokenAddress, saleAddress[1] = getTokenOwner, saleAddress[2] = liquidityVaultAddress
    function create(
        string calldata name,
        address _owner,
        address[3] calldata saleAddresses,
        uint256 _index
    )
        external override
        nonZeroAddress(_owner)
        nonZeroAddress(saleAddresses[0])
        nonZeroAddress(saleAddresses[1])
        nonZeroAddress(saleAddresses[2])
        returns (address)
    {
        require(bytes(name).length > 0,"name is empty");

        PublicSaleProxy proxy = new PublicSaleProxy();

        require(
            address(proxy) != address(0),
            "proxy zero"
        );

        (address initialVault, ) = IVaultFactory(vaultFactory).getContracts(_index);
        require(initialVault == saleAddresses[2], "another liquidityVault");

        proxy.addProxyAdmin(upgradeAdmin);
        proxy.addAdmin(upgradeAdmin);
        proxy.addAdmin(_owner);
        proxy.setImplementation(publicLogic);

        proxy.initialize(
            saleAddresses[0],
            saleAddresses[1],
            saleAddresses[2]
        );

        proxy.changeBasicSet(
            tonAddress,
            sTOSAddress,
            wtonAddress,
            uniRouterAddress,
            tosAddress
        );

        proxy.setMaxMinPercent(
            minTOS,
            maxTOS
        );

        proxy.setSTOSstandard(
            tier1,
            tier2,
            tier3,
            tier4
        );

        proxy.setDelayTime(
            delayTime
        );


        proxy.removeAdmin();

        createdContracts[totalCreatedContracts] = ContractInfo(address(proxy), name);
        totalCreatedContracts++;

        bytes memory abiencode = abi.encode(address(proxy), name);

        IEventLog(logEventAddress).logEvent(
            keccak256("PublicSaleProxyFactory"),
            keccak256("CreatedPublicSaleProxy"),
            address(this),
            abiencode
        );

        emit CreatedPublicSaleProxy(address(proxy), name);

        return address(proxy);
    }

    /// @inheritdoc IPublicSaleProxyFactory
    function basicSet(
        address[6] calldata _basicAddress
    )
        external 
        override
        onlyOwner
    {
        tonAddress = _basicAddress[0];
        wtonAddress = _basicAddress[1];
        sTOSAddress = _basicAddress[2];
        tosAddress = _basicAddress[3];
        uniRouterAddress = _basicAddress[4];
        publicLogic = _basicAddress[5];
    }

    function allSet(
        address[3] calldata _addr,
        uint256[7] calldata _value
    ) 
        external
        override
        onlyOwner
    {
        setUpgradeAdmin(_addr[0]);
        setVault(_addr[1]);
        setEventLog(_addr[2]);
        setMaxMin(_value[0],_value[1]);
        setSTOS(_value[2],_value[3],_value[4],_value[5]);
        setDelay(_value[6]);
    }

    function setUpgradeAdmin(
        address addr
    )   
        public
        override 
        onlyOwner
        nonZeroAddress(addr)
    {
        require(addr != upgradeAdmin, "same addrs");
        upgradeAdmin = addr;
    }

    function setVault(
        address _vaultFactory
    )
        public
        override
        onlyOwner
    {
        require(_vaultFactory != vaultFactory, "same addrs");
        vaultFactory = _vaultFactory;
    }

    function setEventLog(
        address _addr
    )
        public
        override
        onlyOwner
    {   
        require(_addr != logEventAddress, "same addrs");
        logEventAddress = _addr;
    }

    function setMaxMin(
        uint256 _min,
        uint256 _max
    )
        public
        override
        onlyOwner
    {
        require(_min < _max, "need min < max");
        minTOS = _min;
        maxTOS = _max;
    }

    function setSTOS(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    ) 
        public
        override
        onlyOwner
    {
        require(
            (_tier1 < _tier2) &&
            (_tier2 < _tier3) &&
            (_tier3 < _tier4),
            "tier set error"
        );
        tier1 = _tier1;
        tier2 = _tier2;
        tier3 = _tier3;
        tier4 = _tier4;
    }

    function setDelay(
        uint256 _delay
    )
        public
        override
        onlyOwner
    {
        require(delayTime != _delay, "same value");
        delayTime = _delay;
    }
    
    

    /// @inheritdoc IPublicSaleProxyFactory
    function lastestCreated() external view override returns (address contractAddress, string memory name){
        if(totalCreatedContracts > 0){
            return (createdContracts[totalCreatedContracts-1].contractAddress, createdContracts[totalCreatedContracts-1].name );
        } else {
            return (address(0), "");
        }
    }

    /// @inheritdoc IPublicSaleProxyFactory
    function getContracts(uint256 _index) external view override returns (address contractAddress, string memory name){
        if(_index < totalCreatedContracts){
            return (createdContracts[_index].contractAddress, createdContracts[_index].name);
        } else {
            return (address(0), "");
        }
    }

}
