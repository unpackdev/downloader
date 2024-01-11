// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./VaultStorage.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract YieldsterVault is VaultStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    event Response(address feeAddress, string message);
    event CallStatus(string message);
    event TransferLOG(string message, address initator, address token);

    /// @dev Function to upgrade the mastercopy of Yieldster Vault.
    /// @param _mastercopy Address of new mastercopy of Yieldster Vault.
    function upgradeMasterCopy(address _mastercopy) external {
        _isYieldsterGOD();
        (bool result, ) = address(this).call(
            abi.encodeWithSignature("changeMasterCopy(address)", _mastercopy)
        );
        revertDelegate(result);
    }

    /// @dev Function to set APS Address.
    /// @param _APContract Address of Yieldster APS contract.
    function setAPS(address _APContract) external {
        _isYieldsterGOD();
        APContract = _APContract;
    }

    /// @dev Function to toggle Emergency Break feature of the Vault.
    function toggleEmergencyBreak() external {
        _isYieldsterGOD();
        if (emergencyConditions == 1) emergencyConditions = 0;
        else if (emergencyConditions == 0) emergencyConditions = 1;
    }

    /// @dev Function to enable emergency exit.
    function enableEmergencyExit() external {
        _isYieldsterGOD();
        emergencyConditions = 2;
        for (uint256 i = 0; i < assetList.length; i++) {
            if (assetList[i] == eth) {
                uint256 tokenBalance = address(this).balance;
                if (tokenBalance > 0) {
                    address payable to = payable(emergencyVault);
                    // to.transfer replaced here
                    (bool success, ) = to.call{value: tokenBalance}("");
                    if (success == false) {
                        emit CallStatus("call failed");
                    }
                }
            } else {
                IERC20 token = IERC20(assetList[i]);
                uint256 tokenBalance = token.balanceOf(address(this));
                if (tokenBalance > 0) {
                    token.safeTransfer(emergencyVault, tokenBalance);
                }
            }
        }
    }

    /// @dev Function that checks if the user is whitelisted.
    function _isWhiteListed() private view {
        if (whiteListGroups.length == 0) {
            return;
        } else {
            for (uint256 i = 0; i < whiteListGroups.length; i++) {
                if (isWhiteListGroupPresent[whiteListGroups[i]]) {
                    if (
                        IWhitelist(IAPContract(APContract).whitelistModule())
                            .isMember(whiteListGroups[i], msg.sender)
                    ) {
                        return;
                    }
                }
            }
            revert("Only Whitelisted");
        }
    }

    /// @dev Function that is called once after vault creation to Register the Vault with APS.
    function registerVaultWithAPS() external onlyNormalMode {
        require(msg.sender == owner, "unauthorized");
        require(!vaultRegistrationCompleted, "Vault is already registered");
        vaultRegistrationCompleted = true;
        IAPContract(APContract).addVault(vaultAdmin, whiteListGroups);
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _APContract Address of apcontract.
    /// @param _vaultAdmin Address of the Vault APS Manager.
    /// @param _emergencyVault Address of the emergency vault.
    function setup(
        address _APContract,
        address _vaultAdmin,
        address _emergencyVault
    ) external {
        require(!vaultSetupCompleted, "Vault is already setup");
        vaultSetupCompleted = true;
        vaultAdmin = _vaultAdmin;
        APContract = _APContract;
        owner = _vaultAdmin;
        eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        emergencyVault = _emergencyVault;
        tokenBalances = new TokenBalanceStorage();
    }

    /// @dev Function to transfer ownership.
    /// @param _owner Address of the new owner.
    function transferOwnership(address _owner) external {
        require(msg.sender == owner, "unauthorized");
        owner = _owner;
    }

    /// @dev Function to add whiteListGroups.
    /// @param _whiteListGroups List of whiteListGroups to be added.
    function addWhiteListGroups(uint256[] memory _whiteListGroups) external {
        _isVaultAdmin();
        for (uint256 i = 0; i < _whiteListGroups.length; i++) {
            if (!isWhiteListGroupPresent[_whiteListGroups[i]]) {
                whiteListGroups.push(_whiteListGroups[i]);
                isWhiteListGroupPresent[_whiteListGroups[i]] = true;
            }
        }
    }

    /// @dev Function to remove whiteListGroups.
    /// @param _whiteListGroups List of whiteListGroups to be removed.
    function removeWhiteListGroups(uint256[] memory _whiteListGroups) external {
        _isVaultAdmin();
        for (uint256 i = 0; i < _whiteListGroups.length; i++) {
            isWhiteListGroupPresent[_whiteListGroups[i]] = false;
        }
    }

    /// @dev Function to set TokenDetails.
    /// @param _tokenName Token Name.
    /// @param _symbol Token Symbol.
    function setTokenDetails(string memory _tokenName, string memory _symbol)
        external
    {
        require(msg.sender == owner, "unauthorized");
        setupToken(_tokenName, _symbol);
    }

    /// @dev Function to set Slippage percentage of the vault.
    /// @param _slippage Slippage percentage.
    function setVaultSlippage(uint256 _slippage) external onlyNormalMode {
        require(msg.sender == vaultAdmin, "unauthorized");
        IAPContract(APContract).setVaultSlippage(_slippage);
    }

    /// @dev Function to manage the assets supported by the vaults.
    /// @param _enabledDepositAsset List of assets to be enabled in Deposit assets.
    /// @param _enabledWithdrawalAsset List of assets to be enabled in Withdrawal assets.
    /// @param _disabledDepositAsset List of assets to be disabled in Deposit assets.
    /// @param _disabledWithdrawalAsset List of assets to be disabled in Withdrawal assets.
    function setVaultAssets(
        address[] calldata _enabledDepositAsset,
        address[] calldata _enabledWithdrawalAsset,
        address[] calldata _disabledDepositAsset,
        address[] calldata _disabledWithdrawalAsset
    ) external onlyNormalMode {
        require(msg.sender == vaultAdmin, "unauthorized");
        IAPContract(APContract).setVaultAssets(
            _enabledDepositAsset,
            _enabledWithdrawalAsset,
            _disabledDepositAsset,
            _disabledWithdrawalAsset
        );
    }

    /// @dev Function to change the APS Manager of the Vault.
    /// @param _vaultAdmin Address of the new APS Manager.
    function changeVaultAdmin(address _vaultAdmin) external onlyNormalMode {
        require(
            IAPContract(APContract).yieldsterDAO() == msg.sender ||
                vaultAdmin == msg.sender,
            "unauthorized"
        );
        vaultAdmin = _vaultAdmin;
        IAPContract(APContract).changeVaultAdmin(_vaultAdmin);
    }

    /// @dev Function to set smart strategies to vault.
    /// @param _smartStrategyAddress Address of smart Strategy.
    /// @param _type Type of smart strategy.
    function setVaultSmartStrategy(address _smartStrategyAddress, uint256 _type)
        public
    {
        _isVaultAdmin();
        IAPContract(APContract).setVaultSmartStrategy(
            _smartStrategyAddress,
            _type
        );
    }

    /// @dev Function to set threshold Vaule.
    /// @param _threshold minimum threshold of an asset in vault.
    function setThreshold(uint256 _threshold) external {
        _isVaultAdmin();
        threshold = _threshold;
    }

    /// @dev Function to Deposit assets into the Vault.
    /// @param _tokenAddress Address of the deposit token.
    /// @param _amount Amount of deposit token.
    function deposit(address _tokenAddress, uint256 _amount)
        external
        payable
        onlyNormalMode
        whenNotPaused
    {
        _isWhiteListed();
        require(
            IAPContract(APContract).isDepositAsset(_tokenAddress),
            "Not an approved deposit asset"
        );

        if (_tokenAddress == eth) {
            require(_amount == msg.value, "incorrect value");
        }

        managementFeeCleanUp(_tokenAddress);

        (bool result, ) = IAPContract(APContract)
            .getDepositStrategy()
            .delegatecall(
                abi.encodeWithSignature(
                    "deposit(address,uint256)",
                    _tokenAddress,
                    _amount
                )
            );
        revertDelegate(result);
        if (!result)
            emit TransferLOG("Deposit Failed", msg.sender, _tokenAddress);
        else emit TransferLOG("Deposit Success", msg.sender, _tokenAddress);
    }

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        external
        onlyNormalMode
    {
        _isWhiteListed();
        require(
            IAPContract(APContract).isWithdrawalAsset(_tokenAddress),
            "Not an approved Withdrawal asset"
        );
        require(
            balanceOf(msg.sender) >= _shares,
            "You don't have enough shares"
        );

        managementFeeCleanUp(_tokenAddress);

        (bool result, ) = IAPContract(APContract)
            .getWithdrawStrategy()
            .delegatecall(
                abi.encodeWithSignature(
                    "withdraw(address,uint256)",
                    _tokenAddress,
                    _shares
                )
            );
        if (!result)
            emit TransferLOG("Withdraw Failed", msg.sender, _tokenAddress);
        else emit TransferLOG("Withdraw Success", msg.sender, _tokenAddress);
        revertDelegate(result);
    }

    /// @dev Function to set Beneficiary Address and Percentage.
    /// @param _beneficiary strategy beneficiary to which profit fee is given.
    /// @param _percentage percentage of profit fee to be given.
    function setBeneficiaryAndPercentage(
        address _beneficiary,
        uint256 _percentage
    ) external onlyNormalMode {
        _isVaultAdmin();
        strategyBeneficiary = _beneficiary;
        strategyPercentage = _percentage;
    }

    /// @dev Function to return balance amount in vault.
    /// @param _token Address of token whose balance amount has to be returned.
    function returnBalance(address _token) internal view returns (uint256) {
        uint256 amount;
        if (_token == eth) {
            amount = address(this).balance;
        } else if (_token != address(0)) {
            amount = IERC20(_token).balanceOf(address(this));
        }

        return amount;
    }

    /// @dev Function to deposit/withdraw vault assets to protocol
    /// @param _poolAddress Address of the protocol
    /// @param _instruction Encoded instruction to perform protocol deposit of vault tokens
    /// @param _amount Amount to be deposited to the protocol
    /// @param _fromToken Deposit token address
    /// @param _returnToken Address of the token returned by the protocol
    function protocolInteraction(
        address _poolAddress,
        bytes calldata _instruction,
        uint256[] calldata _amount,
        address[] calldata _fromToken,
        address[] calldata _returnToken
    ) external onlyNormalMode whenPaused {
        require(
            IAPContract(APContract).sdkContract() == msg.sender,
            "only through sdk"
        );
        bool operationSatisfied;

        if (_instruction.length > 0) operationSatisfied = true;
        else if (_poolAddress == IAPContract(APContract).sdkContract())
            operationSatisfied = true;
        else operationSatisfied = false;

        require(operationSatisfied, "Not supported operation");

        uint256[] memory returnTokenBalance = new uint256[](
            _returnToken.length
        );

        if (_returnToken.length > 0) {
            for (uint256 i = 0; i < _returnToken.length; i++) {
                returnTokenBalance[i] = returnBalance(_returnToken[i]);
                if (_returnToken[i] != address(0))
                    addToAssetList(_returnToken[i]);
            }
        }

        uint256 fromTokenEthAmount;

        if (_fromToken.length > 0) {
            require(_fromToken.length == _amount.length, "require same");
            for (uint256 i = 0; i < _fromToken.length; i++) {
                require(
                    _amount[i] <= tokenBalances.getTokenBalance(_fromToken[i]),
                    "Not enough token present"
                );
                if (_fromToken[i] != eth)
                    _approveToken(_fromToken[i], _poolAddress, _amount[i]);
                else if (_fromToken[i] == eth)
                    fromTokenEthAmount = fromTokenEthAmount.add(_amount[i]);
            }
        }

        bool result;

        if (fromTokenEthAmount != 0) {
            (result, ) = _poolAddress.call{value: fromTokenEthAmount}(
                _instruction
            );
        } else if (_fromToken.length > 0) {
            if (_instruction.length > 0)
                (result, ) = _poolAddress.call(_instruction);
            else result = true;
        } else {
            (result, ) = _poolAddress.call(_instruction);
        }

        if (_fromToken.length > 0) {
            for (uint256 i; i < _fromToken.length; i++) {
                if (_fromToken[i] != address(0))
                    tokenBalances.setTokenBalance(
                        _fromToken[i],
                        tokenBalances.getTokenBalance(_fromToken[i]).sub(
                            _amount[i]
                        )
                    );
            }
        }

        if (_returnToken.length > 0)
            for (uint256 i = 0; i < _returnToken.length; i++) {
                if (_returnToken[i] != address(0)) {
                    uint256 returnTokenAmountAfter = returnBalance(
                        _returnToken[i]
                    );
                    tokenBalances.setTokenBalance(
                        _returnToken[i],
                        tokenBalances.getTokenBalance(_returnToken[i]).add(
                            returnTokenAmountAfter.sub(returnTokenBalance[i])
                        )
                    );
                }
            }

        revertDelegate(result);
    }

    /// @dev Function to get list of all the assets deposited to the vault
    function getAssetList() public view returns (address[] memory) {
        return assetList;
    }

    /// @dev Function to exchange token using Yieldster exchanges
    /// @param _fromToken Address of the exchange from token
    /// @param _toToken Address of the exchange to token
    /// @param _amount Exchange amount
    /// @param _slippageSwap Acceptable slippage percentage(50 == 0.5%)
    function exchangeToken(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        uint256 _slippageSwap
    ) public whenPaused returns (uint256) {
        require(
            _amount <= tokenBalances.getTokenBalance(_fromToken),
            "Not enough token present"
        );
        require(
            IAPContract(APContract).sdkContract() == msg.sender,
            "only through sdk"
        );
        uint256 exchangeReturn;
        IExchangeRegistry exchangeRegistry = IExchangeRegistry(
            IAPContract(APContract).exchangeRegistry()
        );
        address exchange = exchangeRegistry.getPair(_fromToken, _toToken);
        require(exchange != address(0), "Exchange pair not present");
        addToAssetList(_toToken);
        uint256 minReturn = IAPContract(APContract).calculateSlippage(
            _fromToken,
            _toToken,
            _amount,
            _slippageSwap
        );

        _approveToken(_fromToken, exchange, _amount);
        exchangeReturn = IExchange(exchange).swap(
            _fromToken,
            _toToken,
            _amount,
            minReturn
        );
        tokenBalances.setTokenBalance(
            _fromToken,
            tokenBalances.getTokenBalance(_fromToken).sub(_amount)
        );

        tokenBalances.setTokenBalance(
            _toToken,
            tokenBalances.getTokenBalance(_toToken).add(exchangeReturn)
        );
        return exchangeReturn;
    }

    /// @dev Function to perform Management fee Calculations in the Vault.
    /// @param _tokenAddress Address of token on which managementFeeCleanUp has to be performed
    function managementFeeCleanUp(address _tokenAddress) public {
        address[] memory managementFeeStrategies = IAPContract(APContract)
            .getVaultManagementFee();
        for (uint256 i = 0; i < managementFeeStrategies.length; i++) {
            (bool result, ) = managementFeeStrategies[i].delegatecall(
                abi.encodeWithSignature(
                    "executeSafeCleanUp(address)",
                    _tokenAddress
                )
            );
            if (result == false) {
                emit Response(
                    managementFeeStrategies[i],
                    "Failed in managementFeeCleanUp"
                );
            }
        }
    }

    modifier onlyNormalMode() {
        _onlyNormalMode();
        _;
    }

    /// @dev Function to check if msg.sender is VaultAdmin.
    function _isVaultAdmin() private view {
        require(msg.sender == vaultAdmin, "not vaultAdmin");
    }

    /// @dev Function to check if msg.sender is yieldsterGOD.
    function _isYieldsterGOD() private view {
        require(
            msg.sender == IAPContract(APContract).yieldsterGOD(),
            "unauthorized"
        );
    }

    /// @dev Function that Disables vault interactions in case of Emergency Break and Emergency Exit.
    function _onlyNormalMode() private view {
        if (emergencyConditions == 1) {
            _isYieldsterGOD();
        } else if (emergencyConditions == 2) {
            revert("safe inactive");
        }
    }

    receive() external payable {
        etherDepositors.push(msg.sender);
        userEtherBalance[msg.sender] = userEtherBalance[msg.sender] + msg.value;
    }

    /// @dev Function to perform operation on Receival of ERC1155 token from Yieldster Strategy Minter.
    /// @param id Number denoting the type of instruction. 0 = safe Minter,2 = deposit strategy minter, 3 = withdrawal strategy minter.
    /// @param data Bytes containing encoded function call.
    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256,
        bytes calldata data
    ) external virtual override onlyNormalMode returns (bytes4) {
        // managementFeeCleanUp();
        if (id == 0) {
            require(
                IAPContract(APContract).safeMinter() == msg.sender,
                "Only Safe Minter"
            );
            (bool success, ) = IAPContract(APContract).safeUtils().delegatecall(
                data
            );
            revertDelegate(success);
        } else if (id == 2 || id == 3) {
            require(
                (IAPContract(APContract).getStrategyFromMinter(msg.sender) ==
                    IAPContract(APContract).getDepositStrategy()) ||
                    (IAPContract(APContract).getStrategyFromMinter(
                        msg.sender
                    ) == IAPContract(APContract).getWithdrawStrategy()),
                "Neither Deposit nor Withdraw strategy"
            );
            (bool success, ) = IAPContract(APContract)
                .getStrategyFromMinter(msg.sender)
                .delegatecall(data);
            revertDelegate(success);
        }

        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /// @dev Function to pause a function.
    function toPause() external {
        require(
            msg.sender == vaultAdmin ||
                IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        _pause();
    }

    /// @dev Function to unpause a function.
    function unPause() external {
        require(
            msg.sender == vaultAdmin ||
                IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        _unpause();
    }

    /// @dev Function to getVaultSlippage.
    function getVaultSlippage() external view returns (uint256) {
        return IAPContract(APContract).getVaultSlippage();
    }

    /// @dev Function to change emergency vault
    /// @param _emergencyVault  address of the emergency vault
    function changeEmergencyVault(address _emergencyVault) public {
        _isVaultAdmin();
        emergencyVault = _emergencyVault;
    }

    /// @dev Function to clear assetList Array
    /// @param array  array of assetList indices to clear
    function removeFromAssetList(uint256[] calldata array) public {
        require(
            IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        for (uint256 i = 0; i < array.length; i++) {
            uint256 tempIndex = array[i];
            address tempAddr = assetList[tempIndex];
            isAssetPresent[tempAddr] = false;
            removeFromArray(tempIndex);
        }
    }

    function removeFromArray(uint256 index) internal {
        uint256 assetListLength = assetList.length - 1;
        assetList[index] = assetList[assetListLength];
        assetList.pop();
    }
}
