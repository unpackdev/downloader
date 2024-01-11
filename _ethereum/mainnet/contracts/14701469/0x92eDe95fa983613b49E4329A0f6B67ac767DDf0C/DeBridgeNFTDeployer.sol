// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";

import "./DeNFT.sol";
import "./DeBridgeTokenProxy.sol";

contract DeBridgeNFTDeployer is Initializable, AccessControlUpgradeable {
    /* ========== STATE VARIABLES ========== */

    /// @dev Address of deNFT beacon
    address public beacon;
    /// @dev Debridge gate address
    address public nftBridgeAddress;
    /// @dev Maps debridge id to deBridgeToken address
    mapping(bytes32 => address) public deployedAssetAddresses;

    /// @dev Count of deployed NFT's
    uint256 nonce;

    /* ========== ERRORS ========== */

    error WrongArgument();
    error DeployedAlready();

    error AdminBadRole();
    error NFTBridgeBadRole();
    error DuplicateDebrdigeId();

    error ZeroAddress();

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    modifier onlyNFTBridge() {
        if (msg.sender != nftBridgeAddress) revert NFTBridgeBadRole();
        _;
    }

    /* ========== EVENTS ========== */

    event NFTDeployed(address asset, string name, string symbol, string baseUri, uint256 nonce);

    /* ========== CONSTRUCTOR  ========== */

    /// @dev Constructor that initializes the most important configurations.
    /// @param _beacon Address of token beacon
    /// @param _nftBridgeAddress NFT gate address.
    function initialize(address _beacon, address _nftBridgeAddress) public initializer {
        if (_beacon == address(0) || _nftBridgeAddress == address(0)) revert ZeroAddress();

        beacon = _beacon;
        nftBridgeAddress = _nftBridgeAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Deploy a deToken for an asset
    /// @param _debridgeId Asset identifier
    /// @param _name Asset name
    /// @param _symbol Asset symbol
    function deployAsset(
        bytes32 _debridgeId,
        string memory _name,
        string memory _symbol
    ) external onlyNFTBridge returns (address deBridgeTokenAddress) {
        if (deployedAssetAddresses[_debridgeId] != address(0)) revert DeployedAlready();

        deBridgeTokenAddress = _createNewAssets(nftBridgeAddress, _name, _symbol, "", _debridgeId);

        deployedAssetAddresses[_debridgeId] = deBridgeTokenAddress;
    }

    /// @dev Create NFT
    /// @param _name Asset name
    /// @param _symbol Asset symbol
    function createNFT(address _minter, string memory _name, string memory _symbol, string memory _baseUri)
        external
        onlyNFTBridge
        returns (address deBridgeTokenAddress)
    {
        deBridgeTokenAddress = _createNewAssets(
            _minter,
            _name,
            _symbol,
            _baseUri,
            keccak256(abi.encodePacked(nonce))
        );
        bytes32 debridgeId = getDebridgeId(getChainId(), deBridgeTokenAddress);
        if (deployedAssetAddresses[debridgeId] != address(0)) revert DuplicateDebrdigeId();
        deployedAssetAddresses[debridgeId] = deBridgeTokenAddress;
    }

    /* ========== ADMIN ========== */

    /// @dev Sets core debridge contract address.
    /// @param _nftBridgeAddress Debridge address.
    function setNftBridgeAddress(address _nftBridgeAddress) external onlyAdmin {
        if (_nftBridgeAddress == address(0)) revert WrongArgument();
        nftBridgeAddress = _nftBridgeAddress;
    }

    // ============ Private methods ============

    function _createNewAssets(
        address minter,
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        bytes32 salt
    ) internal returns (address deBridgeTokenAddress) {
        // Initialize args
        bytes memory initializationArgs = abi.encodeWithSelector(
            DeNFT.initialize.selector,
            _name,
            _symbol,
            _baseUri,
            minter,
            nftBridgeAddress
        );

        // initialize Proxy
        bytes memory constructorArgs = abi.encode(beacon, initializationArgs);

        // deployment code
        bytes memory bytecode = abi.encodePacked(
            type(DeBridgeTokenProxy).creationCode,
            constructorArgs
        );

        assembly {
            // debridgeId is a salt
            deBridgeTokenAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(deBridgeTokenAddress)) {
                revert(0, 0)
            }
        }

        emit NFTDeployed(deBridgeTokenAddress, _name, _symbol, _baseUri, nonce);
        nonce++;
    }

    // ============ VIEWS ============

    /// @dev Calculates asset identifier.
    /// @param _chainId Current chain id.
    /// @param _tokenAddress Address of the asset on the other chain.
    function getDebridgeId(uint256 _chainId, address _tokenAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_chainId, _tokenAddress));
    }

    /// @dev Get current chain id
    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }

    // ============ Version Control ============

    /// @dev Get this contract's version
    function version() external pure returns (uint256) {
        return 100; // 1.0.0
    }
}
