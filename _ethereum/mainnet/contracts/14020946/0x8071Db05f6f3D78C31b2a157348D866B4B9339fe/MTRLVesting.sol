//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract MTRLVesting {
    using SafeERC20 for IERC20;

    /// @notice blocks per month by assuming 4 blocks per minute
    uint256 public constant blocksPerMonth = 30 * 24 * 60 * 4;

    /// @notice blockNumber that vesting will start
    uint256 public immutable vestingStartBlock;

    /// @notice tokens will be unlocked per this cycle
    uint256 public immutable UNLOCK_CYCLE;

    /// @notice amount of tokens that will be unlocked per month
    uint256 public constant UNLOCK_AMOUNT = 1000000e18; // 1M

    /// @notice lastClaimIndex
    uint256 public lastClaimIndex;

    /// @notice vesting token (in our case, MTRL)
    IERC20 public immutable token;

    /// @notice admin
    address public admin;

    /// @notice address that will receive unlocked tokens
    address public wallet;

    /// @notice return unlocked amount per month
    mapping(uint256 => uint256) public unlockedAmount;

    constructor(
        IERC20 _token,
        address _admin,
        address _wallet,
        uint256 _unlockCycle
    ) {
        require(address(_token) != address(0), 'constructor: invalid MTRL');
        require(_admin != address(0), 'constructor: invalid admin');
        require(_wallet != address(0), 'constructor: invalid wallet');
        require(
            _unlockCycle > 0 && _unlockCycle <= blocksPerMonth,
            'constructor: invalid unlockCycle'
        );

        admin = _admin;
        token = _token;
        UNLOCK_CYCLE = _unlockCycle;
        vestingStartBlock = block.number + 1;
        wallet = _wallet;
        lastClaimIndex = 1;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, 'onlyAdmin: caller is not the owner');
        _;
    }

    event SetWallet(address indexed _newWallet);
    event SetAdmin(address indexed _newAdmin);
    event Claimed(uint256 _claimedBlock, uint256 indexed _amount, address indexed _wallet);

    /// @dev transfer ownership
    function transferOwnership(address _newAdmin) external onlyAdmin {
        require(admin != _newAdmin && _newAdmin != address(0), 'transferOwnership: invalid admin');
        admin = _newAdmin;
        emit SetAdmin(_newAdmin);
    }

    /// @dev setWallet
    /// @param _newWallet new address of wallet that will receive unlocked tokens
    function setWallet(address _newWallet) external onlyAdmin {
        require(_newWallet != address(0) && _newWallet != wallet, 'setWallet: invalid wallet');
        wallet = _newWallet;
        emit SetWallet(_newWallet);
    }

    /// @dev anyone can call this function to transfer unlocked tokens to the wallet
    function claim() external {
        require(block.number >= vestingStartBlock, 'claim: vesting not started');

        uint256 passedBlocks = block.number - vestingStartBlock;
        require(passedBlocks >= UNLOCK_CYCLE, 'claim: not claimable yet');

        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, 'claim: no tokens');

        uint256 monthIndex = passedBlocks / UNLOCK_CYCLE;
        uint256 totalClaimAmount;

        // check missing months that should be claimed
        for (uint256 i = lastClaimIndex; i <= monthIndex; i++) {
            if (tokenBalance > totalClaimAmount && unlockedAmount[i] == 0) {
                uint256 availableAmount = tokenBalance - totalClaimAmount;

                uint256 claimAmount = availableAmount >= UNLOCK_AMOUNT
                    ? UNLOCK_AMOUNT
                    : availableAmount;

                unlockedAmount[i] = claimAmount;
                totalClaimAmount += claimAmount;
                lastClaimIndex = i;
            }
        }

        if (totalClaimAmount > 0) {
            token.safeTransfer(wallet, totalClaimAmount);
            emit Claimed(block.number, totalClaimAmount, wallet);
        }
    }
}
