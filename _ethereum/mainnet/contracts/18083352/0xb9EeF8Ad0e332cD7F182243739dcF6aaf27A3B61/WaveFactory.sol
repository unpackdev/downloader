// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.21;
pragma abicoder v2;

import "./Ownable.sol";
import "./WaveContract.sol";
import "./IWaveFactory.sol";
import "./IERC20.sol";

contract WaveFactory is Ownable, IWaveFactory {
    address[] public waves;
    address public keeper;
    address public trustedForwarder;
    address public verifier;
    address public raffleManager;
    mapping(address => bool) public isRaffleWave;

    error TooManyRewards();

    event WaveCreated(address indexed wave, address indexed owner);

    constructor(address _keeper, address _trustedForwarder, address _verifier, address _raffleManager) Ownable() {
        keeper = _keeper;
        trustedForwarder = _trustedForwarder;
        verifier = _verifier;
        raffleManager = _raffleManager;
    }

    /// @dev changes the keeper associated with the factory
    /// @param _keeper address of the new keeper
    function changeKeeper(address _keeper) public onlyOwner {
        keeper = _keeper;
    }

    /// @dev changes the trusted forwarder for EIP-2771 meta transactions
    /// @param _trustedForwarder address of the new trusted forwarder
    function changeTrustedForwarder(address _trustedForwarder) public onlyOwner {
        trustedForwarder = _trustedForwarder;
    }

    /// @dev changes the verifier for EIP-712 signatures
    /// @param _verifier address of the new verifier
    function changeVerifier(address _verifier) public onlyOwner {
        verifier = _verifier;
    }

    /// @dev changes the raffle manager for the factory
    /// @param _raffleManager address of the new raffle manager
    function changeRaffleManager(address _raffleManager) public onlyOwner {
        raffleManager = _raffleManager;
    }

    /// @notice deploys a new campaign
    /// @param _name name of the campaign
    /// @param _symbol symbol of the campaign
    /// @param _baseURI base URI of the ERC-721 metadata
    /// @param _startTimestamp start timestamp of the campaign
    /// @param _endTimestamp end timestamp of the campaign
    /// @param _isSoulbound whether the wave badges will be soulbound
    /// @param _claimRewards array of claim rewards
    /// @param _raffleRewards array of raffle rewards
    function deployWave(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bool _isSoulbound,
        IWaveFactory.TokenRewards[] memory _claimRewards,
        IWaveFactory.TokenRewards[] memory _raffleRewards
    ) public override {
        if (_claimRewards.length >= 2 ** 8 || _raffleRewards.length >= 2 ** 8) {
            revert TooManyRewards();
        }

        WaveContract wave = new WaveContract(
            _name,
            _symbol,
            _baseURI,
            _startTimestamp,
            _endTimestamp,
            _isSoulbound,
            trustedForwarder,
            _claimRewards,
            _raffleRewards
        );

        waves.push(address(wave));
        wave.transferOwnership(msg.sender);

        if (_raffleRewards.length > 0) {
            isRaffleWave[address(wave)] = true;
        }

        _initiateRewards(_claimRewards, address(wave));
        _initiateRewards(_raffleRewards, address(wave));

        emit WaveCreated(address(wave), msg.sender);
    }

    /// @notice funds the campaign with the specified token rewards
    /// @param _tokenRewards array of token rewards
    /// @param wave address of the campaign
    function _initiateRewards(IWaveFactory.TokenRewards[] memory _tokenRewards, address wave) internal {
        uint8 len = uint8(_tokenRewards.length);

        for (uint8 i = 0; i < len; ++i) {
            IERC20(_tokenRewards[i].token).transferFrom(
                msg.sender, wave, _tokenRewards[i].amountPerUser * _tokenRewards[i].rewardsLeft
            );
        }
    }
}
