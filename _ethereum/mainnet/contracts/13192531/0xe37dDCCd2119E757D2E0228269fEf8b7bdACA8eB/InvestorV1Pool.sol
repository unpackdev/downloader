// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IInvestorV1Pool.sol";
import "./IInvestorV1PoolDeployer.sol";

contract InvestorV1Pool is IInvestorV1Pool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant HSF = 0xbA6B0dbb2bA8dAA8F5D6817946393Aef8D3A4487;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public immutable override factory;
    address public immutable override operator;
    string public override name;
    uint256 public immutable override maxCapacity;
    uint256 public immutable override minCapacity;
    uint256 public override oraclePrice;
    uint256 public immutable override startTime;
    uint256 public immutable override stageTime;
    uint256 public immutable override endTime;
    uint24 public immutable override fee;
    uint24 public immutable override interestRate;

    mapping(address => uint256) public override pooledAmt;
    mapping(address => uint256) public override restakeAmt;
    mapping(address => bool) public override claimed;

    address[] public override depositorList;
    address[] public override restakerList;

    uint256 public override funded = 0;
    uint256 public override exited = 0;
    uint256 public override restaked = 0;

    string public override collateralDocument;
    string public override collateralHash;
    string public override detailLink;

    enum PoolState { Created, Opened, Active, Reverted, Liquidated, Dishonored }

    PoolState private poolState = PoolState.Created;

    modifier onlyOperator() {
        require(operator == msg.sender, "InvestorV1Pool: not operator");
        _;
    }
    
    constructor() {
        ( 
            factory, 
            operator, 
            name, 
            maxCapacity, 
            minCapacity
        ) = IInvestorV1PoolDeployer(msg.sender).parameter1();
        (
            oraclePrice, 
            startTime, 
            stageTime, 
            endTime, 
            fee,
            interestRate
        ) = IInvestorV1PoolDeployer(msg.sender).parameter2();
    }

    function depositors() public override view returns(uint256) {
        return depositorList.length;
    }

    function restakers() public override view returns(uint256) {
        return restakerList.length;
    }

    function getInfo(address _account) public override view returns (string memory, string memory, uint256, uint256, uint256, uint256, uint256, uint256, uint24, uint24) {
        uint256 mypool = pooledAmt[_account];
        uint256 myrestake = restakeAmt[_account];
        return (name, getPoolState(), maxCapacity, funded, restaked, exited, mypool, myrestake, fee, interestRate);
    }

    function getExtra() public override view returns (address, address, uint256, uint256, uint256, string memory, string memory, string memory) {
        return (operator, factory, oraclePrice, depositors(), restakers(), collateralDocument, collateralHash, detailLink);
    }

    function expectedRestakeRevenue(uint256 amount) public override view returns (uint256) {
        if(amount == 0) return 0;

        uint256 estimated = (10000 - fee);
        uint256 added = restaked.add(amount);
        estimated = estimated * (10000 + interestRate);
        estimated = exited.mul(estimated);
        estimated = estimated.div(100000000);
        estimated = estimated.mul(amount);
        estimated = estimated.div(added);

        return estimated;
    }

    function getPoolState() public override view returns (string memory) {
        if (poolState == PoolState.Opened) return "Opened";
        if (poolState == PoolState.Active) return "Active";
        if (poolState == PoolState.Created) return "Created";
        if (poolState == PoolState.Dishonored) return "Dishonored";
        if (poolState == PoolState.Liquidated) return "Liquidated";
        if (poolState == PoolState.Reverted) return "Reverted";
        return "Impossible";
    }

    function removeDepositor(address user) internal {
        require(depositorList.length >= 1);
        if(depositorList[depositorList.length-1] == user) {
            depositorList.pop();
            return;
        }

        for (uint i = 0; i < depositorList.length-1; i++){
            if(depositorList[i] == user) {
                depositorList[i] = depositorList[depositorList.length-1];
                depositorList.pop();
                return;
            }
        }
    }

    function removeRestaker(address user) internal {
        require(restakerList.length >= 1);
        if(restakerList[restakerList.length-1] == user) {
            restakerList.pop();
            return;
        }

        for (uint i = 0; i < restakerList.length-1; i++){
            if(restakerList[i] == user) {
                restakerList[i] = restakerList[restakerList.length-1];
                restakerList.pop();
                return;
            }
        }
    }

    // State Update
    function update() public override returns (bool) {
        if(poolState == PoolState.Opened && block.timestamp > stageTime) {
            if(funded >= minCapacity) { 
                poolState = PoolState.Active; 
                exited = maxCapacity - funded;
                emit PoolActiviated(funded);
            }
            else { 
                poolState = PoolState.Reverted; 
                emit PoolReverted(minCapacity, funded);
            }
            return true;
        }

        if(poolState == PoolState.Active && block.timestamp > endTime) {
            uint256 liquidityFund = IERC20(USDT).balanceOf(address(this));
            uint256 estimated = (10000 - fee);
            estimated = estimated * (10000 + interestRate);
            if(exited > 0 && restaked == 0) estimated = funded.mul(estimated);
            else estimated = maxCapacity.mul(estimated);
            estimated = estimated.div(100000000);
            if(liquidityFund >= estimated) { 
                poolState = PoolState.Liquidated; 
                emit PoolLiquidated(liquidityFund);
            }
            else { 
                poolState = PoolState.Dishonored; 
                emit PoolDishonored(estimated, liquidityFund);
            }
        }

        return true;
    }

    function setOraclePrice(uint256 _oraclePrice) public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Opened 
            || poolState == PoolState.Created, "InvestorV1Pool: pool not open");
        require(_oraclePrice != oraclePrice, "InvestorV1Pool: oraclePrice not changed");

        uint256 minDeposit = maxCapacity.mul(100);
        minDeposit = minDeposit.div(_oraclePrice);
        if (maxCapacity.mod(_oraclePrice) != 0) { minDeposit = minDeposit.add(1); }
        minDeposit = minDeposit.mul(10**12);

        if(oraclePrice > _oraclePrice) {
            minDeposit = minDeposit.sub(IERC20(HSF).balanceOf(address(this)));
            oraclePrice = _oraclePrice;

            IERC20(HSF).safeTransferFrom(msg.sender, address(this), minDeposit);
            emit Deposit(HSF, msg.sender, minDeposit);
        }
        else {
            uint256 operatorDeposits = IERC20(HSF).balanceOf(address(this));
            minDeposit = operatorDeposits.sub(minDeposit);
            oraclePrice = _oraclePrice;

            IERC20(HSF).safeTransfer(msg.sender, minDeposit);
            emit Withdrawal(HSF, msg.sender, msg.sender, minDeposit);
        }

        emit OraclePriceChanged(_oraclePrice);

        return true;
    }

    function setPoolDetailLink(string memory _newLink) public override onlyOperator returns (bool) {
        detailLink = _newLink;

        emit PoolDetailLinkChanged(detailLink);

        return true;
    }

    function setColletralHash(string memory _newHash) public override onlyOperator returns (bool) {
        string memory oldHash = collateralHash;
        collateralHash = _newHash;

        emit ColletralHashChanged(oldHash, collateralHash);

        return true;
    }
    function setColletralLink(string memory _newLink) public override onlyOperator returns (bool) {
        string memory oldLink = collateralDocument;
        collateralDocument = _newLink;

        emit ColletralLinkChanged(oldLink, collateralDocument);

        return true;
    }
    
    function rescue(address target) public override onlyOperator returns (bool) {
        require(target != USDT && target != HSF, "InvestorV1Pool: USDT and HSF cannot be rescued");
        require(IERC20(target).balanceOf(address(this)) > 0, "InvestorV1Pool: no target token here");

        IERC20(target).safeTransfer(msg.sender, IERC20(target).balanceOf(address(this)));

        emit Withdrawal(target, msg.sender, msg.sender, IERC20(target).balanceOf(address(this)));

        return true;
    }

    function pullDeposit() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Active, "InvestorV1Pool: pool not active");

        uint256 pooledTotal = IERC20(USDT).balanceOf(address(this));
        IERC20(USDT).safeTransfer(msg.sender, pooledTotal);

        emit Withdrawal(USDT, msg.sender, msg.sender, pooledTotal);

        return true;
    }

    function liquidate() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Active, "InvestorV1Pool: pool not active");
        uint256 estimated = (10000 - fee);
        estimated = estimated * (10000 + interestRate);

        if(exited > 0 && restaked == 0) estimated = funded.mul(estimated);
        else estimated = maxCapacity.mul(estimated);
        
        estimated = estimated.div(100000000);

        uint256 currentBalance = IERC20(USDT).balanceOf(address(this));

        if(estimated <= currentBalance) return true;

        IERC20(USDT).safeTransferFrom(msg.sender, address(this), estimated.sub(currentBalance));

        emit Deposit(USDT, msg.sender, estimated.sub(currentBalance));

        return true;
    }

    function openPool() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Created, "InvestorV1Pool: not create state");

        uint256 minDeposit = maxCapacity.mul(100);
        minDeposit = minDeposit.div(oraclePrice);
        if (maxCapacity.mod(oraclePrice) != 0) { minDeposit = minDeposit.add(1); }
        minDeposit = minDeposit.mul(10**12);

        poolState = PoolState.Opened;

        IERC20(HSF).safeTransferFrom(msg.sender, address(this), minDeposit);

        emit Deposit(HSF, msg.sender, minDeposit);
        emit PoolOpened(msg.sender, startTime, minDeposit);

        return true;
    }
    function closePool() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Liquidated, "InvestorV1Pool: pool not finalized");

        uint256 stakedAmt = IERC20(HSF).balanceOf(address(this));
        IERC20(HSF).safeTransfer(msg.sender, stakedAmt);

        emit Withdrawal(HSF, msg.sender, msg.sender, stakedAmt);

        return true;
    }
    function revertPool() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Opened 
            || poolState == PoolState.Created, "InvestorV1Pool: not revertable state");

        poolState = PoolState.Reverted;

        uint256 operatorDeposits = IERC20(HSF).balanceOf(address(this));
        IERC20(HSF).safeTransfer(msg.sender, operatorDeposits);

        emit Withdrawal(HSF, msg.sender, msg.sender, operatorDeposits);
        emit PoolReverted(minCapacity, funded);

        return true;
    }

    function deposit(uint256 amount) public override returns (bool) {
        update();

        require(poolState == PoolState.Opened, "InvestorV1Pool: pool not opened");
        require(block.timestamp >= startTime, "InvestorV1Pool: not started yet");
        require(amount > 0, "InvestorV1Pool: amount is zero");
        require(funded.add(amount) <= maxCapacity, "InvestorV1Pool: deposit over capacity");

        pooledAmt[msg.sender] = pooledAmt[msg.sender].add(amount);
        funded = funded.add(amount);
        depositorList.push(msg.sender);

        IERC20(USDT).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(USDT, msg.sender, amount);

        return true;
    }

    function withdraw(uint256 amount, address to) public override returns (bool) {
        update();

        require(poolState == PoolState.Opened || poolState == PoolState.Reverted, "InvestorV1Pool: pool not opened");
        require(block.timestamp >= startTime, "InvestorV1Pool: not started yet");
        require(pooledAmt[msg.sender] >= amount, "InvestorV1Pool: not enough deposit");
        require(to != address(0), "InvestorV1Pool: to address is zero");

        pooledAmt[msg.sender] = pooledAmt[msg.sender].sub(amount);
        funded = funded.sub(amount);
        if(pooledAmt[msg.sender]==0) {
            removeDepositor(msg.sender);
        }

        IERC20(USDT).safeTransfer(to, amount);

        emit Withdrawal(USDT, msg.sender, to, amount);

        return true;
    }

    function exit(uint256 amount, address to) public override returns (bool) {
        update();

        require(poolState == PoolState.Active || poolState == PoolState.Dishonored, "InvestorV1Pool: pool not active");
        require(pooledAmt[msg.sender] >= amount, "InvestorV1Pool: not enough deposit");
        require(to != address(0), "InvestorV1Pool: to address is zero");

        pooledAmt[msg.sender] = pooledAmt[msg.sender].sub(amount);
        exited = exited.add(amount);
        if(pooledAmt[msg.sender]==0) {
            removeDepositor(msg.sender);
        }

        uint256 exitAmt = amount.mul(10**14);
        exitAmt = exitAmt.div(oraclePrice);

        IERC20(HSF).safeTransfer(to, exitAmt);

        emit Exited(msg.sender, to, exitAmt);

        return true;
    }

    function claim(address to) public override returns (bool) {
        update();

        require(poolState == PoolState.Liquidated, "InvestorV1Pool: pool not finalized");
        require(!claimed[msg.sender], "InvestorV1Pool: already claimed");
        require(to != address(0), "InvestorV1Pool: to address is zero");

        
        uint256 liquidityTotal = (10000 - fee);
        liquidityTotal = liquidityTotal * (10000 + interestRate);
        liquidityTotal = maxCapacity.mul(liquidityTotal);
        liquidityTotal = liquidityTotal.div(100000000);

        uint256 poolClaim = 0;
        uint256 restakeClaim = 0;

        if(pooledAmt[msg.sender] > 0) {
            poolClaim = liquidityTotal.mul(pooledAmt[msg.sender]);
            poolClaim = poolClaim.div(maxCapacity);   
        }

        if(restakeAmt[msg.sender] > 0 && exited > 0) {
            restakeClaim = liquidityTotal.mul(exited);
            restakeClaim = restakeClaim.mul(restakeAmt[msg.sender]);
            restakeClaim = restakeClaim.div(maxCapacity);
            restakeClaim = restakeClaim.div(restaked);
        }

        claimed[msg.sender] = true;

        require(poolClaim.add(restakeClaim) > 0, "InvestorV1Pool: no claim for you");

        IERC20(USDT).safeTransfer(to, poolClaim.add(restakeClaim));

        emit Claim(msg.sender, to, poolClaim.add(restakeClaim));

        return true;

    }

    function restake(uint256 amount) public override returns (bool) {
        update();

        require(poolState == PoolState.Active, "InvestorV1Pool: pool not active");
        require(exited > 0, "InvestorV1Pool: no capacity for restake");

        restakeAmt[msg.sender] = restakeAmt[msg.sender].add(amount);
        restaked = restaked.add(amount);
        restakerList.push(msg.sender);

        IERC20(HSF).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(HSF, msg.sender, amount);

        return true;

    }

    function unstake(uint256 amount, address to) public override returns (bool) {
        update();

        require(poolState == PoolState.Active || poolState == PoolState.Dishonored, "InvestorV1Pool: pool not active");
        require(restakeAmt[msg.sender] >= amount, "InvestorV1Pool: not enough restake");
        require(to != address(0), "InvestorV1Pool: to address is zero");

        restakeAmt[msg.sender] = restakeAmt[msg.sender].sub(amount);
        restaked = restaked.sub(amount);
        if(restakeAmt[msg.sender]==0) {
            removeRestaker(msg.sender);
        }

        IERC20(HSF).safeTransfer(to, amount);

        emit Withdrawal(HSF, msg.sender, to, amount);

        return true;
    }


}