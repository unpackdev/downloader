// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./ITreasury.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC20Mintable.sol";
import "./IPSIERC20.sol";
import "./IBondCalculator.sol";

contract Treasury is Ownable, ITreasury {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    event Deposit(address indexed token, uint amount, uint value);
    event Withdrawal(address indexed token, uint amount, uint value);
    event CreateDebt(address indexed debtor, address indexed token, uint amount, uint value);
    event RepayDebt(address indexed debtor, address indexed token, uint amount, uint value);
    event ReservesManaged(address indexed token, uint amount);
    event ReservesUpdated(uint indexed totalReserves);
    event ReservesAudited(uint indexed totalReserves);
    event RewardsMinted(address indexed caller, address indexed recipient, uint amount);
    event ChangeQueued(MANAGING indexed managing, address queued);
    event ChangeActivated(MANAGING indexed managing, address activated, bool result);

    enum MANAGING {RESERVEDEPOSITOR, RESERVESPENDER, RESERVETOKEN, RESERVEMANAGER, LIQUIDITYDEPOSITOR, LIQUIDITYTOKEN, LIQUIDITYMANAGER, DEBTOR, REWARDMANAGER, SPSI}

    address public immutable PSI;
    uint public immutable blocksNeededForQueue;

    address[] public reserveTokens; // Push only, beware false-positives.
    mapping(address => bool) public isReserveToken;
    mapping(address => uint) public reserveTokenQueue; // Delays changes to mapping.

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveDepositor;
    mapping(address => uint) public reserveDepositorQueue; // Delays changes to mapping.

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveSpender;
    mapping(address => uint) public reserveSpenderQueue; // Delays changes to mapping.

    address[] public liquidityTokens; // Push only, beware false-positives.
    mapping(address => bool) public isLiquidityToken;
    mapping(address => uint) public LiquidityTokenQueue; // Delays changes to mapping.

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityDepositor;
    mapping(address => uint) public LiquidityDepositorQueue; // Delays changes to mapping.

    mapping(address => address) public bondCalculator; // bond calculator for liquidity token

    address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveManager;
    mapping(address => uint) public ReserveManagerQueue; // Delays changes to mapping.

    address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityManager;
    mapping(address => uint) public LiquidityManagerQueue; // Delays changes to mapping.

    address[] public debtors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isDebtor;
    mapping(address => uint) public debtorQueue; // Delays changes to mapping.
    mapping(address => uint) public debtorBalance;

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isRewardManager;
    mapping(address => uint) public rewardManagerQueue; // Delays changes to mapping.

    address public sPSI;
    uint public sPSIQueue; // Delays change to sPSI address

    uint public totalReserves; // Risk-free value of all assets
    uint public totalDebt;

    address public stable;
    uint256 public psiPriceInUsd;
    uint256 public priceDecimals;
    uint256 public constant PCT_PRECISION = 1e4;
    address public burnWallet;
    address public burnVault;
    uint256 public vaultPct;
    uint256 public psiDecimals;
    uint256 public stableDecimals;


    constructor (
        address _PSI,
        address _DAI,
        uint _blocksNeededForQueue,
        address _stable,
        address _burnWallet,
        address _burnVault,
        uint256 _price
    ) {
        require(_PSI != address(0));
        PSI = _PSI;

        isReserveToken[_DAI] = true;
        reserveTokens.push(_DAI);

        blocksNeededForQueue = _blocksNeededForQueue;
        stable = _stable;
        burnVault = _burnVault;
        burnWallet = _burnWallet;
        psiPriceInUsd = _price;
        priceDecimals = 2;
        vaultPct = PCT_PRECISION / 2;
        psiDecimals = IERC20Metadata(_PSI).decimals();
        stableDecimals = IERC20Metadata(stable).decimals();
    }

    /**
        @notice allow approved address to deposit an asset for PSI
        @param _amount uint
        @param _token address
        @param _profit uint
        @return send_ uint
     */
    function deposit(uint _amount, address _token, uint _profit) external override returns (uint send_) {
        require(isReserveToken[_token] || isLiquidityToken[_token], "Not accepted");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        if (isReserveToken[_token]) {
            require(isReserveDepositor[msg.sender], "Not approved");
        } else {
            require(isLiquidityDepositor[msg.sender], "Not approved");
        }

        uint value = valueOf(_token, _amount);
        // mint PSI needed and store amount of rewards for distribution
        send_ = value.sub(_profit);
        if (send_ > 0) {
            IERC20Mintable(PSI).mint(msg.sender, send_);
        }

        totalReserves = totalReserves.add(value);
        emit ReservesUpdated(totalReserves);

        emit Deposit(_token, _amount, value);
    }

    /**
        @notice allow approved address to burn PSI for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw(uint _amount, address _token) external {
        require(isReserveToken[_token], "Not accepted");
        // Only reserves can be used for redemptions
        require(isReserveSpender[msg.sender] == true, "Not approved");

        uint value = valueOf(_token, _amount);
        totalReserves = totalReserves.sub(value);
        emit ReservesUpdated(totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, value);
    }

    /**
        @notice allow approved address to borrow reserves
        @param _amount uint
        @param _token address
     */
    function incurDebt(uint _amount, address _token) external {
        require(isDebtor[msg.sender], "Not approved");
        require(isReserveToken[_token], "Not accepted");

        uint value = valueOf(_token, _amount);

        uint maximumDebt = IERC20(sPSI).balanceOf(msg.sender);
        // Can only borrow against sPSI held
        uint availableDebt = maximumDebt.sub(debtorBalance[msg.sender]);
        require(value <= availableDebt, "Exceeds debt limit");

        debtorBalance[msg.sender] = debtorBalance[msg.sender].add(value);
        totalDebt = totalDebt.add(value);

        totalReserves = totalReserves.sub(value);
        emit ReservesUpdated(totalReserves);

        IERC20(_token).transfer(msg.sender, _amount);

        emit CreateDebt(msg.sender, _token, _amount, value);
    }

    /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param _amount uint
        @param _token address
     */
    function repayDebtWithReserve(uint _amount, address _token) external {
        require(isDebtor[msg.sender], "Not approved");
        require(isReserveToken[_token], "Not accepted");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint value = valueOf(_token, _amount);
        debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(value);
        totalDebt = totalDebt.sub(value);

        totalReserves = totalReserves.add(value);
        emit ReservesUpdated(totalReserves);

        emit RepayDebt(msg.sender, _token, _amount, value);
    }

    /**
        @notice allow approved address to repay borrowed reserves with PSI
        @param _amount uint
     */
    function repayDebtWithPSI(uint _amount) external {
        require(isDebtor[msg.sender], "Not approved");

        IPSIERC20(PSI).burnFrom(msg.sender, _amount);

        debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(_amount);
        totalDebt = totalDebt.sub(_amount);

        emit RepayDebt(msg.sender, PSI, _amount, _amount);
    }

    /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */
    function manage(address _token, uint _amount) external {
        if (isLiquidityToken[_token]) {
            require(isLiquidityManager[msg.sender], "Not approved");
        } else {
            require(isReserveManager[msg.sender], "Not approved");
        }

        uint value = valueOf(_token, _amount);
        require(value <= excessReserves(), "Insufficient reserves");

        totalReserves = totalReserves.sub(value);
        emit ReservesUpdated(totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit ReservesManaged(_token, _amount);
    }

    /**
        @notice send epoch reward to staking contract
     */
    function mintRewards(address _recipient, uint _amount) external override {
        require(isRewardManager[msg.sender], "Not approved");
        require(_amount <= excessReserves(), "Insufficient reserves");

        IERC20Mintable(PSI).mint(_recipient, _amount);

        emit RewardsMinted(msg.sender, _recipient, _amount);
    }

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves() public view returns (uint) {
        return totalReserves.sub(IERC20(PSI).totalSupply().sub(totalDebt));
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyManager() {
        uint reserves;
        for (uint i = 0; i < reserveTokens.length; i++) {
            reserves = reserves.add(
                valueOf(reserveTokens[i], IERC20(reserveTokens[i]).balanceOf(address(this)))
            );
        }
        for (uint i = 0; i < liquidityTokens.length; i++) {
            reserves = reserves.add(
                valueOf(liquidityTokens[i], IERC20(liquidityTokens[i]).balanceOf(address(this)))
            );
        }
        totalReserves = reserves;
        emit ReservesUpdated(reserves);
        emit ReservesAudited(reserves);
    }

    /**
        @notice returns PSI valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOf(address _token, uint _amount) public view returns (uint value_) {
        if (isReserveToken[_token]) {
            // convert amount to match PSI decimals
            value_ = _amount.mul(10 ** IERC20Metadata(PSI).decimals()).div(10 ** IERC20Metadata(_token).decimals());
        } else if (isLiquidityToken[_token]) {
            value_ = IBondCalculator(bondCalculator[_token]).valuation(_token, _amount);
        }
    }

    /**
        @notice queue address to cpsige boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function queue(MANAGING _managing, address _address) external onlyManager() returns (bool) {
        require(_address != address(0));
        if (_managing == MANAGING.RESERVEDEPOSITOR) {// 0
            reserveDepositorQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.RESERVESPENDER) {// 1
            reserveSpenderQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.RESERVETOKEN) {// 2
            reserveTokenQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.RESERVEMANAGER) {// 3
            ReserveManagerQueue[_address] = block.number.add(blocksNeededForQueue.mul(2));
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {// 4
            LiquidityDepositorQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {// 5
            LiquidityTokenQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.LIQUIDITYMANAGER) {// 6
            LiquidityManagerQueue[_address] = block.number.add(blocksNeededForQueue.mul(2));
        } else if (_managing == MANAGING.DEBTOR) {// 7
            debtorQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.REWARDMANAGER) {// 8
            rewardManagerQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.SPSI) {// 9
            sPSIQueue = block.number.add(blocksNeededForQueue);
        } else return false;

        emit ChangeQueued(_managing, _address);
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
    function toggle(MANAGING _managing, address _address, address _calculator) external onlyManager() returns (bool) {
        require(_address != address(0));
        bool result;
        if (_managing == MANAGING.RESERVEDEPOSITOR) {// 0
            if (requirements(reserveDepositorQueue, isReserveDepositor, _address)) {
                reserveDepositorQueue[_address] = 0;
                if (!listContains(reserveDepositors, _address)) {
                    reserveDepositors.push(_address);
                }
            }
            result = !isReserveDepositor[_address];
            isReserveDepositor[_address] = result;

        } else if (_managing == MANAGING.RESERVESPENDER) {// 1
            if (requirements(reserveSpenderQueue, isReserveSpender, _address)) {
                reserveSpenderQueue[_address] = 0;
                if (!listContains(reserveSpenders, _address)) {
                    reserveSpenders.push(_address);
                }
            }
            result = !isReserveSpender[_address];
            isReserveSpender[_address] = result;

        } else if (_managing == MANAGING.RESERVETOKEN) {// 2
            if (requirements(reserveTokenQueue, isReserveToken, _address)) {
                reserveTokenQueue[_address] = 0;
                if (!listContains(reserveTokens, _address)) {
                    reserveTokens.push(_address);
                }
            }
            result = !isReserveToken[_address];
            isReserveToken[_address] = result;

        } else if (_managing == MANAGING.RESERVEMANAGER) {// 3
            if (requirements(ReserveManagerQueue, isReserveManager, _address)) {
                reserveManagers.push(_address);
                ReserveManagerQueue[_address] = 0;
                if (!listContains(reserveManagers, _address)) {
                    reserveManagers.push(_address);
                }
            }
            result = !isReserveManager[_address];
            isReserveManager[_address] = result;

        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {// 4
            if (requirements(LiquidityDepositorQueue, isLiquidityDepositor, _address)) {
                liquidityDepositors.push(_address);
                LiquidityDepositorQueue[_address] = 0;
                if (!listContains(liquidityDepositors, _address)) {
                    liquidityDepositors.push(_address);
                }
            }
            result = !isLiquidityDepositor[_address];
            isLiquidityDepositor[_address] = result;

        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {// 5
            if (requirements(LiquidityTokenQueue, isLiquidityToken, _address)) {
                LiquidityTokenQueue[_address] = 0;
                if (!listContains(liquidityTokens, _address)) {
                    liquidityTokens.push(_address);
                }
            }
            result = !isLiquidityToken[_address];
            isLiquidityToken[_address] = result;
            bondCalculator[_address] = _calculator;

        } else if (_managing == MANAGING.LIQUIDITYMANAGER) {// 6
            if (requirements(LiquidityManagerQueue, isLiquidityManager, _address)) {
                LiquidityManagerQueue[_address] = 0;
                if (!listContains(liquidityManagers, _address)) {
                    liquidityManagers.push(_address);
                }
            }
            result = !isLiquidityManager[_address];
            isLiquidityManager[_address] = result;

        } else if (_managing == MANAGING.DEBTOR) {// 7
            if (requirements(debtorQueue, isDebtor, _address)) {
                debtorQueue[_address] = 0;
                if (!listContains(debtors, _address)) {
                    debtors.push(_address);
                }
            }
            result = !isDebtor[_address];
            isDebtor[_address] = result;

        } else if (_managing == MANAGING.REWARDMANAGER) {// 8
            if (requirements(rewardManagerQueue, isRewardManager, _address)) {
                rewardManagerQueue[_address] = 0;
                if (!listContains(rewardManagers, _address)) {
                    rewardManagers.push(_address);
                }
            }
            result = !isRewardManager[_address];
            isRewardManager[_address] = result;

        } else if (_managing == MANAGING.SPSI) {// 9
            sPSIQueue = 0;
            sPSI = _address;
            result = true;

        } else return false;

        emit ChangeActivated(_managing, _address, result);
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool 
     */
    function requirements(
        mapping(address => uint) storage queue_,
        mapping(address => bool) storage status_,
        address _address
    ) internal view returns (bool) {
        if (!status_[_address]) {
            require(queue_[_address] != 0, "Must queue");
            require(queue_[_address] <= block.number, "Queue not expired");
            return true;
        }
        return false;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains(address[] storage _list, address _token) internal view returns (bool) {
        for (uint i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function setPsiPrice(uint256 price, uint256 decimals) public onlyManager {
        psiPriceInUsd = price;
        priceDecimals = decimals;
    }

    function setVaultPct(uint256 pct) public onlyManager {
        vaultPct = pct;
    }

    function setBurnWallet(address wallet) public onlyManager {
        burnWallet = wallet;
    }

    function setBurnVault(address vault) public onlyManager {
        burnVault = vault;
    }

    function redeemPsi(uint256 amountToRedeem, uint256 slippage) public {
        uint256 stableAmount = stableDecimals < psiDecimals
        ? (amountToRedeem * psiPriceInUsd) /
        (10 ** priceDecimals) /
        (10 ** (psiDecimals - stableDecimals))
        : ((amountToRedeem * psiPriceInUsd) * (10 ** (stableDecimals - psiDecimals))) /
        (10 ** priceDecimals);
        require(stableAmount >= slippage, "Slippage too high");
        uint256 amountForVault = (amountToRedeem * vaultPct) / PCT_PRECISION;
        IERC20(PSI).safeTransferFrom(msg.sender, burnVault, amountForVault);
        IERC20(PSI).safeTransferFrom(msg.sender, burnWallet, amountToRedeem - amountForVault);
        IERC20(stable).safeTransfer(msg.sender, stableAmount);
    }

    function scoopTokens(address _token, uint256 amount) external onlyManager {
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
}