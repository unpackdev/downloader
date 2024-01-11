// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV3CrossPoolOracle.sol";
import "./Mintable.sol";
import "./draft-EIP712.sol";

interface IOldManagerContract {
    struct StakeInfo {
        //for gpool
        uint256 amount;
        uint256 startStake; // start stake time
        // for nft
        uint256 nftInGpoolAmount;
    }

    function hadStake(address _user) external view returns (bool);
    function stakeInfo(address _user) external view returns (StakeInfo memory);
}

contract StakeManager is AccessControl, ReentrancyGuard, EIP712 {
    using SafeERC20 for IERC20;

    // keccak256("BIG_GUARDIAN_ROLE")
    bytes32 public constant BIG_GUARDIAN_ROLE = 0x05c653944982f4fec5b037dad255d4ecd85c5b85ea2ec7654def404ae5f686ec;
    // keccak256("GUARDIAN_ROLE")
    bytes32 public constant GUARDIAN_ROLE = 0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;
    // keccak256("Claim(address user,address rewardToken,uint poolId,uint pendingReward,uint currentTier,uint nonce)").
    bytes32 public constant CLAIM_TYPEHASH = 0x4409e925f2186a56f91d8d400d8f11f2d109f0b152bc5b39d62f54ef93031d3c;
    // keccak256("Claim(address user,address[] rewardTokens,uint[] poolId,uint[] pendingRewards,uint currentTier,uint nonce)").
    bytes32 public constant MULTIPLE_CLAIM_TYPEHASH = 0x0b8be51f347f62ce5ef93add4bff216e052cd43dc27fd0364defd80ccb596fdb;
    // keccak256("Claim(address user,uint poolId,uint currentTier,uint nonce)").
    bytes32 public constant LOCK_REWARD_CLAIM_TYPEHASH = 0x0059ca09dcfe017a0d2256d3570133ce65c6f2b120016a794ad924c5efb8ded8;
    // keccak256("SIGNER_ROLE")
    bytes32 public constant SIGNER_ROLE = 0xe2f4eaae4a9751e85a3e4a7b9587827a877f29914755229b07a7b2da98285f70;

    uint256 public constant USDC_THRESHOLD = 1000 * 10**6;
    uint8 public constant MAX_TIER = 3;
    uint256 public constant SILVER_PIVOT = 50 days;
    uint256 public constant GOLD_PIVOT = 100 days;

    struct StakeInfo {
        uint256 amount;
        uint256 startStake;
    }

    enum Tier {
        NORANK,
        BRONZE,
        SILVER,
        GOLD
    }

    mapping(address => StakeInfo) public stakeInfo;
    mapping(address => bool) public hadStake;
    mapping(address => uint) internal _nonces;

    uint32 public twapPeriod = 1;
    uint256 public firstStakingFee; //eth
    address payable public feeTo;

    IERC20 public gpoolToken;
    IERC20 public usdc;
    IUniswapV3CrossPoolOracle public oracle;
    IOldManagerContract public oldContract;
    address public signer;

    event Stake(address sender, uint256 amount, uint256 startStake);
    event Unstake(address sender, uint256 amount, uint256 startStake);
    event ClaimReward(address sender, uint256 poolId, uint256 amount);
    event ClaimMultipleReward(address sender, bytes signature, uint256 chainId);
    event UpdateFirstStakingFee(uint256 _fee, address payable _feeTo);
    event SetStartStake(address user, uint256 startStake);
    event WithdrawGP(address user, uint256 amount);
    event Refund(address indexed receiver, uint256 amount);

    constructor(
        IUniswapV3CrossPoolOracle _oracle,
        IERC20 _gpoolToken,
        IERC20 _usdc,
        address payable _feeTo,
        uint256 _firstStakingFee,
        address _signer,
        address _oldContract,
        address[] memory _admins
    ) EIP712("GPOOL VAULT", "1.0.0") {
        oracle = _oracle;
        gpoolToken = _gpoolToken;
        usdc = _usdc;
        firstStakingFee = _firstStakingFee;
        feeTo = _feeTo;
        signer = _signer;
        oldContract = IOldManagerContract(_oldContract);
        for (uint256 i = 0; i < _admins.length; ++i) {
            _setupRole(GUARDIAN_ROLE, _admins[i]);
        }

        _setRoleAdmin(GUARDIAN_ROLE, BIG_GUARDIAN_ROLE);
        _setRoleAdmin(SIGNER_ROLE, GUARDIAN_ROLE);
        _setupRole(GUARDIAN_ROLE, msg.sender);
        _setupRole(BIG_GUARDIAN_ROLE, msg.sender);
        _setupRole(SIGNER_ROLE, _signer);
    }

    function transferBigGuardian(address _newGuardian) public onlyRole(BIG_GUARDIAN_ROLE) {
        require(_newGuardian != address(0) && _newGuardian != msg.sender, "Invalid new guardian");
        renounceRole(BIG_GUARDIAN_ROLE, msg.sender);
        _setupRole(BIG_GUARDIAN_ROLE, _newGuardian);
    }

    function withdraw(address user, uint256 amount) public onlyRole(BIG_GUARDIAN_ROLE) {
        gpoolToken.safeTransfer(user, amount);
        emit WithdrawGP(user, amount);
    }

    function recoverFund(
        address _token,
        address _receiver
    ) external onlyRole(BIG_GUARDIAN_ROLE) {
        _paramsValidate(_token, _receiver);

        uint balance = IERC20(_token).balanceOf(address(this));

        require(balance > 0, "Balance is not enough!");
        IERC20(_token).safeTransfer(_receiver, balance);

        emit Refund(_receiver, balance);
    }

    function _paramsValidate(address _token, address _receiver) internal pure {
        require(
            _token != address(0) && _receiver != address(0),
            "Invalid address!"
        );
    }

    function grantSigner(address _signer) public onlyRole(GUARDIAN_ROLE) {
        require(_signer != address(0), "Signer address is invalid!");
        revokeRole(SIGNER_ROLE, signer);
        _setupRole(SIGNER_ROLE, _signer);
        signer = _signer;
    }

    /**
     * @notice stake gpool to manager.
     * @param amount amount to stake
     */
    function stake(uint256 amount) external payable nonReentrant {
        require(gpoolToken.balanceOf(msg.sender) >= amount, "not enough gpool");
        _getStakeFeeIfNeed(msg.value, msg.sender);
        StakeInfo storage oldStake = stakeInfo[msg.sender];
        uint256 startStake = getStartStake(msg.sender);
        if (getTierByStartStake(startStake) == Tier.NORANK) {
            require(
                gpoolInUSDC(oldStake.amount + amount) >= USDC_THRESHOLD,
                "minimum stake does not match"
            );
        }

        gpoolToken.safeTransferFrom(msg.sender, address(this), amount);
        if (oldStake.startStake == 0) {
            if (!hadStake[msg.sender]) {
                oldStake.startStake = startStake;
            } else {
                oldStake.startStake = block.timestamp;
            }
        }

        oldStake.amount += amount;
        hadStake[msg.sender] = true;
        emit Stake(msg.sender, amount, oldStake.startStake);
    }

    /**
     * @notice unstake Gpool.
     * @param amount amount to withdraw
     */
    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage oldStake = stakeInfo[msg.sender];
        require(amount <= oldStake.amount, "not enough balance");
        oldStake.amount -= amount;
        if (
            oldStake.amount == 0 ||
            gpoolInUSDC(oldStake.amount) < USDC_THRESHOLD
        ) {
            oldStake.startStake = 0;
        } else {
            oldStake.startStake = block.timestamp;
        }
        emit Unstake(msg.sender, amount, oldStake.startStake);
        gpoolToken.safeTransfer(msg.sender, amount);
    }

    function _getStakeFeeIfNeed(uint256 amount, address user) private {
        if (!oldContract.hadStake(user) && !hadStake[user]) {
            require(amount == firstStakingFee, "Fee is not valid");
            feeTo.transfer(amount);
        } else {
            require(amount == 0, "Fee only apply in first staking");
        }
    }

    function claimReward(
        address _user,
        address[] memory _rewardTokens,
        uint[] memory _poolIds,
        uint[] memory _pendingRewards,
        uint _currentTier,
        uint _nonce,
        bytes memory _signature
    ) public {
        _verifyMultipleClaimProof(_user, _rewardTokens, _poolIds, _pendingRewards, _currentTier, _nonce, _signature);
        for (uint i = 0; i < _poolIds.length; i++) {
            _claim(_user, _rewardTokens[i], _poolIds[i], _pendingRewards[i]);
        }
        emit ClaimMultipleReward(msg.sender, _signature, block.chainid);
    }

    function _verifyMultipleClaimProof(
        address _user,
        address[] memory _rewardTokens,
        uint[] memory _poolIds,
        uint[] memory _pendingRewards,
        uint _currentTier,
        uint _nonce,
        bytes memory _signature
    ) internal {
        require(
            _poolIds.length == _pendingRewards.length && _rewardTokens.length == _pendingRewards.length,
            "Invalid array length!"
        );
        require(
            _currentTier <= MAX_TIER,
            "Invalid Tier"
        );
        require(
            _nonce == _nonces[_user],
            "Invalid nonce!"
        );
        require(
            _verify(
                _multipleClaimHash(_user, _rewardTokens, _poolIds, _pendingRewards, _currentTier, _nonce),
                _signature
            ),
            "Not approval by GPool!"
        );

        _nonces[_user] = _nonce + 1;
    }

    function _verify(bytes32 _digest, bytes memory _signature) internal view returns (bool) {
        return hasRole(SIGNER_ROLE, ECDSA.recover(_digest, _signature));
    }

    function _multipleClaimHash(
        address _user,
        address[] memory _rewardTokens,
        uint[] memory _poolIds,
        uint[] memory _pendingRewards,
        uint _currentTier,
        uint _nonce
    ) internal view returns (bytes32 hash) {
        hash = _hashTypedDataV4(keccak256(abi.encode(
                MULTIPLE_CLAIM_TYPEHASH,
                _user,
                keccak256(abi.encodePacked(_rewardTokens)),
                keccak256(abi.encodePacked(_poolIds)),
                keccak256(abi.encodePacked(_pendingRewards)),
                _currentTier,
                _nonce
            )));
    }

    function _claim(
        address _user,
        address _rewardToken,
        uint _poolId,
        uint _pendingReward
    ) internal {
        require(IERC20(_rewardToken).balanceOf(address(this)) >= _pendingReward, "Exceeds current balance!");
        IERC20(_rewardToken).safeTransfer(_user, _pendingReward);
        // emit ClaimReward(msg.sender, _poolId, _pendingReward);
    }

    function updateFirstStakingFee(uint256 _fee, address payable _feeTo) public onlyRole(GUARDIAN_ROLE) {
        feeTo = _feeTo;
        firstStakingFee = _fee;
        emit UpdateFirstStakingFee(_fee, _feeTo);
    }

    // gpoolInUSDC
    // convert gpool to usdc value
    function gpoolInUSDC(uint256 gpoolAmount) public view returns (uint256) {
        // twap is in second
        return oracle.assetToAsset(address(gpoolToken), gpoolAmount, address(usdc), twapPeriod);
    }

    function setTwapPeriod(uint32 _twapPeriod) external onlyRole(GUARDIAN_ROLE) {
        twapPeriod = _twapPeriod;
    }

    function getNonce(address _from) public view returns (uint) {
        return _nonces[_from];
    }

    function setStartStake(address[] memory user, uint256[] memory startStake) external onlyRole(GUARDIAN_ROLE) {
        require(user.length == startStake.length, "NOT VALID INPUT");
        for (uint256 i = 0; i < user.length; ++i) {
            StakeInfo storage staker = stakeInfo[user[i]];
            staker.startStake = startStake[i]; 
            emit SetStartStake(user[i], startStake[i]);
        }
    }

    // getTier: user's gpass
    function getTier(address user) public view returns (Tier) {
        StakeInfo memory staker = stakeInfo[user];
        if (staker.startStake == 0) {
            return Tier.NORANK;
        }

        if (block.timestamp <= staker.startStake + SILVER_PIVOT) {
            return Tier.BRONZE;
        }

        if (block.timestamp <= staker.startStake + GOLD_PIVOT) {
            return Tier.SILVER;
        }

        return Tier.GOLD;
    }

    function getStartStake(address _user) public view returns (uint256) {
        StakeInfo memory staker = stakeInfo[_user];
        if (hadStake[_user]) {
            return staker.startStake;
        }
        IOldManagerContract.StakeInfo memory oldInfo = oldContract.stakeInfo(_user);
        return oldInfo.startStake;
    }

    function getTierByStartStake(uint256 _startStake) public view returns (Tier) {
        if (_startStake == 0) {
            return Tier.NORANK;
        }
        if (block.timestamp <= _startStake + SILVER_PIVOT) {
            return Tier.BRONZE;
        }

        if (block.timestamp <= _startStake + GOLD_PIVOT) {
            return Tier.SILVER;
        }

        return Tier.GOLD;
    }
}
