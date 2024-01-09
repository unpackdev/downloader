// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "flatHelper.sol";

contract AQRURouter is AccessControlUpgradeable {

    struct UserInfo{
        uint256 deposited;
        uint256 shares;
        uint256 discount;
        uint256 gained;
        uint256 decr;
    }

    uint256 public constant PERCENT_ACCURACY = 100_00;

    address public stakingPools;
    address public rewardsContract;
    uint256 public AQRUPool;

    uint256[] public discountThresholds;
    uint256[] public discounts;

    /// @notice vaultId => vaultAdress
    mapping(uint256 => IVaultAPI) public vaults;

    /// @notice vaultId => user address => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => bool) public allowList;

    event Deposit(uint256 vid, address user, uint256 deposited, uint256 shares, uint256 discount);
    event Withdraw(uint256 vid, address user, uint256 withdrawed, uint256 income, uint256 shares, uint256 discount, bool gained);
    event AddVault(uint256 vid, address vault);

    modifier onlyAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller must be an admin");
        _;
    }

    modifier hasVault(uint256 vid){
        require(address(vaults[vid]) != address(0), "There is no vault for this id");
        _;
    }

    modifier onlyUser(){
        require(!AddressUpgradeable.isContract(_msgSender()) || allowList[_msgSender()], "Only user can use this function");
        _;
    }

    function initialize() public virtual initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setThresholdsAndDiscount(uint[] memory _discountThresholds, uint256[] memory _discounts) external onlyAdmin{
        require(_discountThresholds.length == _discounts.length, "Length mismatch"); //TOS+DOncomments
        if(_discounts.length > 1){
            for(uint256 i; i < _discounts.length - 1; i++){
                require(_discounts[i] > _discounts[i+1], "Numbers must be from largest to smallest");
                require(_discountThresholds[i] > _discountThresholds[i+1], "Numbers must be from largest to smallest");
                require( _discounts[i] <= PERCENT_ACCURACY && _discounts[i+1] <= PERCENT_ACCURACY, "Discount must be with only 2 decimals");
            }
        }
        discountThresholds = _discountThresholds;
        discounts = _discounts;
    }

    function setStakingPools(address _stakingPools) external onlyAdmin{
        stakingPools = _stakingPools;
    }

    function setAQRUPool(uint256 _pid) external onlyAdmin {
        AQRUPool = _pid;
    } 

    function setRewardsContract(address _rewards) external onlyAdmin{
        rewardsContract = _rewards;
    }

    function addVault(uint256 _vid, address _vaultAddress) external onlyAdmin {
        vaults[_vid] = IVaultAPI(_vaultAddress); // todo event
        emit AddVault(_vid, _vaultAddress);
    }

    function addToAllowList(address _contract, bool flag) external onlyAdmin{
        allowList[_contract] = flag;
    }

    function getDiscount(address _user) public view returns (uint256 discount){
        for(uint256 i; i < discounts.length; i++){
            if(IAQRUStaking(stakingPools).userPoolAmount(AQRUPool, _user) >= discountThresholds[i]) return discounts[i];
        }
    }

    function deposit(uint256 _vid, uint256 _amount) external hasVault(_vid) onlyUser{
        require(_amount > 0, "Amount is too low");
        IVaultAPI vault = vaults[_vid];
        UserInfo storage user = userInfo[_vid][_msgSender()];
        IERC20(vault.token()).transferFrom(_msgSender(), address(this), _amount);
        IERC20(vault.token()).approve(address(vault), _amount);
        uint256 sharesIncome =  vault.deposit(_amount, address(this));

        uint256 discount = getDiscount(_msgSender());
        (user.discount == 0) ? user.discount = discount 
        : user.discount = (user.discount < discount) ? user.discount : discount;
 
        user.shares += sharesIncome;
        user.deposited += _amount;
        
        emit Deposit(_vid, _msgSender(), _amount, sharesIncome, user.discount);
    }

    function withdraw(uint256 _vid, uint256 _amount) external hasVault(_vid) onlyUser{
        uint256 shares = userInfo[_vid][_msgSender()].shares;
        require(shares > 0, "You have to deposit before withdraw");
        require(shares >= _amount && _amount > 0, "Wrong amount");
        _withdraw(_vid, _amount);
    }

    function withdrawAll(uint256 _vid) external hasVault(_vid) onlyUser{
        uint256 shares = userInfo[_vid][_msgSender()].shares;
        require(shares > 0, "You have to deposit before withdraw");
        _withdraw(_vid, shares);
    }
    function getUserInfo(uint256 _vid, address _user) external view hasVault(_vid) returns(UserInfo memory){
        return(userInfo[_vid][_user]);
    }
   
    function _withdraw(uint256 _vid, uint256 _amount) internal {
        UserInfo storage user = userInfo[_vid][_msgSender()];
        bool lost;
        uint256 gain;
        uint256 loss;
        vaults[_vid].approve(address(vaults[_vid]), _amount);
        uint256 withdrawed = vaults[_vid].withdraw(_amount, _msgSender());        
        if(vaults[_vid].shareValue(user.shares) > user.deposited){
            gain = withdrawed - _amount * user.deposited / user.shares;
            uint256 feeToCompensate = _calculatefeeToCompensate(_vid, gain, user);
            if (feeToCompensate > 0){                
                IRewardsCollector(rewardsContract).getCompensation(feeToCompensate, _msgSender(), address(vaults[_vid]));
            }
        } else {
            lost = true;
            loss = _amount * user.deposited / user.shares - withdrawed;
        }
        user.shares -= _amount;
        if(user.shares == 0) user.deposited = 0;
        emit Withdraw(_vid, _msgSender(), withdrawed, (loss == 0)? gain : loss, _amount, getDiscount(_msgSender()), !lost);
    }

    function _calculatefeeToCompensate(uint256 _vid, uint256 _gain, UserInfo memory user) internal view returns(uint256 fee) {
        if (user.discount > 0){
            uint256 currentDiscount = getDiscount(_msgSender());
            if(currentDiscount > 0){
                fee = _gain * (vaults[_vid].performanceFee() + (vaults[_vid].managementFee())) / PERCENT_ACCURACY;
                uint256 feeToCompensate = fee * (
                    (currentDiscount > user.discount)? user.discount : currentDiscount
                    ) / (PERCENT_ACCURACY);
                return feeToCompensate;
            }      
        }
   }
}