pragma solidity 0.5.16;

import "./Address.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IController.sol";
import "./IStrategy.sol";
import "./IVault.sol";
import "./IFeeRewardForwarder.sol";
import "./Governable.sol";
import "./GalacticRewards.sol";

contract Controller is IController, Governable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // external parties
    address public feeRewardForwarder;

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    mapping(address => bool) public greyList;

    // All vaults that we have
    mapping(address => bool) public vaults;

    // Rewards for force unleash. Nullable.
    GalacticRewards public galacticRewards;

    uint256 public constant profitSharingNumerator = 5;
    uint256 public constant profitSharingDenominator = 100;

    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    modifier validVault(address _vault) {
        require(vaults[_vault], "vault does not exist");
        _;
    }

    mapping(address => bool) public galacticWorkers;

    modifier onlyGalacticWorkerOrGovernance() {
        require(
            galacticWorkers[msg.sender] || (msg.sender == governance()),
            "only force unleasher can call this"
        );
        _;
    }

    constructor(address _storage, address _feeRewardForwarder)
        public
        Governable(_storage)
    {
        require(
            _feeRewardForwarder != address(0),
            "feeRewardForwarder should not be empty"
        );
        feeRewardForwarder = _feeRewardForwarder;
    }

    function addGalacticWorker(address _worker) public onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        galacticWorkers[_worker] = true;
    }

    function removeGalacticWorker(address _worker) public onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        galacticWorkers[_worker] = false;
    }

    function hasVault(address _vault) external returns (bool) {
        return vaults[_vault];
    }

    // Only smart contracts will be affected by the greyList.
    function addToGreyList(address _target) public onlyGovernance {
        greyList[_target] = true;
    }

    function removeFromGreyList(address _target) public onlyGovernance {
        greyList[_target] = false;
    }

    function setFeeRewardForwarder(address _feeRewardForwarder)
        public
        onlyGovernance
    {
        require(
            _feeRewardForwarder != address(0),
            "new reward forwarder should not be empty"
        );
        feeRewardForwarder = _feeRewardForwarder;
    }

    function addVaultAndStrategy(address _vault, address _strategy)
        external
        onlyGovernance
    {
        require(_vault != address(0), "new vault shouldn't be empty");
        require(!vaults[_vault], "vault already exists");
        require(_strategy != address(0), "new strategy shouldn't be empty");

        vaults[_vault] = true;
        // adding happens while setting
        IVault(_vault).setStrategy(_strategy);
    }

    function forceUnleashed(address _vault)
        external
        onlyGalacticWorkerOrGovernance
        validVault(_vault)
    {
        uint256 oldSharePrice = IVault(_vault).getPricePerFullShare();
        IVault(_vault).forceUnleashed();
        if (address(galacticRewards) != address(0)) {
            // rewards are an option now
            galacticRewards.rewardMe(msg.sender, _vault);
        }
        emit SharePriceChangeLog(
            _vault,
            IVault(_vault).strategy(),
            oldSharePrice,
            IVault(_vault).getPricePerFullShare(),
            block.timestamp
        );
    }

    function rebalance(address _vault)
        external
        onlyGalacticWorkerOrGovernance
        validVault(_vault)
    {
        IVault(_vault).rebalance();
    }

    function setGalacticRewards(address _galacticRewards)
        external
        onlyGovernance
    {
        galacticRewards = GalacticRewards(_galacticRewards);
    }

    // transfers token in the controller contract to the governance
    function salvage(address _token, uint256 _amount) external onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    function salvageStrategy(
        address _strategy,
        address _token,
        uint256 _amount
    ) external onlyGovernance {
        // the strategy is responsible for maintaining the list of
        // salvagable tokens, to make sure that governance cannot come
        // in and take away the coins
        IStrategy(_strategy).salvage(governance(), _token, _amount);
    }

    function notifyFee(address underlying, uint256 fee) external {
        if (fee > 0) {
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), fee);
            IERC20(underlying).safeApprove(feeRewardForwarder, 0);
            IERC20(underlying).safeApprove(feeRewardForwarder, fee);
            IFeeRewardForwarder(feeRewardForwarder).poolNotifyFixedTarget(
                underlying,
                fee
            );
        }
    }
}
