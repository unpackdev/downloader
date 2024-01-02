// SPDX-License-Identifier: MIT

//** DCB Crowdfunding Contract */
//** Author: Aceson & Aaron 2023.3 */

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./ECDSA.sol";

import "./IDCBCrowdfunding.sol";
import "./IDCBInvestments.sol";
import "./IDCBPlatformVesting.sol";
import "./ILayerZeroReceiver.sol";

contract DCBCrowdfunding is IDCBCrowdfunding, Initializable, ReentrancyGuard, ILayerZeroReceiver {
    using SafeERC20 for IERC20;

    address[] private _participants; //total number of participants
    address[] private _registeredUsers; //total number of registered users
    IDCBInvestments public investment; //investment contract
    IDCBPlatformVesting public vesting; //vesting contract

    AgreementInfo public dcbAgreement; //agreement info
    IERC20 public saleToken; //sale token
    address public layerZero; //layer zero contract

    mapping(address => InvestorAllocation) public userAllocation; //user allocation

    uint256 public totalShares;
    address public tierMigratorAddr;
    uint16 internal nativeChainId;

    event UserRegistered(address user);
    event BulkUserRegustered(address[] users);
    event EditAgreement(Params p);

    modifier onlyManager() {
        require(investment.hasRole(keccak256("MANAGER_ROLE"), msg.sender), "Only manager");
        _;
    }

    function initialize(Params calldata p) external initializer {
        investment = IDCBInvestments(p.investmentAddr);
        vesting = IDCBPlatformVesting(p.vestingAddr);
        saleToken = IERC20(p.saleTokenAddr);
        layerZero = p.layerZeroAddr;
        tierMigratorAddr = p.tierMigratorAddr;
        nativeChainId = p.nativeChainId;

        /**
         * generate the new agreement
         */
        dcbAgreement.totalTokenOnSale = p.totalTokenOnSale;
        dcbAgreement.hardcap = p.hardcap;
        dcbAgreement.createDate = uint32(block.timestamp);
        dcbAgreement.startDate = p.startDate;
        dcbAgreement.endDate = p.startDate + 24 hours;
        dcbAgreement.token = IERC20(p.paymentToken);
        dcbAgreement.totalInvestFund = 0;
        dcbAgreement.minTier = p.minTier;

        /**
         * emit the agreement generation event
         */
        emit CreateAgreement(p);
    }

    function setParams(Params calldata p) external {
        require(msg.sender == address(investment), "Only factory");

        saleToken = IERC20(p.saleTokenAddr);
        layerZero = p.layerZeroAddr;
        tierMigratorAddr = p.tierMigratorAddr;

        /**
         * generate the new agreement
         */
        dcbAgreement.totalTokenOnSale = p.totalTokenOnSale;
        dcbAgreement.hardcap = p.hardcap;
        dcbAgreement.startDate = p.startDate;
        dcbAgreement.endDate = p.startDate + 24 hours;
        dcbAgreement.token = IERC20(p.paymentToken);
        dcbAgreement.minTier = p.minTier;

        /**
         * emit the agreement generation event
         */
        emit EditAgreement(p);
    }

    function setToken(address _token) external {
        require(msg.sender == address(investment), "Only factory");
        saleToken = IERC20(_token);
    }

    /**
     *
     * @dev set a users allocation
     *
     * @param {_sig} Signature from the user
     *
     * @return {bool} return status of operation
     *
     */
    function registerForAllocation(address _user, uint8 _tier, uint8 _multi) public override returns (bool) {
        require(msg.sender == (layerZero) || msg.sender == tierMigratorAddr, "Invalid sender");
        uint256 shares = (2 ** _tier) * _multi;

        if ((block.timestamp >= dcbAgreement.startDate) || _tier < dcbAgreement.minTier) {
            shares = 0;
        }

        userAllocation[_user].active = true;
        userAllocation[_user].tier = _tier;
        userAllocation[_user].multi = _multi;

        _registeredUsers.push(_user);

        if (shares > 0) {
            userAllocation[_user].shares = shares;
            totalShares = totalShares + shares;
        }

        emit UserRegistered(_user);
        return true;
    }

    function lzReceive(uint16 _id, bytes calldata _srcAddress, uint64, bytes memory data) public override {
        require(
            _id == nativeChainId
                && keccak256(_srcAddress) == keccak256(abi.encodePacked(tierMigratorAddr, address(this))),
            "Invalid source"
        );

        address user;
        uint8 tier;
        uint8 multi;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Extract the address from data (first 20 bytes)
            user := mload(add(data, 0x14))

            // Extract the first uint8 (21st byte)
            tier := byte(0, mload(add(data, 0x34)))

            // Extract the second uint8 (22nd byte)
            multi := byte(0, mload(add(data, 0x35)))
        }

        registerForAllocation(user, tier, multi);
    }

    function registerByManager(
        address[] calldata _users,
        uint256[] calldata _tierOfUser,
        uint256[] calldata _multiOfUser
    )
        external
        onlyManager
    {
        require((_users.length == _tierOfUser.length) && (_tierOfUser.length == _multiOfUser.length), "Invalid input");
        uint256 len = _users.length;
        require(uint32(block.timestamp) <= dcbAgreement.startDate, "Registration closed");
        uint256 total;

        for (uint256 i = 0; i < len; ++i) {
            require(_tierOfUser[i] >= dcbAgreement.minTier, "User not part of required tier");
            require(!userAllocation[_users[i]].active, "Already registered");

            uint256 shares = (2 ** _tierOfUser[i]) * _multiOfUser[i];

            userAllocation[_users[i]].active = true;
            userAllocation[_users[i]].shares = shares;
            userAllocation[_users[i]].tier = uint8(_tierOfUser[i]);
            userAllocation[_users[i]].multi = uint8(_multiOfUser[i]);

            _registeredUsers.push(_users[i]);

            total = total + shares;
        }

        totalShares = totalShares + total;
        emit BulkUserRegustered(_users);
    }

    /**
     *
     * @dev investor join available agreement. Already complied users can pass empty signature
     *
     * @param {uint256} Deposit amount
     * @param {bytes} Signature of user
     *
     * @return {bool} return if investor successfully joined to the agreement
     *
     */
    function fundAgreement(uint256 _investFund) external override nonReentrant returns (bool) {
        /**
         * Check if user have registered
         */
        require(userAllocation[msg.sender].active, "User not registered");

        /**
         * check if project has provided tokens
         */
        require(
            saleToken.balanceOf(address(vesting)) >= dcbAgreement.totalTokenOnSale, "Tokens not received from project"
        );

        /**
         * check if investor is willing to invest any funds
         */
        require(_investFund > 0, "You cannot invest 0");

        /**
         * check if startDate has started
         */
        require(uint32(block.timestamp) >= dcbAgreement.startDate, "Crowdfunding not open");

        /**
         * check if endDate has already passed
         */
        require(uint32(block.timestamp) < dcbAgreement.endDate, "Crowdfunding ended");

        require(dcbAgreement.totalInvestFund + _investFund <= dcbAgreement.hardcap, "Hardcap already met");

        bool isGa;
        uint256 multi = 1;

        // First 8 hours is gauranteed allocation
        if (uint32(block.timestamp) < dcbAgreement.startDate + 8 hours) {
            isGa = true;
            // second 1 hours is FCFS - 2x allocation
        } else if (uint32(block.timestamp) < dcbAgreement.startDate + 9 hours) {
            multi = 2;
            // final 8 hours is Free for all - 10x allocation
        } else {
            multi = 10;
        }

        // Allocation of user
        uint256 alloc;

        if (isGa) {
            alloc = getUserAllocation(msg.sender);
        } else {
            alloc = getAllocationForTier(userAllocation[msg.sender].tier, userAllocation[msg.sender].multi);
        }

        // during FCFS users get multiplied allocation
        require(
            dcbAgreement.investorList[msg.sender].investAmount + _investFund <= alloc * multi,
            "Amount greater than allocation"
        );

        if (dcbAgreement.investorList[msg.sender].active == 0) {
            /**
             * add new investor to investor list for specific agreeement
             */
            dcbAgreement.investorList[msg.sender].wallet = msg.sender;
            dcbAgreement.investorList[msg.sender].investAmount = _investFund;
            dcbAgreement.investorList[msg.sender].joinDate = uint32(block.timestamp);
            dcbAgreement.investorList[msg.sender].active = 1;
            _participants.push(msg.sender);
        }
        // user has already deposited so update the deposit
        else {
            dcbAgreement.investorList[msg.sender].investAmount =
                dcbAgreement.investorList[msg.sender].investAmount + _investFund;
        }

        dcbAgreement.totalInvestFund = dcbAgreement.totalInvestFund + _investFund;

        uint256 value = dcbAgreement.investorList[msg.sender].investAmount;
        uint256 numTokens = (value * dcbAgreement.totalTokenOnSale) / (dcbAgreement.hardcap);

        require(numTokens > 0, "Tokens cannot be 0");

        investment.setUserInvestment(msg.sender, address(this), value);
        vesting.setCrowdfundingWhitelist(msg.sender, numTokens, value);

        emit NewInvestment(msg.sender, _investFund);

        return true;
    }

    /**
     *
     * @dev getter function for list of participants
     *
     * @return {uint256} return total participant count of crowdfunding
     *
     */
    function getParticipants() external view returns (address[] memory) {
        return _participants;
    }

    /**
     *
     * @dev getter function for list of registered users
     *
     * @return {address[]} return total participants registered for crowdfunding
     *
     */
    function getRegisteredUsers() external view returns (address[] memory) {
        return _registeredUsers;
    }

    function userInvestment(address _address) external view override returns (uint256 investAmount, uint256 joinDate) {
        investAmount = dcbAgreement.investorList[_address].investAmount;
        joinDate = dcbAgreement.investorList[_address].joinDate;
    }

    /**
     *
     * @dev getter function for ticket value of a tier
     *
     * @param _tier Tier value
     * @param _multi multiplier if applicable (default 1)
     *
     * @return return total participant count of crowdfunding
     *
     */
    function getAllocationForTier(uint8 _tier, uint8 _multi) public view returns (uint256) {
        if (totalShares == 0) return 0;
        return (((2 ** _tier) * _multi * dcbAgreement.hardcap) / totalShares);
    }

    /**
     *
     * @dev getter function for allocation of a user
     *
     * @param _address Address of the user
     *
     * @return return total participant count of crowdfunding
     *
     */
    function getUserAllocation(address _address) public view override returns (uint256) {
        if (totalShares == 0) return 0;
        return (userAllocation[_address].shares * dcbAgreement.hardcap) / totalShares;
    }

    /**
     *
     * @dev getter function for total participants
     *
     * @return {uint256} return total participant count of crowdfunding
     *
     */
    function getInfo() public view override returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            dcbAgreement.hardcap,
            dcbAgreement.createDate,
            dcbAgreement.startDate,
            dcbAgreement.endDate,
            dcbAgreement.totalInvestFund,
            _participants.length
        );
    }
}
