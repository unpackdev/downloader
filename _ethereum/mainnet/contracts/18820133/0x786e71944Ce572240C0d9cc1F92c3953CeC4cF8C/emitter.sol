// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Initializable.sol";
import "./AccessControl.sol";

/// @title StationXFactory Emitter Contract
/// @dev Contract Emits events for Factory and Proxy
contract Emitter is Initializable, AccessControl {
    bytes32 constant ADMIN = keccak256("ADMIN");
    bytes32 public constant EMITTER = keccak256("EMITTER");
    bytes32 public constant FACTORY = keccak256("FACTORY");

    //FACTORY EVENTS
    event DefineContracts(
        address indexed factory,
        address ERC20ImplementationAddress,
        address ERC721ImplementationAddress,
        address emitterImplementationAddress
    );

    event ChangeMerkleRoot(
        address indexed factory,
        address indexed daoAddress,
        bytes32 newMerkleRoot
    );

    event CreateDaoErc20(
        address indexed deployerAddress,
        address indexed proxy,
        string name,
        string symbol,
        uint256 distributionAmount,
        uint256 pricePerToken,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 ownerFee,
        uint256 _days,
        uint256 quorum,
        uint256 threshold,
        address depositTokenAddress,
        address emitter,
        address gnosisAddress,
        bool isGovernanceActive,
        bool isTransferable,
        bool assetsStoredOnGnosis
    );

    event CreateDaoErc721(
        address indexed deployerAddress,
        address indexed proxy,
        string name,
        string symbol,
        string tokenURI,
        uint256 pricePerToken,
        uint256 distributionAmount,
        uint256 maxTokensPerUser,
        uint256 ownerFee,
        uint256 _days,
        uint256 quorum,
        uint256 threshold,
        address depositTokenAddress,
        address emitter,
        address gnosisAddress,
        bool isGovernanceActive,
        bool isTransferable,
        bool assetsStoredOnGnosis
    );

    event FactoryCreated(
        address indexed _ERC20Implementation,
        address indexed _ERC721Implementation,
        address _wrappedTokenAddress,
        address indexed _factory,
        address _emitter
    );

    //PROXY EVENTS
    event Deposited(
        address indexed _daoAddress,
        address indexed _depositor,
        address indexed _depositTokenAddress,
        uint256 _amount,
        uint256 _timeStamp,
        uint256 _ownerFee,
        uint256 _adminShare
    );

    event StartDeposit(
        address indexed _proxy,
        uint256 startTime,
        uint256 closeTime
    );

    event CloseDeposit(address indexed _proxy, uint256 closeTime);

    event UpdateMinMaxDeposit(
        address indexed _proxy,
        uint256 _minDeposit,
        uint256 _maxDeposit
    );

    event UpdateOwnerFee(address indexed _proxy, uint256 _ownerFee);

    event AirDropToken(
        address indexed _daoAddress,
        address _token,
        address _to,
        uint256 _amount
    );

    event MintGTToAddress(
        address indexed _daoAddress,
        uint256[] _amount,
        address[] _userAddress
    );

    event UpdateGovernanceSettings(
        address indexed _daoAddress,
        uint256 _quorum,
        uint256 _threshold
    );

    event UpdateDistributionAmount(
        address indexed _daoAddress,
        uint256 _amount
    );

    event UpdatePricePerToken(address indexed _daoAddress, uint256 _amount);

    event SendCustomToken(
        address indexed _daoAddress,
        address _token,
        uint256[] _amount,
        address[] _addresses
    );

    event NewUser(
        address indexed _daoAddress,
        address indexed _depositor,
        address indexed _depositTokenAddress,
        uint256 _depositTokenAmount,
        uint256 _timeStamp,
        uint256 _gtToken,
        bool _isAdmin
    );

    //nft events
    event MintNft(
        address indexed _to,
        address indexed _daoAddress,
        string _tokenURI,
        uint256 _tokenId
    );

    event UpdateMaxTokensPerUser(
        address indexed _daoAddress,
        uint256 _maxTokensPerUser
    );

    event UpdateTotalSupplyOfToken(
        address indexed _daoAddress,
        uint256 _totalSupplyOfToken
    );

    event UpdateTokenTransferability(
        address indexed _daoAddress,
        bool _isTokenTransferable
    );

    event WhitelistAddress(
        address indexed _daoAddress,
        address indexed _address
    );

    event RemoveWhitelistAddress(
        address indexed _daoAddress,
        address indexed _address
    );

    address public factoryAddress;

    function initialize(
        address _ERC20Implementation,
        address _ERC721Implementation,
        address _wrappedTokenAddress,
        address _factory
    ) external initializer {
        _grantRole(ADMIN, msg.sender);
        _grantRole(FACTORY, _factory);
        factoryAddress = _factory;
        emit FactoryCreated(
            _ERC20Implementation,
            _ERC721Implementation,
            _wrappedTokenAddress,
            _factory,
            address(this)
        );
    }

    function changeFactory(address _newFactory) external onlyRole(ADMIN) {
        _revokeRole(FACTORY, factoryAddress);
        _grantRole(FACTORY, _newFactory);
        factoryAddress = _newFactory;
    }

    function allowActionContract(
        address _actionContract
    ) external onlyRole(ADMIN) {
        _grantRole(EMITTER, _actionContract);
    }

    function defineContracts(
        address ERC20ImplementationAddress,
        address ERC721ImplementationAddress,
        address emitterImplementationAddress
    ) external payable onlyRole(FACTORY) {
        emit DefineContracts(
            msg.sender,
            ERC20ImplementationAddress,
            ERC721ImplementationAddress,
            emitterImplementationAddress
        );
    }

    function changeMerkleRoot(
        address factory,
        address daoAddress,
        bytes32 newMerkleRoot
    ) external payable onlyRole(FACTORY) {
        emit ChangeMerkleRoot(factory, daoAddress, newMerkleRoot);
    }

    function createDaoErc20(
        address _deployerAddress,
        address _proxy,
        string memory _name,
        string memory _symbol,
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _ownerFee,
        uint256 _totalDays,
        uint256 _quorum,
        uint256 _threshold,
        address _emitter,
        address _depositTokenAddress,
        address _gnosisAddress,
        bool _isGovernanceActive,
        bool isTransferable,
        bool assetsStoredOnGnosis
    ) external payable onlyRole(FACTORY) {
        _grantRole(EMITTER, _proxy);
        _grantRole(EMITTER, msg.sender);
        emit CreateDaoErc20(
            _deployerAddress,
            _proxy,
            _name,
            _symbol,
            _distributionAmount,
            _pricePerToken,
            _minDeposit,
            _maxDeposit,
            _ownerFee,
            _totalDays,
            _quorum,
            _threshold,
            _depositTokenAddress,
            _emitter,
            _gnosisAddress,
            _isGovernanceActive,
            isTransferable,
            assetsStoredOnGnosis
        );
    }

    function createDaoErc721(
        address _deployerAddress,
        address _proxy,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _pricePerToken,
        uint256 _distributionAmount,
        uint256 _maxTokensPerUser,
        uint256 _ownerFee,
        uint256 _totalDays,
        uint256 _quorum,
        uint256 _threshold,
        address _depositTokenAddress,
        address _emitter,
        address _gnosisAddress,
        bool _isGovernanceActive,
        bool isTransferable,
        bool assetsStoredOnGnosis
    ) external payable onlyRole(FACTORY) {
        _grantRole(EMITTER, _proxy);
        _grantRole(EMITTER, msg.sender);

        emit CreateDaoErc721(
            _deployerAddress,
            _proxy,
            _name,
            _symbol,
            _tokenURI,
            _pricePerToken,
            _distributionAmount,
            _maxTokensPerUser,
            _ownerFee,
            _totalDays,
            _quorum,
            _threshold,
            _depositTokenAddress,
            _emitter,
            _gnosisAddress,
            _isGovernanceActive,
            isTransferable,
            assetsStoredOnGnosis
        );
    }

    function deposited(
        address _daoAddress,
        address _depositor,
        address _depositTokenAddress,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _ownerFee,
        uint256 _adminShare
    ) external onlyRole(EMITTER) {
        emit Deposited(
            _daoAddress,
            _depositor,
            _depositTokenAddress,
            _amount,
            _timestamp,
            _ownerFee,
            _adminShare
        );
    }

    function newUser(
        address _daoAddress,
        address _depositor,
        address _depositTokenAddress,
        uint256 _depositTokenAmount,
        uint256 _timeStamp,
        uint256 _gtToken,
        bool _isAdmin
    ) external onlyRole(EMITTER) {
        emit NewUser(
            _daoAddress,
            _depositor,
            _depositTokenAddress,
            _depositTokenAmount,
            _timeStamp,
            _gtToken,
            _isAdmin
        );
    }

    function startDeposit(
        address _proxy,
        uint256 _startTime,
        uint256 _closeTime
    ) external onlyRole(EMITTER) {
        emit StartDeposit(_proxy, _startTime, _closeTime);
    }

    function closeDeposit(
        address _proxy,
        uint256 _closeTime
    ) external onlyRole(EMITTER) {
        emit CloseDeposit(_proxy, _closeTime);
    }

    function updateMinMaxDeposit(
        address _proxy,
        uint256 _minDeposit,
        uint256 _maxDeposit
    ) external onlyRole(EMITTER) {
        emit UpdateMinMaxDeposit(_proxy, _minDeposit, _maxDeposit);
    }

    function updateOwnerFee(
        address _proxy,
        uint256 _ownerFee
    ) external onlyRole(EMITTER) {
        emit UpdateOwnerFee(_proxy, _ownerFee);
    }

    function airDropToken(
        address _proxy,
        address _token,
        address _to,
        uint256 _amount
    ) external onlyRole(EMITTER) {
        emit AirDropToken(_proxy, _token, _to, _amount);
    }

    function mintGTToAddress(
        address _proxy,
        uint256[] memory _amount,
        address[] memory _userAddress
    ) external onlyRole(EMITTER) {
        emit MintGTToAddress(_proxy, _amount, _userAddress);
    }

    function updateGovernanceSettings(
        address _proxy,
        uint256 _quorum,
        uint256 _threshold
    ) external onlyRole(EMITTER) {
        emit UpdateGovernanceSettings(_proxy, _quorum, _threshold);
    }

    function updateDistributionAmount(
        address _daoAddress,
        uint256 _distributionAmount
    ) external onlyRole(EMITTER) {
        emit UpdateDistributionAmount(_daoAddress, _distributionAmount);
    }

    function updatePricePerToken(
        address _daoAddress,
        uint256 _pricePerToken
    ) external onlyRole(EMITTER) {
        emit UpdatePricePerToken(_daoAddress, _pricePerToken);
    }

    function sendCustomToken(
        address _daoAddress,
        address _token,
        uint256[] memory _amount,
        address[] memory _addresses
    ) external onlyRole(EMITTER) {
        emit SendCustomToken(_daoAddress, _token, _amount, _addresses);
    }

    function mintNft(
        address _to,
        address _implementation,
        string memory _tokenURI,
        uint256 _tokenId
    ) external onlyRole(EMITTER) {
        emit MintNft(_to, _implementation, _tokenURI, _tokenId);
    }

    function updateMaxTokensPerUser(
        address _nftAddress,
        uint256 _maxTokensPerUser
    ) external onlyRole(EMITTER) {
        emit UpdateMaxTokensPerUser(_nftAddress, _maxTokensPerUser);
    }

    function updateTotalSupplyOfToken(
        address _nftAddress,
        uint256 _totalSupplyOfToken
    ) external onlyRole(EMITTER) {
        emit UpdateTotalSupplyOfToken(_nftAddress, _totalSupplyOfToken);
    }

    function updateTokenTransferability(
        address _nftAddress,
        bool _isTokenTransferable
    ) external onlyRole(EMITTER) {
        emit UpdateTokenTransferability(_nftAddress, _isTokenTransferable);
    }

    function whitelistAddress(
        address _nftAddress,
        address _address
    ) external onlyRole(EMITTER) {
        emit WhitelistAddress(_nftAddress, _address);
    }

    function removeWhitelistAddress(
        address _nftAddress,
        address _address
    ) external onlyRole(EMITTER) {
        emit RemoveWhitelistAddress(_nftAddress, _address);
    }
}
