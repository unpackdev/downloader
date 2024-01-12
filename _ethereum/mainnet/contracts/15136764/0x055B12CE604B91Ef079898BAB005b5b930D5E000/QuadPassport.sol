//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./UUPSUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IAccessControlUpgradeable.sol";

import "./ECDSAUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./IQuadPassport.sol";
import "./IQuadGovernance.sol";
import "./QuadGovernanceStore.sol";
import "./QuadPassportStore.sol";

/// @title Quadrata Web3 Identity Passport
/// @author Fabrice Cheng, Theodore Clapp
/// @notice This represents wallet accounts Web3 Passport
/// @dev Passport extended the ERC1155 standard with restrictions on transfers
contract QuadPassport is IQuadPassport, ERC1155Upgradeable, UUPSUpgradeable, QuadPassportStore {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    event GovernanceUpdated(address indexed _oldGovernance, address indexed _governance);
    event SetPendingGovernance(address indexed _pendingGovernance);

    constructor() initializer {
        // used to prevent logic contract self destruct take over
    }

    /// @dev initializer (constructor)
    /// @param _governanceContract address of the IQuadGovernance contract
    /// @param _uri URI of the Quadrata Passport
    function initialize(
        address _governanceContract,
        string memory _uri
    ) public initializer {
        require(_governanceContract != address(0), "GOVERNANCE_ADDRESS_ZERO");
        __ERC1155_init(_uri);
        governance = IQuadGovernance(_governanceContract);
        name = "Quadrata Passport";
        symbol = "QP";
    }

    /// @dev Overwitten to prevent reverts when a contract is missing `onERC1155BatchReceived` and receiving a passport
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {}

    /// @dev Overwitten to prevent reverts when a contract is missing `onERC1155Received` and receiving a passport
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {}

    fallback() external payable {}

    /// @notice Claim and mint a wallet account Quadrata Passport
    /// @dev Only when authorized by an eligible issuer
    /// @param _config Input paramters required to mint
    /// @param _sigIssuer ECDSA signature computed by an eligible issuer to authorize the mint
    /// @param _sigAccount (Optional) ECDSA signature computed by an eligible EOA to authorize the mint
    function mintPassport(
        MintConfig calldata _config,
        bytes calldata _sigIssuer,
        bytes calldata _sigAccount
    ) external payable override {
        require(msg.value == governance.mintPrice(), "INVALID_MINT_PRICE");
        require(governance.eligibleTokenId(_config.tokenId), "PASSPORT_TOKENID_INVALID");
        require(_config.account != address(0), "ACCOUNT_CANNOT_BE_ZERO");
        require(_config.issuedAt != 0, "ISSUED_AT_CANNOT_BE_ZERO");
        require(_config.issuedAt <= block.timestamp, "INVALID_ISSUED_AT");

        (bytes32 hash, address issuer) = _verifySignersMint(_config, _sigIssuer, _sigAccount);

        _accountBalancesETH[governance.issuersTreasury(issuer)] += governance.mintPrice();
        _usedHashes[hash] = true;
        _attributes[_config.account][keccak256("COUNTRY")][issuer] = Attribute({value: _config.country, epoch: _config.issuedAt});
        _attributes[_config.account][keccak256("DID")][issuer] = Attribute({value: _config.quadDID, epoch: _config.issuedAt});
        _attributes[_config.account][keccak256("IS_BUSINESS")][issuer] = Attribute({value: _config.isBusiness, epoch: _config.issuedAt});
        _attributesByDID[_config.quadDID][keccak256("AML")][issuer] = Attribute({value: _config.aml, epoch: _config.issuedAt});

        if(balanceOf(_config.account, _config.tokenId) == 0)
            _mint(_config.account, _config.tokenId, 1, "");
    }

    /// @notice Update or set a new attribute for your existing passport
    /// @dev Only when authorized by an eligible issuer
    /// @param _account the account to be updated
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type (ex: keccak256("COUNTRY"))
    /// @param _value keccak256 of the value of the attribute (ex: keccak256("FRANCE"))
    /// @param _issuedAt epoch when the operation has been authorized by the Issuer
    /// @param _sig ECDSA signature computed by an eligible issuer to authorize the operation
    function setAttribute(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        bytes32 _value,
        uint256 _issuedAt,
        bytes calldata _sig
    ) external payable override {
        require(msg.value == governance.mintPricePerAttribute(_attribute), "INVALID_ATTR_MINT_PRICE");
        require(_account != address(0), "ACCOUNT_CANNOT_BE_ZERO");
        require(_issuedAt != 0, "ISSUED_AT_CANNOT_BE_ZERO");
        require(_issuedAt <= block.timestamp, "INVALID_ISSUED_AT");

        (bytes32 hash, address issuer) = _verifyIssuerSetAttr(_account, _tokenId, _attribute, _value, _issuedAt, _sig);
        _accountBalancesETH[governance.issuersTreasury(issuer)] += governance.mintPricePerAttribute(_attribute);
        _usedHashes[hash] = true;
        _setAttributeInternal(_account, _tokenId, _attribute, _value, _issuedAt, issuer);
    }

    /// @notice (only Issuer) Update or set a new attribute for an existing passport
    /// @dev Only issuer role
    /// @param _account address of the wallet to update
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type (ex: keccak256("COUNTRY"))
    /// @param _value keccak256 of the value of the attribute (ex: keccak256("FRANCE"))
    /// @param _issuedAt epoch when the operation has been authorized by the Issuer
    function setAttributeIssuer(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        bytes32 _value,
        uint256 _issuedAt
    ) external override {
        require(IAccessControlUpgradeable(address(governance)).hasRole(ISSUER_ROLE, _msgSender()), "INVALID_ISSUER");
        require(_account != address(0), "ACCOUNT_CANNOT_BE_ZERO");
        require(_issuedAt != 0, "ISSUED_AT_CANNOT_BE_ZERO");
        require(_issuedAt <= block.timestamp, "INVALID_ISSUED_AT");

        _setAttributeInternal(_account, _tokenId, _attribute, _value, _issuedAt, _msgSender());
    }

    function _setAttributeInternal(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        bytes32 _value,
        uint256 _issuedAt,
        address _issuer
    ) internal {
        require(governance.eligibleTokenId(_tokenId), "PASSPORT_TOKENID_INVALID");
        require(balanceOf(_account, _tokenId) == 1, "PASSPORT_DOES_NOT_EXIST");
        require(_attribute != keccak256("DID"), "MUST_BURN_AND_MINT");
        require(governance.eligibleAttributes(_attribute)
            || governance.eligibleAttributesByDID(_attribute),
            "ATTRIBUTE_NOT_ELIGIBLE"
        );

        if (governance.eligibleAttributes(_attribute)) {
            _attributes[_account][_attribute][_issuer] = Attribute({
                value: _value,
                epoch: _issuedAt
            });
        } else {
            // Attribute grouped by DID
            bytes32 dID = _attributes[_account][keccak256("DID")][_issuer].value;
            require(dID != bytes32(0), "DID_NOT_FOUND");
            _attributesByDID[dID][_attribute][_issuer] = Attribute({
                value: _value,
                epoch: _issuedAt
            });
        }
    }

    /// @notice Burn your Quadrata passport
    /// @dev Only owner of the passport
    /// @param _tokenId tokenId of the Passport (1 for now)
    function burnPassport(
        uint256 _tokenId
    ) external override {
        require(balanceOf(_msgSender(), _tokenId) == 1, "CANNOT_BURN_ZERO_BALANCE");
        _burn(_msgSender(), _tokenId, 1);

        for (uint256 i = 0; i < governance.getEligibleAttributesLength(); i++) {
            bytes32 attributeType = governance.eligibleAttributesArray(i);
            for(uint256 j = 0; j < governance.getIssuersLength(); j++) {
                delete _attributes[_msgSender()][attributeType][governance.issuers(j).issuer];
            }
        }
    }

    /// @notice Issuer can burn an account's Quadrata passport when requested
    /// @dev Only issuer role
    /// @param _account address of the wallet to burn
    /// @param _tokenId tokenId of the Passport (1 for now)
    function burnPassportIssuer(
        address _account,
        uint256 _tokenId
    ) external override {
        require(IAccessControlUpgradeable(address(governance)).hasRole(ISSUER_ROLE, _msgSender()), "INVALID_ISSUER");
        require(balanceOf(_account, _tokenId) == 1, "CANNOT_BURN_ZERO_BALANCE");

        // only delete attributes from sender
        for (uint256 i = 0; i < governance.getEligibleAttributesLength(); i++) {
            bytes32 attributeType = governance.eligibleAttributesArray(i);
            delete _attributes[_account][attributeType][_msgSender()];
        }

        // if another attribute is found, keep the passport, otherwise burn if all values are null
        for (uint256 i = 0; i < governance.getEligibleAttributesLength(); i++) {
            bytes32 attributeType = governance.eligibleAttributesArray(i);
            for(uint256 j = 0; j < governance.getIssuersLength(); j++) {
                Attribute memory attribute = _attributes[_account][attributeType][governance.issuers(j).issuer];
                if(attribute.epoch != 0) {
                    return;
                }
            }
        }

        _burn(_account, _tokenId, 1);
    }

    /// @dev Verify sigs and ensure account is an EOA or Smart Contract depending on IS_BUSINESS status
    /// @param _config all the mint function parameters
    /// @param _sigIssuer sig of issuer EOA
    /// @param _sigAccount sig of EOA authorizing claim of passport NFT
    /// @return unique hash of mintPassport invocation and extracted issuer of passport
    function _verifySignersMint(
        MintConfig calldata _config,
        bytes calldata _sigIssuer,
        bytes calldata _sigAccount
    ) internal view returns(bytes32, address){
        require(_config.account != address(0), "ACCOUNT_CANNOT_BE_ZERO");
        require(_config.issuedAt != 0, "ISSUED_AT_CANNOT_BE_ZERO");
        require(_config.issuedAt <= block.timestamp, "INVALID_ISSUED_AT");

        bytes32 extractionHash = keccak256(abi.encode(_config.account, _config.tokenId, _config.quadDID, _config.aml, _config.country, _config.isBusiness, _config.issuedAt));
        bytes32 signedMsg = ECDSAUpgradeable.toEthSignedMessageHash(extractionHash);
        address issuer = ECDSAUpgradeable.recover(signedMsg, _sigIssuer);

        bytes32 issuerMintHash = keccak256(abi.encode(extractionHash, issuer));

        require(!_usedHashes[issuerMintHash], "SIGNATURE_ALREADY_USED");
        require(IAccessControlUpgradeable(address(governance)).hasRole(ISSUER_ROLE, issuer), "INVALID_ISSUER");

        // if the account isn't a Business, then ensure account is EOA
        // Businesses can be Smart Contracts or EOAs
        // Individuals can only be EOAs
        if(_config.isBusiness == keccak256("FALSE")) {
            extractionHash = keccak256(abi.encodePacked(_config.account));
            signedMsg = ECDSAUpgradeable.toEthSignedMessageHash(extractionHash);
            require(ECDSAUpgradeable.recover(signedMsg, _sigAccount) == _config.account, "INVALID_ACCOUNT");
        }

        return (issuerMintHash, issuer);
    }

    function _verifyIssuerSetAttr(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        bytes32 _value,
        uint256 _issuedAt,
        bytes calldata _sig
    ) internal view returns(bytes32,address) {
        bytes32 hash = keccak256(abi.encode(_account, _tokenId, _attribute, _value, _issuedAt));

        require(!_usedHashes[hash], "SIGNATURE_ALREADY_USED");

        bytes32 signedMsg = ECDSAUpgradeable.toEthSignedMessageHash(hash);
        address issuer = ECDSAUpgradeable.recover(signedMsg, _sig);
        require(IAccessControlUpgradeable(address(governance)).hasRole(ISSUER_ROLE, issuer), "INVALID_ISSUER");

        return (hash, issuer);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable) {
    require(
        (from == address(0) && to != address(0))
        || (from != address(0) && to == address(0)),
        "ONLY_MINT_OR_BURN_ALLOWED"
    );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, IERC165Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /// @dev Allow an issuer's treasury or the Quadrata treasury to withdraw $ETH
    /// @param _to address of either an issuer's treasury or the Quadrata treasury
    /// @return the amount of $ETH withdrawn
    function withdrawETH(address payable _to) external override returns(uint256) {
       require(_to != address(0), "WITHDRAW_ADDRESS_ZERO");
       uint256 currentBalance = _accountBalancesETH[_to];
       require(currentBalance > 0, "NOT_ENOUGH_BALANCE");
       _accountBalancesETH[_to] = 0;
       (bool sent,) = _to.call{value: currentBalance}("");
       require(sent, "FAILED_TO_TRANSFER_NATIVE_ETH");
       return currentBalance;
    }

    /// @dev Allow an issuer's treasury or the Quadrata treasury to withdraw ERC20 tokens
    /// @param _to address of either an issuer's treasury or the Quadrata treasury
    /// @param _token address of the ERC20 tokens to withdraw
    /// @return the amount of ERC20 withdrawn
    function withdrawToken(address payable _to, address _token) external override returns(uint256) {
       require(_to != address(0), "WITHDRAW_ADDRESS_ZERO");
       uint256 currentBalance = _accountBalances[_token][_to];
       require(currentBalance > 0, "NOT_ENOUGH_BALANCE");
       _accountBalances[_token][_to] = 0;
        IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(_token);
       erc20.safeTransfer(_to, currentBalance);
       return currentBalance;
    }

    /// @dev Admin function to set the new pending Governance address
    /// @param _governanceContract contract address of IQuadGovernance
    function setGovernance(address _governanceContract) external override {
        require(_msgSender() == address(governance), 'ONLY_GOVERNANCE_CONTRACT');
        require(_governanceContract != address(0), "GOVERNANCE_ADDRESS_ZERO");

        pendingGovernance = _governanceContract;
        emit SetPendingGovernance(pendingGovernance);
    }

    /// @dev Admin function to accept and set the governance contract address
    function acceptGovernance() external override {
        require(_msgSender() == pendingGovernance, 'ONLY_PENDING_GOVERNANCE_CONTRACT');

        address oldGov = address(governance);
        governance = IQuadGovernance(pendingGovernance);
        pendingGovernance = address(0);

        emit GovernanceUpdated(oldGov, address(governance));
    }


    /// @dev Allow an authorized readers to get attribute information about a passport holder for a specific issuer
    /// @param _account address of user
    /// @param _attribute attribute to get respective value from
    /// @param _issuer the entity that gave the attribute value
    /// @return value of attribute from issuer
    function attributes(
        address _account,
        bytes32 _attribute,
        address _issuer
    ) public view override returns (Attribute memory) {
        require(IAccessControlUpgradeable(address(governance)).hasRole(READER_ROLE, _msgSender()), "INVALID_READER");
        if (!IAccessControlUpgradeable(address(governance)).hasRole(ISSUER_ROLE, _issuer))
           return Attribute({value: bytes32(0), epoch: 0});
        return _attributes[_account][_attribute][_issuer];
    }

    /// @dev Allow an authorized readers to get information about a QuadDID for a specific issuer
    /// @param _dID did of user
    /// @param _attribute attribute to get respective value from
    /// @param _issuer the entity that gave the attribute value
    /// @return did value by issuer
    function attributesByDID(
        bytes32 _dID,
        bytes32 _attribute,
        address _issuer
    ) public view override returns (Attribute memory) {
        require(IAccessControlUpgradeable(address(governance)).hasRole(READER_ROLE, _msgSender()), "INVALID_READER");
        if (!IAccessControlUpgradeable(address(governance)).hasRole(ISSUER_ROLE, _issuer))
           return Attribute({value: bytes32(0), epoch: 0});
        return _attributesByDID[_dID][_attribute][_issuer];
    }

    /// @dev Increase balance of account
    /// @param _account address of user
    /// @param _amount the entity that gave the attribute value
    function increaseAccountBalanceETH(
        address _account,
        uint256 _amount
    ) public override {
        require(IAccessControlUpgradeable(address(governance)).hasRole(READER_ROLE, _msgSender()), "INVALID_READER");
        _accountBalancesETH[_account] += _amount;
    }

    /// @dev Increase balance of account
    /// @param _account address of user
    /// @param _amount the entity that gave the attribute value
    function increaseAccountBalance(
        address _token,
        address _account,
        uint256 _amount
    ) public override {
        require(IAccessControlUpgradeable(address(governance)).hasRole(READER_ROLE, _msgSender()), "INVALID_READER");
        _accountBalances[_token][_account] += _amount;
    }

    function _authorizeUpgrade(address) internal view override {
        require(IAccessControlUpgradeable(address(governance)).hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
    }
}

