// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IStrategy.sol";
import "./IRewardManager.sol";

contract NativeVault is ERC20, Ownable {
    using SafeERC20 for IERC20;

    // An array of the strategies used for this vault
    address[] public strategies;
    // A mapping which contains the ratio targeted by strategies
    mapping(address => uint8) public ratios;
    // The total ratio allocated to strategies.
    uint256 public ratioTotal;
    // The wallets allowed to deposit withdraw
    mapping(address => bool) private team;
    // A boolean indicating if the vault is closed or not
    bool public isClosed;

    address public rewardManager;

    // Bytes size of an order
    uint8 constant SINGLE_ORDER_LENGTH = 32;
    // Bytes size of an address
    uint8 constant ADDRESS_SIZE = 20;
    // Orders instruction list
    enum Instructions{UNUSED, DEPOSIT, WITHDRAW}
    // Bytes size of a ratio
    uint8 constant SINGLE_RATIO_LENGTH = 21;

    // An event triggered when a deposit is completed
    event Fund(uint256 _value);
    // An event triggered when a withdrawal is completed
    event Withdrawal(address indexed _to, uint256 _value);
    // An event triggered when rebalancing orders are set
    event Rebalance(uint8 instruction, address strategy, uint256 amount);

    modifier onlyTeam {
        require(team[msg.sender] == true, "You are not allowed");
        _;
    }

    modifier onlyStrategies {
        for (uint8 i = 0; i < strategies.length; i++) {
            if (strategies[i] == msg.sender) {
                _;
                return;
            }
        }
        revert("Function must be called by a strategy");
    }

    modifier onlyRewardManager {
        require(msg.sender == rewardManager);
        _;
    }

    constructor(string memory _name,
        string memory _symbol) ERC20(_name, _symbol) {
        isClosed = false;

        // Add team addresses
        team[0xAfCb545E3F2fA80f1AF9F29262b0bD823CD660D5] = true;
        team[0x0C0BB3535E96b47C0E7A65bEFd1A11B7e13BCBeb] = true;
        team[0xEA29fa603cd0DEdDb183a5Db54FA182b564E8412] = true;
        team[0x90Cc775BB8f21eF9cbA7868c6Aa7e91a13A8a7B8] = true;
        team[0x5fBBa8D0D0C77DB5EF559b2D02BC42460aefd452] = true;
        team[0xD0114334C97b446d6360e6994F742F3F9AB63462] = true;
    }

    /**
     * @dev It calculates the total underlying value of {token} held by the vault and the different strategies.
    **/
    function overallBalance() public returns (uint) {
        uint256 totalBalance = address(this).balance;
        for (uint256 i = 0; i < strategies.length; i++) {
            totalBalance += IStrategy(strategies[i]).getVirtualBalance();
        }
        return totalBalance;
    }

    /**
     * @dev Deposits an amount in the vault.
    **/
    function fund() public payable onlyTeam {
        require(isClosed == false, "Vault is closed");
        // Check amount is > 0
        require(msg.value > 0);

        uint256 _amount = msg.value;
        uint256 _pool = overallBalance() - _amount;

        // Mint shares
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply()) / _pool;
        }

        emit Fund(msg.value);

        _mint(msg.sender, shares);
    }

    /**
     * @dev Withdraws an amount to the token holder
     * It will fetch from the most overtarget pool or from the biggest pool
    **/
    function withdraw(uint256 _shares) public onlyTeam {

        require(_shares <= balanceOf(msg.sender), "You can't withdraw more shares than you have");

        uint256 sharesValue = overallBalance() * _shares / totalSupply();
        _burn(msg.sender, _shares);

        if (isClosed) {
            (bool success,) = payable(msg.sender).call{value : sharesValue}("");
            require(success, "Transfer failed.");

            emit Withdrawal(msg.sender, sharesValue);
        } else {
            uint256 totalAmount = 0;

            // Look for most over target strategy
            address strategyToWithdraw;
            uint256 strategyAvailableAmount;
            (strategyToWithdraw, strategyAvailableAmount) = findMostOverTargetStrategy(sharesValue);

            if (sharesValue > strategyAvailableAmount) {
                // Over target strategy is too small, we withdraw from the biggest pool
                (strategyToWithdraw, strategyAvailableAmount) = findMostLockedStrategy();
                require(sharesValue <= strategyAvailableAmount, "Withdrawal amount too big");
            }

            require(sharesValue <= strategyAvailableAmount, "Withdrawal amount is bigger than pool size");

            // Compute pool LP amount to withdraw
            uint256 poolLpAmount = IStrategy(strategyToWithdraw).getConvexLpBalance();
            uint256 poolBalance = IStrategy(strategyToWithdraw).getVirtualBalance();
            uint256 poolLpAmountToWithdraw = (poolLpAmount * sharesValue) / poolBalance;
            totalAmount = IStrategy(strategyToWithdraw).withdraw(poolLpAmountToWithdraw);

            (bool success,) = payable(msg.sender).call{value : totalAmount}("");
            require(success, "Transfer failed.");

            emit Withdrawal(msg.sender, totalAmount);
        }
    }

    /*
     * @dev This method allows to update the ratios which represents the target allocation for the strategies
     * @param ratios: Any amount of 21-byte orders with the format [20 bytes `address`, 1 byte `ratio` (0-100)]
     */
    function setRatios(bytes memory ratiosBytes) public onlyOwner {
        require(ratiosBytes.length % SINGLE_RATIO_LENGTH == 0, "Ratios are not in the right format");

        uint8 addedRatios = 0;

        for (uint i = 0; i < ratiosBytes.length / SINGLE_RATIO_LENGTH; i++) {
            // Decode #0-#19: Address
            uint160 addressAsInt;
            uint8 addressByte;
            address addressParsed;

            for (uint j = 0; j < ADDRESS_SIZE; j++) {
                uint256 index = (i * SINGLE_RATIO_LENGTH) + j;
                addressAsInt *= 256;
                addressByte = uint8(ratiosBytes[index]);
                addressAsInt += addressByte;
            }
            addressParsed = address(addressAsInt);

            // Check that address is inside our strategies
            getStrategyIndex(addressParsed);

            // Decode #20: Amount
            uint256 ratioByte = ((i + 1) * 20) + i;
            // 21th byte [20, 41, 62, ...]
            uint8 ratio = uint8(ratiosBytes[ratioByte]);
            addedRatios += ratio;
            ratios[addressParsed] = ratio;
        }

        ratioTotal = addedRatios;
    }

    /*
     * @dev This method is called by the optimizer to pass orders (deposit/withdraw) that the vault should execute to rebalance the strategies.
     * @param orders: Any amount of 32-byte orders with the format [1 byte `instruction`, 20 bytes `address`, 11 bytes `amount`]
     */
    function setOrders(bytes memory orders) public onlyOwner {
        require(isClosed == false, "Vault is closed");
        require(orders.length % SINGLE_ORDER_LENGTH == 0, "Orders are not in the right format");

        for (uint i = 0; i < orders.length / SINGLE_ORDER_LENGTH; i++) {
            // Decode #0: Instruction code
            bytes1 instructionByte = orders[i * SINGLE_ORDER_LENGTH];
            uint8 instruction = uint8(instructionByte);

            // Decode #1-#20: Address
            uint160 addressAsInt;
            uint8 addressByte;
            address addressParsed;

            for (uint j = 1; j < ADDRESS_SIZE + 1; j++) {
                uint256 index = (i * SINGLE_ORDER_LENGTH) + j;
                addressAsInt *= 256;
                addressByte = uint8(orders[index]);
                addressAsInt += addressByte;
            }
            addressParsed = address(addressAsInt);

            // Check that address is inside our strategies
            getStrategyIndex(addressParsed);

            // Decode #21-#31: Amount
            uint256 amount;
            uint8 amountByte;

            for (uint k = ADDRESS_SIZE + 1; k < SINGLE_ORDER_LENGTH; k++) {
                uint256 index = (i * SINGLE_ORDER_LENGTH) + k;
                amount *= 256;
                amountByte = uint8(orders[index]);
                amount += amountByte;
            }

            if (instruction == uint8(Instructions.DEPOSIT)) {
                IStrategy(addressParsed).deposit{value : amount}();
                emit Rebalance(instruction, addressParsed, amount);
            } else if (instruction == uint8(Instructions.WITHDRAW)) {
                // Compute pool LP amount to withdraw
                uint256 poolLpAmount = IStrategy(addressParsed).getConvexLpBalance();
                uint256 poolBalance = IStrategy(addressParsed).getVirtualBalance();
                uint256 poolLpAmountToWithdraw = (poolLpAmount * amount) / poolBalance;
                IStrategy(addressParsed).withdraw(poolLpAmountToWithdraw);
                emit Rebalance(instruction, addressParsed, amount);
            } else {
                revert("Instruction not recognized");
            }
        }
    }

    /**
     * @dev Returns the index of the strategy
    **/
    function getStrategyIndex(address strategy) public view returns (uint8) {
        for (uint8 i = 0; i < strategies.length; i++) {
            if (strategies[i] == strategy) return i;
        }
        revert("Invalid strategy address");
    }

    /**
     * @dev Adds a strategy to our list of approved strategies
    **/
    function addStrategy(address strategyAddress) public onlyOwner {
        for (uint8 i = 0; i < strategies.length; i++) {
            require(strategies[i] != strategyAddress, "Strategy already exists");
        }
        strategies.push(strategyAddress);
    }

    /**
     * @dev Removes a strategy from our list of approved strategies
     * Transfers the funds back from the strategy to the vault
    **/
    function removeStrategy(address strategy) public onlyOwner {
        if (IStrategy(strategy).getConvexLpBalance() > 0) {
            IStrategy(strategy).withdrawAll();
        }

        uint8 index = getStrategyIndex(strategy);
        require(index < strategies.length);

        address strategyToRemove = strategies[index];
        for (uint8 i = index + 1; i < strategies.length; i++) {
            strategies[i - 1] = strategies[i];
        }

        strategies[strategies.length - 1] = strategyToRemove;
        strategies.pop();

        // Set ratio of strat to 0
        ratioTotal = ratioTotal - ratios[strategy];
        ratios[strategy] = 0;
    }

    /**
     * @dev Will harvest all strategies.
    **/
    function harvestAll() public {
        require(rewardManager != address(0));
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).harvest();
        }
        IRewardManager(rewardManager).collect();
    }

    /**
     * @dev Closes vault, brings back funds from strategies
    **/
    function closeVault() external onlyOwner {
        isClosed = true;
        for (uint8 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).withdrawAll();
            ratios[strategies[i]] = 0;
        }
        ratioTotal = 0;
    }

    /**
     * @dev Opens vault
    **/
    function openVault() external onlyOwner {
        isClosed = false;
    }

    /**
     * @dev This methods find the strategy which is the most above its target.
     * If it has enough balance, it will be used to withdraw from here.
    **/
    function findMostOverTargetStrategy(uint256 withdrawAmount) public returns (address, uint256) {
        require(ratioTotal > 0, "Total ratio should be greater than 0");

        uint256 balance = overallBalance() - withdrawAmount;
        address overTargetStrategy = strategies[0];

        uint256 optimal = balance * ratios[strategies[0]] / ratioTotal;
        uint256 current = IStrategy(strategies[0]).getVirtualBalance();

        bool isLessThanOpt = current < optimal;
        uint256 overTargetBalance = isLessThanOpt ? optimal - current : current - optimal;

        for (uint256 i = 0; i < strategies.length; i++) {
            optimal = balance * ratios[strategies[i]] / ratioTotal;
            current = IStrategy(strategies[i]).getVirtualBalance();

            if (isLessThanOpt && current > optimal) {
                isLessThanOpt = false;
                overTargetBalance = current - optimal;
                overTargetStrategy = strategies[i];
            } else if (isLessThanOpt && current < optimal) {
                if (optimal - current < overTargetBalance) {
                    overTargetBalance = optimal - current;
                    overTargetStrategy = strategies[i];
                }
            } else if (!isLessThanOpt && current >= optimal) {
                if (current - optimal > overTargetBalance) {
                    overTargetBalance = current - optimal;
                    overTargetStrategy = strategies[i];
                }
            }
        }

        if (isLessThanOpt) {
            overTargetBalance = 0;
        }

        return (overTargetStrategy, overTargetBalance);
    }

    /**
     * @dev This methods find the strategy which has the highest balance.
    **/
    function findMostLockedStrategy() public returns (address, uint256) {
        uint256 current;
        address lockedMostAddress = strategies[0];
        uint256 lockedBalance = IStrategy(strategies[0]).getVirtualBalance();

        for (uint256 i = 0; i < strategies.length; i++) {
            current = IStrategy(strategies[i]).getVirtualBalance();
            if (current > lockedBalance) {
                lockedBalance = current;
                lockedMostAddress = strategies[i];
            }
        }

        return (lockedMostAddress, lockedBalance);
    }


    /**
     * @dev This method is used by strategies to transfer back funds to the vault
     */
    function transfer() external payable onlyStrategies {}

    function collect() external payable onlyRewardManager {}

    function setRewardManager(address _newRewardManager) external onlyOwner {
        rewardManager = _newRewardManager;
        for (uint8 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).setRewardManager(_newRewardManager);
        }
    }


    /**
     * @dev Temporary method to set team member
     */
    function setTeamMember(address memberAddress) public onlyOwner {
        team[memberAddress] = true;
    }


    /**
     * @dev Temporary method to remove team member
     */
    function removeTeamMember(address memberAddress) public onlyOwner {
        team[memberAddress] = false;
    }
}
