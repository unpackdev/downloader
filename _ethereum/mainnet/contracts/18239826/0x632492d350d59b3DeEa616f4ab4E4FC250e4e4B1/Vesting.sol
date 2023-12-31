//SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IVesting.sol";

contract Vesting is Ownable, IVesting, ReentrancyGuard {
    uint256 public tokenPendingInICO;
    address public ICOAddress;
    address public receiverAddress = 0xDF155a928dBB5556C52DC0c51b81308d6F41925D;

    address public ECOSYSTEM = 0x4C663c5aac163C3D4ed05BF56F5A7A678c39C5C3;
    address public TREASURY = 0x4fb7C4a2E7aa00bD1E0e12Cad888a017255E56fB;
    address public TEAM = 0x35ca63B94477e0f1bC75BBc96791c354f99E6311;
    address public MARKETING = 0x6ca65f2C2D4baD405951E783522fF42e047da87B;
    address public ADVERTISED = 0xdB8e6E648CBAC55286f6573124EC935470E1aAe7;

    /**
     * User Data Structure for users info like:-
     * Users total amount for claim.
     * Users claimed amount that is till claimed.
     * Users claim for how many times user claims the amount.
     * The Categories are:-
     *      Refferal vesting = 0
     *      ICO phase 1 = 1
     *      ICO phase 2 = 2
     *      ICO phase 3 = 3
     *      ICO phase 4 = 4
     *      ECOSYSTEM = 5
     *      TREASURY = 6
     *      TEAM = 7
     *      MARKETING = 8
     *      ADVERTISED = 9
     */
    struct UserData {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint8 claims;
    }

    struct VestingPhase {
        uint256 percentage;
        uint32 time;
        uint8 claims;
    }

    /* Users Mapping for Users Info. */
    mapping(address => mapping(uint8 => UserData)) public userMapping;

    /*  Time Mapping for Vesting Category to Start.
     */
    mapping(uint8 => VestingPhase) internal vestingPhaseMapping;

    IERC20 public token; /* Dregn token instance */

    constructor(
        address _tokenAddress
    ) {

        token = IERC20(_tokenAddress);

        tokenPendingInICO = (24_000_100 * (10 ** token.decimals()));

        /* Setting the Vesting Total Amount and Time of Categories */
        setVestingCategory(10000, 1698796800, 0, 1); //1 Nov 2023
        setVestingCategory(1666, 1714521600, 1, 6); //1 May 2024
        setVestingCategory(1666, 1709251200, 2, 6); //1 Mar 2024
        setVestingCategory(833, 1698796800, 3, 12); //1 Nov 2023
        setVestingCategory(10000, 1698796800, 4, 1); //1 Nov 2023
        setVestingCategory(416, 1698796800, 5, 24); //1 Nov 2023
        setVestingCategory(416, 1698796800, 6, 24); //1 Nov 2023
        setVestingCategory(416, 1722470400, 7, 24); //1 Aug 2024
        setVestingCategory(416, 1698796800, 8, 24); //1 Nov 2023
        setVestingCategory(10000, 1693526400, 9, 1); //1 sep 2023

        /* setup the team vesting */
        registerUser((10_000_000 * (10 ** token.decimals())), 5, ECOSYSTEM);
        registerUser((5_000_000 * (10 ** token.decimals())), 6, TREASURY);
        registerUser((5_000_000 * (10 ** token.decimals())), 7, TEAM);
        registerUser((5_000_000 * (10 ** token.decimals())), 8, MARKETING);
        registerUser((999_900 * (10 ** token.decimals())), 9, ADVERTISED);
    }

    /* Receive Function */
    receive() external payable {
        /* Sending deposited currency to the receiver address */
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    /* =============== Register The Address For Claiming ===============*/
    function setVestingCategory(
        uint256 _percentage,
        uint32 _time,
        uint8 _choice,
        uint8 _claims
    ) internal {
        VestingPhase storage phase = vestingPhaseMapping[_choice];
        phase.percentage = _percentage;
        phase.time = _time;
        phase.claims = _claims;
    }

    /* =============== Register The Address For Claiming ===============*/

    /**
     * Register User for Vesting
     * _amount for Total Claimable Amount
     * _choice for Vesting Category
     * _to for User's Address
     */
    function registerUser(
        uint256 _amount,
        uint8 _choice,
        address _to
    ) internal returns (bool) {
        UserData storage user = userMapping[_to][_choice];

        user.totalAmount += _amount;

        emit RegisterUser(_amount, _to, _choice);

        return (true);
    }

    function registerUserByICO(
        uint256 _amount,
        uint8 _choice,
        address _to
    ) external returns (bool) {
        require(ICOAddress == msg.sender, "Access Denied.");
        require(_choice < 5, "You can only set ICO Phase Vesting.");
        tokenPendingInICO -= _amount;
        return registerUser(_amount, _choice, _to);
    }

    function updateICOAddress(address _ICOAddress) external onlyOwner {
        require(_ICOAddress != address(0), "Zero address passed.");
        ICOAddress = _ICOAddress;
    }

    /* =============== Token Claiming Functions =============== */
    /**
     * User can claim the tokens with claimTokens function.
     * after start the vesting for that particular vesting category.
     */
    function claimTokens(uint8 _choice) external nonReentrant {
        address _msgSender = msg.sender; 
        require(
            userMapping[_msgSender][_choice].totalAmount > 0,
            "User is not registered with this vesting."
        );

        (uint256 _amount, uint8 _claimCount) = tokensToBeClaimed(
            _msgSender,
            _choice
        );

        require(_amount > 0, "Nothing to claim right now.");

        UserData storage user = userMapping[_msgSender][_choice];
        user.claimedAmount += _amount;
        user.claims = _claimCount;

        TransferHelper.safeTransfer(address(token), _msgSender, _amount);

        uint8 claims = uint8(vestingPhaseMapping[_choice].claims);
        if (claims == _claimCount) {
            delete userMapping[_msgSender][_choice];
        }

        emit ClaimedToken(
            _msgSender,
            _amount,
            uint32(block.timestamp),
            _claimCount,
            _choice
        );
    }

    /* =============== Tokens to be claimed =============== */
    /**
     * tokensToBeClaimed function can be used for checking the claimable amount of the user.
     */
    function tokensToBeClaimed(
        address _to,
        uint8 _choice
    ) public view returns (uint256 _toBeTransfer, uint8 _claimCount) {
        UserData memory user = userMapping[_to][_choice];
        if (
            (block.timestamp < (vestingPhaseMapping[_choice].time)) ||
            (user.totalAmount == 0)
        ) {
            return (0, 0);
        }

        if (user.totalAmount == user.claimedAmount) {
            return (0, 0);
        }

        uint32 _time = uint32(
            block.timestamp - (vestingPhaseMapping[_choice].time)
        );

        /* Claim in Ever Month 30 days for main net and 1 minutes for the test */
        _claimCount = uint8((_time / 30 days) + 1);

        uint8 claims = uint8(vestingPhaseMapping[_choice].claims);

        if (_claimCount > claims) {
            _claimCount = claims;
        }

        if (_claimCount <= user.claims) {
            return (0, _claimCount);
        }

        if (_claimCount == claims) {
            _toBeTransfer = user.totalAmount - user.claimedAmount;
        } else {
            _toBeTransfer = vestingCalulations(
                user.totalAmount,
                _claimCount,
                user.claims,
                _choice
            );
        }
        return (_toBeTransfer, _claimCount);
    }

    /* =============== Vesting Calculations =============== */
    /**
     * vestingCalulations function is used for calculating the amount of token for claim
     */
    function vestingCalulations(
        uint256 _userTotalAmount,
        uint8 _claimCount,
        uint8 _userClaimCount,
        uint8 _choice
    ) internal view returns (uint256) {
        uint256 amount;
        uint8 claim = _claimCount - _userClaimCount;
        amount =
            (_userTotalAmount *
                (vestingPhaseMapping[_choice].percentage * claim)) /
            10000;

        return amount;
    }

    function sendLeftoverTokens() external onlyOwner {
        uint256 _balance = tokenPendingInICO;
        require(_balance > 0, "No tokens left to send.");

        TransferHelper.safeTransfer(address(token), receiverAddress, _balance);
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */
    /* Updates Receiver Address */
    function updateReceiverAddress(
        address _receiverAddress
    ) external onlyOwner {
        require(_receiverAddress != address(0), "Zero address passed.");
        receiverAddress = _receiverAddress;
    }
}
