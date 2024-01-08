//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20CappedUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract YieldToken is Initializable, ERC20CappedUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public constant BASE_RATE = 5 ether; // 5 Candy
    uint256 public constant INITIAL_ISSUANCE = 0 ether; // 0 Candy
    IERC721Upgradeable public CHEEKY_CORGI;

    // Tue Mar 18 2031 17:46:47 GMT+0000
    uint256 public constant START = 1636934400;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    // Events
    event RewardPaid(address indexed user, uint256 reward);

    modifier onlyCC() {
        require(
            msg.sender == address(CHEEKY_CORGI),
            "YieldToken: Only CheekyCorgi can call this"
        );
        _;
    }

    function initialize(address _uninterestedUnicorns, uint256 maxSupply) external initializer {
        __ERC20_init("Yield Token", "Token");
        __ERC20Capped_init(maxSupply);
        
        CHEEKY_CORGI = IERC721Upgradeable(_uninterestedUnicorns);
    }

    /// @dev get larger value of a and b
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @dev called when minting many NFTs
    /// @dev NOT REQUIRED
    /// updated_amount = (balanceOf(user) * base_rate * delta / 86400) + amount * initial rate
    function updateRewardOnMint(address _user, uint256 _amount) external onlyCC {
        uint256 time = max(block.timestamp, START);
        uint256 timerUser = lastUpdate[_user];
        if (timerUser > 0) {
            rewards[_user] = rewards[_user].add(
                CHEEKY_CORGI
                    .balanceOf(_user)
                    .mul(BASE_RATE.mul((time.sub(timerUser))))
                    .div(86400)
                    .add(_amount.mul(INITIAL_ISSUANCE))
            );
        } else {
            rewards[_user] = rewards[_user].add(_amount.mul(INITIAL_ISSUANCE));
        }
        lastUpdate[_user] = time;
    }

    // called on transfers
    function updateReward(address _from, address _to) external onlyCC {
        uint256 time = max(block.timestamp, START);
        uint256 timerFrom = lastUpdate[_from];
        if (timerFrom > 0) {
            rewards[_from] += CHEEKY_CORGI
                .balanceOf(_from)
                .mul(BASE_RATE.mul((time.sub(timerFrom))))
                .div(86400);
        }
        lastUpdate[_from] = time;

        if (_to != address(0)) {
            uint256 timerTo = lastUpdate[_to];
            if (timerTo > 0) {
                rewards[_to] += CHEEKY_CORGI
                    .balanceOf(_to)
                    .mul(BASE_RATE.mul((time.sub(timerTo))))
                    .div(86400);
            }
            lastUpdate[_to] = time;
        }
    }

    function getReward(address _to) external onlyCC {
        uint256 reward = rewards[_to];
        if (reward > 0) {
            rewards[_to] = 0;
            _mint(_to, reward);
            emit RewardPaid(_to, reward);
        }
    }

    function burn(address _from, uint256 _amount) external onlyCC {
        _burn(_from, _amount);
    }

    function getTotalClaimable(address _user) external view returns (uint256) {
        uint256 time = max(block.timestamp, START);
        uint256 pending = CHEEKY_CORGI
            .balanceOf(_user)
            .mul(BASE_RATE.mul((time.sub(lastUpdate[_user]))))
            .div(86400);
        return rewards[_user] + pending;
    }

    uint256[47] private __gap;
}
