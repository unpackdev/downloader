// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "./Initializable.sol";
import "./IERC20.sol";
import "./UD60x18.sol";

import "./IXenoMining.sol";
import "./IXenoStaking.sol";
import "./ManagementUpgradable.sol";
import "./MiningErrors.sol";

contract XenoMining is
    IXenoMining,
    Initializable,
    ManagementUpgradeable,
    MiningErrors {

    IXenoStaking public xenoStaking_;
    IERC20 public wbtc_;

    uint256 public cycle;
    uint8[4018] public tier;

    /// @dev key derived using keccak256(abi.encode(_tokenHash, _claimer))
    /// where _tokenHash is the name of the token keccak256 hashed, e.g. bitcoin, and _claimer is the address of the claimer
    /// @return the amount of tokens claimed by the claimer
    mapping (bytes32 => uint256) public claimed;

    /// @dev key derived using keccak256(abi.encode(_tokenName))
    /// where _tokenName is the name of the token, e.g. bitcoin
    /// @return the address of the token contract which should be valid ERC20 address
    mapping (bytes32 => address) public tokenContracts;

    address public distributor;

    uint256 constant TIER1_AMMO_THRESHOLD = 19000000000000000000000;
    uint256 constant TIER2_AMMO_THRESHOLD = 27000000000000000000000;
    uint256 constant TIER3_AMMO_THRESHOLD = 35000000000000000000000;

    bytes32 constant XENO_UNSTAKE_TOPIC = keccak256("xeno.unstaked");
    bytes32 constant AMMO_UNSTAKE_TOPIC = keccak256("ammo.unstaked");

    //Events
    event CycleStarted(uint256 indexed cycle);
    event Claimed(address indexed claimer, uint256 amount, address receiver);
    event TierDowngrade(uint256 indexed id, uint8 tier);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _xenoStaking, address _distributor) initializer public {
        if (_xenoStaking == address(0)) revert InvalidInput(INVALID_ADDRESS);
        __Management_init();

        xenoStaking_ = IXenoStaking(_xenoStaking);
        distributor = _distributor;

        if(!xenoStaking_.supportsInterface(type(IXenoStaking).interfaceId)) revert InvalidInput(WRONG_XENO_STAKING_CONTRACT);

        cycle = 0;

        _pause();
    }

    function startCycle(Signature memory _signature, bytes memory _proof) public {
        address _contract;
        uint256 _cycle;

        assembly {
            // Get the first 20 bytes of he _proof and store in _contract
            _contract := mload(add(_proof, 0x14))

            // Get the first 52 bytes of he _proof and store the next 32 bytes in _cycle
            _cycle := mload(add(_proof, 0x34))

            for { let i := 0 } lt(i, 126) { i := add(i, 1) } {
                sstore(
                    add(tier.slot, i),
                    mload(
                        add(
                            _proof,
                            add(0x54, mul(i, 0x20))
                        )
                    )
                )
            }
        }

        if(!_isVerified(_signature, _proof)) revert ProofError(INVALID_SIGNATURE);

        if(cycle + 1 != _cycle) revert ProofError(INVALID_CYCLE);
        if(_contract != address(this)) revert ProofError(INVALID_CONTRACT);

        cycle++;

        emit CycleStarted(cycle);
    }

    function claim(uint256 _amount, address _receiver, Signature memory _signature, bytes memory _voucher) whenNotPaused external {
        if(cycle == 0) revert InvalidState(CYCLE_NOT_STARTED);
        if(!_isVerified(_signature, _voucher)) revert ProofError(INVALID_SIGNATURE);
        (address _claimer, address _contract, bytes32 _tokenHash, uint256 _cycle, uint256 _value) = decodeVoucher(_voucher);

        if(_contract != address(this)) revert ProofError(INVALID_CONTRACT);
        if(_cycle >= cycle) revert ProofError(INVALID_CYCLE);
        if(_claimer != msg.sender) revert ProofError(INVALID_CLAIMER);

        bytes32 claimedKey = keccak256(abi.encode(_tokenHash, _claimer));

        if(claimed[claimedKey] + _amount > _value) revert InvalidInput(INSUFFICIENT_BALANCE);

        claimed[claimedKey] += _amount;

        IERC20 token = IERC20(tokenContracts[_tokenHash]);
        token.transfer(_receiver, _amount);

        emit Claimed(msg.sender, _amount, _receiver);
    }

    function setToken(string calldata _tokenName, address _tokenContract) external onlyRole(MANAGER_ROLE) {
        tokenContracts[keccak256(abi.encodePacked(_tokenName))] = _tokenContract;
    }

    function decodeVoucher(bytes memory _voucher)
    public
    pure
    returns (address _claimer, address _contract, bytes32 _tokenHash, uint256 _cycle, uint256 _value) {
        (_claimer, _contract, _tokenHash, _cycle, _value) = abi.decode(_voucher, (address, address, bytes32, uint256, uint256));
    }

    function claimedAmount(string calldata _tokenName, address _claimer) external view returns (uint256) {
        bytes32 claimedKey = keccak256(abi.encode(keccak256(abi.encodePacked(_tokenName)), _claimer));
        return claimed[claimedKey];
    }


    /// @dev check that the coupon sent was signed by the coupon issuer
    function _isVerified(Signature memory _signature, bytes memory _voucher) internal view returns (bool) {
        address signer = ecrecover(keccak256(_voucher), _signature.v, _signature.r, _signature.s);
        if(signer == address(0)) revert ProofError(INVALID_DISTRIBUTOR);
        return signer == distributor;
    }

    function notify(bytes32 _topic, bytes memory _data) external {
        if(msg.sender != address(xenoStaking_)) revert InvalidPublisher(WRONG_XENO_STAKING_CONTRACT);
        if ( _topic == XENO_UNSTAKE_TOPIC ) {
            (uint256 tokenId) = abi.decode(_data, (uint256));
            tier[tokenId] = 0;
            emit TierDowngrade(tokenId, 0);
        } else if ( _topic == AMMO_UNSTAKE_TOPIC ){
            (uint256 tokenId, uint256 ammoStaked,) = abi.decode(_data, (uint256, uint256, address));
            uint8 currentTier = tier[tokenId];

            if(currentTier == 0) return;

            uint8 newTier = getTier(ammoStaked, xenoStaking_.isLegendary(tokenId));

            // Only downgrade if the new tier is lower than the current tier
            if(newTier < currentTier){
                tier[tokenId] = newTier;
                emit TierDowngrade(tokenId, newTier);
            }
        }
    }

    function getTier(uint256 _ammo, bool _legendary) public pure returns (uint8) {
        if(_legendary){
            return 4;
        } else if(_ammo < TIER1_AMMO_THRESHOLD){
            return 1;
        } else if(_ammo < TIER2_AMMO_THRESHOLD){
            return 2;
        } else if(_ammo < TIER3_AMMO_THRESHOLD){
            return 3;
        } else {
            return 4;
        }
    }
}
