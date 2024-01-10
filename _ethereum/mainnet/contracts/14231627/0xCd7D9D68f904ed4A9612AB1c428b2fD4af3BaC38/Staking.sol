// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC20.sol";
import "./ISTARDUST.sol";
import "./ISUPERNOVA.sol";
import "./IDistributor.sol";

import "./StarshipAccessControlled.sol";

contract StarshipStaking is StarshipAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ISTARDUST;
    using SafeERC20 for ISUPERNOVA;

    /* ========== EVENTS ========== */

    event DistributorSet(address distributor);
    event WarmupSet(uint256 warmup);

    /* ========== DATA STRUCTURES ========== */

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    struct Claim {
        uint256 deposit; // if forfeiting
        uint256 gons; // staked balance
        uint256 expiry; // end of warmup period
        bool lock; // prevents malicious delays for claim
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable STAR;
    ISTARDUST public immutable STARDUST;
    ISUPERNOVA public immutable SUPERNOVA;

    Epoch public epoch;

    IDistributor public distributor;

    mapping(address => Claim) public warmupInfo;
    uint256 public warmupPeriod;
    uint256 private gonsInWarmup;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _star,
        address _stardust,
        address _supernova,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochTime,
        address _authority
    ) StarshipAccessControlled(IStarshipAuthority(_authority)) {
        require(_star != address(0), "Zero address: STAR");
        STAR = IERC20(_star);
        require(_stardust != address(0), "Zero address: STARDUST");
        STARDUST = ISTARDUST(_stardust);
        require(_supernova != address(0), "Zero address: SUPERNOVA");
        SUPERNOVA = ISUPERNOVA(_supernova);

        epoch = Epoch({length: _epochLength, number: _firstEpochNumber, end: _firstEpochTime, distribute: 0});
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake star to enter warmup
     * @param _to address
     * @param _amount uint
     * @param _claim bool
     * @param _rebasing bool
     * @return uint
     */
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256) {
        STAR.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = _amount.add(rebase()); // add bounty if rebase occurred
        if (_claim && warmupPeriod == 0) {
            return _send(_to, _amount, _rebasing);
        } else {
            Claim memory info = warmupInfo[_to];
            if (!info.lock) {
                require(_to == msg.sender, "External deposits for account are locked");
            }

            warmupInfo[_to] = Claim({
                deposit: info.deposit.add(_amount),
                gons: info.gons.add(STARDUST.gonsForBalance(_amount)),
                expiry: epoch.number.add(warmupPeriod),
                lock: info.lock
            });

            gonsInWarmup = gonsInWarmup.add(STARDUST.gonsForBalance(_amount));

            return _amount;
        }
    }

    /**
     * @notice retrieve stake from warmup
     * @param _to address
     * @param _rebasing bool
     * @return uint
     */
    function claim(address _to, bool _rebasing) public returns (uint256) {
        Claim memory info = warmupInfo[_to];

        if (!info.lock) {
            require(_to == msg.sender, "External claims for account are locked");
        }

        if (epoch.number >= info.expiry && info.expiry != 0) {
            delete warmupInfo[_to];

            gonsInWarmup = gonsInWarmup.sub(info.gons);

            return _send(_to, STARDUST.balanceForGons(info.gons), _rebasing);
        }
        return 0;
    }

    /**
     * @notice forfeit stake and retrieve STAR
     * @return uint
     */
    function forfeit() external returns (uint256) {
        Claim memory info = warmupInfo[msg.sender];
        delete warmupInfo[msg.sender];

        gonsInWarmup = gonsInWarmup.sub(info.gons);

        STAR.safeTransfer(msg.sender, info.deposit);

        return info.deposit;
    }

    /**
     * @notice prevent new deposits or claims from ext. address (protection from malicious activity)
     */
    function toggleLock() external {
        warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
    }

    /**
     * @notice redeem STARDUST for STAR
     * @param _to address
     * @param _amount uint
     * @param _trigger bool
     * @param _rebasing bool
     * @return amount_ uint
     */
    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256 amount_) {
        amount_ = _amount;
        uint256 bounty;
        if (_trigger) {
            bounty = rebase();
        }
        if (_rebasing) {
            STARDUST.safeTransferFrom(msg.sender, address(this), _amount);
            amount_ = amount_.add(bounty);
        } else {
            SUPERNOVA.burn(msg.sender, _amount); // amount was given in SUPERNOVA terms
            amount_ = SUPERNOVA.balanceFrom(amount_).add(bounty); // convert amount to star terms & add bounty
        }
        require(amount_ <= STAR.balanceOf(address(this)), "Insufficient STAR balance in contract");
        STAR.safeTransfer(_to, amount_);
    }

    /**
     * @notice convert _amount STARDUST into gBalance_ SUPERNOVA
     * @param _to address
     * @param _amount uint
     * @return gBalance_ uint
     */
    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_) {
        STARDUST.safeTransferFrom(msg.sender, address(this), _amount);
        gBalance_ = SUPERNOVA.balanceTo(_amount);
        SUPERNOVA.mint(_to, gBalance_);
    }

    /**
     * @notice convert _amount SUPERNOVA into sBalance_ STARDUST
     * @param _to address
     * @param _amount uint
     * @return sBalance_ uint
     */
    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_) {
        SUPERNOVA.burn(msg.sender, _amount);
        sBalance_ = SUPERNOVA.balanceFrom(_amount);
        STARDUST.safeTransfer(_to, sBalance_);
    }

    /**
     * @notice trigger rebase if epoch over
     * @return uint256
     */
    function rebase() public returns (uint256) {
        uint256 bounty;
        if (epoch.end <= block.timestamp) {
            STARDUST.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end.add(epoch.length);
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
                bounty = distributor.retrieveBounty(); // Will mint star for this contract if there exists a bounty
            }
            uint256 balance = STAR.balanceOf(address(this));
            uint256 staked = STARDUST.circulatingSupply();
            if (balance <= staked.add(bounty)) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked).sub(bounty);
            }
        }
        return bounty;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as STARDUST or SUPERNOVA
     * @param _to address
     * @param _amount uint
     * @param _rebasing bool
     */
    function _send(
        address _to,
        uint256 _amount,
        bool _rebasing
    ) internal returns (uint256) {
        if (_rebasing) {
            STARDUST.safeTransfer(_to, _amount); // send as STARDUST (equal unit as star)
            return _amount;
        } else {
            SUPERNOVA.mint(_to, SUPERNOVA.balanceTo(_amount)); // send as SUPERNOVA (convert units from star)
            return SUPERNOVA.balanceTo(_amount);
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns the STARDUST index, which tracks rebase growth
     * @return uint
     */
    function index() public view returns (uint256) {
        return STARDUST.index();
    }

    /**
     * @notice total supply in warmup
     */
    function supplyInWarmup() public view returns (uint256) {
        return STARDUST.balanceForGons(gonsInWarmup);
    }

    /**
     * @notice seconds until the next epoch begins
     */
    function secondsToNextEpoch() external view returns (uint256) {
        if(epoch.end > block.timestamp)
          { return epoch.end.sub(block.timestamp); } 
        else { return 0; }          
    }
    
    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice sets the contract address for LP staking
     * @param _distributor address
     */
    function setDistributor(address _distributor) external onlyGovernor {
        distributor = IDistributor(_distributor);
        emit DistributorSet(_distributor);
    }
    /**
     * @notice sets the upcoming distribution
     * @param _amount uint256
     */

    function setDistribution(uint256 _amount) external onlyGovernor {
      epoch.distribute = _amount;
    }
    
    /**
     * @notice r3ealigns the epoch
     * @param _time uint256
     */
    function setEpochEnd(uint256 _time) external onlyGovernor {
      epoch.end = _time;
    }

    /**
     * @notice r3ealigns the epoch
     * @param _time uint256
     */
    function setEpochLength(uint256 _time) external onlyGovernor {
      epoch.length = _time;
    }

    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmupLength(uint256 _warmupPeriod) external onlyGovernor {
        warmupPeriod = _warmupPeriod;
        emit WarmupSet(_warmupPeriod);
    }
  
}