// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";

import "./AssetLib.sol";
import "./AssetLib2.sol";

import "./IAssetDeployCode.sol";
import "./IAssetFactory.sol";
import "./IAsset.sol";
import "./IStakingFactory.sol";

contract AssetFactory is AccessControl, ReentrancyGuard, IAssetFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    // public
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address public deployCodeContract;
    address public oracle;
    address public override defaultDexRouter;
    address public override defaultDexFactory;
    address public override weth;
    address public zVault;
    address public feeTaker;

    address[] public allAssets;

    mapping(address => address) public override notDefaultDexRouterToken;
    mapping(address => address) public override notDefaultDexFactoryToken;
    mapping(address => bool) public override isAddressDexRouter;

    // private
    EnumerableSet.AddressSet private _defaultWhitelistSet;
    EnumerableSet.AddressSet private _notDefaultDexTokensSet;

    event NewAssetDeploy(
        address newAsset,
        string name,
        string symbol,
        uint256 imeStartTimestamp,
        uint256 imeEndTimestamp,
        address[] tokensInAsset,
        uint256[] tokensDistribution
    );
    event WhitelistChange(address indexed token, bool newValue);

    modifier onlyManagerOrAdmin {
        address sender = _msgSender();
        require(
            hasRole(MANAGER_ROLE, sender) || hasRole(DEFAULT_ADMIN_ROLE, sender),
            "Access error"
        );
        _;
    }

    // solhint-disable-next-line func-visibility
    constructor(
        address _deployCodeContract,
        address _defaultDexRouter,
        address _defaultDexFactory
    ) {
        deployCodeContract = _deployCodeContract;
        defaultDexRouter = _defaultDexRouter;
        defaultDexFactory = _defaultDexFactory;
        address _weth = AssetLib.getWethFromDex(_defaultDexRouter);
        require(_weth != address(0), "Wrong dex");
        weth = _weth;

        isAddressDexRouter[_defaultDexRouter] = true;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    function deployNewAsset(
        string memory name,
        string memory symbol,
        uint256[2] memory imeTimeParameters,
        address[] memory tokensInAsset,
        uint256[] memory tokensDistribution,
        uint256 initialPrice
    ) external virtual onlyManagerOrAdmin returns (address) {
        address _zVault = zVault;
        require(oracle != address(0), "Oracle not found");
        require(_zVault != address(0), "Oracle not found");

        IAsset assetInst =
            _deployAsset(
                name,
                symbol,
                imeTimeParameters,
                tokensInAsset,
                tokensDistribution,
                initialPrice,
                feeTaker
            );

        IStakingFactory(_zVault).createPool(address(assetInst));

        emit NewAssetDeploy(
            address(assetInst),
            name,
            symbol,
            imeTimeParameters[0],
            imeTimeParameters[1],
            tokensInAsset,
            tokensDistribution
        );

        return address(assetInst);
    }

    function changeIsTokenWhitelisted(address token, bool value) external onlyManagerOrAdmin {
        require(token != address(0), "Token error");
        if (value) {
            address[] memory temp = new address[](1);
            temp[0] = token;
            AssetLib.checkIfTokensHavePair(temp, address(this));
            require(_defaultWhitelistSet.add(token), "Wrong value");
        } else {
            require(_defaultWhitelistSet.remove(token), "Wrong value");
        }

        emit WhitelistChange(token, value);
    }

    function changeOracle(address newOracle) external onlyManagerOrAdmin {
        require(oracle == address(0) && newOracle != address(0), "Bad use");
        oracle = newOracle;
    }

    function changeZVault(address newZVault) external onlyManagerOrAdmin {
        require(zVault == address(0) && newZVault != address(0), "Bad use");
        zVault = newZVault;
    }

    function changeFeeTaker(address newFeeTaker) external onlyManagerOrAdmin {
        require(feeTaker == address(0) && newFeeTaker != address(0), "Bad use");
        feeTaker = newFeeTaker;
    }

    function addNotDefaultDexToken(
        address token,
        address dexRouter,
        address dexFactory
    ) external onlyManagerOrAdmin {
        address _weth = AssetLib.getWethFromDex(dexRouter);
        require(_weth != address(0) && _weth == weth, "Wrong dex router");

        isAddressDexRouter[dexRouter] = true;

        _notDefaultDexTokensSet.add(token);
        notDefaultDexRouterToken[token] = dexRouter;
        notDefaultDexFactoryToken[token] = dexFactory;

        address[] memory temp = new address[](1);
        temp[0] = token;
        AssetLib.checkIfTokensHavePair(temp, address(this));
    }

    function removeNotDefaultDexToken(address token) external onlyManagerOrAdmin {
        _notDefaultDexTokensSet.remove(token);
        delete notDefaultDexRouterToken[token];
        delete notDefaultDexFactoryToken[token];
    }

    function allAssetsLen() external view returns (uint256) {
        return allAssets.length;
    }

    function defaultTokenWhitelistLen() external view returns (uint256) {
        return _defaultWhitelistSet.length();
    }

    function notDefaultDexTokensSetLen() external view returns (uint256) {
        return _notDefaultDexTokensSet.length();
    }

    function getNotDefaultDexTokensSet(uint256 index) external view returns (address) {
        return _notDefaultDexTokensSet.at(index);
    }

    function isTokenDefaultWhitelisted(address token) external view returns (bool) {
        return _defaultWhitelistSet.contains(token);
    }

    function defaultTokenWhitelist(uint256 index) external view returns (address) {
        return _defaultWhitelistSet.at(index);
    }

    function _deployAsset(
        string memory name,
        string memory symbol,
        uint256[2] memory imeTimeParameters,
        address[] memory tokensInAsset,
        uint256[] memory tokensDistribution,
        uint256 initialPrice,
        address feeAddress
    ) internal returns (IAsset assetInst) {
        (bool success, bytes memory data) =
            // solhint-disable-next-line avoid-low-level-calls
            deployCodeContract.delegatecall(
                abi.encodeWithSelector(
                    IAssetDeployCode.newAsset.selector,
                    bytes32(allAssets.length)
                )
            );
        require(success == true, "Deploy failed");

        assetInst = IAsset(abi.decode(data, (address)));

        uint256 defaultWhitelistLen = _defaultWhitelistSet.length();
        address[] memory defaultWhitelist = new address[](defaultWhitelistLen);
        for (uint256 i = 0; i < defaultWhitelistLen; ++i) {
            defaultWhitelist[i] = _defaultWhitelistSet.at(i);
        }

        assetInst.__Asset_init(
            [name, symbol],
            [oracle, zVault, weth],
            [imeTimeParameters[0], imeTimeParameters[1], initialPrice],
            defaultWhitelist,
            tokensInAsset,
            tokensDistribution,
            payable(feeAddress)
        );

        allAssets.push(address(assetInst));
    }
}
