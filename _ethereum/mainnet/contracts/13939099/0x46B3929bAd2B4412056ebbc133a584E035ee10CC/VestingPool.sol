//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./GTH.sol";
import "./OwnableUpgradeable.sol";




contract VestingPool is OwnableUpgradeable {
    // The token being vested
    GTH public token;

    // Category name identifiers
    bytes32 public constant privateCategory = keccak256("privateCategory");
    bytes32 public constant platformCategory = keccak256("platformCategory");
    bytes32 public constant seedCategory = keccak256("seedCategory");
    bytes32 public constant foundationCategory = keccak256("foundationCategory");
    bytes32 public constant marketingCategory = keccak256("marketingCategory");
    bytes32 public constant teamCategory = keccak256("teamCategory");
    bytes32 public constant advisorCategory = keccak256("advisorCategory");

    bool public isVestingStarted;
    uint256 public vestingStartDate;

    struct vestingInfo {
        uint256 limit;
        uint256 released;
        uint256[] scheme;
        mapping(address => bool) adminEmergencyFirstApprove;
        mapping(address => bool) adminEmergencySecondApprove;
        bool multiownedEmergencyFirstApprove;
        bool multiownedEmergencySecondApprove;
        uint256 initEmergencyDate;
    }

    mapping(bytes32 => vestingInfo) public vesting;

    uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint32 private constant SECONDS_PER_MONTH = SECONDS_PER_DAY * 30;

    address public admin1address;
    address public admin2address;

    event Withdraw(address _to, uint256 _amount);

    function VestingPool_init(address tokenAddress) public initializer {
        require(tokenAddress != address(0), "Gather: Token address must be set for vesting");

        __Ownable_init();

        token = GTH(tokenAddress);

        // Set storage variables to old contract values
        // have these variables in init for possible future upgrades
        isVestingStarted = true;
        vestingStartDate = 1599686156;
        admin1address = 0xe8517582FfB8B8E80fBA2388Eb3F08aea1DED4e2;
        admin2address = 0x95B58643b53172Cfdd711A7F54ae8f09ED4d37Ac;

        // Setup vesting data for each category
        _initVestingDataV2();
    }

    modifier isNotStarted() {
        require(!isVestingStarted, "Gather: Vesting is already started");
        _;
    }

    modifier isStarted() {
        require(isVestingStarted, "Gather: Vesting is not started yet");
        _;
    }

    modifier approvedByAdmins(bytes32 _category) {
        require(
            vesting[_category].adminEmergencyFirstApprove[admin1address],
            "Gather: Emergency transfer must be approved by Admin 1"
        );
        require(
            vesting[_category].adminEmergencyFirstApprove[admin2address],
            "Gather: Emergency transfer must be approved by Admin 2"
        );
        require(
            vesting[_category].adminEmergencySecondApprove[admin1address],
            "Gather: Emergency transfer must be approved twice by Admin 1"
        );
        require(
            vesting[_category].adminEmergencySecondApprove[admin2address],
            "Gather: Emergency transfer must be approved twice by Admin 2"
        );
        _;
    }

    modifier approvedByMultiowned(bytes32 _category) {
        require(
            vesting[_category].multiownedEmergencyFirstApprove,
            "Gather: Emergency transfer must be approved by Multiowned"
        );
        require(
            vesting[_category].multiownedEmergencySecondApprove,
            "Gather: Emergency transfer must be approved twice by Multiowned"
        );
        _;
    }

    function startVesting() public onlyOwner isNotStarted {
        vestingStartDate = block.timestamp;
        isVestingStarted = true;
    }

    // Two Admins for emergency transfer
    function addAdmin1address(address _admin) public onlyOwner {
        require(
            _admin != address(0),
            "Gather: Admin 1 address must be exist for emergency transfer"
        );
        _resetAllAdminApprovals(_admin);
        admin1address = _admin;
    }

    function addAdmin2address(address _admin) public onlyOwner {
        require(
            _admin != address(0),
            "Gather: Admin 2 address must be exist for emergency transfer"
        );
        _resetAllAdminApprovals(_admin);
        admin2address = _admin;
    }

    function multipleWithdraw(
        address[] calldata _addresses,
        uint256[] calldata _amounts,
        bytes32 _category
    ) public onlyOwner isStarted {
        require(
            _addresses.length == _amounts.length,
            "Gather: Amount of adddresses must be equal amounts length"
        );

        uint256 withdrawalAmount;
        uint256 availableAmount = getAvailableAmountFor(_category);
        for (uint256 i = 0; i < _amounts.length; i++) {
            withdrawalAmount = withdrawalAmount + _amounts[i];
        }
        require(
            withdrawalAmount <= availableAmount,
            "Gather: Withdraw amount more than available limit"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            _withdraw(_addresses[i], _amounts[i], _category);
        }
    }

    function _withdraw(
        address _beneficiary,
        uint256 _amount,
        bytes32 _category
    ) internal {
        token.transfer(_beneficiary, _amount);
        vesting[_category].released = vesting[_category].released + _amount;

        emit Withdraw(_beneficiary, _amount);
    }

    function getAvailableAmountFor(bytes32 _category)
        public
        view
        returns (uint256)
    {
        uint256 currentMonth = (block.timestamp - vestingStartDate) / SECONDS_PER_MONTH;
        uint256 totalUnlockedAmount;

        // Fix array index out of bound error
        uint256 vestingMonths = vesting[_category].scheme.length;
        uint256 k = currentMonth;
        if (vestingMonths <= k) {
          k = vestingMonths - 1;
        }

        for (uint256 i = 0; i <= k; i++) {
            totalUnlockedAmount = totalUnlockedAmount + vesting[_category].scheme[i];
        }
        return totalUnlockedAmount - vesting[_category].released;
    }

    function firstAdminEmergencyApproveFor(bytes32 _category, address _admin)
        public
        onlyOwner
    {
        require(
            _admin == admin1address || _admin == admin2address,
            "Gather: Approve for emergency address must be from admin address"
        );
        require(
            !vesting[_category].adminEmergencyFirstApprove[_admin],
            "Gather: First admin emergency address already set"
        );

        if (vesting[_category].initEmergencyDate == 0) {
            vesting[_category].initEmergencyDate = block.timestamp;
        }
        vesting[_category].adminEmergencyFirstApprove[_admin] = true;
    }

    function secondAdminEmergencyApproveFor(bytes32 _category, address _admin)
        public
        onlyOwner
    {
        require(
            _admin == admin1address || _admin == admin2address,
            "Gather: Approve for emergency address must be from admin address"
        );
        require(
            vesting[_category].adminEmergencyFirstApprove[_admin], 
            "Gather: First emergency admin must be set");
        require(
            block.timestamp - vesting[_category].initEmergencyDate > SECONDS_PER_DAY,
            "Gather: Second admin emergency approve must be in 24 hours"
        );

        vesting[_category].adminEmergencySecondApprove[_admin] = true;
    }

    function firstMultiownedEmergencyApproveFor(bytes32 _category)
        public
        onlyOwner
    {
        require(
            !vesting[_category].multiownedEmergencyFirstApprove,
            "Gather: First multiowned emergency already set"
            );

        if (vesting[_category].initEmergencyDate == 0) {
            vesting[_category].initEmergencyDate = block.timestamp;
        }
        vesting[_category].multiownedEmergencyFirstApprove = true;
    }

    function secondMultiownedEmergencyApproveFor(bytes32 _category)
        public
        onlyOwner
    {
        require(
            vesting[_category].multiownedEmergencyFirstApprove,
            "Gather: Fisrt multiowned approval must be set first"
        );
        require(
            block.timestamp - vesting[_category].initEmergencyDate > SECONDS_PER_DAY,
            "Gather: Second multiowned approval must be in 24 hours"
        );

        vesting[_category].multiownedEmergencySecondApprove = true;
    }

    function emergencyTransferFor(bytes32 _category, address _to)
        public
        onlyOwner
        approvedByAdmins(_category)
        approvedByMultiowned(_category)
    {
        require(
            _to != address(0),
            "Gather: Address must be transmit for emergency transfer"
        );
        uint256 limit = vesting[_category].limit;
        uint256 released = vesting[_category].released;
        
        //issue: limit <  released then limit - released = -....(negative value) 
        //as a result an error is thrown as negative value appears for uint
        uint256 availableAmount = limit - released; 
        _withdraw(_to, availableAmount, _category);
    }

    function _resetAllAdminApprovals(address _admin) internal {
        vesting[seedCategory].adminEmergencyFirstApprove[_admin] = false;
        vesting[seedCategory].adminEmergencySecondApprove[_admin] = false;
        vesting[foundationCategory].adminEmergencyFirstApprove[_admin] = false;
        vesting[foundationCategory].adminEmergencySecondApprove[_admin] = false;
        vesting[marketingCategory].adminEmergencyFirstApprove[_admin] = false;
        vesting[marketingCategory].adminEmergencySecondApprove[_admin] = false;
        vesting[teamCategory].adminEmergencyFirstApprove[_admin] = false;
        vesting[teamCategory].adminEmergencySecondApprove[_admin] = false;
        vesting[advisorCategory].adminEmergencyFirstApprove[_admin] = false;
        vesting[advisorCategory].adminEmergencySecondApprove[_admin] = false;
    }

    // Vesting data for public sale category
    function _initVestingDataV2() internal {
        // Vesting data for private category
        vesting[privateCategory].limit = 20000000 ether;
        vesting[privateCategory].released = 30000000 ether;
        vesting[privateCategory].scheme = [
            /* initial amount */
            10500000 ether,
            /* M+1 M+2 */
            10500000 ether,
            9000000 ether
        ];

        // Vesting data for platform category
        vesting[platformCategory].limit = 30000000 ether;
        vesting[platformCategory].released = 30000000 ether;
        vesting[platformCategory].scheme = [
            /* initial amount */
            30000000 ether
        ];

        // Vesting data for seed category
        vesting[seedCategory].limit = 22522500 ether;
        vesting[seedCategory].released = 22522500 ether;
        vesting[seedCategory].scheme = [
            /* initial amount */
            5630625 ether,
            /* M+1 M+2 M+3 M+4 M+5 */
            3378375 ether,
            3378375 ether,
            3378375 ether,
            3378375 ether,
            3378375 ether
        ];

        // Vesting data for foundation category
        vesting[foundationCategory].limit = 193477500 ether;
        vesting[foundationCategory].released = 50000000 ether;
        vesting[foundationCategory].scheme = [
            /* initial amount */
            0 ether,
            /* M+1 M+2 M+3 M+4 M+5 M+6 M+7 M+8 M+9 M+10 M+11 M+12 */
            0 ether,
            0 ether,
            0 ether,
            0 ether,
            0 ether,
            6000000 ether,
            6000000 ether,
            6000000 ether,
            6000000 ether,
            6000000 ether,
            6000000 ether,
            6000000 ether,
            /* Y+2 */
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            /* Y+3 */
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            4000000 ether,
            /* Y+4 */
            3000000 ether,
            3000000 ether,
            3000000 ether,
            3000000 ether,
            3000000 ether,
            3000000 ether,
            3000000 ether,
            3000000 ether,
            3000000 ether,
            3000000 ether,
            3000000 ether,
            3000000 ether,
            /* Y+5 */
            19477500 ether
        ];

        // Vesting data for marketing category
        vesting[marketingCategory].limit = 50000000 ether;
        vesting[marketingCategory].released = 23000000 ether;
        vesting[marketingCategory].scheme = [
            /* initial amount */
            0 ether,
            /* M+1 M+2 M+3 M+4 M+5 M+6 M+7 M+8 M+9 M+10 M+11 M+12 */
            0 ether,
            0 ether,
            2000000 ether,
            2000000 ether,
            2000000 ether,
            2000000 ether,
            2000000 ether,
            2000000 ether,
            2000000 ether,
            2000000 ether,
            2000000 ether,
            2000000 ether,
            /* Y+2 */
            1500000 ether,
            1500000 ether,
            1500000 ether,
            1500000 ether,
            1500000 ether,
            1500000 ether,
            1500000 ether,
            1500000 ether,
            1500000 ether,
            1500000 ether,
            1500000 ether,
            1500000 ether,
            /* Y+3 */
            1000000 ether,
            1000000 ether,
            1000000 ether,
            1000000 ether,
            1000000 ether,
            1000000 ether,
            1000000 ether,
            1000000 ether,
            1000000 ether,
            1000000 ether,
            1000000 ether,
            1000000 ether
        ];

        // Vesting data for team category
        vesting[teamCategory].limit = 50000000 ether;
        vesting[teamCategory].released = 21000000 ether;
        vesting[teamCategory].scheme = [
            /* initial amount */
            0 ether,
            /* M+1 M+2 M+3 M+4 M+5 M+6 M+7 M+8 M+9 M+10 M+11 M+12 */
            0 ether,
            0 ether,
            0 ether,
            0 ether,
            0 ether,
            7000000 ether,
            0 ether,
            0 ether,
            0 ether,
            7000000 ether,
            0 ether,
            0 ether,
            /* Y+2 */
            0 ether,
            7000000 ether,
            0 ether,
            0 ether,
            0 ether,
            7000000 ether,
            0 ether,
            0 ether,
            7000000 ether,
            0 ether,
            0 ether,
            0 ether,
            /* Y+3 */
            0 ether,
            7500000 ether,
            0 ether,
            0 ether,
            0 ether,
            7500000 ether
        ];

        // Vesting data for advisor category
        vesting[advisorCategory].limit = 24000000 ether;
        vesting[advisorCategory].released = 24000000 ether;
        vesting[advisorCategory].scheme = [
            /* initial amount */
            0 ether,
            /* M+1 M+2 M+3 M+4 M+5 M+6 M+7 M+8 M+9 */
            0 ether,
            0 ether,
            6000000 ether,
            6000000 ether,
            4500000 ether,
            4500000 ether,
            0 ether,
            1500000 ether,
            1500000 ether
        ];

    }

    // New functions
    function setTokenAddress(address tokenAddress) external onlyOwner {
        require(
            tokenAddress != address(0),
            "Gather: tokenAddress must not be 0"
        );
        token = GTH(tokenAddress);
    }
}
