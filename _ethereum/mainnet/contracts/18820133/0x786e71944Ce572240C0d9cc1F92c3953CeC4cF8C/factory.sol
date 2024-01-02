// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./proxy.sol";
import "./emitter.sol";
import "./erc20dao.sol";
import "./erc721dao.sol";
import "./helper.sol";

interface IWrappedToken {
    function deposit() external payable;
}

interface Safe {
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) external returns (address proxy);

    function isOwner(address owner) external view returns (bool);
}

/// @title StationXFactory Cloning Contract
/// @dev Contract create proxies of DAO Token and Governor contract
contract Factory is Helper {
    using SafeERC20 for IERC20;

    address private ERC20Implementation;
    address private ERC721Implementation;
    address private emitterAddress;
    address private constant wrappedTokenAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private safe;
    address private singleton;
    address private _owner;

    //Mapping to get details of a particular dao
    mapping(address => DAODetails) private daoDetails;

    //Mapping to store total deposit by a user in a particular dao
    mapping(address => mapping(address => uint256)) private totalDeposit;

    //Mapping to get details of token gating for a particular dao
    mapping(address => TokenGatingCondition[]) private tokenGatingDetails;

    bool private _initialized;

    function initialize() external {
        require(!_initialized);
        _owner = msg.sender;
        _initialized = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        _owner = _newOwner;
    }

    function defineTokenContracts(
        address ERC20ImplementationAddress,
        address ERC721ImplementationAddress,
        address emitterImplementationAddress,
        address _safe,
        address _singleton
    ) external onlyOwner {
        //Setting ERC20 implementation contract for the reference
        ERC20Implementation = ERC20ImplementationAddress;

        //Setting ERC721 implementation contract for the reference
        ERC721Implementation = ERC721ImplementationAddress;

        //Setting Emitter proxy contract
        emitterAddress = emitterImplementationAddress;

        safe = _safe;
        singleton = _singleton;
    }

    /// @dev This function returns details of a particular dao
    /// @param _daoAddress address of token contract
    function getDAOdetails(
        address _daoAddress
    ) public view returns (DAODetails memory) {
        return daoDetails[_daoAddress];
    }

    /// @dev This function returns token gating details of a particular dao
    /// @param _daoAddress address of token contract
    function getTokenGatingDetails(
        address _daoAddress
    ) external view returns (TokenGatingCondition[] memory) {
        return tokenGatingDetails[_daoAddress];
    }

    /// @dev Function to change merkle root of particular token contract
    /// @param _daoAddress address token contract
    function changeMerkleRoot(
        address _daoAddress,
        bytes32 _newMerkleRoot
    ) external payable onlyGnosisOrDao(address(this), _daoAddress) {
        if (!daoDetails[_daoAddress].isDeployedByFactory)
            revert AddressInvalid("_daoAddress", _daoAddress);
        daoDetails[_daoAddress].merkleRoot = _newMerkleRoot;

        Emitter(emitterAddress).changeMerkleRoot(
            address(this),
            _daoAddress,
            _newMerkleRoot
        );
    }

    /// @dev Function to create proxies and initialization of Token and Governor contract
    function createERC20DAO(
        string memory _DaoName,
        string memory _DaoSymbol,
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        uint256 _minDepositPerUser,
        uint256 _maxDepositPerUser,
        uint256 _ownerFeePerDepositPercent,
        uint256 _depositTime,
        uint256 _quorumPercent,
        uint256 _thresholdPercent,
        uint256 _safeThreshold,
        address _depositTokenAddress,
        address _gnosisAddress,
        address[] memory _admins,
        bool _isGovernanceActive,
        bool _isTransferable,
        bool _onlyAllowWhitelist,
        bool _assetsStoredOnGnosis,
        bytes32 _merkleRoot
    ) external {
        if (_quorumPercent == 0 || _quorumPercent > FLOAT_HANDLER_TEN_4)
            revert AmountInvalid("_quorumPercent", _quorumPercent);

        if (_thresholdPercent == 0 || _thresholdPercent > FLOAT_HANDLER_TEN_4)
            revert AmountInvalid("_thresholdPercent", _thresholdPercent);

        if (_depositTime == 0)
            revert AmountInvalid("_depositFunctioningDays", _depositTime);

        if (!(_ownerFeePerDepositPercent < FLOAT_HANDLER_TEN_4))
            revert AmountInvalid(
                "_ownerFeePerDeposit",
                _ownerFeePerDepositPercent
            );

        if (_maxDepositPerUser == 0)
            revert AmountInvalid("_maxDepositPerUser", _maxDepositPerUser);

        if (_maxDepositPerUser <= _minDepositPerUser)
            revert DepositAmountInvalid(_maxDepositPerUser, _minDepositPerUser);

        if (
            ((_distributionAmount * _pricePerToken) / 1e18) < _maxDepositPerUser
        )
            revert RaiseAmountInvalid(
                ((_distributionAmount * _pricePerToken) / 1e18),
                _maxDepositPerUser
            );

        address _safe;
        if (_gnosisAddress == address(0)) {
            bytes memory _initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                _admins,
                _safeThreshold,
                0x0000000000000000000000000000000000000000,
                "0x",
                0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4,
                0x0000000000000000000000000000000000000000,
                0,
                0x0000000000000000000000000000000000000000
            );
            _safe = Safe(safe).createProxyWithNonce(
                singleton,
                _initializer,
                block.timestamp
            );
        } else {
            _safe = _gnosisAddress;
        }

        bytes memory data = abi.encodeWithSignature(
            "initializeERC20(address,address,string,string,uint256,uint256,bool,bool,address,bool)",
            address(this),
            emitterAddress,
            _DaoName,
            _DaoSymbol,
            _quorumPercent,
            _thresholdPercent,
            _isGovernanceActive,
            _isTransferable,
            msg.sender,
            _onlyAllowWhitelist
        );

        address _daoAddress = address(
            new ProxyContract(ERC20Implementation, _owner, data)
        );

        daoDetails[_daoAddress] = DAODetails(
            _pricePerToken,
            _distributionAmount,
            _minDepositPerUser,
            _maxDepositPerUser,
            _ownerFeePerDepositPercent,
            _depositTime,
            _depositTokenAddress,
            _safe,
            _merkleRoot,
            true,
            false,
            _assetsStoredOnGnosis
        );

        Emitter(emitterAddress).createDaoErc20(
            msg.sender,
            _daoAddress,
            _DaoName,
            _DaoSymbol,
            _distributionAmount,
            _pricePerToken,
            _minDepositPerUser,
            _maxDepositPerUser,
            _ownerFeePerDepositPercent,
            _depositTime,
            _quorumPercent,
            _thresholdPercent,
            _depositTokenAddress,
            emitterAddress,
            _safe,
            _isGovernanceActive,
            _isTransferable,
            _assetsStoredOnGnosis
        );

        for (uint i; i < _admins.length; ) {
            Emitter(emitterAddress).newUser(
                _daoAddress,
                _admins[i],
                _depositTokenAddress,
                0,
                block.timestamp,
                0,
                true
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Function to create proxies and initialization of Token and Governor contract
    function createERC721DAO(
        string memory _DaoName,
        string memory _DaoSymbol,
        string memory _tokenURI,
        uint256 _ownerFeePerDepositPercent,
        uint256 _depositTime,
        uint256 _quorumPercent,
        uint256 _thresholdPercent,
        uint256 _safeThreshold,
        address _depositTokenAddress,
        address _gnosisAddress,
        address[] memory _admins,
        uint256 _maxTokensPerUser,
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        bool _isNftTransferable,
        bool _isNftTotalSupplyUnlimited,
        bool _isGovernanceActive,
        bool _onlyAllowWhitelist,
        bool _assetsStoredOnGnosis,
        bytes32 _merkleRoot
    ) external {
        if (_quorumPercent == 0 || _quorumPercent > FLOAT_HANDLER_TEN_4)
            revert AmountInvalid("_quorumPercent", _quorumPercent);

        if (_thresholdPercent == 0 || _thresholdPercent > FLOAT_HANDLER_TEN_4)
            revert AmountInvalid("_thresholdPercent", _thresholdPercent);

        if (_depositTime == 0)
            revert AmountInvalid("_depositFunctioningDays", _depositTime);

        if (!(_ownerFeePerDepositPercent < FLOAT_HANDLER_TEN_4))
            revert AmountInvalid(
                "_ownerFeePerDeposit",
                _ownerFeePerDepositPercent
            );

        if (_maxTokensPerUser == 0)
            revert AmountInvalid("_maxTokensPerUser", _maxTokensPerUser);

        address _safe;
        if (_gnosisAddress == address(0)) {
            bytes memory _initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                _admins,
                _safeThreshold,
                0x0000000000000000000000000000000000000000,
                "0x",
                0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4,
                0x0000000000000000000000000000000000000000,
                0,
                0x0000000000000000000000000000000000000000
            );
            _safe = Safe(safe).createProxyWithNonce(
                singleton,
                _initializer,
                block.timestamp
            );
        } else {
            _safe = _gnosisAddress;
        }

        bytes memory data = abi.encodeWithSignature(
            "initializeERC721(string,string,address,address,uint256,uint256,uint256,bool,bool,bool,bool,address)",
            _DaoName,
            _DaoSymbol,
            address(this),
            emitterAddress,
            _quorumPercent,
            _thresholdPercent,
            _maxTokensPerUser,
            _isNftTransferable,
            _isNftTotalSupplyUnlimited,
            _isGovernanceActive,
            _onlyAllowWhitelist,
            msg.sender
        );

        address _daoAddress = address(
            new ProxyContract(ERC721Implementation, _owner, data)
        );

        daoDetails[_daoAddress] = DAODetails(
            _pricePerToken,
            _distributionAmount,
            0,
            0,
            _ownerFeePerDepositPercent,
            _depositTime,
            _depositTokenAddress,
            _safe,
            _merkleRoot,
            true,
            false,
            _assetsStoredOnGnosis
        );

        Emitter(emitterAddress).createDaoErc721(
            msg.sender,
            _daoAddress,
            _DaoName,
            _DaoSymbol,
            _tokenURI,
            _pricePerToken,
            _distributionAmount,
            _maxTokensPerUser,
            _ownerFeePerDepositPercent,
            _depositTime,
            _quorumPercent,
            _thresholdPercent,
            _depositTokenAddress,
            emitterAddress,
            _safe,
            _isGovernanceActive,
            _isNftTransferable,
            _assetsStoredOnGnosis
        );

        for (uint i; i < _admins.length; ) {
            Emitter(emitterAddress).newUser(
                _daoAddress,
                _admins[i],
                _depositTokenAddress,
                0,
                block.timestamp,
                0,
                true
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Function to update Minimum and Maximum deposits allowed by DAO members
    /// @param _minDepositPerUser New minimum deposit requirement amount in wei
    /// @param _maxDepositPerUser New maximum deposit limit amount in wei
    /// @param _daoAddress address of the token contract
    function updateMinMaxDeposit(
        uint256 _minDepositPerUser,
        uint256 _maxDepositPerUser,
        address _daoAddress
    ) external payable onlyGnosisOrDao(address(this), _daoAddress) {
        if (!daoDetails[_daoAddress].isDeployedByFactory)
            revert AddressInvalid("_daoAddress", _daoAddress);

        if (_minDepositPerUser == 0)
            revert AmountInvalid("_minDepositPerUser", _minDepositPerUser);

        if (_minDepositPerUser > _maxDepositPerUser)
            revert DepositAmountInvalid(_minDepositPerUser, _maxDepositPerUser);

        daoDetails[_daoAddress].minDepositPerUser = _minDepositPerUser;
        daoDetails[_daoAddress].maxDepositPerUser = _maxDepositPerUser;

        Emitter(emitterAddress).updateMinMaxDeposit(
            _daoAddress,
            _minDepositPerUser,
            _maxDepositPerUser
        );
    }

    /// @dev Function to update DAO Owner Fee
    /// @param _ownerFeePerDeposit New Owner fee
    /// @param _daoAddress address of the token contract
    function updateOwnerFee(
        uint256 _ownerFeePerDeposit,
        address _daoAddress
    ) external payable onlyAdmins(daoDetails[_daoAddress].gnosisAddress) {
        if (!daoDetails[_daoAddress].isDeployedByFactory)
            revert AddressInvalid("_daoAddress", _daoAddress);

        if (!(_ownerFeePerDeposit < FLOAT_HANDLER_TEN_4))
            revert AmountInvalid("_ownerFeePerDeposit", _ownerFeePerDeposit);
        daoDetails[_daoAddress].ownerFeePerDepositPercent = _ownerFeePerDeposit;

        Emitter(emitterAddress).updateOwnerFee(
            _daoAddress,
            _ownerFeePerDeposit
        );
    }

    /// @dev Function to update total raise amount
    /// @param _newDistributionAmount New distribution amount
    /// @param _newPricePerToken New price per token
    /// @param _daoAddress address of the token contract
    function updateTotalRaiseAmount(
        uint256 _newDistributionAmount,
        uint256 _newPricePerToken,
        address _daoAddress
    ) external payable onlyGnosisOrDao(address(this), _daoAddress) {
        if (!daoDetails[_daoAddress].isDeployedByFactory)
            revert AddressInvalid("_daoAddress", _daoAddress);
        uint _distributionAmount = daoDetails[_daoAddress].distributionAmount;

        if (_distributionAmount != _newDistributionAmount) {
            if (_distributionAmount > _newDistributionAmount)
                revert AmountInvalid(
                    "_newDistributionAmount",
                    _newDistributionAmount
                );
            daoDetails[_daoAddress].distributionAmount = _newDistributionAmount;
            Emitter(emitterAddress).updateDistributionAmount(
                _daoAddress,
                _newDistributionAmount
            );
        }

        if (daoDetails[_daoAddress].pricePerToken != _newPricePerToken) {
            daoDetails[_daoAddress].pricePerToken = _newPricePerToken;
            Emitter(emitterAddress).updatePricePerToken(
                _daoAddress,
                _newPricePerToken
            );
        }
    }

    /// @dev Function to update deposit time
    /// @param _depositTime New start time
    /// @param _daoAddress address of the token contract
    function updateDepositTime(
        uint256 _depositTime,
        address _daoAddress
    ) external payable onlyAdmins(daoDetails[_daoAddress].gnosisAddress) {
        if (!daoDetails[_daoAddress].isDeployedByFactory)
            revert AddressInvalid("_daoAddress", _daoAddress);

        if (_depositTime == 0) revert AmountInvalid("_days", _depositTime);

        daoDetails[_daoAddress].depositCloseTime = _depositTime;

        Emitter(emitterAddress).startDeposit(
            _daoAddress,
            block.timestamp,
            daoDetails[_daoAddress].depositCloseTime
        );
    }

    /// @dev Function to setup multiple token checks to gate community
    /// @param _tokenA Address of token A
    /// @param _tokenB Address of token B
    /// @param _operator Operator for token checks (0 for AND and 1 for OR)
    /// @param _comparator Operator for comparing token balances (0 for GREATER, 1 for BELOW and 2 for EQUAL)
    /// @param _value Minimum user balance amount
    /// @param _daoAddress Address to DAO
    function setupTokenGating(
        address _tokenA,
        address _tokenB,
        Operator _operator,
        Comparator _comparator,
        uint256[] memory _value,
        address payable _daoAddress
    ) external payable onlyAdmins(daoDetails[_daoAddress].gnosisAddress) {
        require(_value.length == 2, "Length mismatch");

        TokenGatingCondition
            memory _tokenGatingCondition = TokenGatingCondition(
                _tokenA,
                _tokenB,
                _operator,
                _comparator,
                _value
            );
        if (_tokenA == address(0) || _tokenB == address(0)) {
            require(uint8(_operator) == 1, "Operator cannot be AND");
        }
        tokenGatingDetails[_daoAddress].push(_tokenGatingCondition);

        daoDetails[_daoAddress].isTokenGatingApplied = true;
    }

    /// @dev Function to disable token gating
    /// @param _daoAddress address of the token contract
    function disableTokenGating(
        address _daoAddress
    ) external payable onlyAdmins(daoDetails[_daoAddress].gnosisAddress) {
        delete tokenGatingDetails[_daoAddress];
        daoDetails[_daoAddress].isTokenGatingApplied = false;
    }

    function buyGovernanceTokenWithNative(
        address payable _daoAddress,
        uint256 _numOfTokensToBuy,
        string memory _tokenURI,
        bool isNFTGovernance,
        bytes32[] calldata _proof
    ) external payable {
        require(
            daoDetails[_daoAddress].depositTokenAddress == wrappedTokenAddress,
            "Token not supported"
        );

        IWrappedToken(wrappedTokenAddress).deposit{value: msg.value}();

        if (isNFTGovernance) {
            buyGovernanceTokenERC721DAO(
                address(this),
                _daoAddress,
                _tokenURI,
                _numOfTokensToBuy,
                _proof
            );
        } else {
            buyGovernanceTokenERC20DAO(
                address(this),
                _daoAddress,
                _numOfTokensToBuy,
                _proof
            );
        }
    }

    /// @dev function to deposit tokens and receive dao tokens in return
    /// @param _daoAddress address of the token contract
    /// @param _numOfTokensToBuy amount of tokens to buy
    function buyGovernanceTokenERC20DAO(
        address _user,
        address payable _daoAddress,
        uint256 _numOfTokensToBuy,
        bytes32[] calldata _merkleProof
    ) public {
        if (daoDetails[_daoAddress].depositCloseTime < block.timestamp)
            revert DepositClosed();

        uint _totalDeposit = totalDeposit[msg.sender][_daoAddress];
        uint256 _totalAmount = (_numOfTokensToBuy *
            daoDetails[_daoAddress].pricePerToken) / 1e18;

        if (_totalDeposit == 0) {
            if (_totalAmount < daoDetails[_daoAddress].minDepositPerUser)
                revert AmountInvalid("_numOfTokensToBuy", _numOfTokensToBuy);
            if (_totalAmount > daoDetails[_daoAddress].maxDepositPerUser)
                revert AmountInvalid("_numOfTokensToBuy", _numOfTokensToBuy);
        } else {
            if (
                _totalDeposit + _totalAmount >
                daoDetails[_daoAddress].maxDepositPerUser
            ) revert AmountInvalid("_numOfTokensToBuy", _numOfTokensToBuy);
        }

        if (daoDetails[_daoAddress].isTokenGatingApplied) {
            ifTokenGatingApplied(_daoAddress);
        }

        uint256 daoBalance = IERC20(daoDetails[_daoAddress].depositTokenAddress)
            .balanceOf(_daoAddress);

        daoBalance += _totalAmount;
        totalDeposit[msg.sender][_daoAddress] += _totalAmount;

        if (
            daoBalance >
            (daoDetails[_daoAddress].pricePerToken *
                daoDetails[_daoAddress].distributionAmount) /
                1e18
        ) revert AmountInvalid("daoBalance", daoBalance);

        uint256 ownerShare = (_totalAmount *
            daoDetails[_daoAddress].ownerFeePerDepositPercent) /
            (FLOAT_HANDLER_TEN_4);

        uint256 userShare = _totalAmount - ownerShare;

        checkFeeAndMintTokens(
            _user,
            _daoAddress,
            daoDetails[_daoAddress].depositTokenAddress,
            userShare,
            ownerShare,
            _numOfTokensToBuy,
            _totalAmount,
            _merkleProof
        );
    }

    /// @dev This internal function performs required operations if token gating is applied
    function ifTokenGatingApplied(address _daoAddress) private view {
        TokenGatingCondition[] memory conditions = tokenGatingDetails[
            _daoAddress
        ];

        for (uint i; i < conditions.length; ) {
            address _tokenA = conditions[i].tokenA;
            address _tokenB = conditions[i].tokenB;
            uint _valueA = conditions[i].value[0];
            uint _valueB = conditions[i].value[1];
            uint _balanceA = IERC20(_tokenA).balanceOf(msg.sender);
            uint _balanceB = IERC20(_tokenB).balanceOf(msg.sender);
            if (conditions[i].operator == Operator.AND) {
                if (conditions[i].comparator == Comparator.GREATER) {
                    if (_balanceA < _valueA) revert InsufficientBalance();
                    if (_balanceB < _valueB) revert InsufficientBalance();
                } else if (conditions[i].comparator == Comparator.BELOW) {
                    if (_balanceA > _valueA) revert InsufficientBalance();
                    if (_balanceB > _valueB) revert InsufficientBalance();
                } else {
                    if (_balanceA != _valueA) revert InsufficientBalance();
                    if (_balanceB != _valueB) revert InsufficientBalance();
                }
            } else {
                if (conditions[i].comparator == Comparator.GREATER) {
                    if (_balanceA < _valueA && _balanceB < _valueB)
                        revert InsufficientBalance();
                } else if (conditions[i].comparator == Comparator.BELOW) {
                    if (_balanceA > _valueA && _balanceB > _valueB)
                        revert InsufficientBalance();
                } else {
                    if (_balanceA != _valueA && _balanceB != _valueB)
                        revert InsufficientBalance();
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev function to deposit tokens and receive dao tokens in return
    /// @param _daoAddress address of the token contract
    /// @param _tokenURI token URI of nft
    /// @param _numOfTokensToBuy amount of nfts to mint
    function buyGovernanceTokenERC721DAO(
        address _user,
        address payable _daoAddress,
        string memory _tokenURI,
        uint256 _numOfTokensToBuy,
        bytes32[] calldata _merkleProof
    ) public {
        if (daoDetails[_daoAddress].depositCloseTime < block.timestamp)
            revert DepositClosed();

        if (_numOfTokensToBuy == 0)
            revert AmountInvalid("_numOfTokensToBuy", _numOfTokensToBuy);

        uint _totalAmount = daoDetails[_daoAddress].pricePerToken *
            (_numOfTokensToBuy);

        if (daoDetails[_daoAddress].isTokenGatingApplied) {
            ifTokenGatingApplied(_daoAddress);
        }

        uint256 daoBalance = IERC20(daoDetails[_daoAddress].depositTokenAddress)
            .balanceOf(_daoAddress);

        daoBalance += _totalAmount;

        uint256 ownerShare = (_totalAmount *
            daoDetails[_daoAddress].ownerFeePerDepositPercent) /
            (FLOAT_HANDLER_TEN_4);
        uint256 userShare = _totalAmount - ownerShare;

        IERC20(daoDetails[_daoAddress].depositTokenAddress).safeTransferFrom(
            _user,
            daoDetails[_daoAddress].assetsStoredOnGnosis
                ? daoDetails[_daoAddress].gnosisAddress
                : _daoAddress,
            userShare
        );

        IERC20(daoDetails[_daoAddress].depositTokenAddress).safeTransferFrom(
            _user,
            ERC721DAO(_daoAddress).getERC721DAOdetails().ownerAddress,
            ownerShare
        );

        for (uint256 i; i < _numOfTokensToBuy; ) {
            ERC721DAO(_daoAddress).mintNft(msg.sender, _tokenURI, _merkleProof);
            unchecked {
                ++i;
            }
        }

        Emitter(emitterAddress).deposited(
            _daoAddress,
            msg.sender,
            daoDetails[_daoAddress].depositTokenAddress,
            _totalAmount,
            block.timestamp,
            daoDetails[_daoAddress].ownerFeePerDepositPercent,
            ownerShare
        );

        Emitter(emitterAddress).newUser(
            _daoAddress,
            msg.sender,
            daoDetails[_daoAddress].depositTokenAddress,
            _totalAmount,
            block.timestamp,
            _numOfTokensToBuy,
            false
        );
    }

    /// @dev This internal function checks if Fee is true and mints tokens accordingly
    function checkFeeAndMintTokens(
        address _user,
        address payable _daoAddress,
        address _depositTokenAddress,
        uint256 userShare,
        uint256 ownerShare,
        uint256 userGtTokens,
        uint256 _totalAmount,
        bytes32[] calldata _merkleProof
    ) internal {
        ERC20DAOdetails memory _details = ERC20DAO(_daoAddress)
            .getERC20DAOdetails();

        if (daoDetails[_daoAddress].ownerFeePerDepositPercent > 0) {
            IERC20(_depositTokenAddress).safeTransferFrom(
                _user,
                daoDetails[_daoAddress].assetsStoredOnGnosis
                    ? daoDetails[_daoAddress].gnosisAddress
                    : _daoAddress,
                userShare
            );

            IERC20(_depositTokenAddress).safeTransferFrom(
                _user,
                _details.ownerAddress,
                ownerShare
            );

            ERC20DAO(_daoAddress).mintToken(
                msg.sender,
                userGtTokens,
                _merkleProof
            );

            Emitter(emitterAddress).deposited(
                _daoAddress,
                msg.sender,
                _depositTokenAddress,
                _totalAmount,
                block.timestamp,
                daoDetails[_daoAddress].ownerFeePerDepositPercent,
                ownerShare
            );

            Emitter(emitterAddress).newUser(
                _daoAddress,
                msg.sender,
                _depositTokenAddress,
                _totalAmount,
                block.timestamp,
                userGtTokens,
                false
            );
        } else {
            IERC20(_depositTokenAddress).safeTransferFrom(
                _user,
                daoDetails[_daoAddress].assetsStoredOnGnosis
                    ? daoDetails[_daoAddress].gnosisAddress
                    : _daoAddress,
                _totalAmount
            );

            ERC20DAO(_daoAddress).mintToken(
                msg.sender,
                userGtTokens,
                _merkleProof
            );

            Emitter(emitterAddress).deposited(
                _daoAddress,
                msg.sender,
                _depositTokenAddress,
                _totalAmount,
                block.timestamp,
                daoDetails[_daoAddress].ownerFeePerDepositPercent,
                userGtTokens
            );

            Emitter(emitterAddress).newUser(
                _daoAddress,
                msg.sender,
                _depositTokenAddress,
                _totalAmount,
                block.timestamp,
                userGtTokens,
                false
            );
        }
    }
}
