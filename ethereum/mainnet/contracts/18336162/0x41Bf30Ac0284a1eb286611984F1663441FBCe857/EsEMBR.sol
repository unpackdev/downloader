// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./EsEMBRRewardsDistributor.sol";
import "./EmberVault.sol";
import "./IVester.sol";
import "./IEMBR.sol";
import "./ERC20.sol";
import "./Owned.sol";

contract EsEMBR is ERC20, Owned, IEsEMBR {
    IEMBRToken public embr;
    address public distributor;
    EmberVault public vault;

    uint256 private totalEthStaked;
    uint256 private totalEmbrStaked;
    uint256 private totalRewardPerEth;
    uint256 private totalRewardPerEmbr;
    uint256 private totalEthPerEsembr;

    uint256 public rewardsLeft = 15_000_000 * 1e18;

    mapping(address => uint256) public stakedEth;
    mapping(address => uint256) public stakedEmbr;
    mapping(address => uint256) entriesEth;
    mapping(address => uint256) entriesEmbr;
    mapping(address => uint256) claimableRewards;

    uint256 public constant PRECISION = 1e30; // thanks gmx

    mapping(address => uint256) public entries;
    mapping(address => uint256) public claimableEth;
    mapping(address => bool) public revShareSources;

    mapping(uint256 => IVester) vesters; // mapping(Timeframe => IVester)
    mapping(uint256 => bool) enabled_vesters; // mapping(Timeframe => bool)

    event Claimed(address indexed user, uint256 amount);

    constructor(address payable _embr, address _distributor, address payable _vault) ERC20("Escrowed EMBR", "esEMBR", 18) Owned(msg.sender) {
        vault = EmberVault(_vault);
        embr = IEMBRToken(_embr);
        distributor = _distributor;

        revShareSources[_vault] = true; // The vault will send the package costs right after token is created
        revShareSources[msg.sender] = true; // Owner will periodically send tax revshare
    }

    modifier onlyDistributor() {
        require(msg.sender == distributor, "esEMBR: Only the distributor can access this function");
        _;
    }

    receive() external payable {
        require(revShareSources[msg.sender], "esEMBR: Only whitelisted addresses can send ETH to esEMBR");

        _updateRevShareForAll(msg.value);
    }

    // =============================== SOUL BOUND OVERRIDES ===============================
    // Transfers should only be allowed to be done by the distributor
    function _transfer(address from, address to, uint256 amount) internal {
        uint256 from_balance = balanceOf[from];
        require(from_balance >= amount, "esEMBR: Amount exceeds balance"); /// I think not needed, the instruction below should revert since we are using SafeMath

        balanceOf[from] = from_balance - amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) onlyDistributor public override returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function _mintRewards(address to, uint256 amount) internal {
        rewardsLeft -= amount;

        _mint(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) onlyDistributor public override returns (bool) {
        _transfer(from, to, amount);

        return true;
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("esEMBR: Approvals are not allowed");
    }

    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) public pure override {
        revert("esEMBR: Permits are not allowed");
    }

    // =============================== ETH STAKING/UNSTAKING ===============================
    event StakedEth(address user, uint256 amount);
    function stakeEth() external payable {
        require(msg.value != 0, "esEMBR: Staked amount cannot be 0");

        _updateRewardsEthForUser(msg.sender);

        stakedEth[msg.sender] += msg.value;
        totalEthStaked += msg.value;

        // send eth to vault
        (bool success, ) = payable(address(vault)).call{value: msg.value}("");
        require(success, "esEMBR: Error forwarding the ETH to the Vault");
    }

    event UnstakedEth(address user, uint256 amount);
    function unstakeEth(uint256 amount) external {
        require(amount != 0, "esEMBR: Unstaked amount cannot be 0");

        _updateRewardsEthForUser(msg.sender);

        uint256 staked = stakedEth[msg.sender];
        require(staked >= amount, "esEMBR: Requested amount exceeds staked amount");

        stakedEth[msg.sender] = staked - amount;
        totalEthStaked -= amount;

        // pull eth from vault
        vault.unstakeEth(amount, msg.sender);

        emit UnstakedEth(msg.sender, amount);
    }

    // =============================== EMBR STAKING/UNSTAKING ===============================
    event StakedEmbr(address user, uint256 amount);
    function stakeEmbr(uint256 amount) external {
        require(amount != 0, "esEMBR: Staked amount cannot be 0");

        _updateRewardsEmbrForUser(msg.sender);

        IEMBRToken(embr).transferFrom(msg.sender, address(this), amount);

        stakedEmbr[msg.sender] += amount;
        totalEmbrStaked += amount;

        emit StakedEmbr(msg.sender, amount);
    }

    event UnstakedEmbr(address user, uint256 amount);
    function unstakeEmbr(uint256 amount) external {
        require(amount != 0, "esEMBR: Unstaked amount cannot be 0");
    
        _updateRewardsEmbrForUser(msg.sender);

        uint256 staked = stakedEmbr[msg.sender];
        require(staked >= amount, "esEMBR: Requested amount exceeds staked amount");

        stakedEmbr[msg.sender] = staked - amount;
        totalEmbrStaked -= amount;

        IEMBRToken(embr).transfer(msg.sender, amount);

		emit UnstakedEmbr(msg.sender, amount);
    }
    
    // ======================== VAULT-ONLY FUNCTIONS =====================
    // This is called by the vault to reward users that pull liquidity of failed tokens
    function reward(address recipient, uint256 amount) external {
        require(msg.sender == address(vault), "esEMBR: Only the vault can reward");

        uint256 _rewardsLeft = rewardsLeft;
        if (amount > _rewardsLeft) amount = _rewardsLeft;

        _updateRevShareForUser(0, recipient);
        _mintRewards(recipient, amount);
    }

    // =============================== CLAIMING ===============================
    // EMBR and ETH stakers can call this function to receive their esEMBR
    function claim() external returns (uint256) {
        _updateRewardsEthForUser(msg.sender);
        _updateRewardsEmbrForUser(msg.sender);
        _updateRevShareForUser(0, msg.sender);

        uint256 to_claim = claimableRewards[msg.sender];
        if (to_claim == 0) return 0;

        claimableRewards[msg.sender] = 0;

        _mintRewards(msg.sender, to_claim);

        return to_claim;
    }

    // This pays out the ETH made from rev share to the esEMBR holder
    function claimRevShare() public returns (uint256) {
        _updateRevShareForUser(0, msg.sender);

        uint256 to_claim = claimableEth[msg.sender];
        if (to_claim == 0) return 0;

        claimableEth[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: to_claim}("");
        require(success, "esEMBR: claimRevShare: failed to send ether");

        return to_claim;
    }
    
    // =============================== ETH REWARDS UPDATER ===============================
    // This function should be called by distributor when the rate changes
    function updateRewardsEthForAll() public {
        uint256 reward_amount = EsEMBRRewardsDistributor(distributor).distributeForEth();
        uint256 _totalEthStaked = totalEthStaked;

        if (reward_amount != 0 && _totalEthStaked != 0) {
            totalRewardPerEth += reward_amount * PRECISION / _totalEthStaked;
        }
    }

    function _updateRewardsEthForUser(address _user) internal {
        updateRewardsEthForAll();

        uint256 staked = stakedEth[_user];
        uint256 userReward = (staked * (totalRewardPerEth - entriesEth[_user])) / PRECISION;

        claimableRewards[_user] += userReward;
        entriesEth[_user] = totalRewardPerEth;
    }

    // =============================== EMBR REWARDS UPDATER ===============================
    function updateRewardsEmbrForAll() public {
        uint256 reward_amount = EsEMBRRewardsDistributor(distributor).distributeForEmbr();
        uint256 supply = totalEmbrStaked;

        if (reward_amount != 0 && supply != 0) {
            totalRewardPerEmbr += reward_amount * PRECISION / supply;
        }
    }

    function _updateRewardsEmbrForUser(address receiver) private {
        updateRewardsEmbrForAll();

        uint256 staked = stakedEmbr[receiver];
        uint256 userReward = (staked * (totalRewardPerEmbr - entriesEmbr[receiver])) / PRECISION;

        claimableRewards[receiver] += userReward;
        entriesEmbr[receiver] = totalRewardPerEmbr;
    }

    // =============================== REV SHARE UPDATER ===============================
    function _updateRevShareForAll(uint256 added) internal {
        uint256 _totalSupply = totalSupply;

        if (added != 0 && _totalSupply != 0) {
            totalEthPerEsembr += added * PRECISION / _totalSupply;
        }
    }

    function _updateRevShareForUser(uint256 added, address receiver) internal {
        _updateRevShareForAll(added);

        uint256 staked = balanceOf[receiver];
        uint256 userReward = (totalEthPerEsembr - entries[receiver]) * staked / PRECISION;

        claimableEth[receiver] += userReward;
        entries[receiver] = totalEthPerEsembr;
    }

    function vest(uint256 timeframe, uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "esEMBR: Amount exceeds your balance");

        IVester _vester = vesters[timeframe];
        require(address(_vester) != address(0), "esEMBR: Invalid vesting timeframe");
        require(enabled_vesters[timeframe], "esEMBR: This vesting timeframe is currently disabled");

        // Update revshare state so the user doesn't keep collecting revshare for the old balance
        _updateRevShareForUser(0, msg.sender);

        // Burn the tokens
        _burn(msg.sender, amount);

        // Claim whatever EMBR rewards the user had pending in this timeframe before vesting the new amount
        _collect(msg.sender, timeframe);

        _vester.vest(msg.sender, amount);
    }

    // Useful for batching multiple different claims into one call
    function batchCollectVested(uint[] calldata timeframes) external returns (uint) {
        uint256 totalClaimed = 0;

        for (uint256 i = 0; i < timeframes.length; i++) {
            totalClaimed += _collect(msg.sender, timeframes[i]);
        }

        return totalClaimed;
    }

    // Collect the vested EMBR, if any
    function collectVested(uint256 timeframe) external returns (uint) {
        return _collect(msg.sender, timeframe);
    }

    // Checks with the vester if there is any EMBR to claim, and if yes, transfer the EMBR and emit event
    // Returns the claimed amount
    function _collect(address addy, uint256 timeframe) internal returns(uint) {
        uint256 claimable_amount = vesters[timeframe].claim(addy);
        if (claimable_amount != 0) {
            embr.transfer(addy, claimable_amount);

            emit Claimed(msg.sender, claimable_amount);
        }

        return claimable_amount;
    }

    // ====================== VIEW FUNCTIONS ========================
    // Returns the amount of esEMBR tokens that are available to be claimed by _address, both for embr staking and eth staking
    function claimable(address _address) public view returns (uint256) {
        uint256 stakedAmountEth = stakedEth[_address];
        uint256 stakedAmountEmbr = stakedEmbr[_address];
        if (stakedAmountEth == 0 && stakedAmountEmbr == 0) {
            return claimableRewards[_address];
        }

        uint256 _totalEthStaked = totalEthStaked;
        uint256 userRewardForEth;
        if (_totalEthStaked != 0) {
            uint256 pendingRewardsEth = EsEMBRRewardsDistributor(distributor).pendingForEth() * PRECISION;
            uint256 currentTotalRewardPerEth = totalRewardPerEth + (pendingRewardsEth / _totalEthStaked);

            userRewardForEth = stakedAmountEth * (currentTotalRewardPerEth - entriesEth[_address]) / PRECISION;
        }

        uint256 _totalEmbrStaked = totalEmbrStaked;
        uint256 userRewardForEmbr;
        if (_totalEmbrStaked != 0) {
            uint256 pendingRewardsEmbr = EsEMBRRewardsDistributor(distributor).pendingForEmbr() * PRECISION;
            uint256 currentTotalRewardPerEmbr = totalRewardPerEmbr + (pendingRewardsEmbr / _totalEmbrStaked);

            userRewardForEmbr = stakedAmountEmbr * (currentTotalRewardPerEmbr - entriesEmbr[_address]) / PRECISION;
        }

        return claimableRewards[_address] + userRewardForEth + userRewardForEmbr;
    }

    // Accounts for the pending rewards as well
    function claimableRevShare(address _address) public view returns (uint256) {
        uint256 esembr_balance = balanceOf[_address];
        if (esembr_balance == 0) {
            return claimableEth[_address];
        }

        return claimableEth[_address] + ((totalEthPerEsembr - entries[_address]) * esembr_balance / PRECISION);
    }

    // Returns the amount of EMBR tokens that can be claimed by esEMBR vesters
    function claimableEMBR(address addy, uint256[] calldata timeframes) public view returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < timeframes.length; i++) {
            ( uint256 claimableAmount, ) = vesters[timeframes[i]].claimable(addy);

            total += claimableAmount;
        }

        return total;
    }

    function getVestedEsEMBR(address addy, uint256[] calldata timeframes) public view returns (uint256[] memory) {
        uint256[] memory vestedAmounts = new uint256[](timeframes.length);

        for (uint256 i = 0; i < timeframes.length; i++) {
            vestedAmounts[i] = vesters[timeframes[i]].vestingAmount(addy);
        }

        return vestedAmounts;
    }

    // ====================== ADMIN FUNCTIONS =========================
    // Add new vester contracts
    function addVester(uint256 timeframe, IVester vester) onlyOwner external {
        require(vester.vestingTime() == timeframe, "esEMBR: The timeframe provided does not match the vester's timeframe");
        require(address(vesters[timeframe]) == address(0), "esEMBR: The timeframe provided already exists");

        vesters[timeframe] = vester;
        enabled_vesters[timeframe] = true;
    }

    // Allow owner to disable specific vesting timeframes, this will stop new users from vesting but existing vesters will be able to claim their tokens without an issue.
    function setVesterStatus(uint256 timeframe, bool status) onlyOwner external {
        require(address(vesters[timeframe]) != address(0), "esEMBR: Timeframe does not exist");

        enabled_vesters[timeframe] = status;
    }

    function setRevShareSource(address _source, bool _enabled) onlyOwner external {
        revShareSources[_source] = _enabled;
    }
}