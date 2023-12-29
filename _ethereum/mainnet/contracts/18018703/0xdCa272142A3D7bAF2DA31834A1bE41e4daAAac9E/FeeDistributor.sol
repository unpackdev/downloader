// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IRewardsDistributionRecipient.sol";
import "./IVaultFactory.sol";
import "./IVault.sol";
import "./IWstETH.sol";
import "./IFeeWallet.sol";
import "./IFeeManager.sol";

// FeeDistributor is a contract that collects fee (in wstETH) from fee wallets (Protocol Fee Wallet and Redemption Fee Wallet) 
// and distribute to recipients contract (e.g., StakingRewards)
contract FeeDistributor is Ownable {

    /* ========== STATE VARIABLES ========== */

    IRewardsDistributionRecipient[] public recipients;
    uint256[] public protocolFeeShares; // how many shares recipients[i] gets of protocolFee
    uint256[] public redemptionFeeShares; // how many shares recipients[i] gets of redemptionFee
    uint256 public toalProtocolFeeShares;
    uint256 public totalRedemptionFeeShares;

    IVaultFactory public factory;
    
    mapping(address => bool) public keepers;
    bool public allowPublicKeeper;
    uint public keeperFee = 1e17; // flat fee in reward token

    /* ========== CONSTRUCTOR ========== */

    constructor(IVaultFactory _factory) {
        factory = _factory;
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function setKeeper(address _address, bool _status) external onlyOwner {
        keepers[_address] = _status;
    }

    function setAllowPublicKeeper(bool _status) external onlyOwner {
        allowPublicKeeper = _status;
    }

    function setDistribution(
        IRewardsDistributionRecipient[] calldata _recipients,
        uint256[] calldata _protocolFeeShares,
        uint256[] calldata _redemptionFeeShares
    )
        external
        onlyOwner
    {
        require(_recipients.length == _protocolFeeShares.length && _recipients.length == _redemptionFeeShares.length, "!length");

        recipients = _recipients;
        protocolFeeShares = _protocolFeeShares;
        redemptionFeeShares = _redemptionFeeShares;

        // recalculate total shares
        uint256 _totalProtocolFeeShares;
        uint256 _totalRedemptionFeeShares;
        for (uint256 i = 0; i < _recipients.length; i++) {
            _totalProtocolFeeShares += _protocolFeeShares[i];
            _totalRedemptionFeeShares += _redemptionFeeShares[i];
        }
        toalProtocolFeeShares = _totalProtocolFeeShares;
        totalRedemptionFeeShares = _totalRedemptionFeeShares;
    }

    function setKeeperFee(uint _keeperFee) external onlyOwner {
        keeperFee = _keeperFee;
    }

    function rescue(address _token, address _recipient) external onlyOwner {
        uint _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_recipient, _balance);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Claim pending rewards from all vaults
    function claimAll() public {
        uint len = factory.vaultsLength();
        for (uint i=0; i<len; i++) {
            IVault(factory.allVaults(i)).claim();
        }
    }

    // Claim from all vaults with pending rewards > _pending
    function claimAllGreaterThan(uint _pending) public {
        uint len = factory.vaultsLength();
        for (uint i=0; i<len; i++) {
            IVault vault = IVault(factory.allVaults(i));
            if (vault.pendingYield() >= _pending) {
                vault.claim();
            }
        }
    }

    // Claim from selected vaults
    function claimSome(IVault[] calldata vaults) public {
        uint len = vaults.length;
        for (uint i=0; i<len; i++) {
            vaults[i].claim();
        }
    }

    function claimAllAndDistribute() external onlyKeeperOrAllowPublicKeeper {
        claimAll();
        _distributeFee();
    }

    function claimAllGreaterThanAndDistribute(uint _pending) external onlyKeeper {
        claimAllGreaterThan(_pending);
        _distributeFee();
    }

    function claimSomeAndDistribute(IVault[] calldata vaults) external onlyKeeper {
        claimSome(vaults);
        _distributeFee();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // get fee (wstETH) from fee wallets (ProtocolFeeWallet and RedemptionFeeWallet) and distribute to recipients contract
    function _distributeFee() internal {
        IFeeWallet protocolFeeWallet = IFeeWallet(IFeeManager(factory.feeManager()).protocolFeeTo());
        IFeeWallet redemptionFeeWallet = IFeeWallet(IFeeManager(factory.feeManager()).redemptionFeeTo());

        uint protocolFee = protocolFeeWallet.withdraw();
        uint redemptionFee = redemptionFeeWallet.withdraw();
        // protocolFeeWallet and redemptionFeeWallet use same fee token (wstETH)
        IERC20 feeToken = IERC20(protocolFeeWallet.feeToken());        
        // Pay keeper
        // we make the keeper fee be shared between protocol fee and redemption fee (proportionally), because
        // 1. it's fair
        // 2. even if one of the fee (e.g., protocol fee) is 0, the reward from another fee (redemption fee) can still be distributed
        require(protocolFee + redemptionFee > keeperFee, "not enough fee collected");
        uint keeperFeeFromProtocolFee =  keeperFee * protocolFee / (protocolFee + redemptionFee);
        uint keeperFeeFromRedemptionFee = keeperFee * redemptionFee / (protocolFee + redemptionFee);
        protocolFee -= keeperFeeFromProtocolFee;
        redemptionFee -= keeperFeeFromRedemptionFee;
        feeToken.transfer(msg.sender, keeperFeeFromProtocolFee + keeperFeeFromRedemptionFee);

        // Distribute to recipient
        for (uint i = 0; i < recipients.length; i++) {
            // Revert if recipient reward period not finished
            IRewardsDistributionRecipient recipient = recipients[i];
            require(block.timestamp >= recipient.periodFinish(), "!finished");
            uint256 amount = protocolFee * protocolFeeShares[i] / toalProtocolFeeShares + redemptionFee * redemptionFeeShares[i] / totalRedemptionFeeShares;
            // Send reward and notify
            feeToken.transfer(address(recipient), amount);
            recipient.notifyRewardAmount(amount);
            emit DistributedReward(msg.sender, address(recipient), address(feeToken), amount);
        }
    }

    /* ========== MODIFIERS ========== */
    

    modifier onlyKeeperOrAllowPublicKeeper() {
        require(keepers[msg.sender] == true || allowPublicKeeper, "!allowed");
        _;
    }

    modifier onlyKeeper() {
        require(keepers[msg.sender] == true, "!keeper");
        _;
    }

    /* ========== EVENTS ========== */

    event DistributedReward(address funder, address recipient, address feeToken, uint256 amount);
}
