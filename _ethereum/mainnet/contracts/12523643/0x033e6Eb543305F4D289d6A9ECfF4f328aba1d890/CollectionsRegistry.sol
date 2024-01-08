pragma solidity 0.6.6;

import "./Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

contract CollectionsRegistry is Ownable {
    address public tokenImplementation;

    mapping(address => address[]) public collections;

    event CollectionCreated(address indexed creator, address indexed collectionAddress);

    constructor(address _tokenImplementation) public {
        require(_tokenImplementation != address(0), "CollectionsRegistry: wrong token implementation");
        tokenImplementation = _tokenImplementation;
    }

    function setTokenImplementation(address _newTokenImplementation) external onlyOwner {
        require(_newTokenImplementation != address(0), "CollectionsRegistry: wrong token implementation");
        tokenImplementation = _newTokenImplementation;
    }

    /**
    *  @notice Create a new collection.
    *  @dev create a new proxy of ChildMintableERC1155.
    *  @param _name - name of collectiont to be created.
    *  @param _uri - url of metadata api for collection.
    *  @param _childChainManager - address of ChildChainManager to setup DEPOSITOR_ROLE.
    *  @return proxy Address of recently created collection.
    */
    function createCollection(
        string memory _name, 
        string memory _uri,
		address _childChainManager
    )
        public
        returns (address proxy)
    {
        bytes memory bytesData = abi.encodeWithSignature(
            "initialize(string,string,address,address)", 
            _name, 
            _uri,
            msg.sender,
		    _childChainManager
        );

        proxy = address(
            new TransparentUpgradeableProxy(
                tokenImplementation, 
                owner(),
                bytesData
            )
        );
        
        collections[msg.sender].push(proxy);

        emit CollectionCreated(msg.sender, address(proxy));
    }

}
