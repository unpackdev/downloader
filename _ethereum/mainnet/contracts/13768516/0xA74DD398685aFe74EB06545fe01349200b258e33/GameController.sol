// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IERC721.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./IBLOODBAG.sol";
import "./ILair.sol";
import "./IBloodFarm.sol";
import "./Random.sol";

import "./IVampireGameERC721.sol";

contract GameController is ReentrancyGuard, Ownable, Pausable {
    /// @notice the tax vampires charge in percentage (20%)
    uint256 public constant BLOOD_CLAIM_TAX_PERCENTAGE = 20;

    /// @notice amount of blood distributed when no vampires are staked
    uint256 public unaccountedRewards = 0;

    // Other contracts this caontract controls
    IVampireGameERC721 public vgame;
    IBLOODBAG public bloodbag;
    ILair public lair;
    IBloodFarm public bloodfarm;
    IRandom public random;

    /// ==== Constructor

    constructor(
        address _vgame,
        address _bloodbag,
        address _lair,
        address _bloodfarm,
        address _random
    ) {
        vgame = IVampireGameERC721(_vgame);
        bloodbag = IBLOODBAG(_bloodbag);
        lair = ILair(_lair);
        bloodfarm = IBloodFarm(_bloodfarm);
        random = IRandom(_random);
    }

    /// ==== Mixed Controls

    /// @notice stake many vampire and human tokens
    /// @param tokenIds the ids of tokens to be staked. The caller should own the tokens
    function stakeManyTokens(uint16[] calldata tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        IVampireGameERC721 vgameRef = vgame;
        IBloodFarm bloodfarmRef = bloodfarm;
        address sender = _msgSender();
        for (uint16 i = 0; i < tokenIds.length; i++) {
            uint16 tokenId = tokenIds[i];
            require(vgameRef.isTokenRevealed(tokenId), "NO_STAKING_COFFINS");
            if (_isVampire(vgameRef, tokenId)) {
                _stakeVampire(vgameRef, lair, sender, tokenId);
            } else {
                _stakeHuman(vgameRef, bloodfarmRef, sender, tokenId);
            }
        }
    }

    /// @notice unstake many tokens.
    /// - Vampires can be staked at any time
    /// - Humans need to have a unstake request first
    function unstakeManyTokens(
        uint16[] calldata requestToUnstakeIds,
        uint16[] calldata unstakeHumanIds,
        uint16[] calldata unstakeVampireIds
    ) external whenNotPaused nonReentrant {
        uint256 totalOwed = 0;
        uint256 totalTax = 0;
        IVampireGameERC721 vgameRef = vgame;
        IBloodFarm bloodfarmRef = bloodfarm;
        ILair lairRef = lair;
        address sender = _msgSender();

        for (uint16 i = 0; i < unstakeHumanIds.length; i++) {
            uint16 tokenId = unstakeHumanIds[i];
            (uint256 owed, uint256 tax) = _unstakeHuman(
                vgameRef,
                bloodfarmRef,
                sender,
                tokenId
            );
            totalOwed += owed;
            totalTax += tax;
        }

        for (uint16 i = 0; i < requestToUnstakeIds.length; i++) {
            _requestToUnstakeHuman(
                bloodfarmRef,
                sender,
                requestToUnstakeIds[i]
            );
        }

        if (totalTax != 0) {
            _addVampireTax(lairRef, totalTax);
        }

        for (uint16 i = 0; i < unstakeVampireIds.length; i++) {
            totalOwed += _unstakeVampire(
                vgameRef,
                lairRef,
                sender,
                unstakeVampireIds[i]
            );
        }

        if (totalOwed != 0) {
            bloodbag.mint(sender, totalOwed);
        }
    }

    /// @notice claim blood bags
    /// @dev checks of ownersgip performed in Lair and BloodFarm
    /// @param humans humans tokenIds
    /// @param vampires vampires tokenIds
    function claimBloodBags(
        uint16[] calldata humans,
        uint16[] calldata vampires
    )
        external
        whenNotPaused
        nonReentrant
    {
        uint256 owed = 0;
        uint256 tax = 0;
        address sender = _msgSender();
        ILair lairRef = lair;
        IBloodFarm bloodfarmRef = bloodfarm;

        for (uint16 i = 0; i < humans.length; i++) {
            uint256 _owed = bloodfarmRef.claimBloodBags(sender, humans[i]);
            uint256 _tax = (_owed * BLOOD_CLAIM_TAX_PERCENTAGE) / 100;
            tax += _tax;
            owed += _owed - _tax;
        }

        if (tax != 0) {
            _addVampireTax(lairRef, tax);
        }

        for (uint16 i = 0; i < vampires.length; i++) {
            owed += lairRef.claimBloodBags(sender, vampires[i]);
        }

        bloodbag.mint(sender, owed);
    }

    /// ==== Human Controls

    function _stakeHuman(
        IVampireGameERC721 vgameRef,
        IBloodFarm bloodfarmRef,
        address sender,
        uint16 tokenId
    ) private {
        bloodfarmRef.stakeHuman(sender, tokenId);
        vgameRef.transferFrom(sender, address(bloodfarmRef), tokenId);
    }

    function _requestToUnstakeHuman(
        IBloodFarm bloodfarmRef,
        address sender,
        uint16 tokenId
    ) private {
        bloodfarmRef.requestToUnstakeHuman(sender, tokenId);
        random.submitHash(sender, tokenId);
    }

    function _unstakeHuman(
        IVampireGameERC721 vgameRef,
        IBloodFarm bloodfarmRef,
        address sender,
        uint16 tokenId
    ) private returns (uint256 owed, uint256 tax) {
        require(!_isVampire(vgameRef, tokenId), "NOT_HUMAN");
        uint256 _owed = bloodfarmRef.unstakeHuman(sender, tokenId);

        // Check if stolen
        if (random.getRandomNumber(tokenId) & 1 == 1) {
            tax += _owed;
        } else {
            tax += (_owed * BLOOD_CLAIM_TAX_PERCENTAGE) / 100;
            owed += (_owed * (100 - BLOOD_CLAIM_TAX_PERCENTAGE)) / 100;
        }

        vgameRef.transferFrom(address(bloodfarmRef), sender, tokenId);
    }

    /// ==== Vampire Controls

    /// @dev Stake one vapmire
    /// - Calls Lair to update staking state (stake)
    /// - Transfer the NFT from sender to the Lair
    ///
    /// - Ownership only checked here
    function _stakeVampire(
        IVampireGameERC721 vgameRef,
        ILair lairRef,
        address sender,
        uint16 tokenId
    ) private {
        require(vgameRef.ownerOf(tokenId) == sender, "NOT_VAMPIRE_OWNER");
        lairRef.stakeVampire(sender, tokenId);
        vgameRef.transferFrom(sender, address(lairRef), tokenId);
    }

    /// @dev Unstake one vampire
    ///
    /// - Calls Lair to update staking state (unstake)
    /// - Transfer the NFT from Lair to sender
    ///
    /// - Ownership is checked in Lair
    function _unstakeVampire(
        IVampireGameERC721 vgameRef,
        ILair lairRef,
        address sender,
        uint16 tokenId
    ) private returns (uint256 owed) {
        require(_isVampire(vgameRef, tokenId), "NOT_VAMPIRE");
        owed += lairRef.unstakeVampire(sender, tokenId);
        vgameRef.transferFrom(address(lairRef), sender, tokenId);
    }

    /// ==== Helpers

    function _addVampireTax(ILair lairRef, uint256 amount) private {
        uint256 totalPredatorScoreStaked = lairRef
            .getTotalPredatorScoreStaked();
        uint256 _unaccountedRewards = unaccountedRewards;

        if (totalPredatorScoreStaked == 0) {
            _unaccountedRewards += amount;
            return;
        }

        lairRef.addTaxToVampires(amount, _unaccountedRewards);
        unaccountedRewards = 0;
    }

    function _isVampire(IVampireGameERC721 vgameRef, uint16 tokenId)
        private
        view
        returns (bool)
    {
        return vgameRef.isTokenVampire(tokenId);
    }

    /// ==== pause/unpause

    function upause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    /// ==== Update Parts

    function setVgame(address _vgame) external onlyOwner {
        vgame = IVampireGameERC721(_vgame);
    }

    function setBloodBag(address _bloodbag) external onlyOwner {
        bloodbag = IBLOODBAG(_bloodbag);
    }

    function setLair(address _lair) external onlyOwner {
        lair = ILair(_lair);
    }

    function setBloodFarm(address _bloodfarm) external onlyOwner {
        bloodfarm = IBloodFarm(_bloodfarm);
    }

    function setRandom(address _random) external onlyOwner {
        random = IRandom(_random);
    }
}
