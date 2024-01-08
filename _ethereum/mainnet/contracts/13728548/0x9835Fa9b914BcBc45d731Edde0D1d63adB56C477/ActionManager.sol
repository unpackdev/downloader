// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IXTokenWrapper.sol";
import "./IBFactory.sol";
import "./IBPool.sol";
import "./IBRegistry.sol";
import "./IXTokenFactory.sol";
import "./IXToken.sol";

contract ActionManager is
    Initializable,
    AccessControlUpgradeable,
    ERC1155HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Address of BFactory module.
     */
    address public bFactoryAddress;

    /**
     * @dev Address of BRegistry module.
     */
    address public bRegistryAddress;

    /**
     * @dev Address of xToken Factory module.
     */
    address public xTokenFactoryAddress;

    /**
     * @dev Address of xToken Wrapper module.
     */
    address public xTokenWrapperAddress;

    /**
     * @dev Address of authorizationProxyAddress module.
     */
    address public authorizationProxyAddress;

    /**
     * @dev Address of the default price feed.
     */
    address public defaultPriceFeedAddress;

    /**
     * @dev Address of the Admin for the xToken contracts
     */
    address public xTokenAdminAddress;

    /**
     * @dev String to deploy xToken
     */
    string public constant xSPT = "xSPT";

    /**
     * @dev String to deploy xToken
        Extracted from bRegistry (these values are private)
        constan uint256 bone = 10**18;
     */
    uint256 public constant maxSwapFee = (3 * 1e18) / 100;

    /**
     * @dev Emitted when `bFactoryAddress` is set.
     */
    event BFactorySet(address indexed _bFactoryAddress);

    /**
     * @dev Emitted when `bRegistryAddress` is set.
     */
    event BRegistrySet(address indexed _bRegistryAddress);

    /**
     * @dev Emitted when `xTokenFactoryAddress` is set.
     */
    event XTokenFactorySet(address indexed _xTokenFactoryAddress);

    /**
     * @dev Emitted when `xTokenWrapperAddress` is set.
     */
    event XTokenWrapperSet(address indexed _xTokenWrapperAddress);

    /**
     * @dev Emitted when `authorizationProxyAddress` is set.
     */
    event AuthorizationProxySet(address indexed _authorizationProxyAddress);

    /**
     * @dev Emitted when `authorizationProxyAddress` is set.
     */
    event DefaultPriceFeedSet(address indexed _priceFeedAddress);

    /**
     * @dev Emitted when `xTokenAdminAddress` is set.
     */
    event XTokenAdminSet(address indexed _xTokenAdminAddress);

    /**
     * @dev Emitted after a pool was created correctly
     */
    event PoolCreationSuccess(
        address indexed _msgSender,
        address indexed poolAndTokenAddress,
        address indexed poolXTokenAddress
    );

    /**
     * @dev Check if sender has the DEFAULT_ADMIN_ROLE role to execute a function
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not admin");
        _;
    }

    /**
     * @dev Initalize the contract.
     *
     * @param _bFactoryAddress sets the bfactory address
     * @param _bRegistryAddress sets the bregistry address
     * @param _xTokenFactoryAddress sets the xTokenFactory address
     * @param _xTokenWrapperAddress sets the xTokenWrapper address
     * @param _authorizationProxyAddress sets the authotizationProxy address
     */
    function initialize(
        address _bFactoryAddress,
        address _bRegistryAddress,
        address _xTokenFactoryAddress,
        address _xTokenWrapperAddress,
        address _authorizationProxyAddress
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setBFactoryAddress(_bFactoryAddress);
        _setBRegistryAddress(_bRegistryAddress);
        _setXTokenFactoryAddress(_xTokenFactoryAddress);
        _setXTokenWrapperAddress(_xTokenWrapperAddress);
        _setAuthorizationProxyAddress(_authorizationProxyAddress);
    }

    /**
     * @dev Grants DEFAULT_ADMIN_ROLE to set contract parameters.
     *
     * Requirements:
     * - the caller must have admin role.
     */
    function grantAdminRole(address newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    /**
     * @dev Sets `_bFactoryAddress` as the BFactory module.
     * @param _bFactoryAddress bFactoryAddress contract
     */
    function setBFactory(address _bFactoryAddress) external onlyAdmin {
        _setBFactoryAddress(_bFactoryAddress);
    }

    /**
     * @dev Sets `_bRegistryAddress` as the RegistryContract module.
     * @param _bRegistryAddress bRegistryAddress contract
     */
    function setBRegistry(address _bRegistryAddress) external onlyAdmin {
        _setBRegistryAddress(_bRegistryAddress);
    }

    /**
     * @dev Sets `_xTokenFactoryAddress` as the xToken Factory module.
     * @param _xTokenFactoryAddress xTokenFactoryAddress contract
     */
    function setXTokenFactory(address _xTokenFactoryAddress) external onlyAdmin {
        _setXTokenFactoryAddress(_xTokenFactoryAddress);
    }

    /**
     * @dev Sets `_xTokenWrapperAddress` as the xToken Wrapper module.
     * @param _xTokenWrapperAddress  xTokenWrapperAddress contract
     */
    function setXTokenWrapper(address _xTokenWrapperAddress) external onlyAdmin {
        _setXTokenWrapperAddress(_xTokenWrapperAddress);
    }

    /**
     * @dev Sets `_authorizationProxyAddress` as the authorizationProxyAddress module.
     * @param _authorizationProxyAddress  authorizationProxyAddress contract
     */
    function setAuthorizationProxy(address _authorizationProxyAddress) external onlyAdmin {
        _setAuthorizationProxyAddress(_authorizationProxyAddress);
    }

    /**
     * @dev Sets `_priceFeedAddress` as the defaultPriceFeed address.
     * @param _priceFeedAddress  priceFeed address contract
     */
    function setDefaultPriceFeed(address _priceFeedAddress) external onlyAdmin {
        require(_priceFeedAddress != address(0), "_priceFeedAddress is zero address");
        emit DefaultPriceFeedSet(_priceFeedAddress);
        defaultPriceFeedAddress = _priceFeedAddress;
    }

    /**
     * @dev Sets `_xTokenAdminAddress` as the xTokenAdmin address
     * @param _xTokenAdminAddress  xToken admin address
     */
    function setXTokenAdmin(address _xTokenAdminAddress) external onlyAdmin {
        require(_xTokenAdminAddress != address(0), "_xTokenAdminAddress is zero address");
        emit XTokenAdminSet(_xTokenAdminAddress);
        xTokenAdminAddress = _xTokenAdminAddress;
    }

    /**
     * @dev Sets `bFactoryAddress` as the BFactory module.
     * @param _bFactoryAddress bFactoryAddress contract
     */
    function _setBFactoryAddress(address _bFactoryAddress) internal {
        require(_bFactoryAddress != address(0), "_bFactoryAddress is zero address");
        emit BFactorySet(_bFactoryAddress);
        bFactoryAddress = _bFactoryAddress;
    }

    /**
     * @dev Sets `bRegistryAddress` as the RegistryContract module.
     * @param _bRegistryAddress registryAddress contract
     */
    function _setBRegistryAddress(address _bRegistryAddress) internal {
        require(_bRegistryAddress != address(0), "_bRegistryAddress is zero address");
        emit BRegistrySet(_bRegistryAddress);
        bRegistryAddress = _bRegistryAddress;
    }

    /**
     * @dev Sets `xTokenFactoryAddress` as the xToken Factory module.
     * @param _xTokenFactoryAddress xTokenFactoryAddress contract
     */
    function _setXTokenFactoryAddress(address _xTokenFactoryAddress) internal {
        require(_xTokenFactoryAddress != address(0), "_xTokenFactoryAddress is zero address");
        emit XTokenFactorySet(_xTokenFactoryAddress);
        xTokenFactoryAddress = _xTokenFactoryAddress;
    }

    /**
     * @dev Sets `xTokenWrapperAddress` as the xToken Wrapper module.
     * @param _xTokenWrapperAddress The address of the new xToken Wrapper module.
     */
    function _setXTokenWrapperAddress(address _xTokenWrapperAddress) internal {
        require(_xTokenWrapperAddress != address(0), "_xTokenWrapperAddress is zero address");
        emit XTokenWrapperSet(_xTokenWrapperAddress);
        xTokenWrapperAddress = _xTokenWrapperAddress;
    }

    /**
     * @dev Sets `authorizationProxyAddress` as the authorizationProxyAddress module.
     * @param _authorizationProxyAddress The address of the new xToken Wrapper module.
     */
    function _setAuthorizationProxyAddress(address _authorizationProxyAddress) internal {
        require(_authorizationProxyAddress != address(0), "_authorizationProxyAddress is zero address");
        emit AuthorizationProxySet(_authorizationProxyAddress);
        authorizationProxyAddress = _authorizationProxyAddress;
    }

    /**
     * @dev Makes the token transfer n times as tokens defined
     * @param _tokens The address array of the tokens
     * @param _from   The address of the sender
     * @param _to The address of the receiver
     * @param _amounts The array amounts
     * @return a boolean signaling the completiion of the function
     */
    function _tokenTransfer(
        address[] memory _tokens,
        address _from,
        address _to,
        uint256[] memory _amounts
    ) private returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20Upgradeable(_tokens[i]).safeTransferFrom(_from, _to, _amounts[i]);
        }
        return true;
    }

    /**
     * @dev Makes the approve n times as tokens defined
     * @param _tokens The address array of the tokens
     * @param _spender The address of the receiver
     * @param _amounts The array amounts
     * @return a boolean signaling the completiion of the function
     */
    function _approveTokenTransfer(
        address[] memory _tokens,
        address _spender,
        uint256[] memory _amounts
    ) private returns (bool) {
        bool returnedValue = false;
        for (uint256 i = 0; i < _tokens.length; i++) {
            returnedValue = IERC20Upgradeable(_tokens[i]).approve(_spender, _amounts[i]);
            require(returnedValue, "Approve failed");
        }
        return true;
    }

    /**
     * @dev Makes the wrapping of each token in the array
     * @param _tokenAddresses The address array of the tokens
     * @param _amounts The array amounts
     * @return a boolean signaling the completiion of the function
     */
    function _wrapToken(address[] memory _tokenAddresses, uint256[] memory _amounts) private returns (bool) {
        bool returnedValue = false;
        IXTokenWrapper xTokenWrapperContract = IXTokenWrapper(xTokenWrapperAddress);
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            returnedValue = xTokenWrapperContract.wrap(_tokenAddresses[i], _amounts[i]);
            require(returnedValue, "Wrap failed");
        }
        return true;
    }

    /**
     * @dev Makes the actual pool creation
     * @return an IBPOOL contract to handle the pool operations
     */
    function _createNewPool() private returns (IBPool) {
        IBFactory bFactoryContract = IBFactory(bFactoryAddress);
        IBPool poolAndTokenContract = bFactoryContract.newBPool();

        // userToPool[msg.sender] = address(poolAndTokenContract);
        bool txOk = poolAndTokenContract.getController() == address(this);
        require(txOk, "pool creation failed");
        return poolAndTokenContract;
    }

    /**
     * @dev Gets the xToken address for each token
     * @param _tokenAddress The address of the tokens
     * @return an address of the xToken stored in the xTokenWrapper map
     */
    function _getXTokenAddress(address _tokenAddress) private view returns (address) {
        IXTokenWrapper xTokenWrapperContract = IXTokenWrapper(xTokenWrapperAddress);
        address xTokenAddress = xTokenWrapperContract.tokenToXToken(_tokenAddress);
        return xTokenAddress;
    }

    /**
     * @dev builds an array of the xTokens corresponding to the standrad tokens
     * @param _tokenAddresses The address array of the tokens
     * @return an address array containing all the xTokens
     */
    function _buildXTokenArray(address[] memory _tokenAddresses) private view returns (address[] memory) {
        uint256 length = _tokenAddresses.length;
        address[] memory xTokensAddresses = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            xTokensAddresses[i] = _getXTokenAddress(_tokenAddresses[i]);
        }

        require(xTokensAddresses.length == _tokenAddresses.length, "Invalid xTokenArray generated");
        return xTokensAddresses;
    }

    /**
     * @dev Binds each xToken to the pool
     * @param _xTokenAddresses The address array of the xTokens
     * @param _amounts The array amounts
     * @param _xTokensWeight The array of the weight of each token
     * @return a boolean signaling the completiion of the function
     */
    function _bindXTokensToPool(
        address[] memory _xTokenAddresses,
        uint256[] memory _amounts,
        uint256[] memory _xTokensWeight,
        IBPool poolAndTokenContract
    ) private returns (bool) {
        for (uint256 i = 0; i < _xTokenAddresses.length; i++) {
            poolAndTokenContract.bind(_xTokenAddresses[i], _amounts[i], _xTokensWeight[i]);
        }
        return true;
    }

    /**
     * @dev Generates the possible combination of each pair to add it to the pool
     * @param _poolAndTokenAddress The address of the created pool/token
     * @param _xTokenAddresses The address array of the xTokens
     * @return a boolean signaling the completiion of the function
     */
    function _addPoolPair(address _poolAndTokenAddress, address[] memory _xTokenAddresses) private returns (bool) {
        IBRegistry bRegistryContract = IBRegistry(bRegistryAddress);

        for (uint256 i = 0; i < _xTokenAddresses.length - 1; i++) {
            for (uint256 j = i + 1; j < _xTokenAddresses.length; j++) {
                bRegistryContract.addPoolPair(_poolAndTokenAddress, _xTokenAddresses[i], _xTokenAddresses[j]);
            }
        }
        return true;
    }

    /**
     * @dev Issues the sortPools command
     * @param _xTokenAddresses The address array of the xTokens
     * @return a boolean signaling the completiion of the function
     */
    function _sortPools(address[] memory _xTokenAddresses) private returns (bool) {
        IBRegistry bRegistryContract = IBRegistry(bRegistryAddress);
        for (uint256 i = 0; i < _xTokenAddresses.length; i++) {
            bRegistryContract.sortPools(_xTokenAddresses, 10);
        }
        return true;
    }

    /**
     * @dev Makes the token transfer n times as tokens defined
     * @param _poolContractAddress The address of the created pool/token
     * @param _priceFeed The price feed for the pool
     * @param _poolName The name displayed on the app for the pool
     * @return an address of the new pool xToken deployed
     */
    function _deployXPoolToken(
        address _poolContractAddress,
        address _priceFeed,
        string memory _poolName
    ) private returns (address) {
        IXTokenFactory xTokenFactoryContract = IXTokenFactory(xTokenFactoryAddress);
        address poolXTokenAddress =
            xTokenFactoryContract.deployXToken(
                _poolContractAddress,
                _poolName,
                xSPT,
                18,
                xSPT,
                authorizationProxyAddress,
                _priceFeed
            );

        IXToken xTokenContract = IXToken(poolXTokenAddress);
        bytes32 defaultAdminRole = 0x00;
        xTokenContract.grantRole(defaultAdminRole, xTokenAdminAddress);
        return poolXTokenAddress;
    }

    /**
     * @dev Checks the value of the swapFee to not fail later on
     * @param _swapFee The swapFee value
     */
    function _checkSwapFee(uint256 _swapFee) private pure {
        require(_swapFee > 0, "SwapFee is ZERO");

        require(_swapFee <= maxSwapFee, "SwapFee higher than bRegistry maxSwapFee");
    }

    /**
     * @dev Checks each value of the three arrays
     * @param _tokenAddresses The array for all the tokens
     * @param _amounts  The array for all the amounts
     * @param _xTokensWeight  The array for all the tokens weight
     */
    function _checkArrays(
        address[] memory _tokenAddresses,
        uint256[] memory _amounts,
        uint256[] memory _xTokensWeight
    ) private pure {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            require(_tokenAddresses[i] != address(0), "Invalid tokenAddresses array");
            require(_amounts[i] > 0, "Invalid amounts array");
            require(_xTokensWeight[i] > 0, "Invalid xTokensWeight array");
        }
    }

    /**
     * @dev Converts a single address to an array of one address to use the transfer and approve functions
     * @param _tokenAddress The token address to convert
     * @return an array of 1 element containing the tokenAddress
     */
    function _convertToArrayOfOneAddress(address _tokenAddress) private pure returns (address[] memory) {
        address[] memory tokenAddressArr = new address[](1);
        tokenAddressArr[0] = _tokenAddress;
        return tokenAddressArr;
    }

    /**
     * @dev Converts a single amount to an array of one amount to use the transfer and approve functions
     * @param _amount The amount to convert
     * @return an array of 1 element containing the tokenAddress
     */
    function _convertToArrayOfOneUint(uint256 _amount) private pure returns (uint256[] memory) {
        uint256[] memory amountArr = new uint256[](1);
        amountArr[0] = _amount;
        return amountArr;
    }

    /**
     * @dev Makes the token transfer n times as tokens defined
     * @param tokenAddresses The address array of the tokens
     * @param amounts The array amounts
     * @param swapFee The swapFee value
     * @param xTokensWeight The array of the weight of each token
     * @param poolName The name displayed on the app for the pool
     * @return a boolean signaling the completiion of the function
     */
    function standardPoolCreation(
        address[] memory tokenAddresses,
        uint256[] memory amounts,
        uint256 swapFee,
        uint256[] memory xTokensWeight,
        string memory poolName
    ) external nonReentrant returns (bool) {
        require(tokenAddresses.length == amounts.length, "Different tknAddress-amounts length");
        require(tokenAddresses.length == xTokensWeight.length, "Different tknAddress-xtknWeight length");
        require(bytes(poolName).length > 3, "Invalid PoolName provided"); // 3 chars pool name ?
        require(defaultPriceFeedAddress != address(0), "defaultPriceFeedAddress is NOT SET");
        require(xTokenAdminAddress != address(0), "xTokenAdminAddress is NOT SET");

        _checkSwapFee(swapFee);
        _checkArrays(tokenAddresses, amounts, xTokensWeight);

        bool txOk = false;

        txOk = _tokenTransfer(tokenAddresses, _msgSender(), address(this), amounts);
        require(txOk, "Transfer 01 - failed");

        _approveTokenTransfer(tokenAddresses, xTokenWrapperAddress, amounts);

        _wrapToken(tokenAddresses, amounts);

        IBPool poolAndTokenContract = _createNewPool();
        poolAndTokenContract.setSwapFee(swapFee);
        address poolAndTokenAddress = address(poolAndTokenContract);

        address[] memory xTokenAddresses = _buildXTokenArray(tokenAddresses);

        _approveTokenTransfer(xTokenAddresses, poolAndTokenAddress, amounts);

        txOk = _bindXTokensToPool(xTokenAddresses, amounts, xTokensWeight, poolAndTokenContract);
        require(txOk, "bind tkns failed");

        poolAndTokenContract.finalize();

        txOk = _addPoolPair(poolAndTokenAddress, xTokenAddresses);
        require(txOk, "addPoolPair failed");

        txOk = _sortPools(xTokenAddresses);
        require(txOk, "sortPools failed");

        address poolXTokenAddress = _deployXPoolToken(poolAndTokenAddress, defaultPriceFeedAddress, poolName);
        require(txOk, "deployXPoolToken failed");

        address[] memory poolAndTokenAddressArr = _convertToArrayOfOneAddress(poolAndTokenAddress);
        address[] memory poolXTokenAddressArr = _convertToArrayOfOneAddress(poolXTokenAddress);

        uint256 balanceToken = poolAndTokenContract.balanceOf(address(this));
        uint256[] memory balancePoolTokenArr = _convertToArrayOfOneUint(balanceToken);

        _approveTokenTransfer(poolAndTokenAddressArr, xTokenWrapperAddress, balancePoolTokenArr);
        _wrapToken(poolAndTokenAddressArr, balancePoolTokenArr);

        balanceToken = IERC20Upgradeable(poolXTokenAddress).balanceOf(address(this));
        uint256[] memory balanceXPoolTokenArr = _convertToArrayOfOneUint(balanceToken);

        _approveTokenTransfer(poolXTokenAddressArr, address(this), balanceXPoolTokenArr);

        txOk = _tokenTransfer(poolXTokenAddressArr, address(this), _msgSender(), balanceXPoolTokenArr);
        require(txOk, "Transfer 02 - failed");

        emit PoolCreationSuccess(_msgSender(), poolAndTokenAddress, poolXTokenAddress);

        return true;
    }
}
