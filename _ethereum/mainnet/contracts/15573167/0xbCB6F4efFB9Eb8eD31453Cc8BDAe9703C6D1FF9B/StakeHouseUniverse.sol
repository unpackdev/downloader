pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import "./Initializable.sol";
import "./BeaconProxy.sol";
import "./ERC1967Proxy.sol";
import "./StakeHouseUUPSCoreModule.sol";
import "./IStakeHouseUniverse.sol";
import "./StakeHouseRegistry.sol";
import "./Banking.sol";
import "./savETHManager.sol";
import "./StakeHouseAccessControls.sol";
import "./CommunityCentral.sol";
import "./TransactionRouter.sol";
import "./AccountManager.sol";

/// @title Universe of StakeHouses. All StakeHouses are deployed from this factory
/// @dev It's possible to index all StakeHouses and their members from this contract
/// @dev A StakeHouse is a KNOT in the universe and its members are a collection of further KNOTs (for indexing)
contract StakeHouseUniverse is Initializable, IStakeHouseUniverse, Banking, StakeHouseUUPSCoreModule {

    /// @notice Address of the community central entry point contract
    CommunityCentral public communityCentral;

    /// @notice Address of the StakeHouse protocol access control role ledger
    StakeHouseAccessControls public accessControls;

    /// @notice Address of the manager of deposits
    AccountManager public accountManager;

    /// @notice Address of the deposit contract transaction manager
    TransactionRouter public transactionManager;

    /// @notice Adaptor for public functions of savETH registry
    savETHManager public savETHMan;

    /// @dev Address of the contract that knows the implementation address for stake house logic
    address private stakeHouseRegistryBeacon;

    /// @notice Essentially equal to the total number of Stakehouses in the universe
    uint256 public stakeHouseKNOTIndexPointer;

    /// @notice KNOT index assigned to a StakeHouse
    mapping(address => uint256) public stakeHouseToKNOTIndex;

    /// @notice StakeHouse assigned to a KNOT index
    mapping(uint256 => address) public knotIndexToStakeHouse;

    /// @notice Member ID -> assigned StakeHouse. Iron rule is that member can only be active in 1 StakeHouse
    mapping(bytes => address) public memberKnotToStakeHouse;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _accessControls Address for governing admin methods
    /// @param _slotRegistryLogic Logic contract for the slot settlement registry
    /// @param _sETHBeacon Beacon contract for sETH token
    /// @param _saveETHRegistryLogic Logic contract for savETH registry
    /// @param _saveETHLogic Logic contract for SaveETH token
    /// @param _stakeHouseRegistryBeacon Beacon contract containing the implementation of a stake house
    /// @param _accountManagerLogic Internal account manager and EF Contract deposit storage
    function init(
        StakeHouseAccessControls _accessControls,
        address _slotRegistryLogic,
        address _sETHBeacon,
        address _saveETHRegistryLogic,
        address _dETHLogic,
        address _saveETHLogic,
        address _stakeHouseRegistryBeacon,
        address _accountManagerLogic,
        address _transactionManagerLogic,
        address _savETHManagerLogic,
        CommunityCentral _communityCentral
    ) external initializer {
        {
            require(_accessControls.isAdmin(msg.sender), "Only admin");
            require(_slotRegistryLogic != address(0), "SLOT registry cannot be zero");
            require(_sETHBeacon != address(0), "sETH beacon cannot be zero address");
            require(_saveETHRegistryLogic != address(0), "savETH registry cannot be zero");
            require(_saveETHLogic != address(0), "savETH logic cannot be zero");
            require(_dETHLogic != address(0), "dETH logic cannot be zero");
            require(_stakeHouseRegistryBeacon != address(0), "Registry beacon cannot be zero address");
            require(_accountManagerLogic != address(0), "Account manager logic cannot be zero address");
            require(_transactionManagerLogic != address(0), "TX manager logic cannot be zero address");
        }

        accessControls = _accessControls;
        communityCentral = _communityCentral;

        // deploy account manager and transaction manager
        {
            ERC1967Proxy accountManagerProxy = new ERC1967Proxy(
                _accountManagerLogic,
                abi.encodeCall(AccountManager(_accountManagerLogic).init, (StakeHouseUniverse(address(this))))
            );

            accountManager = AccountManager(address(accountManagerProxy));

            ERC1967Proxy transactionManagerProxy = new ERC1967Proxy(
                _transactionManagerLogic,
                abi.encodeCall(
                    TransactionRouter(_transactionManagerLogic).init,
                    (StakeHouseUniverse(address(this)), address(accountManagerProxy))
                )
            );

            transactionManager = TransactionRouter(address(transactionManagerProxy));
        }

        // deploy registries
        ERC1967Proxy settlementProxy = new ERC1967Proxy(
            _slotRegistryLogic,
            abi.encodeCall(
                SlotSettlementRegistry(_slotRegistryLogic).init,
                (StakeHouseUniverse(address(this)), _sETHBeacon)
            )
        );

        slotRegistry = SlotSettlementRegistry(address(settlementProxy));

        ERC1967Proxy saveETHRegistryProxy = new ERC1967Proxy(
            _saveETHRegistryLogic,
            abi.encodeCall(
                savETHRegistry(_saveETHRegistryLogic).init,
                (StakeHouseUniverse(address(this)), _dETHLogic, _saveETHLogic)
            )
        );

        saveETHRegistry = savETHRegistry(address(saveETHRegistryProxy));

        ERC1967Proxy saveETHManagerProxy = new ERC1967Proxy(
            _savETHManagerLogic,
            abi.encodeCall(
                savETHManager(_savETHManagerLogic).init,
                (StakeHouseUniverse(address(this)))
            )
        );

        savETHMan = savETHManager(address(saveETHManagerProxy));

        // store beacon to registry
        stakeHouseRegistryBeacon = _stakeHouseRegistryBeacon;

        __StakeHouseUUPSCoreModule_init(StakeHouseUniverse(address(this)));

        emit CoreModulesInit();
    }

    /// @inheritdoc IStakeHouseUniverse
    function newStakeHouse(
        address _summoner,
        string calldata _ticker,
        bytes calldata _firstMember,
        uint256 _savETHIndexId
    ) external override onlyModule returns (address) {
        require(msg.sender == address(accountManager), "Only account manager");
        require(_summoner != address(0), "Summoner cannot be zero address");
        require(memberKnotToStakeHouse[_firstMember] == address(0), "Knot already registered");

        // Deploy a proxy to a Stake House and call init during proxy deployment
        BeaconProxy stakeHouseProxy = new BeaconProxy(
            stakeHouseRegistryBeacon,
            abi.encodeCall(
                StakeHouseRegistry(stakeHouseRegistryBeacon).init,
                (StakeHouseUniverse(address(this)))
            )
        );

        address stakeHouseAddress = address(stakeHouseProxy);

        // Assign an index to the deployed StakeHouse starting at 1 (so we increment the pointer first)
        unchecked { // number of stakehouses unlikely to exceed ( (2 ^ 256) - 1 )
            stakeHouseToKNOTIndex[stakeHouseAddress] = ++stakeHouseKNOTIndexPointer;
        }

        knotIndexToStakeHouse[stakeHouseKNOTIndexPointer] = stakeHouseAddress;

        // Set up core modules
        slotRegistry.deployStakeHouseShareToken(stakeHouseAddress);

        // Every member is associated with 1 house
        memberKnotToStakeHouse[_firstMember] = stakeHouseAddress;

        // either return _savETHIndexId or create a new index for the caller
        uint256 savETHIndexId = _getOrCreateSavETHIndex(_savETHIndexId, _summoner);

        // Add the first member to the StakeHouse and issue the KNOT share tokens
        _addMember(stakeHouseAddress, _firstMember, _summoner, savETHIndexId);

        // mint a brandNFT
        uint256 brandId = communityCentral.mintBrand(
            _ticker,
            _summoner,
            _firstMember
        );

        // Emit an event for indexers and return the address of the stake house
        emit NewStakeHouse(stakeHouseAddress, brandId);

        return stakeHouseAddress;
    }

    /// @inheritdoc IStakeHouseUniverse
    function addMemberToExistingHouse(
        address _stakeHouse,
        bytes calldata _memberId,
        address _applicant,
        uint256 _brandTokenId,
        uint256 _savETHIndexId
    ) external override onlyModule {
        _addMemberToStakeHouse(_stakeHouse, _memberId, _applicant, _savETHIndexId);

        communityCentral.associateSlotWithBrand(_brandTokenId, _memberId);

        emit MemberAddedToExistingStakeHouse(_stakeHouse);
    }

    /// @inheritdoc IStakeHouseUniverse
    function addMemberToHouseAndCreateBrand(
        address _stakeHouse,
        bytes calldata _memberId,
        address _applicant,
        string calldata _ticker,
        uint256 _savETHIndexId
    ) external override onlyModule {
        _addMemberToStakeHouse(_stakeHouse, _memberId, _applicant, _savETHIndexId);

        // mint a brandNFT which automatically associates the KNOT with the brand
        uint256 brandId = communityCentral.mintBrand(
            _ticker,
            _applicant,
            _memberId
        );

        emit MemberAddedToExistingStakeHouseAndBrandCreated(_stakeHouse, brandId);
    }

    /// @inheritdoc IStakeHouseUniverse
    function rageQuitKnot(
        address _stakeHouse,
        bytes calldata _memberId,
        address _rageQuitter,
        uint256 _amountOfETHInDepositQueue
    ) external override onlyModule {
        // auto-create index for rage quit
        _addMemberToStakeHouse(_stakeHouse, _memberId, _rageQuitter, 0);

        // As this function is for a rage quit BEFORE the derivatives were ever minted, _rageQuitter is passed multiple times
        address[] memory _collateralisedOwner = new address[](1);
        _collateralisedOwner[0] = _rageQuitter;

        slotRegistry.rageQuitKnotOnBehalfOf(
            _stakeHouse,
            _memberId,
            _rageQuitter,
            _collateralisedOwner,
            _rageQuitter,
            _rageQuitter,
            _amountOfETHInDepositQueue
        );
    }

    /// @inheritdoc IStakeHouseUniverse
    function numberOfStakeHouses() external override view returns (uint256) {
        return stakeHouseKNOTIndexPointer;
    }

    /// @inheritdoc IStakeHouseUniverse
    function stakeHouseAtIndex(uint256 _index) public override view returns (address) {
        return knotIndexToStakeHouse[_index];
    }

    /// @inheritdoc IStakeHouseUniverse
    function numberOfSubKNOTsAtIndex(uint256 _index) external override view returns (uint256) {
        return StakeHouseRegistry(stakeHouseAtIndex(_index)).numberOfMemberKNOTs();
    }

    /// @inheritdoc IStakeHouseUniverse
    function subKNOTAtIndexCoordinates(uint256 _index, uint256 _subIndex) public override view returns (bytes memory) {
        return StakeHouseRegistry(stakeHouseAtIndex(_index)).memberIndexToMemberId(_subIndex);
    }

    /// @inheritdoc IStakeHouseUniverse
    function stakeHouseKnotInfoGivenCoordinates(uint256 _index, uint256 _subIndex) external override view returns (
        address stakeHouse,     // Address of registered StakeHouse
        address sETHAddress,    // Address of sETH address associated with StakeHouse
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint256 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    ) {
        return stakeHouseKnotInfo(subKNOTAtIndexCoordinates(_index, _subIndex));
    }

    /// @inheritdoc IStakeHouseUniverse
    function stakeHouseKnotInfo(bytes memory _memberId) public override view returns (
        address stakeHouse,     // Address of registered StakeHouse
        address sETHAddress,    // Address of sETH address associated with StakeHouse
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint256 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    ) {
        require(memberKnotToStakeHouse[_memberId] != address(0), "Member is not assigned to any StakeHouse");
        address _stakeHouse = memberKnotToStakeHouse[_memberId];
        address _sETHAddress = address(slotRegistry.stakeHouseShareTokens(_stakeHouse));

        (
            address _applicant,
            uint256 _knotMemberIndex,
            uint256 _flags,
            bool _isActive
        ) = StakeHouseRegistry(_stakeHouse).getMemberInfo(_memberId);

        return (
            _stakeHouse,
            _sETHAddress,
            _applicant,
            _knotMemberIndex,
            _flags,
            _isActive
        );
    }

    /// @dev Internal and re-usable method for adding a KNOT to an existing house
    function _addMemberToStakeHouse(
        address _stakeHouse,
        bytes calldata _memberId,
        address _applicant,
        uint256 _savETHIndexId
    ) internal {
        require(msg.sender == address(accountManager), "Only account manager");
        require(stakeHouseToKNOTIndex[_stakeHouse] > 0, "Only universe StakeHouse");
        require(memberKnotToStakeHouse[_memberId] == address(0), "Knot already registered");
        require(_applicant != address(0), "Applicant cannot be zero address");

        // Every member is associated with 1 house
        memberKnotToStakeHouse[_memberId] = _stakeHouse;

        // either return _savETHIndexId or create a new index for the caller
        uint256 savETHIndexId = _getOrCreateSavETHIndex(_savETHIndexId, _applicant);

        _addMember(_stakeHouse, _memberId, _applicant, savETHIndexId);
    }

    /// @dev Helper method which checks the index ID. If it is zero, it uses this to trigger the creation of an index
    /// @param _indexId ID of an index or zero if there is a user request to create a new index
    /// @param _caller Will become the owner of the new index if one is created
    function _getOrCreateSavETHIndex(uint256 _indexId, address _caller) internal returns (uint256) {
        uint256 savETHIndexId = _indexId;

        if (savETHIndexId == 0) {
            savETHIndexId = saveETHRegistry.createIndex(_caller);
        }

        return savETHIndexId;
    }
}
