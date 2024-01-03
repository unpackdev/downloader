// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "./IERC20.sol";
import "./IxEXCV.sol";
import "./IxCAVO.sol";
import "./IExcavoFactory.sol";
import "./IExcavoCallee.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";

library PairLibrary {
    using SafeMath for uint;

    struct Data {
        address factory;
        address token0;
        address token1;
        address router;
        uint totalSupply;
        
        uint accumulatedUnclaimedLiquidity;
    
        uint112 reserve0;           // uses single storage slot, accessible via getReserves
        uint112 reserve1;           // uses single storage slot, accessible via getReserves
        uint32 blockTimestampLast;  // uses single storage slot, accessible via getReserves

        uint price0CumulativeLast;
        uint price1CumulativeLast;
    
        mapping(address => uint) kOf;
        mapping(address => uint) lastUnclaimedLiquidityOf;
        mapping(address => uint) virtualKOf;
        mapping(address => uint) balanceOf;

        uint totalK;
        address xEXCV;
        address xCAVO;
        address CAVO;
    }

    function initialize(Data storage self, address _token0, address _token1, address _router) external {
        require(msg.sender == self.factory, 'Excavo: FORBIDDEN'); // sufficient check
        self.token0 = _token0;
        self.token1 = _token1;
        self.router = _router;
    }       

    function setCAVO(Data storage self, address _CAVO, address _xCAVO) external {
        require(msg.sender == self.factory, 'Excavo: FORBIDDEN'); // sufficient check
        self.CAVO = _CAVO;
        self.xCAVO = _xCAVO;
        if (_CAVO != address(0)) {
            IxCAVO(_xCAVO).registerPairCreation();
        }
    }

    function setxEXCV(Data storage self, address _xEXCV) external {
        require(self.xEXCV == address(0) && msg.sender == IExcavoFactory(self.factory).feeToSetter(), "Excavo: FORBIDDEN"); 
        self.xEXCV = _xEXCV;
        IxEXCV(_xEXCV).addPair(self.token0, self.token1);
    }

    function claimLiquidity(Data storage self, address account, uint256 amount) external returns (uint claimAmount) {
        require(msg.sender == self.xEXCV || msg.sender == self.xCAVO, "Excavo: FORBIDDEN");
        _accumulateLiquidityGrowth(
            self,
            IERC20(self.token0).balanceOf(address(this)), 
            IERC20(self.token1).balanceOf(address(this)), 
            self.balanceOf[account], 
            self.totalSupply, 
            account
        );
        claimAmount = self.lastUnclaimedLiquidityOf[account].sub(amount); 
        self.lastUnclaimedLiquidityOf[account] = claimAmount;
    }

    function claimAllLiquidity(Data storage self, address account) public returns (uint claimAmount) {
        require(msg.sender == self.xEXCV || msg.sender == self.xCAVO, "Excavo: FORBIDDEN");
        self.virtualKOf[address(this)] = _accumulateTotalLiquidityGrowth(self);
        _accumulateLiquidityGrowth(
            self,
            IERC20(self.token0).balanceOf(address(this)), 
            IERC20(self.token1).balanceOf(address(this)), 
            self.balanceOf[account], 
            self.totalSupply, 
            account
        );
        claimAmount = self.lastUnclaimedLiquidityOf[account];
        self.lastUnclaimedLiquidityOf[account] = 0;
    }

    function accumulatedLiquidityGrowth(Data storage self) external view returns (uint) {
        uint lastTotalK = self.virtualKOf[address(this)].add(self.totalK);
        uint newTotalK = _calculateNewK(
            self.reserve0, 
            self.reserve1, 
            self.totalSupply,
            self.totalSupply,
            lastTotalK
        );
        if (newTotalK > lastTotalK) {
            return self.accumulatedUnclaimedLiquidity + (newTotalK - lastTotalK); // overflow desired
        }
        return self.accumulatedUnclaimedLiquidity;
    }

    function unclaimedLiquidityOf(Data storage self, address account) external view returns (uint) {
        uint newK = _calculateNewK(
            IERC20(self.token0).balanceOf(address(this)), 
            IERC20(self.token1).balanceOf(address(this)), 
            self.balanceOf[account],
            self.totalSupply,
            self.virtualKOf[account]
        );
        if (newK > self.virtualKOf[account]) {
            uint liquidityGrowth = newK - self.virtualKOf[account]; // cannot overflow
            return self.lastUnclaimedLiquidityOf[account].add(liquidityGrowth);
        }
        return self.lastUnclaimedLiquidityOf[account];
    }

    function compoundLiquidity(Data storage self) external returns (uint) {
        self.virtualKOf[address(this)] = _accumulateTotalLiquidityGrowth(self);
        return _accumulateLiquidityGrowth(
            self,
            IERC20(self.token0).balanceOf(address(this)), 
            IERC20(self.token1).balanceOf(address(this)), 
            self.balanceOf[msg.sender], 
            self.totalSupply, 
            msg.sender
        );
    }

    function mint(Data storage self, address to, uint value, uint k) external {
        _accumulateTotalLiquidityGrowth(self);
        _accumulateLiquidityGrowth(
            self,
            IERC20(self.token0).balanceOf(address(this)), 
            IERC20(self.token1).balanceOf(address(this)), 
            self.balanceOf[to], 
            self.totalSupply, 
            to
        );
        uint newKTo = self.kOf[to].add(k);
        _updateK(self, to, newKTo, newKTo);
        self.totalK = self.totalK.add(k);
        self.virtualKOf[address(this)] = 0;
       
        uint newBalance = self.balanceOf[to].add(value);
        self.totalSupply = self.totalSupply.add(value);
        self.balanceOf[to] = newBalance;
    }

    function burn(Data storage self, address from, uint value) external {
        uint newBalance = self.balanceOf[from].sub(value);
        _accumulateTotalLiquidityGrowth(self);
        _accumulateLiquidityGrowth(
            self,
            IERC20(self.token0).balanceOf(address(this)), 
            IERC20(self.token1).balanceOf(address(this)), 
            self.balanceOf[from], 
            self.totalSupply, 
            from
        );
        uint newK = self.kOf[from].mul(newBalance).div(self.balanceOf[from]);
        _updateK(self, from, newK, newK);
        
        self.totalK = self.totalK.sub(self.kOf[from].sub(newK));
        self.virtualKOf[address(this)] = 0;
        self.balanceOf[from] = newBalance;
        self.totalSupply = self.totalSupply.sub(value);
    }

    function transfer(Data storage self, address from, address to, uint value) external {
        uint newBalanceFrom = self.balanceOf[from].sub(value);
        uint newBalanceTo = self.balanceOf[to].add(value);

        uint balance0 = IERC20(self.token0).balanceOf(address(this));
        uint balance1 = IERC20(self.token1).balanceOf(address(this));
        uint _totalSupply = self.totalSupply;
        _accumulateLiquidityGrowth(
            self,
            balance0, 
            balance1, 
            self.balanceOf[from], 
            _totalSupply, 
            from
        );
        _accumulateLiquidityGrowth(
            self,
            balance0, 
            balance1, 
            self.balanceOf[to], 
            _totalSupply, 
            to
        );

        uint newKFrom = self.kOf[from].mul(newBalanceFrom).div(self.balanceOf[from]);
        uint newKTo = self.kOf[to].add(self.kOf[from].sub(newKFrom));
        uint virtualKTo = _calculateNewK(
            balance0, 
            balance1, 
            newBalanceTo,
            _totalSupply,
            newKTo
        );
        uint virtualKFrom = _calculateNewK(
            balance0, 
            balance1, 
            newBalanceFrom,
            _totalSupply,
            newKFrom
        );
        _updateK(self, to, newKTo, virtualKTo);
        _updateK(self, from, newKFrom, virtualKFrom);

        self.balanceOf[from] = newBalanceFrom;
        self.balanceOf[to] = newBalanceTo;
    }

    function _calculateNewK(
        uint balance0, 
        uint balance1,
        uint liquidity, 
        uint totalSupply,
        uint virtualK
    ) private pure returns (uint k) {
        if (totalSupply == 0) {
            return virtualK;
        } 
        uint amount0 = liquidity.mul(balance0) / totalSupply;
        uint amount1 = liquidity.mul(balance1) / totalSupply;
        if (amount0 == 0 || amount1 == 0) {
            return virtualK;
        }
        k = Math.sqrt(amount0.mul(amount1));
    }   

    function _accumulateTotalLiquidityGrowth(Data storage self) private returns (uint virtualTotalK) {
        virtualTotalK = self.virtualKOf[address(this)];
        uint lastTotalK = virtualTotalK.add(self.totalK);
        uint newTotalK = _calculateNewK(
            self.reserve0, 
            self.reserve1, 
            self.totalSupply,
            self.totalSupply,
            lastTotalK
        );
        if (newTotalK > lastTotalK) {
            virtualTotalK = newTotalK.sub(self.totalK);
            self.accumulatedUnclaimedLiquidity = self.accumulatedUnclaimedLiquidity + (newTotalK - lastTotalK); // overflow desired
        }
    }

    function _accumulateLiquidityGrowth(
        Data storage self, 
        uint balance0, 
        uint balance1,
        uint liquidity, 
        uint totalSupply,
        address account
    ) private returns (uint liquidityGrowth) {
        uint virtualK = self.virtualKOf[account];
        if (account == address(this)) {
            return virtualK;
        }
        uint newK = _calculateNewK(
            balance0, 
            balance1, 
            liquidity,
            totalSupply,
            virtualK
        );
        if (newK > virtualK) {
            liquidityGrowth = newK - virtualK; // cannot overflow
            self.virtualKOf[account] = newK;
            self.lastUnclaimedLiquidityOf[account] = self.lastUnclaimedLiquidityOf[account].add(liquidityGrowth);
        }
    }

    function _updateK(Data storage self, address account, uint k, uint virtualK) private {
        self.kOf[account] = k;
        self.virtualKOf[account] = virtualK;
    }
}