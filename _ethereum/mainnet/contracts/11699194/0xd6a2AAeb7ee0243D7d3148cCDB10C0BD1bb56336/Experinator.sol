pragma experimental ABIEncoderV2;
pragma solidity 0.7.3;

import "./IProxy.sol";
import "./IPV2SmartPool.sol";
import "./IBPool.sol";
import "./IBFactory.sol";
import "./ISmartPoolStorageDoctor.sol";
import "./IExperiPieStorageDoctor.sol";
import "./Diamond.sol";
import "./IDiamondCut.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IExperiPie.sol";
import "./console.sol";

contract Experinator is Ownable {

    address diamondImplementation;
    address experiPieStorageDoctor;
    address balancerFactory;
    address smartPoolImplementation;
    address smartPoolStorageDoctor;

    IDiamondCut.FacetCut[] public diamondCut;

    constructor(
        // IDiamondCut.FacetCut[] memory _diamondCut,
        address _diamondImplementation,
        address _balancerFactory,
        address _smartPoolImplementation,
        address _smartPoolStorageDoctor,
        address _experiPieStorageDoctor
    ) {
        // setCut(_diamondCut);
        diamondImplementation = _diamondImplementation;
        balancerFactory = _balancerFactory;
        smartPoolImplementation = _smartPoolImplementation;
        smartPoolStorageDoctor = _smartPoolStorageDoctor;
        experiPieStorageDoctor = _experiPieStorageDoctor;
    }

    function setCut(IDiamondCut.FacetCut[] memory _diamondCut) public onlyOwner {
        delete diamondCut;
        for(uint256 i = 0; i < _diamondCut.length; i ++) {
            diamondCut.push(_diamondCut[i]);
        }
    }

    // Make sure its initialised!
    function setDiamondImplementation(address _diamondImplementation) external onlyOwner {
        diamondImplementation = _diamondImplementation;
    }

    function setBalancerFactory(address _factory) external onlyOwner {
        balancerFactory = _factory;
    }

    function setSmartPoolImplementation(address _smartPoolImplementation) external onlyOwner {
        smartPoolImplementation = _smartPoolImplementation;
    }

    function setSmartPoolStorageDoctor(address _storageDoctor) external onlyOwner {
        smartPoolStorageDoctor = _storageDoctor;
    }

    function setExperiPieStorageDoctor(address _storageDoctor) external onlyOwner {
        experiPieStorageDoctor = _storageDoctor;
    }

    function toExperiPie(address _smartPool, address _controller) external onlyOwner {
        IProxy proxy = IProxy(_smartPool);
        Diamond diamond = Diamond(payable(_smartPool));
        IPV2SmartPool smartPool = IPV2SmartPool(_smartPool);
        IExperiPie experiPie = IExperiPie(_smartPool);
        IBPool bPool = IBPool(smartPool.getBPool());
        IExperiPieStorageDoctor eStorage = IExperiPieStorageDoctor(_smartPool);

        address[] memory tokens = smartPool.getTokens();

        console.log("Controller");
        console.log(smartPool.getController());

        smartPool.setTokenBinder(address(this));

        for(uint256 i = 0; i < tokens.length; i ++) {
            smartPool.unbind(tokens[i]);
        }

        smartPool.setTokenBinder(_controller);
        smartPool.setController(_controller);

        proxy.setImplementation(experiPieStorageDoctor);
        eStorage.operate();

        proxy.setImplementation(diamondImplementation);
        diamond.initialize(diamondCut, address(this));

        
        for(uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            token.transfer(_smartPool, token.balanceOf(address(this)));
            experiPie.addToken(tokens[i]);
        }

        // set proxy contract ownership to the controller
        experiPie.transferOwnership(_controller);
        proxy.setProxyOwner(_controller);
    }

    function toSmartPool(address _experiPie, address _owner, uint256[] memory _weights) external onlyOwner {
        IProxy proxy = IProxy(_experiPie);
        Diamond diamond = Diamond(payable(_experiPie));
        IPV2SmartPool smartPool = IPV2SmartPool(_experiPie);
        IExperiPie experiPie = IExperiPie(_experiPie);
        ISmartPoolStorageDoctor spStorage = ISmartPoolStorageDoctor(_experiPie);

        address[] memory tokens = experiPie.getTokens();

        require(_weights.length == tokens.length, "ARRAY_LENGTH_MISMATCH");

        // deploy a fresh _bPool

        IBPool bPool = IBPool(IBFactory(balancerFactory).newBPool());

        //remove remove tokens and deposit them into a fresh balancer pool
        for(uint256 i = 0; i < tokens.length; i ++) {
            experiPie.removeToken(tokens[i]);
            
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(_experiPie);
            experiPie.singleCall(tokens[i], abi.encodeWithSelector(token.transfer.selector, address(this), balance), 0);
            token.approve(address(bPool), balance);
            bPool.bind(tokens[i], balance, _weights[i]);
        }

        bPool.setController(_experiPie);

        // set storage doctor as implementation
        proxy.setImplementation(smartPoolStorageDoctor);

        spStorage.operate(address(bPool));

        proxy.setImplementation(smartPoolImplementation);

        console.log("pool controller");
        console.log(smartPool.getController());

        smartPool.setController(_owner);
        proxy.setProxyOwner(_owner);
    }


    // In case migration does not work we handle control back to another address again
    function setProxyOwner(address _proxy, address _owner) external onlyOwner {
        IProxy proxy = IProxy(_proxy);
        proxy.setProxyOwner(_owner);
    }

    // In case migration does not work set the smart pool address to another address again
    function setController(address _pie, address _controller) external onlyOwner {
        IPV2SmartPool pie = IPV2SmartPool(_pie);
        pie.setController(_controller);
    }

    function setOwner(address _pie, address _owner) external onlyOwner {
        IExperiPie experiPie = IExperiPie(_pie);
        experiPie.transferOwnership(_owner);
    }
}