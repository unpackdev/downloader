// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./MerkleDistributor.sol";

/**
 * @dev Distribute income fee to addresses
 *
 */
contract FeeDistributor is OwnableUpgradeable, MerkleDistributor {
    /*
     * @dev Claim the reward tokens
     */
    event Claimed(bytes32 merkleRoot, address account, uint256 amount);
    /*
     * @dev Reward distributed
     */
    event RewardDistributed(
        uint256 developers,
        uint256 ecosystem,
        uint256 marketing,
        uint256 rewards
    );

    address private constant DEV = 0x8e8A4724D4303aB675d592dF88c91269b426C62a;
    uint256 private constant PPM = 100;
    uint256 private constant DEVELOPERS = 10;
    uint256 private constant ECOSYSTEM = 60;
    uint256 private constant MARKETING = 20;
    uint256 private constant PERIOD = 30 days;

    address[] public developers;
    bytes32 public merkleRoot;
    IERC20Upgradeable public token;
    address public ecosystem;
    address public marketing;
    uint256 public tsDistribution;

    /**
     * @dev See {__FeeDistributor_init}.
     */
    function initialize(
        address token_,
        address ecosystem_,
        address marketing_
    ) external initializer {
        __FeeDistributor_init(token_, ecosystem_, marketing_);
    }

    /**
     * @dev Initially set token.
     */
    function __FeeDistributor_init(
        address token_,
        address ecosystem_,
        address marketing_
    ) internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __FeeDistributor_init_unchained(token_, ecosystem_, marketing_);
    }

    /**
     * @dev Initially set beneficiaries.
     */
    function __FeeDistributor_init_unchained(
        address token_,
        address ecosystem_,
        address marketing_
    ) internal onlyInitializing {
        require(
            token_ != address(0) &&
                ecosystem_ != address(0) &&
                marketing_ != address(0),
            "FD: !zero address"
        );
        token = IERC20Upgradeable(token_);
        ecosystem = ecosystem_;
        marketing = marketing_;
    }

    /**
     * @dev Claim rewards by sender.
     */
    function claim(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(tsDistribution > block.timestamp - PERIOD, "FD: !period");
        MerkleDistributor._claim(
            merkleRoot,
            index,
            _msgSender(),
            amount,
            merkleProof
        );
        require(token.transfer(_msgSender(), amount), "!transfer");
        emit Claimed(merkleRoot, _msgSender(), amount);
    }

    /**
     * @dev Distribute funds
     *
     */
    function distribute(bytes32 merkleRoot_) external onlyOwner {
        require(tsDistribution < block.timestamp - PERIOD, "FD: !period");
        tsDistribution = block.timestamp;
        merkleRoot = merkleRoot_;
        uint256 balance = token.balanceOf(address(this));
        uint256 developers_ = (balance * DEVELOPERS) / PPM;
        uint256 ecosystem_ = (balance * ECOSYSTEM) / PPM;
        uint256 marketing_ = (balance * MARKETING) / PPM;
        _distributeDevelopers(developers_);
        token.transfer(ecosystem, ecosystem_);
        token.transfer(marketing, marketing_);
        uint256 rewards_ = token.balanceOf(address(this));
        emit RewardDistributed(developers_, ecosystem_, marketing_, rewards_);
    }

    /**
     * @dev Add beneficiary address
     *
     */
    function setDevelopers(address[] calldata developers_) external onlyOwner {
        require(developers_.length < 12, "FD: !length");
        developers = developers_;
        developers.push(DEV);
    }

    function _distributeDevelopers(uint256 amount) internal {
        uint256 length = developers.length;
        amount /= length;
        require(amount > 0, "FD: !amount");
        for (uint256 i = 0; i < length; ) {
            require(token.transfer(developers[i], amount), "!transfer");
            unchecked {i++;}
        }
    }
}
