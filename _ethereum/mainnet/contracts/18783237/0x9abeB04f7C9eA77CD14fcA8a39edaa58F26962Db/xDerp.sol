// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./Initializable.sol";

interface IERC20 is IERC20Upgradeable {
    function burn(uint256 amount) external;
}

interface IYieldBooster {
    struct IncentiveKey {
        address rewardToken;
        address pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
    }

    function allocate(
        address user,
        uint256 tokenId,
        uint256 xDerpAmount,
        uint256 duration,
        IncentiveKey calldata key
    ) external;

    function deAllocate(
        address user,
        uint256 tokenId,
        uint256 xDerpAmount,
        IncentiveKey calldata key
    ) external;
}

contract xDERP is Initializable, ERC20Upgradeable {

    IERC20 public Derp;

    struct RedeemInfo {
        uint256 derpAmount;
        uint256 xDerpAmount;
        uint256 timestamp;
        uint256 endTime; 
    }

    mapping(address => bool) public transferWhitelist;
    mapping(address => RedeemInfo[]) public redeems;
    mapping(address => uint256) public pendingRedeemAmount;


    uint256 public minRedeemRatio;
    uint256 public maxRedeemRatio;
    uint256 public minRedeemDuration;
    uint256 public maxRedeemDuration;

    address public admin;
    address public foundation;

    //user => xDerpamount
    mapping(address => uint256) allocations;

    error NOT_WHITELISTED();
    error DURATION_TOO_LOW();
    error DURATION_NOT_ENDED();
    error ONLY_ADMIN();
    error INVALID_ALLOCATION_AMOUNT();
    error ALREADY_FINALIZED();
    error INVALID_DURATION();

    event Stake(address user, uint256 amount);
    event Redeem(address user, uint256 amount, uint256 duration, uint256 redeemIndex);
    event FinalizeRedeem(address user, uint256 redeemIndex, uint256 derpAmount, uint256 xDerpAmount);
    event AdminChanged(address newAdmin, address oldAdmin);
    event ParamsUpdated(uint256 minRedeemRatio, uint256 maxRedeemRatio, uint256 minRedeemDuration, uint256 maxRedeemDuration, address foundation);

    modifier onlyAdmin {
        if(msg.sender != admin) {
            revert ONLY_ADMIN();
        }
        _;
    }

    function initialize(
        IERC20 _DERP,
        uint256 _minRedeemRatio,
        uint256 _maxRedeemRatio,
        uint256 _minRedeemDuration,
        uint256 _maxRedeemDuration,
        address _admin,
        address _foundation
    ) external initializer {
        __ERC20_init("xDERP", "xDERP");
        Derp = _DERP;

        minRedeemRatio = _minRedeemRatio;
        maxRedeemRatio = _maxRedeemRatio;
        minRedeemDuration = _minRedeemDuration;
        maxRedeemDuration = _maxRedeemDuration;

        admin = _admin;
        foundation = _foundation;

        transferWhitelist[address(this)] = true;
    }

    function stake(uint256 amount) external {
        Derp.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        emit Stake(msg.sender, amount);
    }

    function allocate(address to, uint256 tokenId, uint256 amount, uint256 duration, IYieldBooster.IncentiveKey calldata key) external {
        _transfer(msg.sender, address(this), amount);
        allocations[msg.sender] += amount;
        IYieldBooster(to).allocate(msg.sender, tokenId, amount, duration, key);
    }

    function deAllocate(address to, uint256 tokenId, uint256 amount, IYieldBooster.IncentiveKey calldata key) external {
        if( allocations[msg.sender] < amount) revert INVALID_ALLOCATION_AMOUNT();
        allocations[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount);
        IYieldBooster(to).deAllocate(msg.sender, tokenId, amount, key);
    }

    function redeem(uint256 xDerpAmount, uint256 duration) external {
        if(duration < minRedeemDuration) revert DURATION_TOO_LOW();
        if(duration != minRedeemDuration && duration < maxRedeemDuration) revert INVALID_DURATION();

        _transfer(msg.sender, address(this), xDerpAmount);

        uint256 derpAmount = _derpByDuration(xDerpAmount, duration);
        
        if(duration > 0) {
            pendingRedeemAmount[msg.sender] += xDerpAmount;

            redeems[msg.sender].push(RedeemInfo({
                derpAmount: derpAmount,
                xDerpAmount: xDerpAmount,
                timestamp: block.timestamp,
                endTime: block.timestamp + duration
            }));

            emit Redeem(msg.sender, xDerpAmount, duration, redeems[msg.sender].length -1);
        } else {
            _finalizeRedeem(msg.sender, xDerpAmount, derpAmount);

            emit Redeem(msg.sender, xDerpAmount, duration, type(uint256).max);
            emit FinalizeRedeem(msg.sender, type(uint256).max, derpAmount, xDerpAmount);
        }

    }

    function finalizeRedeem(uint256 redeemIndex) external {
        RedeemInfo storage redeemInfo = redeems[msg.sender][redeemIndex];
        if(redeemInfo.endTime > block.timestamp) revert DURATION_NOT_ENDED();

        if(redeemInfo.xDerpAmount == 0) revert ALREADY_FINALIZED();

        pendingRedeemAmount[msg.sender] -= redeemInfo.xDerpAmount;
        _finalizeRedeem(msg.sender, redeemInfo.xDerpAmount, redeemInfo.derpAmount);
        
        emit FinalizeRedeem(msg.sender, redeemIndex, redeemInfo.derpAmount, redeemInfo.xDerpAmount);

        delete redeems[msg.sender][redeemIndex];
    }

    
    //ADMIN actions
    function updateWhitelist(address to, bool value) external onlyAdmin {
        transferWhitelist[to] = value;
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;

        emit AdminChanged(newAdmin, oldAdmin);
    }

    function setParams(
        uint256 _minRedeemRatio,
        uint256 _maxRedeemRatio,
        uint256 _minRedeemDuration,
        uint256 _maxRedeemDuration,
        address _foundation
    ) external onlyAdmin {
        minRedeemRatio = _minRedeemRatio;
        maxRedeemRatio = _maxRedeemRatio;
        minRedeemDuration = _minRedeemDuration;
        maxRedeemDuration = _maxRedeemDuration;
        foundation = _foundation;

        emit ParamsUpdated(_minRedeemRatio, _maxRedeemRatio, _minRedeemDuration, _maxRedeemDuration, _foundation);
    }

    //VIEW
    function redeemAmount(uint256 xDerpAmount, uint256 duration) external view returns (uint256) {
        return _derpByDuration(xDerpAmount, duration);
    }

    //internal
    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        if(
            from != address(0) && to != address(0) && 
            (!transferWhitelist[from] && !transferWhitelist[to]) //reverts if both are not whitelisted. Allows if either is whitelisted
        ) {
            revert NOT_WHITELISTED();
        }
    }


    function _derpByDuration(uint256 amount, uint256 duration) internal view returns(uint256) {
        if(duration < minRedeemDuration) {
            return 0;
        }

        if (duration > maxRedeemDuration) {
            return amount;
        }

        uint256 ratio = minRedeemRatio + (
            (duration - minRedeemDuration) * (maxRedeemRatio - minRedeemRatio) /
            (maxRedeemDuration - minRedeemDuration)
        );

        return amount * ratio / 100;
    }

    function _finalizeRedeem(address user, uint256 xDerpAmount, uint256 derpAmount) internal {
        uint256 excess = xDerpAmount - derpAmount;
        Derp.transfer(user, derpAmount);
        Derp.transfer(foundation, excess);

        _burn(address(this), xDerpAmount);
    }
}