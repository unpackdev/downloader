// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./LibProtocolStorage.sol";
import "./IGTokenFactory.sol";
import "./LibAppStorage.sol";

library LibProtocolRegistry {
    event TokensAdded(
        address indexed tokenAddress,
        address indexed dexRouter,
        address indexed gToken,
        bool isMint,
        LibProtocolStorage.TokenType tokenType,
        bool isTokenEnabledAsCollateral
    );
    event TokensUpdated(
        address indexed tokenAddress,
        LibProtocolStorage.Market indexed _marketData
    );

    event SPWalletAdded(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    event SPWalletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );

    event BulkSpWAlletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );
    event SPWalletRemoved(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    event ProtocolRegistryInitialized(
        uint256 govPlatformFee,
        uint256 govAutosellFee,
        uint256 govThresholdFee
    );

    event SPWalletsRemoved(address tokenAddress, address[] indexed spWallets);

    event TokenStatusUpdated(address indexed tokenAddress, bool status);
    event TokenIsMintStatusUpdated(address indexed tokenAddress, bool status);
    event UpdatedStableCoinStatus(address indexed stableCoin, bool status);
    event GovPlatformFeeUpdated(uint256 govPlatformPercentage);
    event ThresholdFeeUpdated(uint256 thresholdPercentageAutosellOff);
    event AutoSellFeeUpdated(uint256 autoSellFeePercentage);

    /// @dev check if _walletAddress is already added Sp in array
    /// @param _walletAddress wallet address checking

    function _isAlreadyAddedSp(
        address _tokenAddress,
        address _walletAddress
    ) internal view returns (bool) {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = s.approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (s.approvedSps[_tokenAddress][i] == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev get index of the wallet from the approvedSps mapping
    /// @param tokenAddress token contract address
    /// @param _walletAddress getting this wallet address index

    function _getWalletIndexfromMapping(
        address tokenAddress,
        address _walletAddress
    ) internal view returns (uint256 index) {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = s.approvedSps[tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (s.approvedSps[tokenAddress][i] == _walletAddress) {
                return i;
            }
        }
    }

    /** Internal functions of the Gov Protocol Contract */

    /// @dev function to add token market data
    /// @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    /// @param marketData struct object to be added in approvedTokens mapping

    function _addToken(
        address _tokenAddress,
        LibProtocolStorage.Market memory marketData
    ) internal {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            _tokenAddress != marketData.dexRouter,
            "GPL: token and dex address same"
        );

        require(_tokenAddress != address(0x0), "GPR: null error");
        //checking Token Contract have not already added
        require(
            es.approvedTokens[_tokenAddress].dexRouter == address(0x0),
            "GPR: already added Token Contract"
        );

        require(
            marketData.dexRouter != address(0),
            "dex address zero not allowed"
        );

        if (marketData.tokenType == LibProtocolStorage.TokenType.ISVIP) {
            require(
                _tokenAddress == marketData.gToken,
                "GPL: gToken must equal token address"
            );
        } else {
            marketData.gToken = address(0x0);
            marketData.isMint = false;
        }

        // Update marketData.gToken if necessary
        if (marketData.tokenType == LibProtocolStorage.TokenType.ISVIP) {
            marketData.gToken = IGTokenFactory(address(this)).deployGToken(
                _tokenAddress
            );
        }

        // Perform state modification
        es.approvedTokens[_tokenAddress] = marketData;

        emit TokensAdded(
            _tokenAddress,
            es.approvedTokens[_tokenAddress].dexRouter,
            es.approvedTokens[_tokenAddress].gToken,
            es.approvedTokens[_tokenAddress].isMint,
            es.approvedTokens[_tokenAddress].tokenType,
            es.approvedTokens[_tokenAddress].isTokenEnabledAsCollateral
        );
        es.allapprovedTokenContracts.push(_tokenAddress);
    }

    /// @dev function to update the token market data
    /// @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    /// @param _marketData struct object to be added in approvedTokens mapping

    function _updateToken(
        address _tokenAddress,
        LibProtocolStorage.Market memory _marketData
    ) internal {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();

        require(
            _tokenAddress != _marketData.dexRouter,
            "GPL: token and dex address same"
        );
        require(
            _marketData.dexRouter != address(0),
            "dex address zero not allowed"
        );

        require(
            es.approvedTokens[_tokenAddress].dexRouter != address(0x0),
            "GPR: add token first"
        );

        //update Token Data  to the approvedTokens mapping
        LibProtocolStorage.Market memory _prevTokenData = es.approvedTokens[
            _tokenAddress
        ];

        require(
            _prevTokenData.gToken == address(0x0) &&
                _marketData.tokenType == LibProtocolStorage.TokenType.ISVIP,
            "Cannot update, already VIP token or new token type is invalid"
        );

        es.approvedTokens[_tokenAddress].isMint = true;
        es.approvedTokens[_tokenAddress].tokenType = LibProtocolStorage
            .TokenType
            .ISVIP;
        es.approvedTokens[_tokenAddress].dexRouter = _marketData.dexRouter;
        es
            .approvedTokens[_tokenAddress]
            .isTokenEnabledAsCollateral = _marketData
            .isTokenEnabledAsCollateral;

        address gToken = IGTokenFactory(address(this)).deployGToken(
            _tokenAddress
        );
        es.approvedTokens[_tokenAddress].gToken = gToken;
    }

    /// @dev internal function to add Strategic Partner Wallet Address to the approvedSps mapping
    /// @param _tokenAddress contract address of the approvedToken Sp
    /// @param _walletAddress sp wallet address added to the approvedSps

    function _addSp(address _tokenAddress, address _walletAddress) internal {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            s.approvedSps[_tokenAddress].length + 1 <=
                LibAppStorage.arrayMaxSize,
            "GPR: array max size reached"
        );
        // add the sp wallet address to the approvedSps mapping
        s.approvedSps[_tokenAddress].push(_walletAddress);
        emit SPWalletAdded(_tokenAddress, _walletAddress);
    }

    /// @dev remove Sp wallet address from the approvedSps mapping across specific tokenaddress
    /// @param index of the approved wallet sp
    /// @param _tokenAddress token contract address of the approvedToken sp

    function _removeSpKeyfromMapping(
        uint256 index,
        address _tokenAddress
    ) internal {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();

        uint256 length = s.approvedSps[_tokenAddress].length;

        // Swap the element to remove with the last element
        uint256 lastIndex = length - 1;
        if (index != lastIndex) {
            // Replace element at index with last element
            s.approvedSps[_tokenAddress][index] = s.approvedSps[_tokenAddress][
                lastIndex
            ];
        }

        // Delete the last element
        s.approvedSps[_tokenAddress].pop();
    }

    /// @dev adding bulk sp wallet address to the approvedSps
    /// @param _tokenAddress token contract address as a key for sp wallets
    /// @param _walletAddress sp wallet addresses adding to the approvedSps mapping

    function _addBulkSps(
        address _tokenAddress,
        address[] memory _walletAddress
    ) internal {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = _walletAddress.length;

        require(
            s.approvedSps[_tokenAddress].length + length <=
                LibAppStorage.arrayMaxSize,
            "GPR: array max size reached"
        );
        for (uint256 i = 0; i < length; i++) {
            //checking Wallet if already added
            require(
                !_isAlreadyAddedSp(_tokenAddress, _walletAddress[i]),
                "one or more wallet addresses already added in approved sps array"
            );

            s.approvedSps[_tokenAddress].push(_walletAddress[i]);
            emit SPWalletAdded(_tokenAddress, _walletAddress[i]);
        }
    }

    /// @dev internal function to update Sp wallet Address,
    /// @dev doing it by removing old wallet first then add new wallet address
    /// @param _tokenAddress token contract address as a key to update sp wallet
    /// @param _oldWalletAddress old SP wallet address
    /// @param _newWalletAddress new SP wallet address

    function _updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) internal {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        //update wallet addres to the approved Sps mapping
        _removeSpKeyfromMapping(
            _getWalletIndexfromMapping(_tokenAddress, _oldWalletAddress),
            _tokenAddress
        );
        s.approvedSps[_tokenAddress].push(_newWalletAddress);

        emit SPWalletUpdated(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    /// @dev update bulk SP wallets to the approvedSps
    /// @param _tokenAddress token contract address being updated
    /// @param _oldWalletAddress  array of old sp wallets
    /// @param _newWalletAddress  array of the new sp wallets

    function _updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) internal {
        require(
            _oldWalletAddress.length == _newWalletAddress.length,
            "GPR: Length of old and new wallet should be equal"
        );
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();

        for (uint256 i = 0; i < _oldWalletAddress.length; i++) {
            //checking Wallet if already added
            address currentWallet = _oldWalletAddress[i];
            address newWallet = _newWalletAddress[i];
            require(
                _isAlreadyAddedSp(_tokenAddress, currentWallet),
                "GPR: cannot update the wallet addresses, token address not exist or not a SP, not in array"
            );

            _removeSpKeyfromMapping(
                _getWalletIndexfromMapping(_tokenAddress, currentWallet),
                _tokenAddress
            );
            s.approvedSps[_tokenAddress].push(newWallet);
            emit BulkSpWAlletUpdated(_tokenAddress, currentWallet, newWallet);
        }
    }
}
