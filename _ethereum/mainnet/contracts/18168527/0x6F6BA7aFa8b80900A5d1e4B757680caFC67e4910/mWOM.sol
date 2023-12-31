// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Address.sol";

import "./IWombatStaking.sol";
import "./IMasterMagpie.sol";
import "./IVLMGP.sol";

/// @title mWOM
/// @author Magpie Team
/// @notice mWOM is a token minted when 1 wom is locked in Magpie
contract mWOM is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public wombatStaking;
    address public wom;
    address public masterMagpie;
    uint256 public totalConverted;
    uint256 public totalAccumulated;

    bool public isWomUp; // not in used anymore, but since upgradable, we should still leave it here

    /* ==== variable added for first upgrade === */

    uint256 public constant DENOMINATOR = 10000;
    uint256 public rewardRatio;
    address public vlMGP;
    address public mgp;

    /* ============ Events ============ */

    event mWomMinted(address indexed user, uint256 amount);
    event MasterMagpieSet(address indexed _masterMagpie);
    event WombatStakingSet(address indexed _wombatStaking);
    event WomConverted(uint256 _womAmount, uint256 _veWomAmount);
    event WomUpSet(bool _isWomUp);
    event VlmgpRewarded(address indexed _beneficiary, uint256 _amount);
    event MPGDustTransfered(address _to, uint256 _amount);

    /* ============ Errors ============ */

    error MasterMagpieNotSet();
    error WombatStakingNotSet();
    error MustBeContract();
    error NoIncentive();

    /* ============ Constructor ============ */

    function __mWom_init(
        address _wombatStaking,
        address _wom,
        uint256 _initMintAmt
    ) public initializer {
        __ERC20_init("mWOM", "mWOM");
        __Ownable_init();
        wombatStaking = _wombatStaking;
        wom = _wom;
        totalConverted = 0;
        totalAccumulated = 0;

        isWomUp = true; // not in used anymore

        // initial mimt to owner
        _mint(owner(), _initMintAmt);
        emit mWomMinted(owner(), _initMintAmt);
    }

    /* ============ External Functions ============ */

    /// @notice deposit WOM in magpie finance and get mWOM at a 1:1 rate
    /// @param _amount the amount of WOM
    function convert(uint256 _amount) external whenNotPaused {
        _convert(_amount, false, true);
    }

    function convertAndStake(uint256 _amount) external whenNotPaused {
        _convert(_amount, true, true);
    }

    function deposit(uint256 _amount) external whenNotPaused {
        _convert(_amount, false, false);
    }

    // if reward ratio is turned on, reward wom converter with vlMGP with the ratio, the ratio can be more than 100%
    function incentiveDeposit(uint256 _amount, bool _stake) external whenNotPaused {
        if (rewardRatio == 0) revert NoIncentive();

        _convert(_amount, _stake, false);
        uint256 vlMGPAmount = (_amount * rewardRatio) / DENOMINATOR;
        IERC20(mgp).safeApprove(address(vlMGP), vlMGPAmount);
        IVLMGP(vlMGP).lockFor(vlMGPAmount, msg.sender);
        emit VlmgpRewarded(msg.sender, vlMGPAmount);
    }

    /* ============ Internal Functions ============ */

    function _convert(
        uint256 _amount,
        bool _forStake,
        bool _doConvert
    ) internal whenNotPaused nonReentrant {
        if (_doConvert) {
            if (wombatStaking == address(0)) revert WombatStakingNotSet();
            IERC20(wom).safeTransferFrom(msg.sender, wombatStaking, _amount);
            _lockWom(_amount, false);
        } else {
            IERC20(wom).safeTransferFrom(msg.sender, address(this), _amount);
        }

        if (_forStake) {
            if (masterMagpie == address(0)) revert MasterMagpieNotSet();
            _mint(address(this), _amount);
            IERC20(address(this)).safeApprove(masterMagpie, _amount);
            IMasterMagpie(masterMagpie).depositFor(
                address(this),
                _amount,
                address(msg.sender)
            );
            IERC20(address(this)).safeApprove(masterMagpie, 0);
        } else {
            _mint(msg.sender, _amount);
        }

        totalConverted = totalConverted + _amount;
        emit mWomMinted(msg.sender, _amount);
    }

    function _lockWom(uint256 _amount, bool _needSend) internal {
        if (_needSend) IERC20(wom).safeTransfer(wombatStaking, _amount);

        uint256 mintedVeWomAmount = IWombatStaking(wombatStaking).convertWOM(_amount);
        totalAccumulated = totalAccumulated + mintedVeWomAmount;

        emit WomConverted(_amount, mintedVeWomAmount);
    }

    /* ============ Admin Functions ============ */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMasterMagpie(address _masterMagpie) external onlyOwner {
        masterMagpie = _masterMagpie;

        emit MasterMagpieSet(_masterMagpie);
    }

    function setWombatStaking(address _wombatStaking) external onlyOwner {
        wombatStaking = _wombatStaking;

        emit WombatStakingSet(wombatStaking);
    }

    function setWomUp(bool _isWomUp) external onlyOwner {
        isWomUp = _isWomUp;

        emit WomUpSet(isWomUp);
    }

    function lockAllWom() external onlyOwner {
        uint256 allWom = IERC20(wom).balanceOf(address(this));
        _lockWom(allWom, true);
    }

    function setRewardRatio(uint256 _rewardRatio) external onlyOwner {
        rewardRatio = _rewardRatio;
    }

    function setVlmgp(address _vlMGP) external onlyOwner {
        if (!Address.isContract(address(_vlMGP))) revert MustBeContract();

        vlMGP = _vlMGP;
        mgp = address(IVLMGP(vlMGP).MGP());
    }

    function transferMGPDust() external onlyOwner {
        uint256 dust = IERC20(mgp).balanceOf(address(this));
        IERC20(mgp).transfer(owner(), dust);

        emit MPGDustTransfered(owner(), dust);
    }

    function mint(address _for, uint256 _amount) external onlyOwner {
        _mint(_for, _amount);
    }
}