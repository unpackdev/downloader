//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20MetadataUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IQuadPassport.sol";
import "./IQuadGovernance.sol";
import "./IUniswapAnchoredView.sol";
import "./QuadGovernanceStore.sol";

/// @title Governance Contract for Quadrata Passport
/// @author Fabrice Cheng, Theodore Clapp
/// @notice All admin functions to govern the QuadPassport contract
contract QuadGovernance is IQuadGovernance, AccessControlUpgradeable, UUPSUpgradeable, QuadGovernanceStore {
    event AllowTokenPayment(address indexed _tokenAddr, bool _isAllowed);
    event AttributePriceUpdated(bytes32 _attribute, uint256 _oldPrice, uint256 _price);
    event BusinessAttributePriceUpdated(bytes32 _attribute, uint256 _oldPrice, uint256 _price);
    event AttributeMintPriceUpdated(bytes32 _attribute, uint256 _oldPrice, uint256 _price);
    event EligibleTokenUpdated(uint256 _tokenId, bool _eligibleStatus);
    event EligibleAttributeUpdated(bytes32 _attribute, bool _eligibleStatus);
    event EligibleAttributeByDIDUpdated(bytes32 _attribute, bool _eligibleStatus);
    event IssuerAdded(address indexed _issuer, address indexed _newTreasury);
    event IssuerDeleted(address indexed _issuer);
    event IssuerStatusChanged(address indexed issuer, IssuerStatus oldStatus, IssuerStatus newStatus);
    event PassportAddressUpdated(address indexed _oldAddress, address indexed _address);
    event PassportVersionUpdated(uint256 _oldVersion, uint256 _version);
    event PassportMintPriceUpdated(uint256 _oldMintPrice, uint256 _mintPrice);
    event OracleUpdated(address indexed _oldAddress, address indexed _address);
    event RevenueSplitIssuerUpdated(uint256 _oldSplit, uint256 _split);
    event TreasuryUpdated(address indexed _oldAddress, address indexed _address);

    constructor() initializer {
        // used to prevent logic contract self destruct take over
    }

    /// @dev Initializer (constructor)
    /// @param _admin address of the admin account
    function initialize(address _admin) public initializer {
        require(_admin != address(0), "ADMIN_ADDRESS_ZERO");
        __AccessControl_init_unchained();

        _eligibleTokenId[1] = true;   // INITIAL PASSPORT_ID

        // Add DID, COUNTRY, AML as valid attributes
        _eligibleAttributes[keccak256("DID")] = true;
        _eligibleAttributes[keccak256("COUNTRY")] = true;
        _eligibleAttributes[keccak256("IS_BUSINESS")] = true;
        _eligibleAttributesByDID[keccak256("AML")] = true;

        _eligibleAttributesArray.push(keccak256("DID"));
        _eligibleAttributesArray.push(keccak256("COUNTRY"));
        _eligibleAttributesArray.push(keccak256("IS_BUSINESS"));

        // Set pricing
        _pricePerAttribute[keccak256("DID")] = 2 * 1e6; // $2
        _pricePerAttribute[keccak256("COUNTRY")] = 1 * 1e6; // $1

        // Set pricing for businesses
        _pricePerBusinessAttribute[keccak256("DID")] = 10 * 1e6; // $10
        _pricePerBusinessAttribute[keccak256("COUNTRY")] = 5 * 1e6; // $5

        _mintPricePerAttribute[keccak256("AML")] = 0.01 ether;
        _mintPricePerAttribute[keccak256("COUNTRY")] = 0.01 ether;
        config.mintPrice = 0.003 ether;

        // Revenue split with issuers
        config.revSplitIssuer = 50;  // 50%

        // Set Roles
        _setRoleAdmin(PAUSER_ROLE, GOVERNANCE_ROLE);
        _setRoleAdmin(ISSUER_ROLE, GOVERNANCE_ROLE);
        _setupRole(GOVERNANCE_ROLE, _admin);
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// @dev Set QuadPassport treasury wallet to withdraw the protocol fees
    /// @notice Restricted behind a TimelockController
    /// @param _treasury address of the treasury
    function setTreasury(address _treasury)  external override {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_treasury != address(0), "TREASURY_ADDRESS_ZERO");
        require(_treasury != config.treasury, "TREASURY_ADDRESS_ALREADY_SET");
        address oldTreasury = config.treasury;
        config.treasury = _treasury;
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    /// @dev Set QuadPassport contract address
    /// @notice Restricted behind a TimelockController
    /// @param _passportAddr address of the QuadPassport contract
    function setPassportContractAddress(address _passportAddr)  external override {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_passportAddr != address(0), "PASSPORT_ADDRESS_ZERO");
        require(address(config.passport) != _passportAddr, "PASSPORT_ADDRESS_ALREADY_SET");
        address _oldPassport = address(config.passport);
        config.passport = IQuadPassport(_passportAddr);

        emit PassportAddressUpdated(_oldPassport, address(config.passport));
    }

    /// @dev Set the pending QuadGovernance address in the QuadPassport contract
    /// @notice Restricted behind a TimelockController
    /// @param _newGovernance address of the QuadGovernance contract
    function updateGovernanceInPassport(address _newGovernance)  external override {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_newGovernance != address(0), "GOVERNANCE_ADDRESS_ZERO");
        require(address(config.passport) != address(0), "PASSPORT_NOT_SET");

        config.passport.setGovernance(_newGovernance);
    }

    /// @dev Confirms the pending QuadGovernance address in the QuadPassport contract
    function acceptGovernanceInPassport() external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        config.passport.acceptGovernance();
    }

    /// @dev Set the price for minting the QuadPassport
    /// @notice Restricted behind a TimelockController
    /// @param _mintPrice price in wei for minting a passport
    function setMintPrice(uint256 _mintPrice)  external override {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(config.mintPrice != _mintPrice, "MINT_PRICE_ALREADY_SET");

        uint256 oldMintPrice = config.mintPrice;
        config.mintPrice = _mintPrice;
        emit PassportMintPriceUpdated(oldMintPrice, config.mintPrice);
    }

    /// @dev Set the eligibility status for a tokenId passport
    /// @notice Restricted behind a TimelockController
    /// @param _tokenId tokenId of the passport
    /// @param _eligibleStatus eligiblity boolean for the tokenId
    function setEligibleTokenId(uint256 _tokenId, bool _eligibleStatus) external override {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_eligibleTokenId[_tokenId] != _eligibleStatus, "TOKEN_ELIGIBILITY_ALREADY_SET");

        _eligibleTokenId[_tokenId] = _eligibleStatus;
        emit EligibleTokenUpdated(_tokenId, _eligibleStatus);
    }

    /// @dev Set the eligibility status for an attribute type
    /// @notice Restricted behind a TimelockController
    /// @param _attribute keccak256 of the attribute name (ex: keccak256("COUNTRY"))
    /// @param _eligibleStatus eligiblity boolean for the attribute
    function setEligibleAttribute(bytes32 _attribute, bool _eligibleStatus) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_eligibleAttributes[_attribute] != _eligibleStatus, "ATTRIBUTE_ELIGIBILITY_SET");

        _eligibleAttributes[_attribute] = _eligibleStatus;
        if (_eligibleStatus) {
            _eligibleAttributesArray.push(_attribute);
        } else {
            for (uint256 i = 0; i < _eligibleAttributesArray.length; i++) {
                if (_eligibleAttributesArray[i] == _attribute) {
                    _eligibleAttributesArray[i] = _eligibleAttributesArray[_eligibleAttributesArray.length - 1];
                    _eligibleAttributesArray.pop();
                    break;
                }
            }
        }
        emit EligibleAttributeUpdated(_attribute, _eligibleStatus);
    }


    /// @dev Set the eligibility status for an attribute type grouped by DID (Applicable to AML only for now)
    /// @notice Restricted behind a TimelockController
    /// @param _attribute keccak256 of the attribute name (ex: keccak256("AML"))
    /// @param _eligibleStatus eligiblity boolean for the attribute
    function setEligibleAttributeByDID(bytes32 _attribute, bool _eligibleStatus) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_eligibleAttributesByDID[_attribute] != _eligibleStatus, "ATTRIBUTE_ELIGIBILITY_SET");

        _eligibleAttributesByDID[_attribute] = _eligibleStatus;
        emit EligibleAttributeByDIDUpdated(_attribute, _eligibleStatus);
    }

    /// @dev Set the price for querying a single attribute after owning a passport
    /// @notice Restricted behind a TimelockController
    /// @param _attribute keccak256 of the attribute name (ex: keccak256("COUNTRY"))
    /// @param _price price (USD)
    function setAttributePrice(bytes32 _attribute, uint256 _price) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_pricePerAttribute[_attribute] != _price, "ATTRIBUTE_PRICE_ALREADY_SET");
        uint256 oldPrice = _pricePerAttribute[_attribute];
        _pricePerAttribute[_attribute] = _price;

        emit AttributePriceUpdated(_attribute, oldPrice, _price);
    }

    /// @dev Set the business attribute price for querying a single attribute after owning a passport
    /// @notice Restricted behind a TimelockController
    /// @param _attribute keccak256 of the attribute name (ex: keccak256("COUNTRY"))
    /// @param _price price (USD)
    function setBusinessAttributePrice(bytes32 _attribute, uint256 _price) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_pricePerBusinessAttribute[_attribute] != _price, "KYB_ATTRIBUTE_PRICE_ALREADY_SET");
        uint256 oldPrice = _pricePerBusinessAttribute[_attribute];
        _pricePerBusinessAttribute[_attribute] = _price;

        emit BusinessAttributePriceUpdated(_attribute, oldPrice, _price);
    }


    /// @dev Set the price to update/set a single attribute after owning a passport
    /// @notice Restricted behind a TimelockController
    /// @param _attribute keccak256 of the attribute name (ex: keccak256("COUNTRY"))
    /// @param _price price (wei)
    function setAttributeMintPrice(bytes32 _attribute, uint256 _price) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_mintPricePerAttribute[_attribute] != _price, "ATTRIBUTE_MINT_PRICE_ALREADY_SET");
        uint256 oldPrice = _mintPricePerAttribute[_attribute];
        _mintPricePerAttribute[_attribute] = _price;

        emit AttributeMintPriceUpdated(_attribute, oldPrice, _price);
    }

    /// @dev Set the UniswapAnchorView oracle (Using Compound)
    /// @notice Restricted behind a TimelockController
    /// @param _oracleAddr address of UniswapAnchorView contract
    function setOracle(address _oracleAddr) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_oracleAddr != address(0), "ORACLE_ADDRESS_ZERO");
        require(config.oracle != _oracleAddr, "ORACLE_ADDRESS_ALREADY_SET");
        // Safety check to ensure that address is a valid Oracle
        IUniswapAnchoredView(_oracleAddr).price("ETH");
        address oldAddress = config.oracle;
        config.oracle = _oracleAddr;
        emit OracleUpdated(oldAddress, _oracleAddr);
    }


    /// @dev Set the revenue split percentage between Issuers and Quadrata Protocol
    /// @notice Restricted behind a TimelockController
    /// @param _split percentage split (`50` equals 50%)
    function setRevSplitIssuer(uint256 _split) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(config.revSplitIssuer != _split, "REV_SPLIT_ALREADY_SET");
        require(_split <= 100, "SPLIT_MUST_BE_LESS_THAN_EQUAL_TO_100");

        uint256 oldSplit = config.revSplitIssuer;
        config.revSplitIssuer = _split;

        emit RevenueSplitIssuerUpdated(oldSplit, _split);
    }

    /// @dev Add a new issuer or update treasury
    /// @notice Restricted behind a TimelockController
    /// @param _issuer address generating the signature authorizing minting/setting attributes
    /// @param _treasury address of the issuer treasury to withdraw the fees
    function setIssuer(address _issuer, address _treasury) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_treasury != address(0), "TREASURY_ISSUER_ADDRESS_ZERO");
        require(_issuer != address(0), "ISSUER_ADDRESS_ZERO");

        _issuersTreasury[_issuer] = _treasury;

        if(_issuerIndices[_issuer] == 0) {
            grantRole(ISSUER_ROLE, _issuer);
            _issuers.push(Issuer(_issuer, IssuerStatus.ACTIVE));
            _issuerIndices[_issuer] = _issuers.length;
        }

        emit IssuerAdded(_issuer, _treasury);
    }

    /// @dev Delete issuer
    /// @notice Restricted behind a TimelockController
    /// @param _issuer address to remove
    function deleteIssuer(address _issuer) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_issuer != address(0), "ISSUER_ADDRESS_ZERO");
        require(_issuerIndices[_issuer] < _issuers.length + 1, "OUT_OF_BOUNDS");

        // don't need to delete treasury
        _issuers[_issuerIndices[_issuer]-1] = _issuers[_issuers.length-1];
        _issuerIndices[_issuers[_issuers.length-1].issuer] = _issuerIndices[_issuer];

        delete _issuerIndices[_issuer];
        _issuers.pop();

        revokeRole(ISSUER_ROLE, _issuer);

        emit IssuerDeleted(_issuer);
    }

    /// @dev Sets the status for specified issuer
    /// @notice Restricted behind a TimelockController
    /// @param _issuer address to change status
    /// @param _status new status for issuer
    function setIssuerStatus(address _issuer, IssuerStatus _status) external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_issuer != address(0), "ISSUER_ADDRESS_ZERO");

        Issuer memory oldIssuerData = _issuers[_issuerIndices[_issuer]-1];
        _issuers[_issuerIndices[_issuer]-1] = Issuer(oldIssuerData.issuer, _status);

        if(_status == IssuerStatus.ACTIVE) {
            grantRole(ISSUER_ROLE, _issuer);
        } else if(_status == IssuerStatus.DEACTIVATED) {
            revokeRole(ISSUER_ROLE, _issuer);
        } else {
            revert("INVALID_STATUS"); //unreachable code
        }

        emit IssuerStatusChanged(_issuer, oldIssuerData.status, _status);
    }

    /// @dev Authorize or deny a payment to be received in specified token
    /// @notice Restricted behind a TimelockController
    /// @param _tokenAddr address of the ERC20 token for payment
    /// @param _isAllowed authorize or deny this token
    function allowTokenPayment(
        address _tokenAddr,
        bool _isAllowed
    ) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_tokenAddr != address(0), "TOKEN_PAYMENT_ADDRESS_ZERO");
        require(
            eligibleTokenPayments[_tokenAddr] != _isAllowed,
            "TOKEN_PAYMENT_STATUS_SET"
        );
        IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(_tokenAddr);
        // SafeCheck call to make sure that _tokenAddr is a valid ERC20 address
        erc20.totalSupply();

        eligibleTokenPayments[_tokenAddr] = _isAllowed;
        emit AllowTokenPayment(_tokenAddr, _isAllowed);
    }

    /// @dev Get number of eligible attributes currently supported
    /// @notice Restricted behind a TimelockController
    /// @return length of eligible attributes
    function getEligibleAttributesLength() override external view returns(uint256) {
        return _eligibleAttributesArray.length;
    }

    function _authorizeUpgrade(address) override internal view {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
    }

    /// @dev Get the price in USD of a token using UniswapAnchorView
    /// @param _tokenAddr address of the ERC20 token
    /// @return price in USD
    function getPrice(address _tokenAddr) override external view returns (uint256) {
        require(config.oracle != address(0), "ORACLE_ADDRESS_ZERO");
        require(eligibleTokenPayments[_tokenAddr], "TOKEN_PAYMENT_NOT_ALLOWED");
        IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(_tokenAddr);
        return IUniswapAnchoredView(config.oracle).price(erc20.symbol());
    }

    /// @dev Get the price in USD for $ETH using UniswapAnchorView
    /// @return price in USD for $ETH
    function getPriceETH() override external view returns (uint256) {
        require(config.oracle != address(0), "ORACLE_ADDRESS_ZERO");
        return IUniswapAnchoredView(config.oracle).price("ETH");
    }

    /// @dev Get the length of _issuers array
    /// @return total number of _issuers
    function getIssuersLength() override public view returns (uint256) {
        return _issuers.length;
    }

    /// @dev Get the _issuers array
    /// @return list of issuers
    function getIssuers() override public view returns (Issuer[] memory) {
        return _issuers;
    }

    /// @dev Get the status of an issuer
    /// @param _issuer address of issuer
    /// @return issuer status
    function getIssuerStatus(address _issuer) override public view returns(IssuerStatus) {
        if(_issuerIndices[_issuer] == 0) {
            // if the issuer isn't in the mapping, just say it's not active
            return IssuerStatus.DEACTIVATED;
        }
        return _issuers[_issuerIndices[_issuer]-1].status;
    }

    /// @dev Get the revenue split between protocol and _issuers
    /// @return ratio of revenue distribution
    function revSplitIssuer() override public view returns(uint256) {
        return config.revSplitIssuer;
    }

    /// @dev Get the cost for minting a passport
    /// @return passport mint price
    function mintPrice() override public view returns(uint256) {
        return config.mintPrice;
    }

    /// @dev Get the address of protocol treasury
    /// @return treasury address
    function treasury() override public view returns(address) {
        return config.treasury;
    }

    /// @dev Get the address of price oracle
    /// @return oracle address
    function oracle() public view returns(address) {
        return config.oracle;
    }

    /// @dev Get the address of passport
    /// @return passport address
    function passport() public view returns(IQuadPassport) {
        return config.passport;
    }

    /// @dev Get the attribute eligibility
    /// @return attribute eligibility
    function eligibleAttributes(bytes32 _value) override public view returns(bool) {
        return _eligibleAttributes[_value];
    }

    /// @dev Get the attribute eligibility by DID
    /// @return attribute eligibility
    function eligibleAttributesByDID(bytes32 _value) override public view returns(bool) {
        return _eligibleAttributesByDID[_value];
    }

    /// @dev Get a maintained attribute from eligibility
    /// @return eligible attribute element
    function eligibleAttributesArray(uint256 _value) override public view returns(bytes32) {
        return _eligibleAttributesArray[_value];
    }

    /// @dev Get active tokenId
    /// @return tokenId eligibility
    function eligibleTokenId(uint256 _value) override public view returns(bool) {
        return _eligibleTokenId[_value];
    }

    /// @dev Get mint price for an attribute
    /// @return attribute price for updating
    function mintPricePerAttribute(bytes32 _value) override public view returns(uint256) {
        return _mintPricePerAttribute[_value];
    }

    /// @dev Get query price for an attribute
    /// @return attribute price for using getter
    function pricePerAttribute(bytes32 _value) override public view returns(uint256) {
        return _pricePerAttribute[_value];
    }

    /// @dev Get query price for an attribute given a business is asking
    /// @return attribute price for using getter given a business is asking
    function pricePerBusinessAttribute(bytes32 _value) override public view returns(uint256) {
        return _pricePerBusinessAttribute[_value];
    }

    /// @dev Get an issuer at a certain index
    /// @return issuer element
    function issuers(uint256 _value) override public view returns(Issuer memory) {
        return _issuers[_value];
    }

    /// @dev Get an issuer's treasury
    /// @return issuer treasury
    function issuersTreasury(address _value) override public view returns (address) {
        return _issuersTreasury[_value];
    }
}

