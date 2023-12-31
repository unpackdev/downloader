import "./IExternalStore.sol";

pragma solidity >=0.8.19;

// SPDX-License-Identifier: MIT

interface IDiamondStore {
    function owner() external view returns (address owner);

    function checkAdmin(address user) external view returns (bool isAdmin);

    function getUserFromWallet(
        address wallet
    ) external view returns (address owner);

    function store(
        address user,
        bytes32 namespace,
        uint slot,
        bytes memory data
    ) external;

    function getStore(
        address user,
        bytes32 namespace,
        uint slot
    ) external view returns (bytes memory);

    function store(bytes32 namespace, uint slot, bytes memory data) external;

    function getStore(
        bytes32 namespace,
        uint slot
    ) external view returns (bytes memory);
}

abstract contract BaseModule {
    /*
        @dev order of import matters! ALWAYS import BaseModule FIRST
        @dev storage will always take up the first slot
        
        Example of storing data        
        contractStore[userProxy][NAMESPACE][0]=abi.encode(user, token, amount, poolAddress);

        Example of retrieving data
        (address user, uint token, uint amount, address poolAddress = abi.decode(contractStore[userProxy][NAMESPACE][0], (address,uint,uint address));
    */

    /// @dev to set when diamond has been minted

    address internal immutable diamond =
        0x98738F824BDbA894F42f3c70B3e13C73cd8f7a3C;

    address internal immutable _this;

    /*
        @dev Determines the namespace for storing data
        @dev Data will be stored in caller contract (Smart Wallet)

        example of storing data 


    */
    bytes32 internal immutable NAMESPACE;

    /// @dev used only for reading directly from the contract. This variable will not return correct data in the event of a delegatecall
    string public name;

    event Event(bytes4 fnSig, uint256 eventIndex, bytes eventData);

    error BaseModuleUnauthorized();

    // Generic error struct
    error FacetError(bytes4 funcSig, uint index);

    struct TokenAmt {
        address token;
        uint amt;
    }

    constructor(string memory name_) {
        _this = address(this);
        name = name_;
        /// @dev we avoid using address(this) as a namespace to cater for upgrades
        NAMESPACE = keccak256(abi.encodePacked(block.chainid, name));
    }

    modifier onlyDiamondOwner() {
        if (msg.sender != IDiamondStore(diamond).owner())
            revert BaseModuleUnauthorized();
        _;
    }

    modifier onlyDiamondAdmin() {
        if (!IDiamondStore(diamond).checkAdmin(msg.sender)) {
            if (msg.sender != IDiamondStore(diamond).owner())
                revert BaseModuleUnauthorized();
        }
        _;
    }

    modifier onlyWalletOwner() {
        if (
            msg.sender !=
            IDiamondStore(diamond).getUserFromWallet((address(this)))
        ) revert BaseModuleUnauthorized();
        _;
    }

    modifier onlySmartWallet() virtual {
        if (
            IDiamondStore(diamond).getUserFromWallet(address(this)) ==
            address(0)
        ) revert BaseModuleUnauthorized();
        _;
    }

    function _store(address user, uint slot, bytes memory data) internal {
        IDiamondStore(diamond).store(user, NAMESPACE, slot, data);
    }

    function _getStore(
        address user,
        bytes32 namespace,
        uint slot
    ) internal view returns (bytes memory) {
        return IDiamondStore(diamond).getStore(user, namespace, slot);
    }

    function _store(uint slot, bytes memory data) internal {
        IDiamondStore(diamond).store(NAMESPACE, slot, data);
    }

    function _getStore(
        bytes32 namespace,
        uint slot
    ) internal view returns (bytes memory) {
        return IDiamondStore(diamond).getStore(namespace, slot);
    }
}
