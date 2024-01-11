// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IPriceModule.sol";
import "./IYieldsterVault.sol";
import "./IAPContract.sol";

contract SDKFunctionV2 {
    using SafeERC20 for IERC20;
    address private priceModule;
    address private sdkManager;
    address private owner;
    address private APContract;

    constructor(address _priceModule, address _apContract) {
        priceModule = _priceModule;
        owner = msg.sender;
        sdkManager = msg.sender;
        APContract = _apContract;
    }

    modifier onlySDKManager() {
        require(msg.sender == sdkManager, "only sdk manager can change this");
        _;
    }

    function setSDKManager(address _manager) public onlySDKManager {
        sdkManager = _manager;
    }

    function changePriceModule(address _priceModule) public {
        require(owner == msg.sender, "not authorised");
        priceModule = _priceModule;
    }

    function changeAPContract(address _apContract) public {
        require(owner == msg.sender, "not authorised");
        APContract = _apContract;
    }

    function getTokenPriceInUSD(address _tokenAddress, bool _isVault)
        external
        view
        returns (uint256)
    {
        require(_tokenAddress != address(0), "invalid token address");
        if (_isVault) {
            return IYieldsterVault(_tokenAddress).tokenValueInUSD();
        } else {
            return IPriceModule(priceModule).getUSDPrice(_tokenAddress);
        }
    }

    function getTokenBalance(address _tokenAddress, address _vaultAddress)
        external
        view
        returns (uint256)
    {
        require(_tokenAddress != address(0), "invalid token address");
        require(_vaultAddress != address(0), "invalid vault address");
        return IYieldsterVault(_vaultAddress).getTokenBalance(_tokenAddress);
    }

    function getVaultNAV(address _vaultAddress)
        external
        view
        returns (uint256)
    {
        require(_vaultAddress != address(0), "invalid vault address");
        return IYieldsterVault(_vaultAddress).getVaultNAV();
    }

    function getVaultAssets(address _vaultAddress)
        external
        view
        returns (address[] memory)
    {
        require(_vaultAddress != address(0), "invalid vault address");
        address[] memory assets = IYieldsterVault(_vaultAddress).getAssetList();
        address[] memory assetsWithBalance = new address[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            if (this.getTokenBalance(assets[i], _vaultAddress) > 0) {
                assetsWithBalance[i] = assets[i];
            }
        }
        return assetsWithBalance;
    }

    function protocolInteraction(
        address _vaultAddress,
        address _poolAddress,
        bytes memory _instruction,
        uint256[] memory _amount,
        address[] memory _fromToken,
        address[] memory _returnToken
    ) public {
        require(_vaultAddress != address(0), "invalid vault address");
        require(
            IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        IYieldsterVault(_vaultAddress).protocolInteraction(
            _poolAddress,
            _instruction,
            _amount,
            _fromToken,
            _returnToken
        );
    }

    function y_Swap(
        address _vaultAddress,
        address _fromToken,
        address _toToken,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256) {
        require(_vaultAddress != address(0), "invalid vault address");
        require(_fromToken != address(0), "invalid fromToken address");
        require(_toToken != address(0), "invalid toToken address");
        require(
            IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        require(
            this.getTokenBalance(_fromToken, _vaultAddress) >= _amount,
            "amount not present"
        );
        uint256 returnAmount = IYieldsterVault(_vaultAddress).exchangeToken(
            _fromToken,
            _toToken,
            _amount,
            _slippage
        );
        return returnAmount;
    }

    function y_0x_Swap(
        address _vaultAddress,
        address _toAddress,
        address _fromToken,
        uint256 _amount,
        bytes memory _instruction,
        address _returnToken
    ) external {
        require(_fromToken != address(0), "No from token");
        require(_returnToken != address(0), "No return Token");
        require(
            IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        uint256[] memory amount = new uint256[](1);
        amount[0] = _amount;
        address[] memory fromToken = new address[](1);
        fromToken[0] = _fromToken;
        address[] memory returnToken = new address[](1);
        returnToken[0] = _returnToken;
        protocolInteraction(
            _vaultAddress,
            _toAddress,
            _instruction,
            amount,
            fromToken,
            returnToken
        );
    }

    function y_OB_Swap(
        address _vaultAddress,
        address _toAddress,
        bytes calldata _instruction,
        uint256 _amount,
        address _fromToken,
        address _returnToken
    ) external {
        require(
            IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        uint256[] memory amount = new uint256[](1);
        amount[0] = _amount;
        address[] memory fromToken = new address[](1);
        fromToken[0] = _fromToken;
        address[] memory returnToken = new address[](1);
        returnToken[0] = _returnToken;
        protocolInteraction(
            _vaultAddress,
            address(this),
            new bytes(0),
            amount,
            fromToken,
            new address[](0)
        );
        IERC20(_fromToken).safeTransferFrom(_vaultAddress, _toAddress, _amount);
        protocolInteraction(
            _vaultAddress,
            _toAddress,
            _instruction,
            new uint256[](0),
            new address[](0),
            returnToken
        );
    }
}
