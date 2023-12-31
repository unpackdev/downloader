// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/// @author The ferrum network.
/// @title This is a vesting contract named as IronVest.
/// @dev This contract is upgradeable please use a framework i.e truffle or hardhat for deploying it.
/// @notice This contract contains the power of accesscontrol.
/// There are two different vesting defined in the contract with different functionalities.
/// Have fun reading it. Hopefully it's bug-free. God Bless.
contract IronVest is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    /// @notice Declaration of token interface with SafeErc20.
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice This struct will save all the pool information about simple vesting i.e addVesting().
    struct PoolInfo {
        string poolName;
        uint256 startTime; /// block.timestamp while creating new pool.
        uint256 vestingEndTime; /// time stamp when to end the vesting.
        address tokenAddress; /// token which we want to vest in the contract.
        uint256 totalVestedTokens; /// total amount of tokens.
        address[] usersAddresses; /// addresses of users an array.
        uint256[] usersAlloc; /// allocation to user with respect to usersAddresses.
    }

    /// @notice Used to store information about the user in simple vesting.
    struct UserInfo {
        uint256 allocation; /// total allocation to a user.
        uint256 claimedAmount; /// claimedAmnt + claimed.
        uint256 remainingToBeClaimable; /// remaining claimable fully claimable once time ended.
        uint256 lastWithdrawal; /// block.timestamp used for internal claimable calculation
        uint256 releaseRatePerSec; /// calculated as vestingTime/(vestingTime-starttime)
    }

    /// @notice This struct will save all the pool information about simple vesting i.e addCliffVesting().
    struct CliffPoolInfo {
        string poolName;
        uint256 startTime; /// block.timestamp while creating new pool.
        uint256 vestingEndTime; /// total time to end cliff vesting.
        uint256 cliffVestingEndTime; /// time in which user can vest cliff tokens should be less than vestingendtime.
        uint256 nonCliffVestingPeriod; /// calculated as cliffPeriod-vestingEndTime. in seconds
        uint256 cliffPeriodEndTime; ///in this time tenure the tokens keep locked in contract. a timestamp
        address tokenAddress; /// token which we want to vest in the contract.
        uint256 totalVestedTokens; /// total amount of tokens.
        uint256 cliffLockPercentage10000; /// for percentage calculation using 10000 instead 100.
        address[] usersAddresses; /// addresses of users an array.
        uint256[] usersAlloc; /// allocation to user with respect to usersAddresses.
    }

    /// @notice Used to store information about the user in cliff vesting.
    struct UserCliffInfo {
        uint256 allocation; /// total allocation cliff+noncliff
        uint256 cliffAlloc; /// (totalallocation*cliffPercentage)/10000
        uint256 claimedAmnt; /// claimedAmnt-claimableClaimed.
        uint256 tokensReleaseTime; /// the time we used to start vesting tokens.
        uint256 remainingToBeClaimableCliff; /// remaining claimable fully claimable once time ended.
        uint256 cliffReleaseRatePerSec; /// calculated as cliffAlloc/(cliffendtime -cliffPeriodendtime).
        uint256 cliffLastWithdrawal; /// block.timestamp used for internal claimable calculation.
    }

    /// @notice Used to store information about the user of non cliff in cliff vesting.
    struct UserNonCliffInfo {
        uint256 allocation; /// total allocation cliff+noncliff
        uint256 nonCliffAlloc; /// (totalallocation-cliffalloc)
        uint256 claimedAmnt; /// claimedAmnt-claimableClaimed
        uint256 tokensReleaseTime; /// the time we used to start vesting tokens.
        uint256 remainingToBeClaimableNonCliff; /// remaining claimable fully claimable once time ended.
        uint256 nonCliffReleaseRatePerSec; /// calculated as nonCliffAlloc/(cliffVestingEndTime-vestingEndTime).
        uint256 nonCliffLastWithdrawal; /// used for internal claimable calculation.
    }

    /// @notice Vester role initilization.
    bytes32 public constant VESTER_ROLE = keccak256("VESTER_ROLE");
    /// @notice Public variable to strore contract name.
    string public vestingContractName;
    /// @notice Unique identity of contract.
    uint256 public vestingPoolSize;
    /// @notice Signer address. Transaction supposed to be sign be this address.
    address public signer;

    /// Cliff mapping with the check if the specific pool relate to the cliff vesting or not.
    mapping(uint256 => bool) public cliff;
    /// Double mapping to check user information by address and poolid for cliff vesting.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// Double mapping to check user information by address and poolid for cliff vesting.
    mapping(uint256 => mapping(address => UserCliffInfo)) public userCliffInfo;
    /// Double mapping to check user information by address and poolid for cliff vesting.
    mapping(uint256 => mapping(address => UserNonCliffInfo))
        public userNonCliffInfo;
    /// Hash Information to avoid the replay from same _messageHash
    mapping(bytes32 => bool) public usedHashes;
    /// Pool information against specific poolid for simple vesting.
    mapping(uint256 => PoolInfo) internal _poolInfo;
    /// Pool information against specific poolid for cliff vesting.
    mapping(uint256 => CliffPoolInfo) internal _cliffPoolInfo;

    /// @dev Creating events for all necessary values while adding simple vesting.
    /// @notice vester address and poolId are indexed.
    event AddVesting(
        address indexed vester,
        uint256 indexed poolId,
        string poolName,
        uint256 startTime,
        uint256 vestingEndTime,
        address tokenAddress,
        uint256 totalVestedTokens,
        address[] usersAddresses,
        uint256[] usersAlloc
    );

    /// @dev Creating events for all necessary values while adding cliff vesting.
    /// @notice vester address and poolId are indexed.
    event CliffAddVesting(
        address indexed vester,
        uint256 indexed poolId,
        string poolName,
        uint256 vestingEndTime,
        uint256 cliffVestingEndTime,
        uint256 nonCliffVestingPeriod,
        uint256 cliffPeriodEndTime,
        address tokenAddress,
        uint256 totalVestedTokens,
        address[] usersAddresses,
        uint256[] usersAlloc
    );

    /// @dev Whenever user claim their amount from simple vesting.
    /// @notice beneficiary address and poolId are indexed.
    event Claim(
        uint256 indexed poolId,
        uint256 claimed,
        address indexed beneficiary,
        uint256 remaining
    );

    /// @dev Whenever user claim their cliff amount from cliff vesting.
    /// @notice beneficiary address and poolId are indexed.
    event CliffClaim(
        uint256 indexed poolId,
        uint256 claimed,
        address indexed beneficiary,
        uint256 remaining
    );

    /// @dev Whenever user claim their non cliff amount from cliff vesting.
    /// @notice beneficiary address and poolId are indexed.
    event NonCliffClaim(
        uint256 indexed poolId,
        uint256 claimed,
        address indexed beneficiary,
        uint256 remaining
    );

    /// @notice Modifier to check if vester.
    modifier onlyVester() {
        require(
            hasRole(VESTER_ROLE, _msgSender()),
            "AccessDenied : Only Vester Call This Function"
        );
        _;
    }

    /// @notice Modifier to check if DEFAULT_ADMIN and Deployer of contract.
    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AccessDenied : Only Admin Call This Function"
        );
        _;
    }

    /// @dev deploy the contract by upgradeable proxy by any framewrok.
    /// @param _vestingName : A name to our vesting contract.
    /// @param _signer : An address verification for facing the replay attack issues.
    /// @notice Contract is upgradeable need initilization and deployer is default admin.
    function initialize(string memory _vestingName, address _signer)
        external
        initializer
    {
        __ReentrancyGuard_init();
        __AccessControl_init();
        vestingContractName = _vestingName;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(VESTER_ROLE, _msgSender());
        signer = _signer;
    }

    /// @dev Only callable by vester.
    /// @param _poolName : Pool name is supposed to be any string.
    /// @param _vestingEndTime : Vesting time is tenure in which token will be released.
    /// @param _tokenAddress : Token address related to the vested token.
    /// @param _usersAddresses : Users addresses whom the vester want to allocate tokens and it is an array.
    /// @param _userAlloc : Users allocation of tokens with respect to address.
    /// @param _signature : Signature of the signed by signer.
    /// @param _keyHash : Specific keyhash value formed to stop replay.
    /// @notice Create a new vesting.
    function addVesting(
        string memory _poolName,
        uint256 _vestingEndTime,
        address _tokenAddress,
        address[] memory _usersAddresses,
        uint256[] memory _userAlloc,
        bytes memory _signature,
        bytes memory _keyHash
    ) external onlyVester nonReentrant {
        require(
            _usersAddresses.length == _userAlloc.length,
            "IIronVest Array : Length of _usersAddresses And _userAlloc Must Be Equal"
        );
        require(
            _vestingEndTime > block.timestamp,
            "IIronVest : Vesting End Time Should Be Greater Than Current Time"
        );
        require(
            signatureVerification(
                _signature,
                _poolName,
                _tokenAddress,
                _keyHash
            ) == signer,
            "Signer : Invalid signer"
        );
        uint256 totalVesting;
        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            totalVesting += _userAlloc[i];
            userInfo[vestingPoolSize][_usersAddresses[i]] = UserInfo(
                _userAlloc[i],
                0,
                _userAlloc[i],
                block.timestamp,
                _userAlloc[i] / (_vestingEndTime - block.timestamp)
            );
        }
        _poolInfo[vestingPoolSize] = PoolInfo(
            _poolName,
            block.timestamp,
            _vestingEndTime,
            _tokenAddress,
            totalVesting,
            _usersAddresses,
            _userAlloc
        );
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            totalVesting
        );
        emit AddVesting(
            _msgSender(),
            vestingPoolSize,
            _poolName,
            block.timestamp,
            _vestingEndTime,
            _tokenAddress,
            totalVesting,
            _usersAddresses,
            _userAlloc
        );
        vestingPoolSize = vestingPoolSize + 1;
        usedHashes[_messageHash(_poolName, _tokenAddress, _keyHash)] = true;
    }

    /// @dev User must have allocation in the pool.
    /// @notice This is for claiming simple vesting.
    /// @param _poolId : poolId from which pool user want to withdraw.
    /// @notice Secured by nonReentrant
    function claim(uint256 _poolId) external nonReentrant {
        uint256 transferAble = claimable(_poolId, _msgSender());
        require(transferAble > 0, "IIronVest : Invalid TransferAble");
        IERC20Upgradeable(_poolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        UserInfo storage info = userInfo[_poolId][_msgSender()];
        uint256 claimed = (info.claimedAmount + transferAble);
        uint256 remainingToBeClaimable = info.allocation - claimed;
        info.claimedAmount = claimed;
        info.remainingToBeClaimable = remainingToBeClaimable;
        info.lastWithdrawal = block.timestamp;

        emit Claim(_poolId, transferAble, _msgSender(), remainingToBeClaimable);
    }

    /// @dev Only callable by vester.
    /// @param _poolName : Pool name is supposed to be any string.
    /// @param _vestingEndTime : Vesting time is tenure in which token will be released.
    /// @param _cliffVestingEndTime : cliff vesting time is the end time for releasing cliff tokens.
    /// @param _cliffPeriodEndTime : cliff period is a period in which token will be locked.
    /// @param _tokenAddress : Token address related to the vested token.
    /// @param _cliffPercentage10000 : cliff percentage defines how may percentage should be allocated to cliff tokens.
    /// @param _usersAddresses : Users addresses whom the vester want to allocate tokens and it is an array.
    /// @param _userAlloc : Users allocation of tokens with respect to address.
    /// @param _signature : Signature of the signed by signer.
    /// @param _keyHash : Specific keyhash value formed to stop replay.
    /// @notice Create a new vesting with cliff.
    function addCliffVesting(
        string memory _poolName,
        uint256 _vestingEndTime,
        uint256 _cliffVestingEndTime,
        uint256 _cliffPeriodEndTime,
        address _tokenAddress,
        uint256 _cliffPercentage10000,
        address[] memory _usersAddresses,
        uint256[] memory _userAlloc,
        bytes memory _signature,
        bytes memory _keyHash
    ) external onlyVester nonReentrant {
        require(
            _usersAddresses.length == _userAlloc.length,
            "IIronVest Array : Length of _usersAddresses And _userAlloc Must Be Equal"
        );
        require(
            _cliffVestingEndTime < _vestingEndTime,
            "IIronVest : Cliff Vesting End Time Must Be Lesser Than Vesting Time"
        );
        require(
            _cliffVestingEndTime > _cliffPeriodEndTime,
            "IIronVest : Cliff Vesting Time Must Be Greater Than Cliff Period"
        );
        require(
            _cliffPeriodEndTime > block.timestamp,
            "IIronVest : Cliff Vesting Time Must Be Lesser Than Vesting Time"
        );
        require(
            signatureVerification(
                _signature,
                _poolName,
                _tokenAddress,
                _keyHash
            ) == signer,
            "Signer : Invalid signer"
        );
        require(
            _cliffPercentage10000 <= 5000,
            "Percentage : Percentage Should Be less Than 50%"
        );
        uint256 totalVesting;
        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            uint256 cliffAlloc = (_userAlloc[i] * _cliffPercentage10000) /
                10000;
            totalVesting += _userAlloc[i];
            uint256 nonCliffReaminingTobeclaimable = _userAlloc[i] - cliffAlloc;
            userCliffInfo[vestingPoolSize][_usersAddresses[i]] = UserCliffInfo(
                _userAlloc[i],
                cliffAlloc,
                0,
                _cliffPeriodEndTime,
                cliffAlloc,
                (cliffAlloc) / (_cliffVestingEndTime - _cliffPeriodEndTime),
                _cliffPeriodEndTime
            );
            userNonCliffInfo[vestingPoolSize][
                _usersAddresses[i]
            ] = UserNonCliffInfo(
                _userAlloc[i],
                nonCliffReaminingTobeclaimable,
                0,
                _cliffPeriodEndTime,
                nonCliffReaminingTobeclaimable,
                (_userAlloc[i] - (cliffAlloc)) /
                    (_vestingEndTime - _cliffPeriodEndTime),
                _cliffPeriodEndTime
            );
        }
        uint256 nonCliffVestingPeriod = _vestingEndTime - _cliffPeriodEndTime;
        _cliffPoolInfo[vestingPoolSize] = CliffPoolInfo(
            _poolName,
            block.timestamp,
            _vestingEndTime,
            _cliffVestingEndTime,
            nonCliffVestingPeriod,
            _cliffPeriodEndTime,
            _tokenAddress,
            totalVesting,
            _cliffPercentage10000,
            _usersAddresses,
            _userAlloc
        );
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            totalVesting
        );
        cliff[vestingPoolSize] = true;
        emit CliffAddVesting(
            _msgSender(),
            vestingPoolSize,
            _poolName,
            _vestingEndTime,
            _cliffVestingEndTime,
            nonCliffVestingPeriod,
            _cliffPeriodEndTime,
            _tokenAddress,
            totalVesting,
            _usersAddresses,
            _userAlloc
        );
        vestingPoolSize = vestingPoolSize + 1;
        usedHashes[_messageHash(_poolName, _tokenAddress, _keyHash)] = true;
    }

    /// @dev User must have allocation in the pool.
    /// @notice This is for claiming cliff vesting.
    /// @notice should be called if need to claim cliff amount.
    /// @param _poolId : Pool Id from which pool user want to withdraw.
    /// @notice Secured by nonReentrant.
    function claimCliff(uint256 _poolId) external nonReentrant {
        UserCliffInfo storage info = userCliffInfo[_poolId][_msgSender()];
        require(
            _cliffPoolInfo[_poolId].cliffPeriodEndTime < block.timestamp,
            "IIronVest : Cliff Period Is Not Over Yet"
        );

        uint256 transferAble = cliffClaimable(_poolId, _msgSender());
        require(transferAble > 0, "IIronVest : Invalid TransferAble");
        IERC20Upgradeable(_cliffPoolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        uint256 claimed = transferAble + info.claimedAmnt;
        uint256 remainingTobeClaimable = info.cliffAlloc - claimed;
        info.claimedAmnt = claimed;
        info.remainingToBeClaimableCliff = remainingTobeClaimable;
        info.cliffLastWithdrawal = block.timestamp;

        emit CliffClaim(
            _poolId,
            transferAble,
            _msgSender(),
            remainingTobeClaimable
        );
    }

    /// @dev User must have allocation in the pool.
    /// @notice This is for claiming cliff vesting.
    /// @notice should be called if need to claim non cliff amount.
    /// @param _poolId : Pool Id from which pool user want to withdraw.
    /// @notice Secured by nonReentrant.
    function claimNonCliff(uint256 _poolId) external nonReentrant {
        UserNonCliffInfo storage info = userNonCliffInfo[_poolId][_msgSender()];
        require(
            _cliffPoolInfo[_poolId].cliffPeriodEndTime < block.timestamp,
            "IIronVest : Cliff Period Is Not Over Yet"
        );

        uint256 transferAble = nonCliffClaimable(_poolId, _msgSender());
        uint256 claimed = transferAble + info.claimedAmnt;
        require(transferAble > 0, "IIronVest : Invalid TransferAble");
        IERC20Upgradeable(_cliffPoolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        uint256 remainingTobeClaimable = info.nonCliffAlloc - claimed;
        info.claimedAmnt = claimed;
        info.remainingToBeClaimableNonCliff = remainingTobeClaimable;
        info.nonCliffLastWithdrawal = block.timestamp;
        emit NonCliffClaim(
            _poolId,
            transferAble,
            _msgSender(),
            remainingTobeClaimable
        );
    }

    /// @dev this function use to withdraw tokens that send to the contract mistakenly
    /// @param _token : Token address that is required to withdraw from contract.
    /// @param _amount : How much tokens need to withdraw.
    function emergencyWithdraw(IERC20Upgradeable _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
    }

    /// @dev Functions is called by a default admin.
    /// @param _signer : An address whom admin want to be a signer.
    function setSigner(address _signer) external onlyOwner {
        require(
            _signer != address(0x00),
            "Invalid : Signer Address Is Invalid"
        );
        signer = _signer;
    }

    /// @dev As we are using poolId as unique ID which is supposed to return pool info i.e
    /// _poolInfo and _cliffPoolInfo but it unique for the contract level this function will
    /// return the values from where this poolId relate to.
    /// @param _poolId : Every Pool has a unique Id.
    /// @return isCliff : If this Id relate to the cliffPool or note?
    /// @return poolName : PoolName If exist.
    /// @return startTime : When does this pool initialized .
    /// @return vestingEndTime : Vesting End Time of this Pool.
    /// @return cliffVestingEndTime : CliffVestingEndTime If exist and if also a cliffPool.
    /// @return nonCliffVestingPeriod : Non CliffVesting Period If exist and also a cliffPool.
    /// @return cliffPeriodEndTime : Cliff Period End Time If exist and also a cliffPool.
    /// @return tokenAddress :  Vested token address If exist.
    /// @return totalVestedTokens : total Vested Tokens If exist.
    /// @return cliffLockPercentage : CliffLockPercentage If exist and also a cliffPool.
    function poolInformation(uint256 _poolId)
        external
        view
        returns (
            bool isCliff,
            string memory poolName,
            uint256 startTime,
            uint256 vestingEndTime,
            uint256 cliffVestingEndTime,
            uint256 nonCliffVestingPeriod,
            uint256 cliffPeriodEndTime,
            address tokenAddress,
            uint256 totalVestedTokens,
            uint256 cliffLockPercentage
        )
    {
        bool isCliff = cliff[_poolId];
        if (isCliff) {
            CliffPoolInfo memory info = _cliffPoolInfo[_poolId];
            return (
                isCliff,
                info.poolName,
                info.startTime,
                info.vestingEndTime,
                info.cliffVestingEndTime,
                info.nonCliffVestingPeriod,
                info.cliffPeriodEndTime,
                info.tokenAddress,
                info.totalVestedTokens,
                info.cliffLockPercentage10000
            );
        } else {
            PoolInfo memory info = _poolInfo[_poolId];
            return (
                isCliff,
                info.poolName,
                info.startTime,
                info.vestingEndTime,
                0,
                0,
                0,
                info.tokenAddress,
                info.totalVestedTokens,
                0
            );
        }
    }

    /// @dev This is check claimable for simple vesting.
    /// @param _poolId : Pool Id from which pool user want to check.
    /// @param _user : User address for which user want to check claimables.
    /// @return returning the claimable amount of the user
    function claimable(uint256 _poolId, address _user)
        public
        view
        returns (uint256)
    {
        uint256 claimable;
        UserInfo memory info = userInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation : You Don't have allocation in this pool"
        );
        if (_poolInfo[_poolId].vestingEndTime <= block.timestamp) {
            claimable = info.remainingToBeClaimable;
        } else
            claimable =
                (block.timestamp - info.lastWithdrawal) *
                info.releaseRatePerSec;

        return (claimable);
    }

    /// @dev This is check claimable for cliff vesting.
    /// @param _poolId : Pool Id from which pool user want to check.
    /// @param _user : User address for which user want to check claimables.
    /// @return returning the claimable amount of the user from cliff vesting.
    function cliffClaimable(uint256 _poolId, address _user)
        public
        view
        returns (uint256)
    {
        uint256 cliffClaimable;
        UserCliffInfo memory info = userCliffInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation : You Don't have allocation in this pool"
        );

        if (_cliffPoolInfo[_poolId].cliffPeriodEndTime <= block.timestamp) {
            if (
                _cliffPoolInfo[_poolId].cliffVestingEndTime >= block.timestamp
            ) {
                cliffClaimable =
                    (block.timestamp - info.cliffLastWithdrawal) *
                    info.cliffReleaseRatePerSec;
            } else cliffClaimable = info.remainingToBeClaimableCliff;
        }

        return (cliffClaimable);
    }

    /// @dev This is check claimable for non cliff vesting.
    /// @param _poolId : Pool Id from which pool user want to check.
    /// @param _user : User address for which user want to check claimables.
    /// @return returning the claimable amount of the user from non cliff vesting.
    function nonCliffClaimable(uint256 _poolId, address _user)
        public
        view
        returns (uint256)
    {
        uint256 nonCliffClaimable;
        UserNonCliffInfo memory info = userNonCliffInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation : You Don't have allocation in this pool"
        );

        if (_cliffPoolInfo[_poolId].cliffPeriodEndTime <= block.timestamp) {
            if (_cliffPoolInfo[_poolId].vestingEndTime >= block.timestamp) {
                nonCliffClaimable =
                    (block.timestamp - info.nonCliffLastWithdrawal) *
                    info.nonCliffReleaseRatePerSec;
            } else nonCliffClaimable = info.remainingToBeClaimableNonCliff;
        }

        return (nonCliffClaimable);
    }

    /// @dev For geting signer address from salt and sgnature.
    /// @param _signature : signature provided signed by signer.
    /// @param _poolName : Pool Name to name a pool.
    /// @param _tokenAddress : tokenAddess of our vested tokesn.
    /// @param _keyHash : keyhash value to stop replay.
    /// @return Address of signer who signed the message hash.
    function signatureVerification(
        bytes memory _signature,
        string memory _poolName,
        address _tokenAddress,
        bytes memory _keyHash
    ) public view returns (address) {
        bytes32 _salt = _messageHash(_poolName, _tokenAddress, _keyHash);
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        require(!usedHashes[_salt], "Message already used");

        address _user = _verifyMessage(_salt, v, r, s);
        return _user;
    }

    /// @dev For splititng signature.
    /// @param _sig : signature provided signed by signer
    /// @return r : First 32 bytes stores the length of the signature.
    /// @return s : add(sig, 32) = pointer of sig + 32
    /// effectively, skips first 32 bytes of signature.
    /// @return v : mload(p) loads next 32 bytes starting
    /// at the memory address p into memory.
    function _splitSignature(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            /// First 32 bytes stores the length of the signature

            /// add(_sig, 32) = pointer of _sig + 32
            /// effectively, skips first 32 bytes of signature

            /// mload(p) loads next 32 bytes starting at the memory address p into memory

            /// first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            /// second 32 bytes
            s := mload(add(_sig, 64))
            /// final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        /// implicitly return (r, s, v)
    }

    /// @dev Verify and recover signer from salt and signature.
    /// @param _salt : A hash value which contains concatened hash of different values.
    /// @param _v : mload(p) loads next 32 bytes starting at the memory address p into memory.
    /// @param _r : First 32 bytes stores the length of the signature.
    /// @param _s : add(sig, 32) = pointer of sig + 32 effectively, skips first 32 bytes of signature.
    /// @return signerAddress : Return the address of signer.
    function _verifyMessage(
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address signerAddress) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _salt)
        );
        address _signerAddress = ecrecover(prefixedHashMessage, _v, _r, _s);
        return _signerAddress;
    }

    /// @dev create a message hash by concatincating the values.
    /// @param _poolName : Pool name.
    /// @param _tokenAddress : Vesting token address .
    /// @param _keyHash : key hash value generated by our backend to stop replay attack.
    /// also a chain Id so that a user can't replay the hash any other chain.
    /// @return returning keccak hash of concate values.
    function _messageHash(
        string memory _poolName,
        address _tokenAddress,
        bytes memory _keyHash
    ) internal view returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(_poolName, _tokenAddress, _keyHash, block.chainid)
        );
        return hash;
    }
}
