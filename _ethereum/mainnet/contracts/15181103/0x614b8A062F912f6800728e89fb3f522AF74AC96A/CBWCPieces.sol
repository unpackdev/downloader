// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "./CBWCBase.sol";
import "./ICBWCStaking.sol";

/// @title Crypto Bear Watch Club Pieces
/// @author Kfish n Chips
/// @notice ERC721 Watch Pieces to be claimed by CBWC holders
/// @dev Claiming begins once WAVE_MANAGER starts a claim wave
/// @custom:security-contact security@kfishnchips.com
contract CBWCPieces is CBWCBase {
    /// @notice Keeping track of active waves
    uint256[] public activeWaves;
    // @notice Mapping the status of wave to bear claim
    // @dev WaveID => ( CBWCID => true/false )
    mapping(uint256 => mapping(uint256 => bool)) private claimed;
    /// @notice Enable/Disable Claim Feature
    bool public claimingActive;
    /// @notice CryptoBear Watch Club Staking Contract
    ICBWCStaking public cbwcStaking;
    /// @notice CBWCWatch contract
    address public cbwcWatch;
    // @notice Role assigned by DEFAULT_ADMIN_ROLE with access to burn
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    // @notice Role assigned by DEFAULT_ADMIN_ROLE to manage claim waves
    bytes32 public constant WAVE_MANAGER = keccak256("WAVE_MANAGER");
    /// @notice Counter of waves to make sure new waves don't override previous ones
    uint256 public waveCounter;

    /// @notice Emitted when CBWC WATCH changed
    /// @dev only DEFAULT_ADMIN_ROLE can perform this action
    /// @param sender address with the role of DEFAULT_ADMIN_ROLE
    /// @param previousCBWCWatch previous CBWC WATCH contract address
    /// @param cbwcWatch new CBWC WATCH contract address
    event CBWCWatchChanged(
        address indexed sender,
        address previousCBWCWatch,
        address cbwcWatch
    );

    /// @notice Emitted when CBWC Staking contract changed
    /// @dev only DEFAULT_ADMIN_ROLE can perform this action
    /// @param sender address with the role of DEFAULT_ADMIN_ROLE
    /// @param previousCBWCStaking previous CBWC Staking contract address
    /// @param cbwcStaking new CBWC Staking contract address
    event CBWCStakingChanged(
        address indexed sender,
        address previousCBWCStaking,
        address cbwcStaking
    );

    /// @dev Emitted when the claiming status change.
    /// @param sender address with the role of DEFAULT_ADMIN_ROLE
    /// @param state the new claiming status
    event ToggleClaiming(
        address sender,
        bool state
    );

    /// @notice Modifier to Enable/Disable Claim Feature
    /// @dev false by default
    modifier isClaimingActive() {
        require(claimingActive, "CBWCP: claiming not active");
        _;
    }

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called at deploy time
    function initialize(
        address cbwcWatch_,
        address cbwcStaking_
    )
        external
        initializer
    {
        __CBWCBase_init(
            "CBWCPieces",
            "CBWCP",
            "https://cryptobearwatchclub.mypinata.cloud/ipfs/QmabYNu8sF9fZvury4pEwU9y95GQvHMbYyJeHXGEcvi4pc",
            "https://api.cbwc.io/pieces/metadata/"
        );
        require(cbwcWatch_ != address(0), "CBWCP: cannot set address zero");
        require(cbwcStaking_ != address(0), "CBWCP: cannot set address zero");
        cbwcWatch = cbwcWatch_;
        cbwcStaking = ICBWCStaking(cbwcStaking_);
        _grantRole(BURNER_ROLE, cbwcWatch);
        _grantRole(WAVE_MANAGER, msg.sender);
    }

    /// @notice Mint multiple NFTs to receivers
    /// @dev Restricted to {MINTER_ROLE}
    /// @param receivers_ The receiving addresses
    /// @param quantities_ The receiver's quantities
    function airdrop(
        address[] calldata receivers_,
        uint256[] calldata quantities_
    )
        external
        onlyRole(MINTER_ROLE)
    {
        require(receivers_.length > 0, "CBWCP: must airdrop at least one address");
        require(receivers_.length == quantities_.length, "CBWCP: receivers and quantities length does not match");
        for (uint256 i = 0; i < receivers_.length; i++) {
            _mint(receivers_[i], quantities_[i]);
        }
    }

    /// @notice Burn existing token
    /// @dev Forge contract will call this function
    /// @param tokenIds_ The tokenIds to burn
    /// @return bool success
    function burnPieces(
        uint256[] calldata tokenIds_,
        address owner_
    )
        external
        onlyRole(BURNER_ROLE)
        returns (bool)
    {
        require(tokenIds_.length > 0, "CBWCP: must burn at least one token");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _burn(tokenIds_[i], owner_);
        }

        return true;
    }

    /// @notice Mints multiple tokens to `msg.sender` based on claimable amount.
    /// @dev staked tokens can claim pieces: cbwcStaking
    /// @param cbwcTokenIds_ Array of CBWC token ids for claiming
    function claim(uint256[] calldata cbwcTokenIds_) external isClaimingActive {
        require(activeWaves.length > 0, "CBWCP: No active waves");
        uint256 unclaimedPieces = 0;
        for (uint256 i = 0; i < cbwcTokenIds_.length; i++) {
            require(
                cbwc.ownerOf(cbwcTokenIds_[i]) == msg.sender || cbwcStaking.tokenOwner(cbwcTokenIds_[i]) == msg.sender,
                "CBWCP: caller is not token owner"
            );
            for (uint256 j = 0; j < activeWaves.length; j++) {
                if (!claimed[activeWaves[j]][cbwcTokenIds_[i]]) {
                    claimed[activeWaves[j]][cbwcTokenIds_[i]] = true;
                    unclaimedPieces += 1;
                }
            }
        }
        require(unclaimedPieces > 0, "CBWCP: no claimable tokens");

        safeMint(msg.sender, unclaimedPieces);
    }

    /// @notice Set CBWCWatch address
    /// @dev revoke and grant the BURNER_ROLE
    /// @param cbwcWatch_ The new CBWC Watch address
    /// Emits a {CBWCWatchChanged} event
    function setCBWCWatch(address cbwcWatch_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(cbwcWatch_ != address(0), "CBWCP: cannot set address zero");

        address previousCBWCWatch = cbwcWatch;
        cbwcWatch = cbwcWatch_;
        _revokeRole(BURNER_ROLE, previousCBWCWatch);
        _grantRole(BURNER_ROLE, cbwcWatch);

        emit CBWCWatchChanged(msg.sender, previousCBWCWatch, cbwcWatch_);
    }

    /// @notice Set CBWCStaking address
    /// @param cbwcStaking_ The new Stating CBWC contract address
    /// Emits a {CBWCStakingChanged} event
    function setCBWCStaking(address cbwcStaking_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(cbwcStaking_ != address(0), "CBWCP: cannot set address zero");

        address previousCBWCStaking = address(cbwcStaking);
        cbwcStaking = ICBWCStaking(cbwcStaking_);

        emit CBWCStakingChanged(msg.sender, previousCBWCStaking, cbwcStaking_);
    }

    /// @notice Used to enable or disable a wave
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param wave_ The wave ID
    /// @param active_ Whether the wave is active or not
    function setWave(
        uint256 wave_,
        bool active_
    )
        external
        isClaimingActive
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(wave_ > 0 && wave_ <= waveCounter, "CBWCP: invalid wave");
        if (active_) {
            for (uint256 i = 0; i < activeWaves.length; i++) {
                require(activeWaves[i] != wave_, "CBWCP: wave already active");
            }
            activeWaves.push(wave_);
        } else {
            uint256[] memory _activeWaves = new uint256[](activeWaves.length - 1);
            uint256 counter = 0;
            for (uint256 i = 0; i < activeWaves.length; i++) {
                if (activeWaves[i] == wave_) {
                    counter = 1;
                } else if (i == _activeWaves.length && counter == 0) {
                    require(activeWaves[i] == wave_, "CBWCP: wave is not active");
                } else {
                    _activeWaves[i - counter] = activeWaves[i];
                }
            }
            activeWaves = _activeWaves;
        }
    }

    /// @notice Start the next wave
    /// @param endCurrentWave_ Whether to end the current wave
    function startNextWave(bool endCurrentWave_) external isClaimingActive onlyRole(WAVE_MANAGER) {
        if (endCurrentWave_) endCurrentWave();
        activeWaves.push(waveCounter + 1);
        waveCounter += 1;
    }

    /// @notice change the status of current POAP
    /// Emits a {ToggleClaiming} event
    function toggleClaiming() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimingActive = !claimingActive;
        emit ToggleClaiming(msg.sender, claimingActive);
    }

    /// @notice Returns amount of claimable watch pieces
    /// @param cbwcTokenIds_ List of CBWC token ids
    /// @dev does NOT check that cbwcTokenIds_ exits
    /// @return The claimable amount
    function getPendingClaims(uint256[] calldata cbwcTokenIds_) external view isClaimingActive returns (uint256) {
        uint256 unclaimedPieces = 0;
        for (uint256 i = 0; i < activeWaves.length; i++) {
            for (uint256 j = 0; j < cbwcTokenIds_.length; j++) {
                if (cbwcTokenIds_[j] > 0 && !claimed[activeWaves[i]][cbwcTokenIds_[j]]) {
                    unclaimedPieces += 1;
                }
            }
        }
        return unclaimedPieces;
    }

    /// @notice End the current wave
    /// @dev must be a active wave
    function endCurrentWave() public isClaimingActive onlyRole(WAVE_MANAGER) {
        require(activeWaves.length > 0, "CBWCP: no active waves");
        activeWaves.pop();
    }
}
