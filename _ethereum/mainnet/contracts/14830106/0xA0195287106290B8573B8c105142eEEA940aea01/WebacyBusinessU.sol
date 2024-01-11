// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IWebacyProxyFactory.sol";
import "./IWebacyProxy.sol";

contract WebacyBusinessU is Initializable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IWebacyProxyFactory public proxyFactory;
    uint256 public transferFee;

    struct AssetBeneficiary {
        address desAddress;
        uint256 tokenId;
    }

    struct TokenBeneficiary {
        address desAddress;
        uint8 percent;
    }

    struct ERC20TokenStatus {
        address newOwner;
        uint256 amountTransferred;
        bool transferred;
    }

    struct ERC721TokenStatus {
        address newOwner;
        uint256 tokenIdTransferred;
        bool transferred;
    }

    struct ERC20Token {
        address scAddress;
        TokenBeneficiary[] tokenBeneficiaries;
        uint256 amount;
    }

    struct ERC721Token {
        address scAddress;
        AssetBeneficiary[] assetBeneficiaries;
    }

    struct TransferredERC20 {
        address scAddress;
        ERC20TokenStatus erc20TokenStatus;
    }

    struct TransferredERC721 {
        address scAddress;
        ERC721TokenStatus[] erc721TokenStatus;
    }

    struct Assets {
        ERC721Token[] erc721;
        address[] backupAddresses;
        ERC20Token[] erc20;
        TransferredERC20[] transferredErc20;
        TransferredERC721[] transferredErc721;
    }

    // Inverse relation with beneficiary
    mapping(address => address) private beneficiaryToMember;

    // * Asset Beneficiary section
    mapping(address => address[]) private memberToERC721Contracts;
    mapping(address => mapping(address => AssetBeneficiary[])) private memberToContractToAssetBeneficiary;
    mapping(address => mapping(address => address)) private assetBeneficiaryToContractToMember;
    mapping(address => mapping(address => ERC721TokenStatus[])) private memberToContractToAssetStatus;
    // Asset Beneficiary section *

    // * Token Beneficiary section
    mapping(address => address[]) private memberToERC20Contracts;
    mapping(address => mapping(address => uint256)) private memberToContractToAllowableAmount;
    mapping(address => mapping(address => TokenBeneficiary[])) private memberToContractToTokenBeneficiaries;
    mapping(address => mapping(address => address)) private tokenBeneficiaryToContractToMember;
    mapping(address => mapping(address => ERC20TokenStatus)) private memberToContractToTokenStatus;
    // Token Beneficiary section *

    // * Backup data strucutre section
    mapping(address => address[]) private memberToBackupWallets;
    mapping(address => address) private backupWalletToMember;
    // Backup data structure section *

    // * Balances
    address[] private contractBalances;
    mapping(address => bool) private hasBalance;

    // Balances *

    bytes32 public constant MEMBERSHIP_ROLE = keccak256("MEMBERSHIP_ROLE");

    mapping(address => bool) public haveToPayUpdate;

    event FeesWithdrawed(address _value);
    event AmountUpdated(string _type, uint256 _value);
    event AddressUpdated(string _type, address _value);

    function initialize(address _proxyFactoryAddress) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        proxyFactory = IWebacyProxyFactory(_proxyFactoryAddress);
        transferFee = 1;
    }

    modifier hasPaidMembership(address _address) {
        address memberContract = address(proxyFactory.deployedContractFromMember(_address));
        require(memberContract != address(0x0), "Sender has no paid membership");
        _;
    }

    function _checkZeroAddress(address _address) internal pure {
        require(_address != address(0), "Zero address");
    }

    function getMemberFromBackup(address _address) external view returns (address) {
        return backupWalletToMember[_address];
    }

    function getMemberFromBeneficiary(address _address) external view returns (address) {
        return beneficiaryToMember[_address];
    }

    function storeERC20Data(
        address contractAddress,
        address[] memory destinationAddresses,
        uint8[] memory destinationPercents,
        uint256 amount,
        address[] memory backupAddresses
    ) external whenNotPaused hasPaidMembership(msg.sender) {
        if (!haveToPayUpdate[msg.sender]) {
            haveToPayUpdate[msg.sender] = true;
        }

        _checkZeroAddress(contractAddress);
        require(destinationAddresses.length == destinationPercents.length, "Equally size arrays required");
        require(amount > 0, "Invalid amount");

        _saveBackupWallet(backupAddresses);

        require(memberToContractToAllowableAmount[msg.sender][contractAddress] == 0, "ERC20 already stored for member");

        memberToERC20Contracts[msg.sender].push(contractAddress);
        memberToContractToAllowableAmount[msg.sender][contractAddress] = amount;

        for (uint256 i = 0; i < destinationAddresses.length; i++) {
            require(destinationPercents[i] >= 0 && destinationPercents[i] <= 100, "Percent must be in range 0-100");
            TokenBeneficiary memory tokenB = TokenBeneficiary(address(0), 0);
            tokenB.desAddress = destinationAddresses[i];
            tokenB.percent = destinationPercents[i];
            _isValidBeneficiary(tokenB.desAddress, contractAddress);
            tokenBeneficiaryToContractToMember[tokenB.desAddress][contractAddress] = msg.sender;
            beneficiaryToMember[tokenB.desAddress] = msg.sender;
            memberToContractToTokenBeneficiaries[msg.sender][contractAddress].push(tokenB);
        }
    }

    function storeERC721Data(
        address contractAddress,
        address[] memory destinationAddresses,
        uint256[] memory destinationTokenIds,
        address[] memory backupAddresses
    ) external whenNotPaused hasPaidMembership(msg.sender) {
        if (!haveToPayUpdate[msg.sender]) {
            haveToPayUpdate[msg.sender] = true;
        }

        require(destinationAddresses.length == destinationTokenIds.length, "Equally size arrays required");

        _saveBackupWallet(backupAddresses);

        AssetBeneficiary[] memory assetBeneficiaries = memberToContractToAssetBeneficiary[msg.sender][contractAddress];

        require(assetBeneficiaries.length == 0, "ERC721 already stored for member");

        memberToERC721Contracts[msg.sender].push(contractAddress);

        require(destinationTokenIds.length != 0, "No empty token ids allowed");

        for (uint256 i = 0; i < destinationAddresses.length; i++) {
            AssetBeneficiary memory assetB = AssetBeneficiary(address(0), 0);
            assetB.desAddress = destinationAddresses[i];
            assetB.tokenId = destinationTokenIds[i];
            _validateERC721CollectibleNotYetAssigned(contractAddress, assetB.tokenId);
            memberToContractToAssetBeneficiary[msg.sender][contractAddress].push(assetB);
            assetBeneficiaryToContractToMember[destinationAddresses[i]][contractAddress] = msg.sender;
            beneficiaryToMember[destinationAddresses[i]] = msg.sender;
        }
    }

    function getApprovedAssets(address owner) external view returns (Assets memory) {
        // INIT ERC20Contracts
        address[] memory erc20Contracts = memberToERC20Contracts[owner];
        // END ERC20Contracts

        // INIT BackupWallets
        address[] memory backupWallets = memberToBackupWallets[owner];
        // END BackupWallets

        // INIT ERC721Contracts
        address[] memory erc721Contracts = memberToERC721Contracts[owner];
        // END ERC721Contracts

        Assets memory assets = Assets(
            new ERC721Token[](erc721Contracts.length),
            new address[](backupWallets.length),
            new ERC20Token[](erc20Contracts.length),
            new TransferredERC20[](erc20Contracts.length),
            new TransferredERC721[](erc721Contracts.length)
        );

        // INIT FULLFILL ERC721 BENEFICIARIES
        for (uint256 i = 0; i < erc721Contracts.length; i++) {
            AssetBeneficiary[] memory assetBeneficiaries = memberToContractToAssetBeneficiary[owner][
                erc721Contracts[i]
            ];
            assets.erc721[i].assetBeneficiaries = assetBeneficiaries;
            assets.erc721[i].scAddress = erc721Contracts[i];

            ERC721TokenStatus[] memory assetsStatus = memberToContractToAssetStatus[owner][erc721Contracts[i]];
            assets.transferredErc721[i].scAddress = erc721Contracts[i];
            assets.transferredErc721[i].erc721TokenStatus = assetsStatus;
        }
        // END FULLFILL ERC721 BENEFICIARIES

        // INIT FULLFILL BACKUPWALLETS
        for (uint256 i = 0; i < backupWallets.length; i++) {
            assets.backupAddresses[i] = backupWallets[i];
        }
        // END FULLFILL BACKUPWALLETS

        for (uint256 i = 0; i < erc20Contracts.length; i++) {
            //FULLFILL ERC20 BENEFICIARIES
            TokenBeneficiary[] memory tokenBeneficiaries = memberToContractToTokenBeneficiaries[owner][
                erc20Contracts[i]
            ];
            assets.erc20[i].tokenBeneficiaries = tokenBeneficiaries;
            assets.erc20[i].scAddress = erc20Contracts[i];
            assets.erc20[i].amount = memberToContractToAllowableAmount[owner][erc20Contracts[i]];
            //FULLFILL TRANSFERRED ERC20
            ERC20TokenStatus memory tokenStatus = memberToContractToTokenStatus[owner][erc20Contracts[i]];
            if (tokenStatus.newOwner != address(0)) {
                assets.transferredErc20[i].scAddress = erc20Contracts[i];
                assets.transferredErc20[i].erc20TokenStatus = tokenStatus;
            }
        }
        // END FULLFILL ERC20 BENEFICIARIES

        return assets;
    }

    function _saveBackupWallet(address[] memory backupAddresses) private {
        if (memberToBackupWallets[msg.sender].length == 0) {
            for (uint256 i = 0; i < backupAddresses.length; i++) {
                _checkZeroAddress(backupAddresses[i]);
                require(backupWalletToMember[backupAddresses[i]] == address(0), "Backup already exists");
                backupWalletToMember[backupAddresses[i]] = msg.sender;
                memberToBackupWallets[msg.sender].push(backupAddresses[i]);
            }
        }
    }

    function _validateERC721CollectibleNotYetAssigned(address _contractAddress, uint256 _tokenId) private view {
        AssetBeneficiary[] memory assetBeneficiaries = memberToContractToAssetBeneficiary[msg.sender][_contractAddress];
        for (uint256 i = 0; i < assetBeneficiaries.length; i++) {
            if (assetBeneficiaries[i].tokenId == _tokenId) {
                require(!(assetBeneficiaries[i].tokenId == _tokenId), "TokenId exists on contract");
            }
        }
    }

    function _isValidBeneficiary(address _destinationAddress, address _contractAddress) private view {
        _checkZeroAddress(_destinationAddress);
        require(
            tokenBeneficiaryToContractToMember[_destinationAddress][_contractAddress] == address(0),
            "Beneficiary already exists"
        );
    }

    function _validateERC721SCExists(address _contractAddress, address _owner) private view {
        AssetBeneficiary[] memory assetBeneficiaries = memberToContractToAssetBeneficiary[_owner][_contractAddress];
        require(assetBeneficiaries.length > 0, "ERC721 address not exists");
    }

    function _validateERC721CollectibleExists(
        address _contractAddress,
        address _owner,
        uint256 _tokenId
    ) private view {
        AssetBeneficiary[] memory assetBeneficiaries = memberToContractToAssetBeneficiary[_owner][_contractAddress];
        bool exists = false;
        for (uint256 i = 0; i < assetBeneficiaries.length; i++) {
            if (assetBeneficiaries[i].tokenId == _tokenId) {
                exists = true;
                break;
            }
        }
        require(exists, "ERC721 tokenId not exists");
    }

    function _validateTokenOwnership(
        address _contractAddress,
        address _owner,
        uint256 _tokenId
    ) private view returns (bool) {
        bool isStillOwner = false;
        address newOwner = IERC721Upgradeable(_contractAddress).ownerOf(_tokenId);
        if (_owner == newOwner) {
            isStillOwner = true;
        }
        return isStillOwner;
    }

    /**
     * @dev Transfers ERC20 and ERC721 tokens approved.
     * If _erc20contracts is empty it will transfer all approved ERC20 assets.
     * If _erc721contracts is empty it will transfer all approved ERC721 assets.
     *
     * Requirements:
     *
     * - `sender` must be a stored backup of some member.
     * - `_erc20contracts` must contain stored ERC20 contract addresses.
     * - `_erc721contracts` must contain stored ERC721 contract addresses.
     * - `_erc721tokensId` must be same length of `_erc721contracts`.
     */
    function transferAssets(
        address[] memory _erc20contracts,
        address[] memory _erc721contracts,
        uint256[][] memory _erc721tokensId
    ) external whenNotPaused nonReentrant {
        require(backupWalletToMember[msg.sender] != address(0), "Associated member not found");
        address member = backupWalletToMember[msg.sender];
        address webacyProxyForMember = address(proxyFactory.deployedContractFromMember(member));
        if (_erc20contracts.length != 0) {
            // Partial transfer
            for (uint256 i = 0; i < _erc20contracts.length; i++) {
                require(
                    memberToContractToAllowableAmount[member][_erc20contracts[i]] != 0,
                    "Contract address not exists"
                );

                uint256 amount = memberToContractToAllowableAmount[member][_erc20contracts[i]];

                uint256 currentAmount = IERC20Upgradeable(_erc20contracts[i]).balanceOf(member);

                if (currentAmount < amount) {
                    amount = currentAmount;
                }

                uint256 feeAmount = calculatePercentage(amount, transferFee);
                uint256 transferAmount = calculatePercentage(amount, 100 - transferFee);

                require(
                    !(memberToContractToTokenStatus[member][_erc20contracts[i]].transferred),
                    "Token already transferred"
                );

                if (!(hasBalance[_erc20contracts[i]])) {
                    hasBalance[_erc20contracts[i]] = true;
                    contractBalances.push(_erc20contracts[i]);
                }
                memberToContractToTokenStatus[member][_erc20contracts[i]] = ERC20TokenStatus(msg.sender, amount, true);

                try
                    IWebacyProxy(webacyProxyForMember).transferErc20TokensAllowed(
                        _erc20contracts[i],
                        member,
                        msg.sender,
                        transferAmount
                    )
                {
                    IWebacyProxy(webacyProxyForMember).transferErc20TokensAllowed(
                        _erc20contracts[i],
                        member,
                        address(this),
                        feeAmount
                    );
                } catch {
                    delete memberToContractToTokenStatus[msg.sender][_erc20contracts[i]];
                }
            }
        }

        if (_erc721contracts.length != 0) {
            require(_erc721contracts.length == _erc721tokensId.length, "ERC721 equally arrays required");
            for (uint256 iContracts = 0; iContracts < _erc721contracts.length; iContracts++) {
                _validateERC721SCExists(_erc721contracts[iContracts], member);
                for (uint256 iTokensId = 0; iTokensId < _erc721tokensId[iContracts].length; iTokensId++) {
                    _validateERC721CollectibleExists(
                        _erc721contracts[iContracts],
                        member,
                        _erc721tokensId[iContracts][iTokensId]
                    );
                    bool isOwner = _validateTokenOwnership(
                        _erc721contracts[iContracts],
                        member,
                        _erc721tokensId[iContracts][iTokensId]
                    );
                    if (isOwner) {
                        memberToContractToAssetStatus[member][_erc721contracts[iContracts]].push(
                            ERC721TokenStatus(msg.sender, _erc721tokensId[iContracts][iTokensId], true)
                        );

                        try
                            IWebacyProxy(webacyProxyForMember).transferErc721TokensAllowed(
                                _erc721contracts[iContracts],
                                member,
                                msg.sender,
                                _erc721tokensId[iContracts][iTokensId]
                            )
                        {
                            continue;
                        } catch {
                            memberToContractToAssetStatus[member][_erc721contracts[iContracts]].pop();
                        }
                    }
                }
            }
        }
    }

    function killswitchTransfer(address _backupWallet)
        external
        whenNotPaused
        hasPaidMembership(msg.sender)
        nonReentrant
    {
        require(backupWalletToMember[_backupWallet] == msg.sender, "Backup and member not match");

        address webacyProxyForMember = address(proxyFactory.deployedContractFromMember(msg.sender));

        // Total ERC20 transfer
        for (uint256 i = 0; i < memberToERC20Contracts[msg.sender].length; i++) {
            address contractAddress = memberToERC20Contracts[msg.sender][i];
            uint256 amount = memberToContractToAllowableAmount[msg.sender][contractAddress];

            require(amount != 0, "Contract address not exists");

            uint256 currentAmount = IERC20Upgradeable(contractAddress).balanceOf(msg.sender);

            if (currentAmount < amount) {
                amount = currentAmount;
            }

            uint256 feeAmount = calculatePercentage(amount, transferFee);
            uint256 transferAmount = calculatePercentage(amount, 100 - transferFee);

            if (!(hasBalance[contractAddress])) {
                hasBalance[contractAddress] = true;
                contractBalances.push(contractAddress);
            }

            if (currentAmount == 0 || memberToContractToTokenStatus[msg.sender][contractAddress].transferred == true)
                continue;

            memberToContractToTokenStatus[msg.sender][contractAddress] = ERC20TokenStatus(_backupWallet, amount, true);

            try
                IWebacyProxy(webacyProxyForMember).transferErc20TokensAllowed(
                    contractAddress,
                    msg.sender,
                    _backupWallet,
                    transferAmount
                )
            {
                IWebacyProxy(webacyProxyForMember).transferErc20TokensAllowed(
                    contractAddress,
                    msg.sender,
                    address(this),
                    feeAmount
                );
            } catch {
                delete memberToContractToTokenStatus[msg.sender][contractAddress];
            }
        }

        // Total ERC721 transfer
        for (uint256 i = 0; i < memberToERC721Contracts[msg.sender].length; i++) {
            address contractAddress = memberToERC721Contracts[msg.sender][i];

            AssetBeneficiary[] memory assetBeneficiaries = memberToContractToAssetBeneficiary[msg.sender][
                contractAddress
            ];

            for (uint256 iAssets = 0; iAssets < assetBeneficiaries.length; iAssets++) {
                bool isOwner = _validateTokenOwnership(
                    contractAddress,
                    msg.sender,
                    assetBeneficiaries[iAssets].tokenId
                );

                if (isOwner) {
                    memberToContractToAssetStatus[msg.sender][contractAddress].push(
                        ERC721TokenStatus(_backupWallet, assetBeneficiaries[iAssets].tokenId, true)
                    );

                    try
                        IWebacyProxy(webacyProxyForMember).transferErc721TokensAllowed(
                            contractAddress,
                            msg.sender,
                            _backupWallet,
                            assetBeneficiaries[iAssets].tokenId
                        )
                    {
                        continue;
                    } catch {
                        memberToContractToAssetStatus[msg.sender][contractAddress].pop();
                    }
                }
            }
        }
    }

    function setProxyFactory(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit AddressUpdated("proxyFactory", _address);
        proxyFactory = IWebacyProxyFactory(_address);
    }

    function calculatePercentage(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        _validateBasisPoints(_fee);
        return (_amount * _fee) / 100;
    }

    function _validateBasisPoints(uint256 _transferFee) private pure {
        require((_transferFee >= 0 && _transferFee <= 100), "BasisP must be in range 0-100");
    }

    function setTransferFee(uint256 _transferFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit AmountUpdated("transferFee", _transferFee);
        require((_transferFee >= 0 && _transferFee <= 100), "BasisP must be in range 0-100");
        transferFee = _transferFee;
    }

    function withdrawAllBalances(address[] memory _contracts, address _recipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address[] memory contractsToIterate;
        if (_contracts.length == 0) {
            contractsToIterate = contractBalances;
        } else {
            contractsToIterate = _contracts;
        }
        for (uint256 i = 0; i < contractsToIterate.length; i++) {
            address iContract = contractsToIterate[i];
            uint256 availableBalance = IERC20Upgradeable(iContract).balanceOf(address(this));
            if (availableBalance > 0) {
                IERC20Upgradeable(iContract).safeTransfer(_recipient, availableBalance);
            }
        }
        emit FeesWithdrawed(_recipient);
    }

    function pauseContract() external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseContract() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function deleteStoredData() external hasPaidMembership(msg.sender) {
        removeStoredData(msg.sender);
    }

    function updateStoredData(address _address) external onlyRole(MEMBERSHIP_ROLE) {
        haveToPayUpdate[_address] = false;
        removeStoredData(_address);
    }

    function removeStoredData(address _address) internal {
        //Iterate over backupwallets and update inverse relation
        address[] memory backupWallets = memberToBackupWallets[_address];
        for (uint256 i = 0; i < backupWallets.length; i++) {
            delete backupWalletToMember[backupWallets[i]];
        }
        //Deleting direct relation
        delete memberToBackupWallets[_address];

        //Iterate over nested ERC20 strucuture and deleting
        address[] memory erc20Contracts = memberToERC20Contracts[_address];
        for (uint256 i = 0; i < erc20Contracts.length; i++) {
            TokenBeneficiary[] memory tokenBeneficiaries = memberToContractToTokenBeneficiaries[_address][
                erc20Contracts[i]
            ];
            for (uint256 x = 0; x < tokenBeneficiaries.length; x++) {
                delete tokenBeneficiaryToContractToMember[tokenBeneficiaries[x].desAddress][erc20Contracts[i]];
                if (!(beneficiaryToMember[tokenBeneficiaries[x].desAddress] == address(0))) {
                    delete beneficiaryToMember[tokenBeneficiaries[x].desAddress];
                }
            }
            delete memberToContractToAllowableAmount[_address][erc20Contracts[i]];
            delete memberToContractToTokenBeneficiaries[_address][erc20Contracts[i]];
            delete memberToContractToTokenStatus[_address][erc20Contracts[i]];
        }
        //Deleting direct relation
        delete memberToERC20Contracts[_address];

        //Iterating over  ERC721 strucuture and deleting
        address[] memory erc721Contracts = memberToERC721Contracts[_address];
        for (uint256 y = 0; y < erc721Contracts.length; y++) {
            AssetBeneficiary[] memory assetBeneficiaries = memberToContractToAssetBeneficiary[_address][
                erc721Contracts[y]
            ];

            for (uint256 z = 0; z < assetBeneficiaries.length; z++) {
                delete assetBeneficiaryToContractToMember[assetBeneficiaries[z].desAddress][erc721Contracts[y]];
                if (!(beneficiaryToMember[assetBeneficiaries[z].desAddress] == address(0))) {
                    delete beneficiaryToMember[assetBeneficiaries[z].desAddress];
                }
            }
            delete memberToContractToAssetBeneficiary[_address][erc721Contracts[y]];
            delete memberToContractToAssetStatus[_address][erc721Contracts[y]];
        }
        //Deleting direct relation
        delete memberToERC721Contracts[_address];
    }
}
