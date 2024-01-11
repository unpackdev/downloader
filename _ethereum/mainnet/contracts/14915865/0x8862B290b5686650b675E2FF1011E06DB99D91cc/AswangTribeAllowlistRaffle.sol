//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IERC721.sol";

import "./OpenAllowlistRaffleBase.sol";

error MustBeAKing();

interface IKaiju is IERC721 {}
interface IMutants is IERC721 {}
interface IScientists is IERC721 {}
interface IRWaste { function burn(address, uint256) external; }
interface IScales { function spend(address, uint256) external; }

contract AswangTribeAllowlistRaffle is OpenAllowlistRaffleBase {
    IKaiju public immutable KAIJU;
    IMutants public immutable MUTANTS;
    IScientists public immutable SCIENTISTS;
    IRWaste public immutable RWASTE;
    IScales public immutable SCALES;
    uint256 public constant RWASTE_FEE = 1 ether;
    uint256 public constant SCALES_FEE = 5 ether;
    uint256 public constant RWASTE_MULTIPLIER = 2;

    constructor(
        IKaiju kaiju,
        IMutants mutants,
        IScientists scientists,
        IRWaste rwaste,
        IScales scales,
        uint256 numberOfWinners,
        address vrfCoordinator
    )
        OpenAllowlistRaffleBase(
            numberOfWinners,
            vrfCoordinator
        )
    {
        KAIJU = kaiju;
        MUTANTS = mutants;
        SCIENTISTS = scientists;
        RWASTE = rwaste;
        SCALES = scales;
    }

    /**
     * @notice Modifier that requires a sender to be part of the KaijuKingz ecosystem
     */
    modifier onlyKingz() {
        if (
            SCIENTISTS.balanceOf(_msgSender()) == 0
            && KAIJU.balanceOf(_msgSender()) == 0
            && MUTANTS.balanceOf(_msgSender()) == 0
        ) revert MustBeAKing();
        _;
    }

    /**
     * @notice Purchase entries into the raffle with $RWASTE
     * @param amount Amount of entries to purchase
     */
    function enterWithRWaste(uint256 amount) public whenNotPaused onlyKingz {
        RWASTE.burn(_msgSender(), amount * RWASTE_FEE);
        OpenAllowlistRaffleBase.enter(amount * RWASTE_MULTIPLIER);
    }

    /**
     * @notice Purchase entries into the raffle with $SCALES
     * @param amount Amount of entries to purchase
     */
    function enterWithScales(uint256 amount) public whenNotPaused onlyKingz {
        SCALES.spend(_msgSender(), amount * SCALES_FEE);
        OpenAllowlistRaffleBase.enter(amount);
    }

    /**
     * @inheritdoc OpenAllowlistRaffleBase
     * @dev Disable entering with parent contract's enter function
     */
    function enter(uint256 amount) public override payable { revert(); }
}