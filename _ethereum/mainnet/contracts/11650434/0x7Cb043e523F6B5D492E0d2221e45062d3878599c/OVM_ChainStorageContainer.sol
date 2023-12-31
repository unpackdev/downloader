pragma solidity ^0.7.0;

/* Library Imports */
import "./Lib_RingBuffer.sol";
import "./Lib_AddressResolver.sol";

/* Interface Imports */
import "./iOVM_ChainStorageContainer.sol";

/**
 * @title OVM_ChainStorageContainer
 */
contract OVM_ChainStorageContainer is iOVM_ChainStorageContainer, Lib_AddressResolver {

    /*************
     * Libraries *
     *************/

    using Lib_RingBuffer for Lib_RingBuffer.RingBuffer;


    /*************
     * Variables *
     *************/

    string public owner;
    Lib_RingBuffer.RingBuffer internal buffer;


    /***************
     * Constructor *
     ***************/
    
    /**
     * @param _libAddressManager Address of the Address Manager.
     * @param _owner Name of the contract that owns this container (will be resolved later).
     */
    constructor(
        address _libAddressManager,
        string memory _owner
    )
        Lib_AddressResolver(_libAddressManager)
    {
        owner = _owner;
    }


    /**********************
     * Function Modifiers *
     **********************/
    
    modifier onlyOwner() {
        require(
            msg.sender == resolve(owner),
            "OVM_ChainStorageContainer: Function can only be called by the owner."
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function setGlobalMetadata(
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        return buffer.setExtraData(_globalMetadata);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function getGlobalMetadata()
        override
        public
        view
        returns (
            bytes27
        )
    {
        return buffer.getExtraData();
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function length()
        override
        public
        view
        returns (
            uint256
        )
    {
        return uint256(buffer.getLength());
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function push(
        bytes32 _object
    )
        override
        public
        onlyOwner
    {
        buffer.push(_object);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function push(
        bytes32 _object,
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        buffer.push(_object, _globalMetadata);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function push2(
        bytes32 _objectA,
        bytes32 _objectB
    )
        override
        public
        onlyOwner
    {
        buffer.push2(_objectA, _objectB);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function push2(
        bytes32 _objectA,
        bytes32 _objectB,
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        buffer.push2(_objectA, _objectB, _globalMetadata);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function get(
        uint256 _index
    )
        override
        public
        view
        returns (
            bytes32
        )
    {
        return buffer.get(uint40(_index));
    }
    
    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function deleteElementsAfterInclusive(
        uint256 _index
    )
        override
        public
        onlyOwner
    {
        buffer.deleteElementsAfterInclusive(
            uint40(_index)
        );
    }
    
    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function deleteElementsAfterInclusive(
        uint256 _index,
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        buffer.deleteElementsAfterInclusive(
            uint40(_index),
            _globalMetadata
        );
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function setNextOverwritableIndex(
        uint256 _index
    )
        override
        public
        onlyOwner
    {
        buffer.nextOverwritableIndex = _index;
    }
}
