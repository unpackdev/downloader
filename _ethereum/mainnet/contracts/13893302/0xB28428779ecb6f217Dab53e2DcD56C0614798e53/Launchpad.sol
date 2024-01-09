//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./AccessLevel.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

/// @author Vlaunch Team
/// @title Launchpad contract for a new project
contract Launchpad is AccessLevel {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract,uint256 chainId)");
    bytes32 private constant STAKING_INFO_TYPEHASH = keccak256("StakingInfo(address owner,uint256 tickets,uint256 validity)");

    struct StakingInfo{
        address owner;
        uint256 tickets;
        uint256 validity;
    }

    event BuyTickets(uint amount, address staker);
    event ClaimedTokend(uint amount, address claimer);

    uint public launchpadId;
    uint public totalTickets;
    uint public ticketCost;
    uint public ticketToLaunchedTokenRatio;
    uint public launchedTokenAmount;
    bool public buyPeriod;
    bool public buyAndClaimTicketsPeriod;
    bool public claimingPeriod;
    bool public recoverFundsPeriod;
    address public ticketPaymentTokenAddress;
    address public launchedTokenAddress;
    address public backendAddress;
    mapping(address => uint) public ticketsBoughtPerAddress;
    
    /** Initialize the contract
    @param owner the owner of the address
    @param launchpadId_ the id that references the project internally
    @param totalTickets_ the total number of tickets that will be set up for this project
    @param ticketCost_ the cost of one ticket
    @param ticketPaymentTokenAddress_ the token the payment will be made in
    @param launchedTokenAddress_ the token that will be launched 
    @param ticketToLaunchedTokenRatio_ the ratio between tiecket and token
    @param backendAddress_ the backend address that will be used to sign the messages
    */
    function initialize(address owner, uint launchpadId_, uint totalTickets_, uint ticketCost_, 
        address ticketPaymentTokenAddress_, address launchedTokenAddress_, 
        uint ticketToLaunchedTokenRatio_, address backendAddress_) initializer external {
        __AccessLevel_init(owner);
        _setupRole(OPERATOR_ROLE, owner);
        launchpadId = launchpadId_;
        totalTickets = totalTickets_;
        ticketCost = ticketCost_;
        ticketPaymentTokenAddress = ticketPaymentTokenAddress_;
        launchedTokenAddress = launchedTokenAddress_;
        ticketToLaunchedTokenRatio = ticketToLaunchedTokenRatio_;
        backendAddress = backendAddress_;
    }

    /** Buy a number of tickets 
    @param tickets_ the number of tickets to buy 
    @param info_ the information that was signed by the backend
    @param sig_ the signature of the info_ structure signed by our backend
    */
    function buyTickets(uint tickets_, StakingInfo calldata info_, bytes memory sig_) external {
        require(buyPeriod, "Cannot buy at this time");
        require(backendAddress == recover(hashSwap(info_), sig_), "Backend address does not match");
        require(msg.sender == info_.owner, "Only owner can buy tickets");
        require(info_.validity >= block.timestamp, "Backend signatura timed out");
        require(totalTickets - tickets_ >= 0, "Not enough tickets");
        require(ticketsBoughtPerAddress[msg.sender] + tickets_ <= info_.tickets,
         "Cannot buy more tickets than assigned");
     
        totalTickets -= tickets_;
        ticketsBoughtPerAddress[msg.sender] += tickets_;
        emit BuyTickets(tickets_, msg.sender);
        IERC20Upgradeable(ticketPaymentTokenAddress).safeTransferFrom(msg.sender, address(this), tickets_ * ticketCost);
    }

    /** Buy and claim tickets directly
    @param info_ the information that was signed by the backend
    @param sig_ the signature of the info_ structure signed by our backend
     */
    function buyAndClaimTickets(StakingInfo calldata info_, bytes memory sig_) external {
        require(buyAndClaimTicketsPeriod, "Cannot buy at this time");
        require(backendAddress == recover(hashSwap(info_), sig_), "Backend address does not match");
        require(msg.sender == info_.owner, "Only owner can buy and claim tickets");
        require(info_.validity >= block.timestamp, "Backend signatura timed out");
        require(totalTickets - info_.tickets >= 0, "Not enough tickets");
        require(ticketsBoughtPerAddress[msg.sender] == 0, "Cannot buy more tickets than assigned");
     
        totalTickets -= info_.tickets;
        ticketsBoughtPerAddress[msg.sender] += info_.tickets;
        emit BuyTickets(info_.tickets, msg.sender);
        IERC20Upgradeable(launchedTokenAddress).safeTransfer(msg.sender, 
        ticketsBoughtPerAddress[msg.sender]*ticketToLaunchedTokenRatio);
    }

    /** Adds reward tokens to the launchpad contract
    @param amount_ the amount of reward tokens that has to be added
     */
    function addRewardToken(uint amount_) external {
        launchedTokenAmount += amount_;
        IERC20Upgradeable(launchedTokenAddress).safeTransferFrom(msg.sender, address(this), amount_);
    }

    /** Set the ticket to token launched token ratio
    @param ticketToLaunchedTokenRatio_ the ticket to token launched token ratio
     */
    function setTicketToLaunchedTokenRatio(uint ticketToLaunchedTokenRatio_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ticketToLaunchedTokenRatio = ticketToLaunchedTokenRatio_;
    }

    /** Set the launched token address
    @param launchedTokenAddress_ the address of the token to launch
     */
    function setLaunchedTokenAddress(address launchedTokenAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        launchedTokenAddress = launchedTokenAddress_;
    }

    /** Set the total number of tickets
    @param totalTickets_ the number of ticketys
     */
    function setTotalTickets(uint totalTickets_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        totalTickets = totalTickets_;
    }

    /** Set the ticket cost
    @param ticketCost_ the ticket cost
     */
    function setTicketCost(uint ticketCost_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ticketCost = ticketCost_;
    }

    /** Start the buy period
    @param buyPeriod_ if the buy period state should be active
     */
    function startBuyPeriod(bool buyPeriod_) external onlyRole(OPERATOR_ROLE) {
        buyPeriod = buyPeriod_;
        claimingPeriod = false;
        recoverFundsPeriod = false;
        buyAndClaimTicketsPeriod = false;
    }

    /** Start the buy and claim period
    @param buyAndClaimTicketsPeriod_ if the buy and claim ticket period starts
     */
    function startBuyAndClaimTicketsPeriod(bool buyAndClaimTicketsPeriod_) 
    external onlyRole(OPERATOR_ROLE) {
        buyPeriod = false;
        claimingPeriod = false;
        recoverFundsPeriod = false;
        buyAndClaimTicketsPeriod = buyAndClaimTicketsPeriod_;
    }

    /** Start the claiming period  
    @param claimingPeriod_ if the claim ticket period starts
     */
    function startClaimingPeriod(bool claimingPeriod_) external onlyRole(OPERATOR_ROLE) {
        buyPeriod = false;
        claimingPeriod = claimingPeriod_;
        recoverFundsPeriod = false;
        buyAndClaimTicketsPeriod = false;
    }

    /** Set the backend address 
    @param backendAddress_ the backend address used to sign the messages
     */
    function setBackendAddress(address backendAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        backendAddress = backendAddress_;
    }

    /** Start the funds recovery period
    @param recoverFundsPeriod_ if the recover period starts
     */
    function startRecoverFundsPeriod(bool recoverFundsPeriod_) external onlyRole(OPERATOR_ROLE) {
        buyPeriod = false;
        claimingPeriod = false;
        recoverFundsPeriod = recoverFundsPeriod_;
        buyAndClaimTicketsPeriod = false;
    }

    /** Claim the funds
    @param teamAddress_ claiming the funds raised and redirecting themin the team address
     */
    function claimFunds(address teamAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(ticketPaymentTokenAddress).safeTransfer(teamAddress_, 
        IERC20Upgradeable(ticketPaymentTokenAddress).balanceOf(address(this)));
    }

    /** Claim the remaining tokens
    @param teamAddress_ claiming the remaining tokens and redirecting them to the team address
     */ 
    function claimRemainingTokens(address teamAddress_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!buyPeriod, "Cannot claim remaining yet");
        require(!claimingPeriod, "Cannot claim remaining yet");
        require(!recoverFundsPeriod, "Cannot claim remaining yet");
        IERC20Upgradeable(launchedTokenAddress).safeTransfer(teamAddress_, 
        IERC20Upgradeable(launchedTokenAddress).balanceOf(address(this)));
    }

    /** Claim the tokens, will claim all the tokens for the sending user
     */ 
    function claimTokens() external {
        require(claimingPeriod, "Cannot claim tokens yet");
        require(launchedTokenAmount > 0, "Tokens not funded yet");
        require(ticketsBoughtPerAddress[msg.sender] > 0, "No tokens to claim");

        uint ticketsToClaim = ticketsBoughtPerAddress[msg.sender] * ticketToLaunchedTokenRatio;
        ticketsBoughtPerAddress[msg.sender] = 0;
        emit ClaimedTokend(ticketsToClaim, msg.sender);
        IERC20Upgradeable(launchedTokenAddress).safeTransfer(msg.sender, ticketsToClaim);
    }

    /** Claim the funds back
    When called, if in the current state the initial payed price for tickets will be refunded
     */ 
    function claimFundsBack() external {
        require(recoverFundsPeriod, "Cannot claimFunds back yet");
        require(ticketsBoughtPerAddress[msg.sender] > 0, "Do not have what to claim");
        IERC20Upgradeable(ticketPaymentTokenAddress).safeTransfer(msg.sender,
        ticketsBoughtPerAddress[msg.sender] * ticketCost);
        ticketsBoughtPerAddress[msg.sender] = 0;
    }

    function hashSwap(StakingInfo calldata stakingInfo) view private returns (bytes32) {
        return keccak256(abi.encodePacked(
	        "\x19\x01",
	        keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("VLAUNCH"),
                keccak256("1"),
                address(this),
                block.chainid
            )),
            keccak256(abi.encode(
                STAKING_INFO_TYPEHASH,
                stakingInfo.owner,
                stakingInfo.tickets,
                stakingInfo.validity
            ))
        ));
    }

    function recover(bytes32 hash, bytes memory sig) pure private returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}
