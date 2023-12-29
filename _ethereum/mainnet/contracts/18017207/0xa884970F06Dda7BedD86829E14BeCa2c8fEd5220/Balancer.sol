// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
pragma abicoder v2;

// ====================================================================
// ======================== Balancer.sol ==============================
// ====================================================================

/**
 * @title Balancer
 * @dev Implementation:
 * Updates the interest rate from Sweep periodically.
 * Executes the auto calls and auto invests in Stabilizers.
 */

import "./Owned.sol";
import "./Sweepr.sol";
import "./IStabilizer.sol";
import "./NonblockingLzApp.sol";

contract Balancer is NonblockingLzApp, Owned {
    SweeprCoin public sweepr;

    enum Mode { IDLE, INVEST, CALL }

    uint256 public index;
    uint256 public period = 1 days;
    uint256 private constant PRECISION = 1e6;    
    uint16 public constant PT_INTEREST_RATE = 1; // packet type for sending interest rate
    
    mapping(uint256 => address) public stabilizers;
    mapping(address => uint256) public amounts;

    // Events
    event InterestRateRefreshed(int256 interestRate);
    event SweeprSet(address indexed sweeprAddress);
    event ActionAdded(address stabilizer, uint256 amount);
    event ActionRemoved(address stabilizer);
    event ChainAdded(uint16 dstChainId, address indexed sweep);
    event ChainRemoved(uint16 dstChainId);
    event Execute(Mode mode);
    event Reset();

    error ModeMismatch(Mode intention, Mode state);
    error WrongDataLength();
    error NotTrustedRemote();
    error ZeroAmount();
    error ZeroETH();
    error NotEnoughETH();

    constructor(address sweepAddress, address lzEndpoint) NonblockingLzApp(lzEndpoint) Owned(sweepAddress) {}

    /**
     * @notice refresh interest rate periodically.
     * returns mode: 0 => idle, 1 => invest, 2 => call
     */
    function refreshInterestRate() public onlyMultisigOrGov returns (Mode mode) {
        int256 interestRate = sweep.interestRate();
        int256 stepValue = sweep.stepValue();
        
        mode = getMode();

        if (mode == Mode.CALL) interestRate += stepValue;
        if (mode == Mode.INVEST) interestRate -= stepValue;

        uint256 periodStart = sweep.periodStart() + period;
        sweep.setInterestRate(interestRate, periodStart);

        if (address(sweepr) != address(0) && sweepr.isGovernanceChain()) {
            _sendInterestRate(interestRate, periodStart);
        }
    }

    function getMode() public view returns (Mode) {
        uint256 twaPrice = sweep.twaPrice();
        uint256 targetPrice = sweep.targetPrice();
        uint256 spread = sweep.arbSpread() * targetPrice / PRECISION;
        uint256 upperBound = targetPrice + spread;
        uint256 lowerBound = targetPrice - spread;

        if (twaPrice < lowerBound) return Mode.CALL;
        if (twaPrice > upperBound) return Mode.INVEST;
        return Mode.IDLE;
    }

    function setSweepr(address sweeprAddress) external onlyGov {
        if (sweeprAddress == address(0)) revert ZeroAddressDetected();
        sweepr = SweeprCoin(sweeprAddress);

        emit SweeprSet(sweeprAddress);
    }

    /**
     * @notice Set Interest Rate
     * @param interestRate new interest rate.
     * @param periodStart new period start.
     */
    function setInterestRate(int256 interestRate, uint256 periodStart) external onlyMultisigOrGov {
        sweep.setInterestRate(interestRate, periodStart);
    }

    /**
     * @notice Set Period for refreshing interest rate
     * @param newPeriod new period. For example, newPeriod = 604800 means 7 days.
     */
    function setPeriod(uint256 newPeriod) external onlyMultisigOrGov {
        if (newPeriod == 0) revert ZeroAmount();
        period = newPeriod;
    }

    /**
     * @notice Recover the Ether from the contract
     */
    function recoverEther() external onlyMultisigOrGov {
        uint256 ethBalance = address(this).balance;
        (bool success, ) = (msg.sender).call{value: ethBalance}(new bytes(0));
        require(success, 'STE');
    }

    function _sendInterestRate(int256 rate, uint256 periodStart) internal {
        uint chainCount = sweepr.chainCount();
        for (uint i = 0; i < chainCount; ) {
            uint16 dstChainId = sweepr.getChainId(i);
            
            address balancerDstAddress = sweepr.getBalancerWithChainId(dstChainId);
            bool isTrusted = this.isTrustedRemote(dstChainId, abi.encodePacked(balancerDstAddress, address(this)));

            if (!isTrusted) revert NotTrustedRemote();

            // encode the payload with the number of pings
            bytes memory payload = abi.encode(PT_INTEREST_RATE, rate, periodStart);


            // use adapterParams v1 to specify more gas for the destination
            uint16 version = 1;
            uint gasForDestinationLzReceive = 350000;
            bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

            // get the fees we need to pay to LayerZero for message delivery
            (uint messageFee, ) = lzEndpoint.estimateFees(dstChainId, address(this), payload, false, adapterParams);
            if (address(this).balance < messageFee) revert NotEnoughETH();

            // send LayerZero message
            _lzSend( // {value: messageFee} will be paid out of this contract!
                dstChainId, // destination chainId
                payload, // abi.encode()'ed bytes
                payable(this), // (msg.sender will be this contract) refund address (LayerZero will refund any extra gas back to caller of send()
                address(0x0), // future param, unused for this example
                adapterParams,
                messageFee // v1 adapterParams, specify custom destination gas qty
            );

            unchecked { i++; }
        }
    }

    function _nonblockingLzReceive(
        uint16, 
        bytes memory, 
        uint64, 
        bytes memory _payload
    ) internal override {
        uint16 packetType;
        assembly {
            packetType := mload(add(_payload, 32))
        }

        if (packetType == PT_INTEREST_RATE) {
            (, int256 newInterestRate, uint256 newPeriodStart) = abi.decode(_payload, (uint16, int256, uint256));

            sweep.setInterestRate(newInterestRate, newPeriodStart);
        } else {
            revert("Balancer: unknown packet type");
        }
    }

    /**
     * @notice Set Loan Limit
     * @dev Assigns a new loan limit to a stabilizer.
     * @param stabilizer to assign the new loan limit to.
     * @param loanLimit new value to be assigned.
     */
    function setLoanLimit(address stabilizer, uint256 loanLimit) external onlyMultisigOrGov {
        IStabilizer(stabilizer).setLoanLimit(loanLimit);
    }

    /**
     * @notice Cancel Call
     * @dev Cancels a call in an off chain stabilizer that is in the line to defaulted if it doesn't repay on time
     * @param stabilizer (offchain) to cancel the call
     */
    function cancelCall(address stabilizer) external onlyMultisigOrGov {
        IStabilizer(stabilizer).cancelCall();
    }

    /**
     * @notice Add Actions
     * @dev Adds a new amounts to be called/invested when executing
     * @param addresess to be added.
     * @param amounts_ to be called or invested,
     */
    function addActions(
        address[] calldata addresess,
        uint256[] calldata amounts_
    ) external onlyMultisigOrGov {
        uint256 len = addresess.length;
        if (len != amounts_.length)
            revert WrongDataLength();

        for (uint256 i = 0; i < len;) {
            addAction(addresess[i], amounts_[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Add Action
     * @dev Adds a new (stabilizer, amount) to be processed in the execute function
     * @param stabilizer stabilizer address,
     * @param amount amount to be called or invested,
     */
    function addAction(
        address stabilizer,
        uint256 amount
    ) public onlyMultisigOrGov {
        stabilizers[index++] = stabilizer;
        amounts[stabilizer] = amount;

        emit ActionAdded(stabilizer, amount);
    }

    /**
     * @notice Remove Action
     * @dev removes amount for the stabilizer
     * @param stabilizer stabilizer to be cleared
     */
    function removeAction(address stabilizer) external onlyMultisigOrGov {
        delete amounts[stabilizer];

        emit ActionRemoved(stabilizer);
    }

    /**
     * @notice Execute
     * @dev refreshes the interest rate, sets new loan limits and auto-calls or auto-invests a list of stabilizers
     * @param intention 0 => idle, 1 => invests, 2 => calls
     * @param force the execution if the state does not corresponds to the intention
     */
    function execute(
        Mode intention,
        bool force,
        uint256 price,
        uint256 slippage
    ) external onlyMultisigOrGov {
        emit Execute(intention);

        Mode state = refreshInterestRate();
        if (intention == Mode.IDLE) return;

        if (intention != state && !force)
            revert ModeMismatch(intention, state);

        for (uint256 i = 0; i < index;) {
            IStabilizer stabilizer = IStabilizer(stabilizers[i]);
            uint256 amount = amounts[stabilizers[i]];

            if (amount > 0) {
                if (intention == Mode.INVEST) {
                    stabilizer.setLoanLimit(stabilizer.loanLimit() + amount);
                    stabilizer.autoInvest(amount, price, slippage);
                } else {
                    // intention is CALL
                    stabilizer.autoCall(amount, price, slippage);
                    stabilizer.setLoanLimit(stabilizer.loanLimit() - amount);
                }
            }

            delete amounts[stabilizers[i]];
            delete stabilizers[i];

            unchecked { ++i; }
        }

        index = 0;
    }

    /**
     * @notice Reset
     * @dev Removes all the pending actions
     */
    function reset() public onlyMultisigOrGov {
        for (uint256 i = 0; i < index;) {
            delete amounts[stabilizers[i]];
            delete stabilizers[i];
            unchecked { ++i; }
        }

        index = 0;

        emit Reset();
    }

    /**
     * @notice Receive Eth
     */
    receive() external payable {}
}
