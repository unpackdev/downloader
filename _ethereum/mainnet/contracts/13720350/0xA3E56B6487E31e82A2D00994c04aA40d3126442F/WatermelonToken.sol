// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./ChubbyHipposNFTInterfaceUser.sol";

/**
 * @title ChubbyHippos contract
 * @dev Extends ERC20 Token Standard basic implementation
 */
contract WatermelonToken is ERC20PresetMinterPauserUpgradeable {

    uint public RATE;
    uint public CREATION_DATE;
    bool public REVEALED;

    mapping(address => uint) public rewards;
    mapping(address => uint) public lastUpdate;

    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    ChubbyHipposNFTInterfaceUser public diamondNFT;

    /***************************************
     *                                     *
     *       Contract Initialization       *
     *                                     *
     ***************************************/

    function init() initializer public {
        __ERC20PresetMinterPauser_init("WATERMELON", "WM");
        _setupRole(UPDATER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(SPENDER_ROLE, _msgSender());
        _setupRole(ISSUER_ROLE, _msgSender());

        // 10 tokens per day
        RATE = 115740740740740;
        CREATION_DATE = block.timestamp;
        REVEALED = false;
    }

    /***************************************
     *                                     *
     *          Contract settings          *
     *                                     *
     ***************************************/

    function setNFTContractAddress(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WatermelonToken: must have admin role to set contract address");
        diamondNFT = ChubbyHipposNFTInterfaceUser(_address);
    }

    function setRate(uint rate) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WatermelonToken: must have admin role to set the rate");
        RATE = rate;
    }

    function reveal() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WatermelonToken: must have admin role to reveal the token");
        REVEALED = true;
    }

    function grantUpdaterRole(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WatermelonToken: must have admin role to grant updater role");
        grantRole(UPDATER_ROLE, _address);
    }

    function revokeUpdaterRole(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WatermelonToken: must have admin role to revoke updater role");
        revokeRole(UPDATER_ROLE, _address);
    }

    function grantIssuerRole(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WatermelonToken: must have admin role to grant issuer role");
        grantRole(ISSUER_ROLE, _address);
    }

    function revokeIssuerRole(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WatermelonToken: must have admin role to revoke issuer role");
        revokeRole(ISSUER_ROLE, _address);
    }

    function grantBurnerRole(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WatermelonToken: must have admin role to grant burner role");
        grantRole(BURNER_ROLE, _address);
    }

    function revokeBurnerRole(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WatermelonToken: must have admin role to revoke burner role");
        revokeRole(BURNER_ROLE, _address);
    }

    /***************************************
     *                                     *
     *           Contract logic            *
     *                                     *
     ***************************************/

    /*
     * Called from the main diamond to update rewards on NFT transfers.
     */
    function updateRewards(address from, address to) external {
        require(hasRole(UPDATER_ROLE, _msgSender()), "WatermelonToken: must have updater role update rewards");

        if (from != address(0)) {
            updateReward(from);
        }
        if (to != address(0)) {
            updateReward(to);
        }
    }

    function claimReward() external {
        require(REVEALED, "WatermelonToken: Tokens are not claimable yet.");

        updateReward(msg.sender);
        _mint(msg.sender, rewards[msg.sender]);
        rewards[msg.sender] = 0;
    }

    function burnTokens(address _address, uint amount) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "WatermelonToken: must have burner role to burn tokens");
        _burn(_address, amount);
    }

    function burnTokensWithClaimable(address _address, uint amount) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "WatermelonToken: must have burner role to burn tokens");

        updateReward(_address);
        int leftOver = int(amount) - int(rewards[_address]);

        if (leftOver <= 0) {
            rewards[_address] -= amount;
        } else {
            rewards[_address] = 0;
            _burn(_address, uint(leftOver));
        }
    }

    function issueTokens(address _address, uint amount) external {
        require(hasRole(ISSUER_ROLE, _msgSender()), "WatermelonToken: must have issuer role to issue tokens");
        _mint(_address, amount);
    }

    function getTotalClaimable(address _address) external view returns (uint) {
        return rewards[_address] + getPendingReward(_address);
    }

    function getPendingReward(address _address) internal view returns (uint) {
        return diamondNFT.balanceOf(_address) * RATE * getElapsedTimeSinceLastUpdate(_address);
    }

    /***************************************
     *                                     *
     *           Contract utils            *
     *                                     *
     ***************************************/

    function updateReward(address _address) internal {
        rewards[_address] += getPendingReward(_address);
        lastUpdate[_address] = block.timestamp;
    }

    function getElapsedTimeSinceLastUpdate(address _address) internal view returns (uint) {
        return block.timestamp - (lastUpdate[_address] >= CREATION_DATE ? lastUpdate[_address] : CREATION_DATE);
    }

}
