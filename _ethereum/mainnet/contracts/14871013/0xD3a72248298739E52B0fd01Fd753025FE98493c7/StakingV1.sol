// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8;

import { Initializable }            from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable}   from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { PausableUpgradeable }      from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ERC721Upgradeable }        from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { FixedPointMathLib }        from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";
import { TransferHelper }           from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import { IERC20Permit }             from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import { IERC20 }                   from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAccrualBondsV1 }          from "../interfaces/IAccrualBondsV1.sol";
import "./StakingStorageV1.sol";

interface ICNV is IERC20, IERC20Permit {
    function mint(address guy, uint256 input) external;
}

interface IValueShuttle {
    function shuttleValue() external returns(uint256);
}

interface IERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract StakingV1 is StakingStorageV1, Initializable, AccessControlUpgradeable, PausableUpgradeable, ERC721Upgradeable {

    using FixedPointMathLib for uint256;

    ////////////////////////////////////////////////////////////////////////////
    // ACCESS CONTROL ROLES
    ////////////////////////////////////////////////////////////////////////////

    bytes32 public constant TREASURY_ROLE           = DEFAULT_ADMIN_ROLE;
    bytes32 public constant POLICY_ROLE             = bytes32(keccak256("POLICY_ROLE"));

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice             emitted when a user locks
    /// @param _amount      amount of CNV locked
    /// @param _poolID      ID of the pool locked into
    /// @param _tokenId     ID of token generated
    /// @param _sender      address of sender
    event Lock(
        uint256 indexed _amount,
        uint256 indexed _poolID,
        uint256 indexed _tokenId,
        address _sender
    );

    /// @notice             emitted when a user unlocks
    /// @param _amount      amount of CNV unlocked (principal + anti-dilutive + excess)
    /// @param _poolID      ID of the pool locked into
    /// @param _owner       address of NFT owner
    event Unlock(
        uint256 indexed _amount,
        uint256 indexed _poolID,
        address indexed _owner
    );

    /// @notice             emitted when a rebase occurs
    /// @param eStakers     emissions for stakes (anti-dilutive + excess)
    /// @param eCOOP        emissions for COOP
    /// @param CNVS         CNV supply used for anti-dilution calculation
    event Rebase(
        uint256 indexed eStakers,
        uint256 indexed eCOOP,
        uint256 indexed CNVS
    );

    /// @notice                     emitted during rebase for each pool
    /// @param poolID               ID of pool
    /// @param baseObligation       anti-dilution rewards for pool
    /// @param excessObligation     excess rewards for pool
    /// @param balance              pool balance before rebase
    event PoolRewarded(
        uint256 indexed poolID,
        uint256 indexed baseObligation,
        uint256 indexed excessObligation,
        uint256 balance
    );


    ////////////////////////////////////////////////////////////////////////////
    // ADMIN MGMT EVENTS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice                 emitted when MGMT creates a new pool
    /// @param _term            length of pool term in seconds
    /// @param _g               amount of CNV supply growth matched to pool
    /// @param _excessRatio     ratio to calculate excess rewards for this pool
    /// @param _poolID          ID of the pool
    event PoolOpened(
        uint64  indexed _term,
        uint256 indexed _g,
        uint256 indexed _excessRatio,
        uint256 _poolID
    );

    /// @notice                 emitted when MGMT manages a pool
    /// @param _term            length of pool term in seconds
    /// @param _g               amount of CNV supply growth matched to pool
    /// @param _excessRatio     ratio to calculate excess rewards for this pool
    /// @param _poolID          ID of the pool
    event PoolManaged(
        uint64 indexed  _term,
        uint256 indexed _g,
        uint256 indexed _excessRatio,
        uint256 _poolID
    );

    /// @notice                         emitted when MGMT manages COOP rate
    /// @param _coopRatePriceControl    used for COOP rate calc
    /// @param _haogegeControl          used for COOP rate calc
    /// @param _coopRateMax             used for COOP rate calc
    event CoopRateManaged(
        uint256 indexed _coopRatePriceControl,
        uint256 indexed _haogegeControl,
        uint256 indexed _coopRateMax
    );

    event ExcessRewardsDistributed(
        uint256 indexed amountDistributed,
        uint256 indexed globalExcess
    );

    /// @notice                         emitted when MGMT manages rebase excess apy
    /// @param apy                      apy
    event RebaseAPYManaged(
        uint256 indexed apy
    );

    /// @notice                         emitted when MGMT manages rebase incentive
    /// @param rebaseIncentive          incentive (in CNV) for calling rebase method
    event RebaseIncentiveManaged(
        uint256 indexed rebaseIncentive
    );

    /// @notice                         emitted when MGMT manages rebase interval
    /// @param rebaseInterval           interval (in seconds) between rebases
    event RebaseIntervalManaged(
        uint256 indexed rebaseInterval
    );

    /// @notice                         emitted when MGMT manages minPrice
    /// @param minPrice                 minPrice used for rebase calculations
    event MinPriceManaged(
        uint256 indexed minPrice
    );

    /// @notice                         emitted when MGMT manages an address
    /// @param _what                    index of address managed
    /// @param _address                 updated address
    event AddressManaged(
        uint8 indexed _what,
        address _address
    );

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    modifier onlyRoles(bytes32 role0, bytes32 role1) {
        require(hasRole(role0, msg.sender) || hasRole(role1, msg.sender));
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    /// @notice                 called instead of constructor on upgradeable contracts,
    ///                         sets initial storage variables, initializes inherited
    ///                         contracts, and pauses.
    /// @param _CNV             address of CNV token
    /// @param _COOP            address of COOP
    /// @param _BONDS           address of BONDS contract
    /// @param _VALUESHUTTLE    address of ValueShuttle contract
    function initialize(
        address _CNV,
        address _COOP,
        address _BONDS,
        address _VALUESHUTTLE,
        address _treasury,
        address _policy,
        uint256 _coopRatePriceControl,
        uint256 _haogegeControl,
        uint256 _coopRateMax,
        uint256 _minPrice,
        uint256 _rebaseInterval
    ) external virtual initializer {

        require(CNV == address(0), "!initialized");

        CNV = _CNV;
        COOP = _COOP;
        BONDS = _BONDS;
        VALUESHUTTLE = _VALUESHUTTLE;

        coopRatePriceControl = _coopRatePriceControl;
        haogegeControl = _haogegeControl;
        coopRateMax = _coopRateMax;
        minPrice = _minPrice;
        rebaseInterval = _rebaseInterval;

        lastRebaseTime = block.timestamp;

        __Context_init();
        __AccessControl_init();
        __ERC165_init();
        __Pausable_init();
        __ERC721_init("Liquid Staked CNV", "lsdCNV");

        _grantRole(TREASURY_ROLE, _treasury);
        _grantRole(POLICY_ROLE, _policy);

        _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*                              LOCK/UNLOCK LOGIC                             */
    /* -------------------------------------------------------------------------- */

    /// @notice                  lock CNV into a pool using eip-2612 permit
    ///                          (https://eips.ethereum.org/EIPS/eip-2612)
    /// @param  to               address to which lock position will be assigned to
    /// @param  input            amount of CNV to lock
    /// @param  pid              pool ID to lock into
    /// @param  permitDeadline   deadline for eip-2612 signature
    /// @param  v                eip-2612 signature
    /// @param  r                eip-2612 signature
    /// @param  s                eip-2612 signature
    /// @return tokenId          ERC721 token ID of lock
    function lockWithPermit(
        address to,
        uint256 input,
        uint256 pid,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual whenNotPaused returns(uint256 tokenId) {
        // Approve tokens for spender - https://eips.ethereum.org/EIPS/eip-2612
        ICNV(CNV).permit(msg.sender, address(this), input, permitDeadline, v, r, s);

        tokenId = _lock(to,input,pid);
    }

    /// @notice                  lock CNV into a pool
    /// @param  to               address to which lock position will be assigned to
    /// @param  input            amount of CNV to lock
    /// @param  pid              pool ID to lock into
    /// @return tokenId          ERC721 token ID of lock
    function lock(
        address to,
        uint256 input,
        uint256 pid
    ) external virtual whenNotPaused returns(uint256 tokenId) {
        tokenId = _lock(to,input,pid);
    }

    /// @notice                  unlock position and withdraw due CNV
    /// @param  to               address to which due CNV will be sent to
    /// @param  tokenId          ERC721 token ID of lock
    /// @return amountOut        amount of CNV due
    function unlock(
        address to,
        uint256 tokenId
    ) external virtual whenNotPaused returns (uint256 amountOut) {
        // F6: CHECKS

        // Check that caller is owner of position to be unlocked
        require(ownerOf(tokenId) == msg.sender, "!OWNER");
        // Fetch position storage to memory
        Position memory position = positions[tokenId];
        // Check that position has matured
        require(position.maturity <= block.timestamp, "!TIME");

        // F6: EFFECTS

        // C2: avoid reading state multiple times
        uint256 shares = position.shares;
        uint256 poolID = position.poolID;
        Pool storage pool = pools[poolID];
        // Calculate base amount obligated to user
        uint256 baseObligation = shares.fmul(_poolIndex(pool.balance, pool.supply), 1e18);
        // Calculate excess amount obligated to user
        uint256 excessObligation = shares.fmul(pool.rewardsPerShare, 1e18) - position.rewardDebt;
        // Calculate "amountOut" due to user
        amountOut = baseObligation + excessObligation;

        lockedExcessRewards -= excessObligation;

        // Subtract users baseObligation and shares from pool storage
        pool.balance -= baseObligation;
        pool.supply -= shares;
        // C38: Delete keyword used when setting a variable to a zero value for refund
        delete positions[tokenId];
        // Transfer user "amountOut" (baseObligation + excessObligation rewards)
        TransferHelper.safeTransfer(CNV, to, amountOut);
        // T2: Events emitted for every storage mutating function.
        emit Unlock(amountOut, poolID, msg.sender);
    }

    /// @notice             called to assign anti-dilution and excess rewards to
    ///                     locks based on bonding that occured since last rebase
    /// returns vebase      whether a rebase took place
    function rebase() external virtual whenNotPaused returns (bool vebase) {
        if (block.timestamp >= lastRebaseTime + rebaseInterval) {
            uint256 incentive = rebaseIncentive;
            (uint256 eCOOP, uint256 eStakers, uint256 CNVS) = _rebase(incentive);
            ICNV(CNV).mint(COOP, eCOOP);
            ICNV(CNV).mint(address(this), eStakers);
            ICNV(CNV).mint(msg.sender, incentive);
            emit Rebase(eStakers, eCOOP, CNVS);
            vebase = true;
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // UTILS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice     to view length of pools array
    /// returns     length of pools array
    function lockPoolsLength() external virtual view returns (uint256) {
        return pools.length;
    }

    /// @notice             calculate index of a pool based on balance and supply
    /// @param   _bal       balance of CNV in pool
    /// @param   _supply    supply of shares in pool
    /// returns index       pool index
    function _poolIndex(
        uint256 _bal,
        uint256 _supply
    ) public pure virtual returns (uint256) {
        if (_bal + _supply == 0) return 1e18;
        return uint256(1e18).fmul(_bal, _supply);
    }


    ////////////////////////////////////////////////////////////////////////////
    // _lock logic
    ////////////////////////////////////////////////////////////////////////////


    function viewPositionRewards(
        uint256 tokenId
    ) external virtual view returns(
        uint256 amountDeposited,
        uint256 baseRewards,
        uint256 excessRewards,
        uint256 totalRewards
    ) {
        // Fetch position storage to memory
        Position memory position = positions[tokenId];

        uint256 shares = position.shares;
        uint256 poolID = position.poolID;

        amountDeposited = position.deposit;

        Pool memory pool = pools[poolID];

        // Calculate base amount obligated to user
        baseRewards = shares.fmul(_poolIndex(pool.balance, pool.supply), 1e18);
        // Calculate excess amount obligated to user
        excessRewards = shares.fmul(pool.rewardsPerShare, 1e18) - position.rewardDebt;
        // Calculate "totalRewards" due to user
        totalRewards = baseRewards + excessRewards;
    }


    /// @notice             calculate how many CNV can be locked into a pool before
    ///                     it reaches a cap.
    /// @param   poolNum    index of pool
    /// returns cap         number of CNV that can be locked in pool
    /// @dev
    /// 1 - coopRateMax - (1 - coopRateMax)/minPrice > lg/cnvs
    /// (1 - coopRateMax - (1 - coopRateMax)/minPrice)*cnvs > lg1 + lg2 + lg3 + lg4
    /// (1 - coopRateMax - (1 - coopRateMax)/minPrice)*cnvs - lg1 - lg2 - lg3 > bal_4*g_4
    /// ((1 - coopRateMax - (1 - coopRateMax)/minPrice)*cnvs - lg1 - lg2 - lg3)/g_4 > bal_4
    /// 1 - coopRateMax - (1 - coopRateMax)/minPrice > lg/cnvs
    /// lhs > lg/cnvs
    /// lhs * cnvs - lg > bal_n * g_n
    /// (lhs * cnvs - lg)/g_n - bal_n > 0
    function viewStakingCap(uint256 poolNum) public view virtual returns(uint256) {

        uint256 lhs = 1e18 - coopRateMax - uint256(1e18 - coopRateMax).fmul(1e18, minPrice);

        uint256 lgm;
        // Avoid fetching length each loop to save gas
        uint256 poolsLength = pools.length;
        // Iterate through pool balances to calculate lgm
        for (uint256 i; i < poolsLength;) {
            // calculate lgm for all pools except selected pool since that will
            // be solved for
            if (poolNum != i) {
                Pool memory lp = pools[i];
                uint256 _balance = lp.balance;
                if (_balance != 0) lgm += _balance.fmul(lp.g, 1e18);
            }
            unchecked { ++i; }
        }
        Pool memory lp = pools[poolNum];
        return (lhs * (circulatingSupply() - IAccrualBondsV1(BONDS).cnvEmitted()) / 1e18 - lgm) * 1e18/lp.g - lp.balance;
    }


    function _lock(
        address to,
        uint256 input,
        uint256 pid
    ) internal virtual returns(uint256 tokenId) {
        // F6: CHECKS

        // Fetch pool storage from pools mapping
        Pool storage pool = pools[pid];
        // C2: avoid reading state multiple times
        uint256 shares = input.fmul(1e18, _poolIndex(pool.balance, pool.supply));
        uint256 rewardDebt = shares.fmul(pool.rewardsPerShare, 1e18);
        // Pull users stake (CNV) to this contract
        TransferHelper.safeTransferFrom(CNV, msg.sender, address(this), input);
        // Optimistically mutate state to calculate lgm, REVIEW F6: possible reentrance issue
        pool.balance += input;
        pool.supply += shares;
        // Create lgm variable to be used in below calculation
        uint256 lgm;
        // Avoid fetching length each loop to save gas
        uint256 poolsLength = pools.length;

        // Iterate through pool balances to calculate lgm
        for (uint256 i; i < poolsLength;) {
            Pool memory lp = pools[i];
            uint256 _balance = lp.balance;
            if (_balance != 0) lgm += _balance.fmul(lp.g, 1e18);
            unchecked { ++i; }
        }

        // Check that staking cap is still satisfied
        uint256 lhs = 1e18 - coopRateMax - uint256(1e18 - coopRateMax).fmul(1e18, minPrice);
        uint256 rhs = lgm.fmul(1e18, circulatingSupply() - IAccrualBondsV1(BONDS).cnvEmitted());
        require(lhs > rhs, "CAP");

        // F6: EFFECTS

        // Increment totalSupply to account for new nft
        unchecked { ++totalSupply; }
        // Set return value, users nft id
        tokenId = totalSupply;
        // Store users position info
        positions[tokenId] = Position(
            uint32(pid),
            uint224(shares),
            uint32(block.timestamp + pool.term),
            uint224(rewardDebt),
            input
        );
        // Mint caller nft that represents their stake
        _mint(to, tokenId);
        // T2: Events emitted for every storage mutating function.
        emit Lock(input, pid, tokenId, msg.sender);
    }

    ////////////////////////////////////////////////////////////////////////////
    // REBASE
    ////////////////////////////////////////////////////////////////////////////

    function _rebase(
        uint256 eRI
    ) internal virtual returns (uint256 eCOOP, uint256 eStakers, uint256 CNVS) {

        uint256 value = IValueShuttle(VALUESHUTTLE).shuttleValue();
        uint256 amountOut = IAccrualBondsV1(BONDS).cnvEmitted();
        uint256 poolsLength = pools.length;
        CNVS = circulatingSupply() - amountOut;
        eCOOP = uint256(value - amountOut).fmul(_calculateCOOPRate(value, amountOut), 1e18);
        uint256 lgm;
        uint256 erm;

        for (uint256 i; i < poolsLength;) {
            Pool memory lp = pools[i];
            uint256 balance = lp.balance;
            if (balance != 0) {
                lgm += balance.fmul(lp.g, 1e18);
                erm += balance.fmul(lp.excessRatio, 1e18);
            }
            unchecked { ++i; }
        }

        uint256 emissions = uint256(amountOut + eCOOP + eRI).fmul(1e18, 1e18 - lgm.fmul(1e18, CNVS));
        uint256 g = emissions.fmul(1e18, CNVS);
        uint256 excessObligation = (value - emissions) + globalExcess;
        uint256 excessRewards = CNVS.fmul(apyPerRebase, 1e18);
        if (excessRewards > excessObligation) excessRewards = excessObligation;
        uint256 excessMultiplier = erm != 0 ? excessRewards.fmul(1e18, erm) : 0;
        (uint256 eStakersAD, uint256 excessConsumed) = _distribute(poolsLength, g, excessMultiplier);

        lockedExcessRewards += excessConsumed;
        globalExcess = excessObligation - excessConsumed;

        // delete cnvEmitted;
        require(IAccrualBondsV1(BONDS).vebase());
        lastRebaseTime = block.timestamp;
        eStakers = eStakersAD + excessConsumed;
    }

    function _distribute(
        uint256 poolsLength,
        uint256 g,
        uint256 excessMultiplier
    ) internal virtual returns(uint256 eStakers, uint256 excessConsumed) {
        for (uint256 i; i < poolsLength;) {
            Pool storage pool =  pools[i];
            uint256 balance = pool.balance;
            uint256 supply = pool.supply;

            if (balance != 0 && supply != 0) {
                uint256 baseObligation = g.fmul(pool.g.fmul(balance, 1e18), 1e18);
                uint256 excessObligation = excessMultiplier.fmul(balance, 1e18).fmul(pool.excessRatio, 1e18);
                emit PoolRewarded(
                    i,
                    baseObligation,
                    excessObligation,
                    pool.balance
                );
                pool.balance = balance + baseObligation;
                pool.rewardsPerShare += excessObligation.fmul(1e18, supply);
                eStakers += baseObligation;
                excessConsumed += excessObligation;
            }
            unchecked { ++i; }
        }
    }


    /// @notice             calculates the effective rate of CNV for COOP on rebase
    /// @param   _value     amount of value accumulated during rebase
    /// @param   _cnvOut    amount of CNV emmitted during rebase
    /// returns coopRate    effective rate of amount distributed to COOP
    function _calculateCOOPRate(
        uint256 _value,
        uint256 _cnvOut
    ) public view virtual returns (uint256) {

        if (_cnvOut == 0) return _value;
        uint256 _bondPrice = _value.fmul(1e18, _cnvOut);

        uint256 coopRate = (coopRatePriceControl * 1e18 / _bondPrice * haogegeControl) / 1e18;
        if (coopRate > coopRateMax) return coopRateMax;
        return coopRate;
    }

    /// @notice          calculates available circulating CNV supply. This number
    ///                  is equal to the total amount of minted CNV minus the amount
    ///                  of CNV that has been minted to the Bond contract but has
    ///                  not yet been sold.
    /// returns supply   available supply
    function circulatingSupply() public view virtual returns(uint256) {
        return ICNV(CNV).totalSupply() - IAccrualBondsV1(BONDS).getAvailableSupply() - lockedExcessRewards;
    }

    /* -------------------------------------------------------------------------- */
    /*                              ERC721.tokenURI()                             */
    /* -------------------------------------------------------------------------- */


    /// @notice             returns data for NFT display of lock position
    /// @param id           ID of lock position
    /// returns             returns lock position NFT image
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (URI_ADDRESS != address(0)) return IERC721(URI_ADDRESS).tokenURI(id);
    }

    /* -------------------------------------------------------------------------- */
    /*                              MANAGEMENT LOGIC                              */
    /* -------------------------------------------------------------------------- */


    /// @notice                 used by MGMT to open a new lock pool
    /// @param _term            length of lock period in seconds
    /// @param _g               CNV supply growth assigned to this pool
    /// @param _excessRatio     ratio of excess rewards for this pool
    function openLockPool(
        uint64 _term,
        uint256 _g,
        uint256 _excessRatio
    ) external virtual onlyRole(TREASURY_ROLE) {
        pools.push(Pool(_term, _g, _excessRatio, 0, 0, 0));

        emit PoolOpened(_term,_g,_excessRatio,pools.length-1);
    }

    /// @notice                 used by MGMT to edit an existing lock pool
    /// @param poolID           ID of pool to manage
    /// @param _term            length of lock period in seconds
    /// @param _g               CNV supply growth assigned to this pool
    /// @param _excessRatio     ratio of excess rewards for this pool
    function manageLockPool(
        uint256 poolID,
        uint64 _term,
        uint256 _g,
        uint256 _excessRatio
    ) external virtual onlyRoles(POLICY_ROLE, TREASURY_ROLE) {

        Pool storage pool = pools[poolID];
        (pool.term, pool.g, pool.excessRatio) = (_term, _g, _excessRatio);

        emit PoolOpened(_term,_g,_excessRatio,poolID);
    }

    /// @notice                         used by MGMT to edit parameters used
    ///                                 to calculate dynamic COOP rate
    /// @param _coopRatePriceControl    price control
    /// @param _haogegeControl          rate control
    /// @param _coopRateMax             max rate
    function setCOOPParameters(
        uint256 _coopRatePriceControl,
        uint256 _haogegeControl,
        uint256 _coopRateMax
    ) external virtual onlyRoles(POLICY_ROLE, TREASURY_ROLE) {

        coopRatePriceControl = _coopRatePriceControl;
        haogegeControl = _haogegeControl;
        coopRateMax = _coopRateMax;

        emit CoopRateManaged(_coopRatePriceControl,_haogegeControl,_coopRateMax);
    }

    function manualExcessDistribution(
        uint256[] memory amounts
    ) external virtual onlyRoles(POLICY_ROLE, TREASURY_ROLE) {

        uint256 length = amounts.length;
        uint256 toDistribute;
        for (uint256 i; i < length;) {
            Pool storage pool = pools[i];
            uint256 amount = amounts[i];
            pool.rewardsPerShare += amount.fmul(1e18, pool.supply);
            toDistribute += amount;
            unchecked { ++i; }
        }
        uint256 ge = globalExcess;
        require(toDistribute <= ge,"EXCEEDS_EXCESS");
        globalExcess = ge - toDistribute;
        ICNV(CNV).mint(address(this), toDistribute);

        emit ExcessRewardsDistributed(toDistribute,globalExcess);
    }

    /// @notice         used by MGMT to update APY per rebase parameter
    /// @param  _apy    updated APY parameter
    function setAPYPerRebase(
        uint256 _apy
    ) external virtual onlyRoles(POLICY_ROLE, TREASURY_ROLE) {
        apyPerRebase = _apy;

        emit RebaseAPYManaged(_apy);
    }

    /// @notice                     used by MGMT to update rebase incentive
    /// @param  _rebaseIncentive    updated rebase incentive
    function setRebaseIncentive(
        uint256 _rebaseIncentive
    ) external virtual onlyRoles(POLICY_ROLE, TREASURY_ROLE) {
        rebaseIncentive = _rebaseIncentive;

        emit RebaseIncentiveManaged(rebaseIncentive);
    }

    /// @notice                     used by MGMT to update rebase interval
    /// @param  _rebaseInterval     updated rebase interval (seconds)
    function setRebaseInterval(
        uint256 _rebaseInterval
    ) external virtual onlyRoles(POLICY_ROLE, TREASURY_ROLE) {
        rebaseInterval = _rebaseInterval;

        emit RebaseIntervalManaged(rebaseInterval);
    }

    /// @notice                 used by MGMT to update min price for anti-dilution
    ///                         calculations
    /// @param  _minPrice       updated min price
    function setMinPrice(
        uint256 _minPrice
    ) external virtual onlyRoles(POLICY_ROLE, TREASURY_ROLE) {
        minPrice = _minPrice;

        emit MinPriceManaged(minPrice);
    }

    /// @notice             used by MGMT to pause/unpause contract
    /// @param  _toPause    whether contract is paused
    function setPause(
        bool _toPause
    ) external virtual onlyRoles(POLICY_ROLE, TREASURY_ROLE) {
        if (_toPause) _pause();
        else _unpause();
    }

    /// @notice             used by MGMT to update an address.
    ///                     0 = CNV
    ///                     1 = BONDS
    ///                     2 = COOP
    ///                     3 = VALUESHUTTLE
    ///                     4 = URI_ADDRESS
    /// @param  _what       index of address to update
    /// @param  _address    updated address
    function setAddress(
        uint8 _what,
        address _address
    ) external virtual onlyRoles(POLICY_ROLE, TREASURY_ROLE) {

        require(_what < 5,"BAD");

        if (_what == 0) {
            CNV = _address;
        } else if (_what == 1) {
            BONDS = _address;
        } else if (_what == 2) {
            COOP = _address;
        } else if (_what == 3) {
            VALUESHUTTLE = _address;
        } else {
            URI_ADDRESS = _address;
        }

        emit AddressManaged(_what, _address);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return ERC721Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

}
