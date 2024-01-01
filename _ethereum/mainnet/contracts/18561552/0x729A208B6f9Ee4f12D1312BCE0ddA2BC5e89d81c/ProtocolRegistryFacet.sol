// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./LibProtocolStorage.sol";
import "./LibProtocolRegistry.sol";
import "./LibAppStorage.sol";
import "./LibDiamond.sol";
import "./LibMeta.sol";

contract ProtocolRegistryFacet is Modifiers {
    function protocolRegistryFacetInit() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            LibMeta._msgSender() == ds.contractOwner,
            "Must own the contract."
        );
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            !es.isInitializedProtocolRegistry,
            "Already initialized Protocol Registry"
        );
        es.isInitializedProtocolRegistry = true;

        es.govPlatformFee = 150;
        es.govAutosellFee = 200;
        es.govThresholdFee = 200;
        emit LibProtocolRegistry.ProtocolRegistryInitialized(
            es.govPlatformFee,
            es.govAutosellFee,
            es.govThresholdFee
        );
    }

    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool true or false if token enable or disbale for collateral
    function isTokenEnabledForCreateLoan(
        address _tokenAddress
    ) external view returns (bool) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.approvedTokens[_tokenAddress].isTokenEnabledAsCollateral;
    }

    /// @dev checking the approvedSps mapping if already walletAddress
    /// @param _tokenAddress contract address of the approvedToken Sp
    /// @param _walletAddress wallet address of the approved Sp
    /// @return bool true or false value for the sp wallet address

    function isAddedSPWallet(
        address _tokenAddress,
        address _walletAddress
    ) external view returns (bool) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = es.approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            address currentWallet = es.approvedSps[_tokenAddress][i];
            if (currentWallet == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev function to enable or disale stable coin in the gov protocol
    /// @param _stableAddress stable token contract address DAI, USDT, etc...
    /// @param _status bool value true or false to change status of stable coin
    function addEditStableCoin(
        address[] memory _stableAddress,
        bool[] memory _status
    ) external onlyEditTokenRole(LibMeta._msgSender()) {
        require(
            _stableAddress.length == _status.length,
            "GPR: length mismatch"
        );
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        for (uint256 i = 0; i < _stableAddress.length; i++) {
            require(_stableAddress[i] != address(0x0), "GPR: null address");
            require(
                es.approveStable[_stableAddress[i]] != _status[i],
                "GPR: already in desired state"
            );
            es.approveStable[_stableAddress[i]] = _status[i];

            emit LibProtocolRegistry.UpdatedStableCoinStatus(
                _stableAddress[i],
                _status[i]
            );
        }
    }

    /// @dev function to add token to approvedTokens mapping
    /// @param _tokenAddress of the new token Address
    /// @param marketData struct of the _tokenAddress

    function addTokens(
        address[] memory _tokenAddress,
        LibProtocolStorage.Market[] memory marketData
    ) external onlyAddTokenRole(LibMeta._msgSender()) {
        require(
            _tokenAddress.length == marketData.length,
            "GPR: Token Address Length must match Market Data"
        );
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            LibProtocolRegistry._addToken(_tokenAddress[i], marketData[i]);
        }
    }

    /// @dev function to update the token market data
    /// @param _tokenAddress to check if it exit in the array and mapping
    /// @param _marketData struct to update the token market
    function updateTokens(
        address[] memory _tokenAddress,
        LibProtocolStorage.Market[] memory _marketData
    ) external onlyEditTokenRole(LibMeta._msgSender()) {
        require(
            _tokenAddress.length == _marketData.length,
            "GPR: Token Address Length must match Market Data"
        );

        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            LibProtocolRegistry._updateToken(_tokenAddress[i], _marketData[i]);
            emit LibProtocolRegistry.TokensUpdated(
                _tokenAddress[i],
                _marketData[i]
            );
        }
    }

    /// @dev function which change the approved token to enable or disable
    /// @param _tokenAddress address which is updating

    function changeTokensStatus(
        address[] memory _tokenAddress,
        bool[] memory _tokenStatus
    ) external onlyEditTokenRole(LibMeta._msgSender()) {
        require(
            _tokenAddress.length == _tokenStatus.length,
            "array length mismatch"
        );
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(
                this.isTokenEnabledForCreateLoan(_tokenAddress[i]) !=
                    _tokenStatus[i],
                "GPR: already in desired status"
            );
            LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
                .protocolRegistryStorage();

            require(
                es.approvedTokens[_tokenAddress[i]].dexRouter != address(0x0),
                "GPR: add token first"
            );

            es
                .approvedTokens[_tokenAddress[i]]
                .isTokenEnabledAsCollateral = _tokenStatus[i];

            emit LibProtocolRegistry.TokenStatusUpdated(
                _tokenAddress[i],
                _tokenStatus[i]
            );
        }
    }

    /// @dev function which enable or disable mint option for synthetic token
    /// @param _tokenAddress address which is updating

    function changeisMintStatus(
        address _tokenAddress
    ) external onlyEditTokenRole(LibMeta._msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].dexRouter != address(0x0),
            "GPR: add token first"
        );

        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not vip token type"
        );

        es.approvedTokens[_tokenAddress].isMint = !es
            .approvedTokens[_tokenAddress]
            .isMint;

        emit LibProtocolRegistry.TokenIsMintStatusUpdated(
            _tokenAddress,
            es.approvedTokens[_tokenAddress].isMint
        );
    }

    /// @dev add sp wallet to the mapping approvedSps
    /// @param _tokenAddress token contract address
    /// @param _walletAddress sp wallet address to add

    function addSp(
        address _tokenAddress,
        address _walletAddress
    ) external onlyAddSpRole(LibMeta._msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            !LibProtocolRegistry._isAlreadyAddedSp(
                _tokenAddress,
                _walletAddress
            ),
            "GPR: SP Already Approved"
        );
        LibProtocolRegistry._addSp(_tokenAddress, _walletAddress);
    }

    /// @dev remove sp wallet from mapping
    /// @param _tokenAddress token address as a key to remove sp
    /// @param _removeWalletAddress sp wallet address to be removed
    function removeSp(
        address _tokenAddress,
        address _removeWalletAddress
    ) external onlyEditSpRole(LibMeta._msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            LibProtocolRegistry._isAlreadyAddedSp(
                _tokenAddress,
                _removeWalletAddress
            ),
            "GPR: cannot remove the SP, does not exist"
        );

        LibProtocolRegistry._removeSpKeyfromMapping(
            LibProtocolRegistry._getWalletIndexfromMapping(
                _tokenAddress,
                _removeWalletAddress
            ),
            _tokenAddress
        );

        emit LibProtocolRegistry.SPWalletRemoved(
            _tokenAddress,
            _removeWalletAddress
        );
    }

    /// @dev adding bulk sp wallet address to the approvedSps
    /// @param _tokenAddress token contract address as a key for sp wallets
    /// @param _walletAddress sp wallet addresses adding to the approvedSps mapping

    function addBulkSps(
        address _tokenAddress,
        address[] memory _walletAddress
    ) external onlyAddSpRole(LibMeta._msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );

        LibProtocolRegistry._addBulkSps(_tokenAddress, _walletAddress);
    }

    /// @dev function to update the sp wallet
    /// @param _tokenAddress to check if it exit in the array and mapping
    /// @param _oldWalletAddress old wallet address to be updated
    /// @param _newWalletAddress new wallet address

    function updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) external onlyEditSpRole(LibMeta._msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            _newWalletAddress != _oldWalletAddress,
            "GPR: same wallet for update not allowed"
        );
        require(
            LibProtocolRegistry._isAlreadyAddedSp(
                _tokenAddress,
                _oldWalletAddress
            ),
            "GPR: cannot update the wallet address, wallet address not exist or not a SP"
        );

        LibProtocolRegistry._updateSp(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    /// @dev external function update bulk SP wallets to the approvedSps
    /// @param _tokenAddress token contract address being updated
    /// @param _oldWalletAddress  array of old sp wallets
    /// @param _newWalletAddress  array of the new sp wallets

    function updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) external onlyEditSpRole(LibMeta._msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );
        LibProtocolRegistry._updateBulkSps(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external onlyEditSpRole(LibMeta._msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );

        for (uint256 i = 0; i < _removeWalletAddress.length; i++) {
            address removeWallet = _removeWalletAddress[i];
            require(
                LibProtocolRegistry._isAlreadyAddedSp(
                    _tokenAddress,
                    removeWallet
                ),
                "GPR: cannot remove the SP, does not exist, not in array"
            );

            //also remove SP key from specific token address
            LibProtocolRegistry._removeSpKeyfromMapping(
                LibProtocolRegistry._getWalletIndexfromMapping(
                    _tokenAddress,
                    removeWallet
                ),
                _tokenAddress
            );
        }

        emit LibProtocolRegistry.SPWalletsRemoved(
            _tokenAddress,
            _removeWalletAddress
        );
    }

    /** Public functions of the Gov Protocol Contract */

    /// @dev get all approved tokens from the allapprovedTokenContracts
    /// @return address[] returns all the approved token contracts
    function getallApprovedTokens() external view returns (address[] memory) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.allapprovedTokenContracts;
    }

    /// @dev get data of single approved token address return Market Struct
    /// @param _tokenAddress approved token address
    /// @return Market market data for the approved token address
    function getSingleApproveToken(
        address _tokenAddress
    ) external view returns (LibProtocolStorage.Market memory) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.approvedTokens[_tokenAddress];
    }

    /// @dev function to check if sythetic mint option is on for the approved collateral token
    /// @param _tokenAddress collateral token address
    /// @return bool returns the bool value true or false
    function isSyntheticMintOn(
        address _tokenAddress
    ) external view returns (bool) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return
            es.approvedTokens[_tokenAddress].tokenType ==
            LibProtocolStorage.TokenType.ISVIP &&
            es.approvedTokens[_tokenAddress].isMint;
    }

    /// @dev get wallet addresses of single tokenAddress
    /// @param _tokenAddress sp token address
    /// @return address[] returns the wallet addresses of the sp token
    function getSingleTokenSps(
        address _tokenAddress
    ) external view returns (address[] memory) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.approvedSps[_tokenAddress];
    }

    /// @dev set the percentage of the Gov Platform Fee to the Gov Lend Market Contracts
    /// @param _percentage percentage which goes to the gov platform
    function setGovPlatfromFee(
        uint256 _percentage
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            _percentage <= 2000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        es.govPlatformFee = _percentage;
        emit LibProtocolRegistry.GovPlatformFeeUpdated(_percentage);
    }

    /// @dev set the liquiation thershold percentage
    function setThresholdFee(
        uint256 _percentage
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        require(
            _percentage <= 5000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        es.govThresholdFee = _percentage;
        emit LibProtocolRegistry.ThresholdFeeUpdated(_percentage);
    }

    /// @dev set the autosell apy fee percentage
    /// @param _percentage percentage value of the autosell fee
    function setAutosellFee(
        uint256 _percentage
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        require(
            _percentage <= 2000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        es.govAutosellFee = _percentage;
        emit LibProtocolRegistry.AutoSellFeeUpdated(_percentage);
    }

    /// @dev get the gov platofrm fee percentage
    function getGovPlatformFee() external view returns (uint256) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.govPlatformFee;
    }

    function getThresholdPercentage() external view returns (uint256) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.govThresholdFee;
    }

    function getAutosellPercentage() external view returns (uint256) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.govAutosellFee;
    }

    function isStableApproved(address _stable) external view returns (bool) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.approveStable[_stable];
    }
}
