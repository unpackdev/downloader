// SPDX-License-Identifier: MIT
// Proxy for Public Mintable User NFT Collection
pragma solidity 0.8.19;
    
    import "ServiceProviderOwnable.sol";
    import "IUsersCollectionFactory.sol";

contract UserCollectionPRegistry is ServiceProviderOwnable {
    
    enum AssetType {EMPTY, NATIVE, ERC20, ERC721, ERC1155, FUTURE1, FUTURE2, FUTURE3}

    struct Asset {
        AssetType assetType;
        address contractAddress;
    }

    Asset[] public supportedImplementations;
    // mapping from user to his(her) contracts with type
    mapping(address => Asset[]) public collectionRegistry;

    IUsersCollectionFactory public factory;
    
    constructor (address _subscrRegistry)
        ServiceProviderOwnable(_subscrRegistry)
    {}

    function deployNewCollection(
        address _implAddress, 
        address _creator,
        string memory name_,
        string memory symbol_,
        string memory _baseurl
    ) external {
        (bool _supported, uint256 index) = isImplementationSupported(_implAddress);
        require(_supported, "This implementation address is not supported");
        _checkAndFixSubscription(msg.sender);
        address newCollection = factory.deployProxyFor(
            _implAddress, 
            _creator,
            name_,
            symbol_,
            _baseurl
        );
        collectionRegistry[_creator].push(Asset(supportedImplementations[index].assetType, newCollection)); 
    }
    function getSupportedImplementation() external view returns(Asset[] memory) {
        return supportedImplementations;
    }

    function getUsersCollections(address _user) external view returns(Asset[] memory) {
        return collectionRegistry[_user];
    }
    ////////////////////////////////////
    /// Admin  functions           /////
    ////////////////////////////////////
    function addImplementation(Asset calldata _impl) external onlyOwner {
        // Check that not exist
        for(uint256 i; i < supportedImplementations.length; ++i){
            require(
                supportedImplementations[i].contractAddress != _impl.contractAddress,
                "Already exist"
            );
        }
        supportedImplementations.push(Asset(_impl.assetType, _impl.contractAddress));
    }

    function removeImplementationByIndex(uint256 _index) external onlyOwner {
        if (_index != supportedImplementations.length -1) {
            supportedImplementations[_index] = supportedImplementations[supportedImplementations.length -1];
        }
        supportedImplementations.pop();
    }

    function setFactory(address _factory) external onlyOwner {
        factory = IUsersCollectionFactory(_factory);
    }

    //////////////////////////////////////
    function isImplementationSupported(address _impl) public view  returns(bool isSupported, uint256 index) {
        for (uint256 i; i < supportedImplementations.length; ++i){
            if (_impl == supportedImplementations[i].contractAddress){
                isSupported = true;
                index = i; 
                break;
            }
        }
    }

    function checkUserSubscription(address _user) 
            external 
            view 
            returns (bool ok, bool needFix)
        {
                (ok, needFix) = _checkUserSubscription(
                    _user
                );
        }
}