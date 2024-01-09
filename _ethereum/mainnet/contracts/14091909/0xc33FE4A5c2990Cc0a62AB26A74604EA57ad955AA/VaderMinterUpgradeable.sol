// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity =0.8.9;

import "./OwnableUpgradeable.sol";

import "./ProtocolConstants.sol";
import "./IVaderMinterUpgradeable.sol";
import "./IUSDV.sol";
import "./VaderMinterStorage.sol";

contract VaderMinterUpgradeable is
    VaderMinterStorage,
    IVaderMinterUpgradeable,
    ProtocolConstants,
    OwnableUpgradeable
{
    // USDV Contract for Mint / Burn Operations
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IUSDV public immutable usdv;

    /* ========== CONSTRUCTOR ========== */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _usdv) {
        require(_usdv != address(0), "usdv = zero address");
        usdv = IUSDV(_usdv);
    }

    function initialize() external initializer {
        __Ownable_init();
        cycleTimestamp = block.timestamp;
    }

    /* ========== VIEWS ========== */

    function getPublicFee() public view returns (uint256) {
        // 24 hours passed, reset fee to 100%
        if (block.timestamp >= cycleTimestamp) {
            return dailyLimits.fee;
        }

        // cycle timestamp > block.timestamp, fee < 100%
        return
            (dailyLimits.fee * (cycleTimestamp - block.timestamp)) / 24 hours;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /*
     * @dev Public mint function that receives Vader and mints USDV.
     * @param vAmount Vader amount to burn.
     * @param uAmountMinOut USDV minimum amount to get back from the mint.
     * @returns uAmount in USDV, represents the USDV amount received from the mint.
     **/
    function mint(uint256 vAmount, uint256 uAmountMinOut)
        external
        returns (uint256 uAmount)
    {
        uint256 vPrice = lbt.getVaderPrice();

        uAmount = (vPrice * vAmount) / 1e18;

        if (cycleTimestamp <= block.timestamp) {
            cycleTimestamp = block.timestamp + 24 hours;
            cycleMints = uAmount;
            cycleBurns = 0;
        } else {
            cycleMints += uAmount;
        }

        require(
            cycleMints <= dailyLimits.mintLimit,
            "VMU::mint: 24 Hour Limit Reached"
        );

        // Actual amount of USDV minted including fees
        uAmount = usdv.mint(
            msg.sender,
            vAmount,
            uAmount,
            getPublicFee(),
            dailyLimits.lockDuration
        );

        require(
            uAmount >= uAmountMinOut,
            "VMU::mint: Insufficient Trade Output"
        );

        return uAmount;
    }

    /*
     * @dev Public burn function that receives USDV and mints Vader.
     * @param uAmount USDV amount to burn.
     * @param vAmountMinOut Vader minimum amount to get back from the burn.
     * @returns vAmount in Vader, represents the Vader amount received from the burn.
     *
     **/
    function burn(uint256 uAmount, uint256 vAmountMinOut)
        external
        returns (uint256 vAmount)
    {
        uint256 vPrice = lbt.getVaderPrice();

        vAmount = (1e18 * uAmount) / vPrice;

        if (cycleTimestamp <= block.timestamp) {
            cycleTimestamp = block.timestamp + 24 hours;
            cycleBurns = uAmount;
            cycleMints = 0;
        } else {
            cycleBurns += uAmount;
        }

        require(
            cycleBurns <= dailyLimits.burnLimit,
            "VMU::burn: 24 Hour Limit Reached"
        );

        // Actual amount of Vader minted including fees
        vAmount = usdv.burn(
            msg.sender,
            uAmount,
            vAmount,
            getPublicFee(),
            dailyLimits.lockDuration
        );

        require(
            vAmount >= vAmountMinOut,
            "VMU::burn: Insufficient Trade Output"
        );

        return vAmount;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /*
     * @dev Partner mint function that receives Vader and mints USDV.
     * @param vAmount Vader amount to burn.
     * @param uAmountMinOut USDV minimum amount to get back from the mint.
     * @returns uAmount in USDV, represents the USDV amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerMint(uint256 vAmount, uint256 uAmountMinOut)
        external
        returns (uint256 uAmount)
    {
        require(
            partnerLimits[msg.sender].mintLimit != 0,
            "VMU::partnerMint: Not Whitelisted"
        );
        uint256 vPrice = lbt.getVaderPrice();

        uAmount = (vPrice * vAmount) / 1e18;

        Limits storage _partnerLimits = partnerLimits[msg.sender];

        require(
            uAmount <= _partnerLimits.mintLimit,
            "VMU::partnerMint: Mint Limit Reached"
        );

        unchecked {
            _partnerLimits.mintLimit -= uAmount;
        }

        uAmount = usdv.mint(
            msg.sender,
            vAmount,
            uAmount,
            _partnerLimits.fee,
            _partnerLimits.lockDuration
        );

        require(
            uAmount >= uAmountMinOut,
            "VMU::partnerMint: Insufficient Trade Output"
        );

        return uAmount;
    }

    /*
     * @dev Partner burn function that receives USDV and mints Vader.
     * @param uAmount USDV amount to burn.
     * @param vAmountMinOut Vader minimum amount to get back from the burn.
     * @returns vAmount in Vader, represents the Vader amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerBurn(uint256 uAmount, uint256 vAmountMinOut)
        external
        returns (uint256 vAmount)
    {
        require(
            partnerLimits[msg.sender].burnLimit != 0,
            "VMU::partnerBurn: Not Whitelisted"
        );
        uint256 vPrice = lbt.getVaderPrice();

        vAmount = (1e18 * uAmount) / vPrice;

        Limits storage _partnerLimits = partnerLimits[msg.sender];

        require(
            vAmount <= _partnerLimits.burnLimit,
            "VMU::partnerBurn: Burn Limit Reached"
        );

        unchecked {
            _partnerLimits.burnLimit -= vAmount;
        }

        vAmount = usdv.burn(
            msg.sender,
            uAmount,
            vAmount,
            _partnerLimits.fee,
            _partnerLimits.lockDuration
        );

        require(
            vAmount >= vAmountMinOut,
            "VMU::partnerBurn: Insufficient Trade Output"
        );

        return vAmount;
    }

    /*
     * @dev Sets the daily limits for public mints represented by the param {_dailyMintLimit}.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_fee} fee can not be bigger than _MAX_BASIS_POINTS.
     * - Param {_mintLimit} mint limit can be 0.
     * - Param {_burnLimit} burn limit can be 0.
     * - Param {_lockDuration} lock duration can be 0.
     **/
    function setDailyLimits(
        uint256 _fee,
        uint256 _mintLimit,
        uint256 _burnLimit,
        uint256 _lockDuration
    ) external onlyOwner {
        require(_fee <= _MAX_BASIS_POINTS, "VMU::setDailyLimits: Invalid Fee");
        require(
            _lockDuration <= _MAX_LOCK_DURATION,
            "VMU::setDailyLimits: Invalid lock duration"
        );

        Limits memory _dailyLimits = Limits({
            fee: _fee,
            mintLimit: _mintLimit,
            burnLimit: _burnLimit,
            lockDuration: _lockDuration
        });

        emit DailyLimitsChanged(dailyLimits, _dailyLimits);
        dailyLimits = _dailyLimits;
    }

    /*
     * @dev Sets the a partner address {_partner }  to a given limit {_limits} that represents the ability
     * to mint USDV from the reserve partners minting allocation.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_partner} cannot be a zero address.
     * - Param {_fee} fee can not be bigger than _MAX_BASIS_POINTS.
     * - Param {_mintLimit} mint limits can be 0.
     * - Param {_burnLimit} burn limits can be 0.
     * - Param {_lockDuration} lock duration can be 0.
     **/
    function whitelistPartner(
        address _partner,
        uint256 _fee,
        uint256 _mintLimit,
        uint256 _burnLimit,
        uint256 _lockDuration
    ) external onlyOwner {
        require(_partner != address(0), "VMU::whitelistPartner: Zero Address");
        require(
            _fee <= _MAX_BASIS_POINTS,
            "VMU::whitelistPartner: Invalid Fee"
        );
        require(
            _lockDuration <= _MAX_LOCK_DURATION,
            "VMU::whitelistPartner: Invalid lock duration"
        );

        emit WhitelistPartner(_partner, _mintLimit, _burnLimit, _fee);
        partnerLimits[_partner] = Limits({
            fee: _fee,
            mintLimit: _mintLimit,
            burnLimit: _burnLimit,
            lockDuration: _lockDuration
        });
    }

    /*
     * @dev Remove partner
     * @param _partner Address of partner.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function removePartner(address _partner) external onlyOwner {
        delete partnerLimits[_partner];
        emit RemovePartner(_partner);
    }

    /*
     * @dev Set partner fee
     * @param _partner Address of partner.
     * @param _fee New fee.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_fee} fee can not be bigger than _MAX_BASIS_POINTS.
     **/
    function setPartnerFee(address _partner, uint256 _fee) external onlyOwner {
        require(_fee <= _MAX_BASIS_POINTS, "VMU::setPartnerFee: Invalid Fee");
        partnerLimits[_partner].fee = _fee;
        emit SetPartnerFee(_partner, _fee);
    }

    /*
     * @dev Increase partner mint limit.
     * @param _partner Address of partner.
     * @param _amount Amount to increase the mint limit by.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function increasePartnerMintLimit(address _partner, uint256 _amount)
        external
        onlyOwner
    {
        Limits storage limits = partnerLimits[_partner];
        limits.mintLimit += _amount;
        emit IncreasePartnerMintLimit(_partner, limits.mintLimit);
    }

    /*
     * @dev Decrease partner mint limit.
     * @param _partner Address of partner.
     * @param _amount Amount to decrease the mint limit by.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function decreasePartnerMintLimit(address _partner, uint256 _amount)
        external
        onlyOwner
    {
        Limits storage limits = partnerLimits[_partner];
        limits.mintLimit -= _amount;
        emit DecreasePartnerMintLimit(_partner, limits.mintLimit);
    }

    /*
     * @dev Increase partner mint limit.
     * @param _partner Address of partner.
     * @param _amount Amount to increase the burn limit by.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function increasePartnerBurnLimit(address _partner, uint256 _amount)
        external
        onlyOwner
    {
        Limits storage limits = partnerLimits[_partner];
        limits.burnLimit += _amount;
        emit IncreasePartnerBurnLimit(_partner, limits.burnLimit);
    }

    /*
     * @dev Decrease partner mint limit.
     * @param _partner Address of partner.
     * @param _amount Amount to decrease the burn limit by.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function decreasePartnerBurnLimit(address _partner, uint256 _amount)
        external
        onlyOwner
    {
        Limits storage limits = partnerLimits[_partner];
        limits.burnLimit -= _amount;
        emit DecreasePartnerBurnLimit(_partner, limits.burnLimit);
    }

    /*
     * @dev Set partner lock duration.
     * @param _partner Address of partner.
     * @param _lockDuration New lock duration
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_lockDuration} cannot be bigger than _MAX_LOCK_DURATION
     **/
    function setPartnerLockDuration(address _partner, uint256 _lockDuration)
        external
        onlyOwner
    {
        require(
            _lockDuration <= _MAX_LOCK_DURATION,
            "VMU::setPartnerLockDuration: Invalid lock duration"
        );
        partnerLimits[_partner].lockDuration = _lockDuration;
        emit SetPartnerLockDuration(_partner, _lockDuration);
    }

    /*
     * @dev Sets the transmuter contract address represented by the param {_transmuter}.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_transmuter} can not be address ZERO.
     **/
    function setTransmuterAddress(address _transmuter) external onlyOwner {
        require(
            _transmuter != address(0),
            "VMU::setTransmuterAddress: Zero Address"
        );
        transmuter = _transmuter;
    }

    /*
     * @dev Sets the lbt contract address represented by the param {_lbt}.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_lbt} can not be address ZERO.
     **/
    function setLBT(ILiquidityBasedTWAP _lbt) external onlyOwner {
        require(
            _lbt != ILiquidityBasedTWAP(address(0)),
            "VMU::setLBT: Zero Address"
        );
        lbt = _lbt;
    }
}
