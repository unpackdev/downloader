// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface iSpot{
    function claim() external;
}

contract SpoTFarm is Ownable, ReentrancyGuard {

    IERC20 private spoT;
    IERC20 private milQ;
    IERC20 private gspoT;
    iSpot public ISPOT;
    IUniswapV2Router02 private uniswapRouter;

    constructor(address _spotAddress, address _milQAddress, address _gspoTAddress, address _oddysParlour, address _uniswapRouterAddress) {    
        spoT = IERC20(_spotAddress);
        ISPOT = iSpot(_spotAddress);
        milQ = IERC20(_milQAddress);
        gspoT = IERC20(_gspoTAddress);
        oddysParlour = _oddysParlour;
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    }   
   
    bool private staQingPaused = true;

    address public oddysParlour;

    address private swapSpot = 0x53020F42f6Da51B50cf6E23e45266ef223122376;
   
    uint256 public daisys = 0; 

    uint256 public bessies = 0;

    uint256 public spoTers = 0;

    uint256 public milQers = 0;

    uint256 public vitaliksMilkShipped = 0;

    uint256 public vitaliksMilkQompounded = 0;

    uint256 private daisysToOddysParlour = 15;

    uint256 private bessiesToOddysParlour = 15;

    uint256 public daisysMilkProduced = 0;

    uint256 public bessiesMilkProduced = 0;

    uint256 public daisysRentalTime;

    uint256 public bessiesRentalTime;

    uint256 public roundUpDaisysTime;

    uint256 public roundUpBessiesTime;

    uint256 public totalVitaliksMilkShipments = 0;

    uint256 public MilqShipments = 0;

    uint256 private minSpoT = 10000000000000000000;

    uint256 private minMilQ = 1000000000000000000;

    uint256 public totalMilQClaimed = 0;

    uint256 private highClaimThreshold = 5000000000000000000;

    event highClaim(address User, uint256 Amount);

    function sethighClaimThreshold(uint256 weiAmount) public onlyOwner {
        highClaimThreshold = weiAmount;
    }

    uint256 private lowBalanceThreshold = 10000000000000000000;

    event lowBalance(uint256 time, uint256 balance);

    function setLowBalanceThreshold(uint256 weiAmount) public onlyOwner {
        lowBalanceThreshold = weiAmount;
    }

    event rewardChange(uint256 index ,uint256 newBessies, uint256 newDaisys);

    event Qompound(address user, uint256 _ethAmount, uint256 boughtAmount);

    event newStaQe(address user, uint256 spot, uint256 milq);

    struct SpoTerParlour {
        uint256 daisys;
        uint256 rentedDaisysSince;
        uint256 rentedDaisysTill;
        uint256 vitaliksMilkShipped;
        uint256 lastShippedVitaliksMilk;
        uint256 vitaliksMilkClaimable;
        uint256 QompoundedMilk;
        uint256 daisysOwnedSince;
        uint256 daisysOwnedTill;
        bool hasDaisys;
        bool ownsDaisys;
        bool owedMilk;
        uint256 shipmentsRecieved;
    }

    struct LpClaim {
        uint256 lastClaimed;
        uint256 totalClaimed;
    }

    struct MilQerParlour {
        uint256 bessies;
        uint256 rentedBessiesSince;
        uint256 rentedBessiesTill;
        uint256 milQClaimed;
        uint256 vitaliksMilkShipped;
        uint256 lastShippedVitaliksMilk;
        uint256 vitaliksMilkClaimable;
        uint256 bessiesOwnedSince;
        uint256 bessiesOwnedTill;
        bool hasBessies;
        bool ownsBessies;
        bool owedMilk;
        uint256 shipmentsRecieved;
    }

    struct MilQShipment {
        uint256 blockTimestamp;
        uint256 MilQShipped;
        uint256 totalspoTStaked;
        uint256 rewardPerspoT;
    }

    struct VitaliksMilkShipment {
        uint256 timestamp;
        uint256 daisysOutput;
        uint256 bessiesOutput;
    }

    mapping(address => LpClaim) public LpClaims;
    mapping(address => SpoTerParlour) public SpoTerParlours;
    mapping(address => MilQerParlour) public MilQerParlours;
    mapping(uint256 => MilQShipment) public MilQShipments;
    mapping(uint256 => VitaliksMilkShipment) public VitaliksMilkShipments;

    function rushOddyFee(uint256 _daisysToOddysParlour, uint256 _bessiesToOddysParlour) public onlyOwner{
        require(_daisysToOddysParlour + _bessiesToOddysParlour <= 60);        
        daisysToOddysParlour = _daisysToOddysParlour;
        bessiesToOddysParlour = _bessiesToOddysParlour;
    }

    function zeroFees() public onlyOwner {
        daisysToOddysParlour = 0;
        bessiesToOddysParlour = 0;
    }

    function setOddysParlour(address _oddysParlour) public onlyOwner {
        oddysParlour = _oddysParlour;
    }

    function setGspoTAddress(IERC20 _gspoT) public onlyOwner {
        gspoT = _gspoT;
    }   

    function prepShipment(uint256 _daisysOutput, uint256 _bessiesOutput) public onlyOwner {
        totalVitaliksMilkShipments ++;
        uint256 index = totalVitaliksMilkShipments;
        VitaliksMilkShipments[index] = VitaliksMilkShipment(block.timestamp, _daisysOutput, _bessiesOutput);
        emit rewardChange(index, _daisysOutput, _bessiesOutput);
    }

    function getprepShipment(uint256 index) public view returns (uint256, uint256, uint256) {
        require(index < totalVitaliksMilkShipments);
        VitaliksMilkShipment memory shipment = VitaliksMilkShipments[index];
        return (shipment.timestamp, shipment.daisysOutput, shipment.bessiesOutput);
    }

    function pauseStaQing(bool _state) public onlyOwner {
        staQingPaused = _state;
    }

    function removeVitaliksMilk(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount);
        payable(oddysParlour).transfer(amount);
    }

    function withdrawERC20(address _ERC20, uint256 _Amt) external onlyOwner {
        IERC20(_ERC20).transfer(msg.sender, _Amt);
    }

    function changeDaisysRentalTime(uint256 _daisysRentalTime) external onlyOwner {
        daisysRentalTime = _daisysRentalTime;
    }

    function changeBessiesRentalTime(uint256 _bessiesRentalTime) external onlyOwner {
        bessiesRentalTime = _bessiesRentalTime;
    }

    function changeRoundUpDaisysTime(uint256 _roundUpDaisysTime) external onlyOwner {
        roundUpDaisysTime = _roundUpDaisysTime;
    }

    function changeRoundUpBessiesTime(uint256 _roundUpBessiesTime) external onlyOwner {
        roundUpBessiesTime = _roundUpBessiesTime;
    }

    function changeMinSpoT(uint256 _minSpoT) external onlyOwner {
        minSpoT = _minSpoT;
    }

    function changeMinMilQ(uint256 _minMilQ) external onlyOwner {
        minMilQ = _minMilQ;
    }

    function staQe(uint256 _amountSpoT, uint256 _amountMilQ, uint256 _token) external {
        require(!staQingPaused);
        require(_token == 0 || _token == 1);

        if (SpoTerParlours[msg.sender].hasDaisys == true || MilQerParlours[msg.sender].hasBessies == true ) {
            howMuchMilkV3();
        }

        if (_token == 0) {
            require(_amountSpoT >= minSpoT);
            
            if (SpoTerParlours[msg.sender].hasDaisys == true) {
                uint256 milQToClaim = checkEstMilQRewards(msg.sender);
                
                if (milQToClaim > 0) {
                    shipSpoTersMilQ();
                }
                
                getMoreDaisys(_amountSpoT);
            }        

            if (SpoTerParlours[msg.sender].hasDaisys == false){
                firstStaQeSpoT(_amountSpoT);
            }      
        }

        if (_token == 1) { 
            require(_amountMilQ >= minMilQ);
            if (MilQerParlours[msg.sender].hasBessies == true){
                getMoreBessies(_amountMilQ);
            } 

            if (MilQerParlours[msg.sender].hasBessies == false){
                firstStaQeMilQ(_amountMilQ);
            }
        }
        emit newStaQe(msg.sender,_amountSpoT, _amountMilQ);
    }

    function getMoreDaisys(uint256 amountSpoT) internal {
        
        spoT.approve(address(this), amountSpoT);
        spoT.transferFrom(msg.sender, address(this), amountSpoT);
        
        if (SpoTerParlours[msg.sender].ownsDaisys == true) {
            gspoT.transfer(msg.sender, amountSpoT);
        } 

        SpoTerParlours[msg.sender].daisys += amountSpoT;
        daisys += amountSpoT; 
    }

    function getMoreBessies(uint256 amountMilQ) internal {
        milQ.approve(address(this), amountMilQ);
        milQ.transferFrom(msg.sender, address(this), amountMilQ);
        MilQerParlours[msg.sender].bessies += amountMilQ;
        bessies += amountMilQ;    
    }
   
    function firstStaQeSpoT(uint256 amountSpoT) internal {
        spoT.approve(address(this), amountSpoT);
        spoT.transferFrom(msg.sender, address(this), amountSpoT);
        SpoTerParlours[msg.sender].daisys += amountSpoT;
        SpoTerParlours[msg.sender].rentedDaisysSince = block.timestamp;
        SpoTerParlours[msg.sender].rentedDaisysTill = block.timestamp + daisysRentalTime; 
        SpoTerParlours[msg.sender].daisysOwnedSince = 0;
        SpoTerParlours[msg.sender].daisysOwnedTill = 32503680000;
        SpoTerParlours[msg.sender].hasDaisys = true;
        SpoTerParlours[msg.sender].ownsDaisys = false;
        SpoTerParlours[msg.sender].vitaliksMilkShipped = 0;
        SpoTerParlours[msg.sender].QompoundedMilk = 0;
        SpoTerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
        SpoTerParlours[msg.sender].shipmentsRecieved = totalVitaliksMilkShipments;
        SpoTerParlours[msg.sender].vitaliksMilkClaimable = 0;
        SpoTerParlours[msg.sender].owedMilk = true;
        LpClaims[msg.sender].lastClaimed = totalMilQClaimed;
        LpClaims[msg.sender].totalClaimed = 0;
        daisys += amountSpoT;
        spoTers ++;
    }

    function firstStaQeMilQ(uint256 amountMilQ) internal {
        milQ.approve(address(this), amountMilQ);
        milQ.transferFrom(msg.sender, address(this), amountMilQ);
        MilQerParlours[msg.sender].bessies += amountMilQ;
        MilQerParlours[msg.sender].rentedBessiesSince = block.timestamp;
        MilQerParlours[msg.sender].rentedBessiesTill = block.timestamp + bessiesRentalTime;
        MilQerParlours[msg.sender].hasBessies = true;
        MilQerParlours[msg.sender].bessiesOwnedSince = 0;
        MilQerParlours[msg.sender].bessiesOwnedTill = 32503680000;
        MilQerParlours[msg.sender].ownsBessies = false;
        MilQerParlours[msg.sender].vitaliksMilkShipped = 0;
        MilQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
        MilQerParlours[msg.sender].shipmentsRecieved = totalVitaliksMilkShipments;
        MilQerParlours[msg.sender].milQClaimed = 0;
        MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        MilQerParlours[msg.sender].owedMilk = true;
        bessies += amountMilQ;
        milQers ++;
    }

    function ownCows(uint256 _cow) external {
        require(!staQingPaused);
        require( _cow == 0 || _cow == 1);

        if (_cow == 0) {
            require(SpoTerParlours[msg.sender].ownsDaisys == false);
            require(SpoTerParlours[msg.sender].hasDaisys == true);
            require(SpoTerParlours[msg.sender].rentedDaisysTill < block.timestamp);
            require(gspoT.transfer(msg.sender, SpoTerParlours[msg.sender].daisys));
            SpoTerParlours[msg.sender].ownsDaisys = true;
            SpoTerParlours[msg.sender].daisysOwnedSince = SpoTerParlours[msg.sender].rentedDaisysTill;
            SpoTerParlours[msg.sender].owedMilk = true;
        }    

        if (_cow == 1) {
            require(MilQerParlours[msg.sender].ownsBessies == false);
            require(MilQerParlours[msg.sender].hasBessies == true);
            require(MilQerParlours[msg.sender].rentedBessiesTill < block.timestamp);
            MilQerParlours[msg.sender].ownsBessies = true;
            MilQerParlours[msg.sender].bessiesOwnedSince = MilQerParlours[msg.sender].rentedBessiesTill;
            MilQerParlours[msg.sender].owedMilk = true;
        }
    }

    function roundUpCows(uint256 _cow) external {
        require(!staQingPaused);
        require(_cow == 0 && SpoTerParlours[msg.sender].ownsDaisys == true || _cow == 1 && MilQerParlours[msg.sender].ownsBessies == true);

            if (_cow == 0) {
                uint256 newTimestamp = block.timestamp + roundUpDaisysTime; //make this time variable    
                SpoTerParlours[msg.sender].daisysOwnedTill = newTimestamp;
            }

            if (_cow == 1) {
                uint256 newTimestamp = block.timestamp + roundUpBessiesTime; 
                MilQerParlours[msg.sender].bessiesOwnedTill = newTimestamp;
            }
    }

    function unstaQe(uint256 _amtSpoT, uint256 _amtMilQ, uint256 _token) external { 
        require(!staQingPaused); 
        require(_token == 0 || _token == 1); 
        uint256 totalMilk = viewHowMuchMilk(msg.sender); 
 
        if (totalMilk > 0) {   
            shipMilk(); 
        } 
 
        if (_token == 0) { 
            require(_amtSpoT > 0); 
            require(SpoTerParlours[msg.sender].daisys >= _amtSpoT);
            require(SpoTerParlours[msg.sender].hasDaisys == true); 
            unstaQeSpoT(_amtSpoT); 
        } 
 
        if (_token == 1) { 
            require(_amtMilQ > 0); 
            require(MilQerParlours[msg.sender].bessies >= _amtMilQ);
            require(MilQerParlours[msg.sender].hasBessies == true); 
            unstaQeMilQ(_amtMilQ); 
        }     
    }

    function unstaQeSpoT(uint256 amtSpoT) internal {        
        if (SpoTerParlours[msg.sender].ownsDaisys == true) {
            gspoT.approve(address(this), amtSpoT);
            gspoT.transferFrom(msg.sender, address(this), amtSpoT);
        }

        uint256 amtToClaim = checkEstMilQRewards(msg.sender);
        
        if (amtToClaim > 0) {
            shipSpoTersMilQ();
        }

        uint256 transferSpoT;
        uint256 dToOddysParlour;

            if (SpoTerParlours[msg.sender].daisysOwnedTill < block.timestamp && SpoTerParlours[msg.sender].ownsDaisys == true){
                spoT.transfer(msg.sender, amtSpoT);
                SpoTerParlours[msg.sender].daisys -= amtSpoT; 
            }

            if (SpoTerParlours[msg.sender].rentedDaisysTill < block.timestamp && SpoTerParlours[msg.sender].ownsDaisys == false){
                spoT.transfer(msg.sender, amtSpoT);
                SpoTerParlours[msg.sender].daisys -= amtSpoT; 
            }

            if (SpoTerParlours[msg.sender].daisysOwnedTill > block.timestamp && SpoTerParlours[msg.sender].ownsDaisys == true){
                dToOddysParlour = (amtSpoT * daisysToOddysParlour / 100);
                transferSpoT = (amtSpoT - dToOddysParlour);
                spoT.transfer(msg.sender, transferSpoT);
                spoT.transfer(oddysParlour, dToOddysParlour);
                SpoTerParlours[msg.sender].daisys -= amtSpoT;          
            }

            if (SpoTerParlours[msg.sender].rentedDaisysTill > block.timestamp && SpoTerParlours[msg.sender].ownsDaisys == false){
                dToOddysParlour = (amtSpoT * daisysToOddysParlour / 100);
                transferSpoT = (amtSpoT - dToOddysParlour);
                spoT.transfer(msg.sender, transferSpoT);
                spoT.transfer(oddysParlour, dToOddysParlour);
                SpoTerParlours[msg.sender].daisys -= amtSpoT;  
            }   

            if (SpoTerParlours[msg.sender].daisys < minSpoT) {
                SpoTerParlours[msg.sender].daisys = 0;
                SpoTerParlours[msg.sender].rentedDaisysSince = 0;
                SpoTerParlours[msg.sender].rentedDaisysTill = 0;
                SpoTerParlours[msg.sender].vitaliksMilkShipped = 0;
                SpoTerParlours[msg.sender].lastShippedVitaliksMilk = 0;
                SpoTerParlours[msg.sender].vitaliksMilkClaimable = 0;
                SpoTerParlours[msg.sender].QompoundedMilk = 0;
                SpoTerParlours[msg.sender].daisysOwnedSince = 0;
                SpoTerParlours[msg.sender].daisysOwnedTill = 0;
                SpoTerParlours[msg.sender].hasDaisys = false;
                SpoTerParlours[msg.sender].ownsDaisys = false;
                SpoTerParlours[msg.sender].owedMilk = false;
                SpoTerParlours[msg.sender].shipmentsRecieved = 0;
                spoTers --;
            }       
    }

    function unstaQeMilQ(uint256 amtMilQ) internal {
        uint256 transferMilQ;
        uint256 bToOddysParlour;

            if (MilQerParlours[msg.sender].bessiesOwnedTill <= block.timestamp && MilQerParlours[msg.sender].ownsBessies == true){
                transferMilQ = amtMilQ;
                milQ.transfer(msg.sender, transferMilQ);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].rentedBessiesTill <= block.timestamp && MilQerParlours[msg.sender].ownsBessies == false){
                transferMilQ = amtMilQ;
                milQ.transfer(msg.sender, transferMilQ);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].bessiesOwnedTill > block.timestamp && MilQerParlours[msg.sender].ownsBessies == true){
                bToOddysParlour = (amtMilQ * bessiesToOddysParlour / 100);
                transferMilQ = (amtMilQ - bToOddysParlour);
                milQ.transfer(msg.sender, transferMilQ);
                milQ.transfer(oddysParlour, bToOddysParlour);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].rentedBessiesTill > block.timestamp && MilQerParlours[msg.sender].ownsBessies == false){
                bToOddysParlour = (amtMilQ * bessiesToOddysParlour / 100);
                transferMilQ = (amtMilQ - bToOddysParlour);
                milQ.transfer(msg.sender, transferMilQ);
                milQ.transfer(oddysParlour, bToOddysParlour);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].bessies < minMilQ) {
                MilQerParlours[msg.sender].bessies = 0;
                MilQerParlours[msg.sender].rentedBessiesSince = 0;
                MilQerParlours[msg.sender].rentedBessiesTill = 0;
                MilQerParlours[msg.sender].milQClaimed = 0;
                MilQerParlours[msg.sender].vitaliksMilkShipped = 0;
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = 0;
                MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
                MilQerParlours[msg.sender].bessiesOwnedSince = 0;
                MilQerParlours[msg.sender].bessiesOwnedTill = 0;
                MilQerParlours[msg.sender].hasBessies = false;
                MilQerParlours[msg.sender].ownsBessies = false;
                MilQerParlours[msg.sender].owedMilk = false;
                MilQerParlours[msg.sender].shipmentsRecieved = 0;
                milQers --;
            }
    }

    function howMuchMilkV3() internal {
        uint256 milkFromDaisys = 0;
        uint256 milkFromBessies = 0;
        if (SpoTerParlours[msg.sender].ownsDaisys == true && SpoTerParlours[msg.sender].daisysOwnedTill > block.timestamp) {
            if (SpoTerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = SpoTerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - SpoTerParlours[msg.sender].lastShippedVitaliksMilk);
                    SpoTerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    SpoTerParlours[msg.sender].shipmentsRecieved ++;
                }
            }
            
            if (SpoTerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - SpoTerParlours[msg.sender].lastShippedVitaliksMilk);
                SpoTerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }

        if (SpoTerParlours[msg.sender].ownsDaisys == false && SpoTerParlours[msg.sender].hasDaisys == true && SpoTerParlours[msg.sender].rentedDaisysTill > block.timestamp) {
            if (SpoTerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = SpoTerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - SpoTerParlours[msg.sender].lastShippedVitaliksMilk);
                    SpoTerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    SpoTerParlours[msg.sender].shipmentsRecieved ++;
                }
            }
            
            if (SpoTerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - SpoTerParlours[msg.sender].lastShippedVitaliksMilk);
                SpoTerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }

        if (SpoTerParlours[msg.sender].ownsDaisys == true && SpoTerParlours[msg.sender].daisysOwnedTill <= block.timestamp && SpoTerParlours[msg.sender].owedMilk == true) {
            if(SpoTerParlours[msg.sender].shipmentsRecieved < totalVitaliksMilkShipments) { 
                for (uint256 i = SpoTerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {

                    if (SpoTerParlours[msg.sender].daisysOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - SpoTerParlours[msg.sender].lastShippedVitaliksMilk);
                        SpoTerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        SpoTerParlours[msg.sender].shipmentsRecieved ++;
                    }
            
                    if (SpoTerParlours[msg.sender].daisysOwnedTill <= VitaliksMilkShipments[i+1].timestamp) {
                        uint256 time = SpoTerParlours[msg.sender].daisysOwnedTill - SpoTerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        SpoTerParlours[msg.sender].lastShippedVitaliksMilk = SpoTerParlours[msg.sender].daisysOwnedTill;
                        SpoTerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }
            }

            if (SpoTerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (SpoTerParlours[msg.sender].daisysOwnedTill - SpoTerParlours[msg.sender].lastShippedVitaliksMilk);
                SpoTerParlours[msg.sender].lastShippedVitaliksMilk = SpoTerParlours[msg.sender].daisysOwnedTill;
                SpoTerParlours[msg.sender].owedMilk = false;
            } 
        }

        if (SpoTerParlours[msg.sender].ownsDaisys == false && SpoTerParlours[msg.sender].hasDaisys == true && SpoTerParlours[msg.sender].rentedDaisysTill <= block.timestamp && SpoTerParlours[msg.sender].owedMilk == true) {
            if(SpoTerParlours[msg.sender].shipmentsRecieved < totalVitaliksMilkShipments){
                for (uint256 i = SpoTerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    if (SpoTerParlours[msg.sender].rentedDaisysTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - SpoTerParlours[msg.sender].lastShippedVitaliksMilk);
                        SpoTerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        SpoTerParlours[msg.sender].shipmentsRecieved ++;
                    }
         
                    if (SpoTerParlours[msg.sender].rentedDaisysTill <= VitaliksMilkShipments[i+1].timestamp && SpoTerParlours[msg.sender].owedMilk == true){
                        uint256 time = SpoTerParlours[msg.sender].rentedDaisysTill - SpoTerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        SpoTerParlours[msg.sender].lastShippedVitaliksMilk = SpoTerParlours[msg.sender].rentedDaisysTill;
                        SpoTerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }  
            }

            if (SpoTerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (SpoTerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (SpoTerParlours[msg.sender].rentedDaisysTill - SpoTerParlours[msg.sender].lastShippedVitaliksMilk);
                SpoTerParlours[msg.sender].lastShippedVitaliksMilk = SpoTerParlours[msg.sender].rentedDaisysTill;
                SpoTerParlours[msg.sender].owedMilk = false;
            }       
        }

        if (MilQerParlours[msg.sender].ownsBessies == true && MilQerParlours[msg.sender].bessiesOwnedTill > block.timestamp) {
            if (MilQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                    MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    MilQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments) {
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }

        if (MilQerParlours[msg.sender].ownsBessies == false && MilQerParlours[msg.sender].hasBessies == true && MilQerParlours[msg.sender].rentedBessiesTill > block.timestamp && MilQerParlours[msg.sender].owedMilk == true) {
            if (MilQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                    MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    MilQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }
        
        if (MilQerParlours[msg.sender].ownsBessies == true && MilQerParlours[msg.sender].bessiesOwnedTill <= block.timestamp && MilQerParlours[msg.sender].owedMilk == true) { 
            if (MilQerParlours[msg.sender].shipmentsRecieved < totalVitaliksMilkShipments) {
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[msg.sender].bessiesOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        MilQerParlours[msg.sender].shipmentsRecieved ++;
                    }
            
                    if (MilQerParlours[msg.sender].bessiesOwnedTill <= VitaliksMilkShipments[i+1].timestamp){
                        uint256 time = MilQerParlours[msg.sender].bessiesOwnedTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].bessiesOwnedTill;
                        MilQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[msg.sender].bessiesOwnedTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].bessiesOwnedTill;
                MilQerParlours[msg.sender].owedMilk = false;
            }    
        }
  
        if (MilQerParlours[msg.sender].ownsBessies == false && MilQerParlours[msg.sender].hasBessies == true && MilQerParlours[msg.sender].rentedBessiesTill <= block.timestamp  && MilQerParlours[msg.sender].owedMilk == true) {
            if(MilQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments){
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[msg.sender].rentedBessiesTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        MilQerParlours[msg.sender].shipmentsRecieved ++;
                    }
        
                    if (MilQerParlours[msg.sender].rentedBessiesTill <= VitaliksMilkShipments[i+1].timestamp){
                        uint256 time = MilQerParlours[msg.sender].rentedBessiesTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].rentedBessiesTill;
                        MilQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }  
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[msg.sender].rentedBessiesTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].rentedBessiesTill;
                MilQerParlours[msg.sender].owedMilk = false;
            }       
        }

        SpoTerParlours[msg.sender].vitaliksMilkClaimable += milkFromDaisys;
        MilQerParlours[msg.sender].vitaliksMilkClaimable += milkFromBessies;
        daisysMilkProduced += milkFromDaisys;
        bessiesMilkProduced += milkFromBessies;      
    }

    function viewHowMuchMilk(address user) public view returns (uint256 Total) {
        uint256 daisysShipped = SpoTerParlours[user].shipmentsRecieved;
        uint256 daisysTimeShipped = SpoTerParlours[user].lastShippedVitaliksMilk;
        uint256 bessiesShipped = MilQerParlours[user].shipmentsRecieved;
        uint256 bessiesTimeShipped = MilQerParlours[user].lastShippedVitaliksMilk;
        uint256 milkFromDaisys = 0;
        uint256 milkFromBessies = 0;

        if (SpoTerParlours[user].ownsDaisys == true && SpoTerParlours[user].daisysOwnedTill > block.timestamp) {
            if (daisysShipped != totalVitaliksMilkShipments) {
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                    daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    daisysShipped ++;
                }
            }
            
            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - daisysTimeShipped);
            }
        }

        if (SpoTerParlours[user].ownsDaisys == false && SpoTerParlours[user].hasDaisys == true && SpoTerParlours[user].rentedDaisysTill > block.timestamp) {
            if (daisysShipped != totalVitaliksMilkShipments) {
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                    daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    daisysShipped ++;
                }
            }
            
            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - daisysTimeShipped);
            }
        }

        if (SpoTerParlours[user].ownsDaisys == true && SpoTerParlours[user].daisysOwnedTill <= block.timestamp && SpoTerParlours[user].owedMilk == true) {
            if(daisysShipped < totalVitaliksMilkShipments) { 
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {

                    if (SpoTerParlours[user].daisysOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                        daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        daisysShipped ++;
                    }
            
                    if (SpoTerParlours[user].daisysOwnedTill <= VitaliksMilkShipments[i+1].timestamp) {
                        uint256 time = SpoTerParlours[user].daisysOwnedTill - daisysTimeShipped;
                        milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        break;   
                    }   
                }
            }

            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (SpoTerParlours[user].daisysOwnedTill - daisysTimeShipped);
            } 
        }

        if (SpoTerParlours[user].ownsDaisys == false && SpoTerParlours[user].hasDaisys == true && SpoTerParlours[user].rentedDaisysTill <= block.timestamp && SpoTerParlours[user].owedMilk == true) {
            if(daisysShipped < totalVitaliksMilkShipments){
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {
                    if (SpoTerParlours[user].rentedDaisysTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                        daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        daisysShipped ++;
                    }
         
                    if (SpoTerParlours[user].rentedDaisysTill <= VitaliksMilkShipments[i+1].timestamp && SpoTerParlours[user].owedMilk == true){
                        uint256 time = SpoTerParlours[user].rentedDaisysTill - daisysTimeShipped;
                        milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        break;   
                    }   
                }  
            }

            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (SpoTerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (SpoTerParlours[user].rentedDaisysTill - daisysTimeShipped);
            }       
        }

        if (MilQerParlours[user].ownsBessies == true && MilQerParlours[user].bessiesOwnedTill > block.timestamp) {
            if (bessiesShipped != totalVitaliksMilkShipments) {
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                    bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    bessiesShipped ++;
                }
            }

            if (bessiesShipped == totalVitaliksMilkShipments) {
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - bessiesTimeShipped);
            }
        }

        if (MilQerParlours[user].ownsBessies == false && MilQerParlours[user].hasBessies == true && MilQerParlours[user].rentedBessiesTill > block.timestamp && MilQerParlours[user].owedMilk == true) {
            if (bessiesShipped != totalVitaliksMilkShipments) {
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                    bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    bessiesShipped ++;
                }
            }

            if (bessiesShipped == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - bessiesTimeShipped);
            }

        }

        if (MilQerParlours[user].ownsBessies == true && MilQerParlours[user].bessiesOwnedTill <= block.timestamp) { 
            if (bessiesShipped != totalVitaliksMilkShipments) {
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[user].bessiesOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                        bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        bessiesShipped ++;
                    }
            
                    if (MilQerParlours[user].bessiesOwnedTill <= VitaliksMilkShipments[i+1].timestamp && MilQerParlours[user].owedMilk == true){
                        uint256 time = MilQerParlours[user].bessiesOwnedTill - bessiesTimeShipped;
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        break;   
                    }   
                }
            }

            if (bessiesShipped == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[user].bessiesOwnedTill - bessiesTimeShipped);
            }    
        }

        if (MilQerParlours[user].ownsBessies == false && MilQerParlours[user].hasBessies == true && MilQerParlours[user].rentedBessiesTill <= block.timestamp) {
            if(bessiesShipped != totalVitaliksMilkShipments){
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[user].rentedBessiesTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                        bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        bessiesShipped ++;
                    }
        
                    if (MilQerParlours[user].rentedBessiesTill <= VitaliksMilkShipments[i+1].timestamp && MilQerParlours[user].owedMilk == true){
                        uint256 time = MilQerParlours[user].rentedBessiesTill - bessiesTimeShipped;
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        break;   
                    }   
                }  
            }

            if (bessiesShipped == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[user].rentedBessiesTill - bessiesTimeShipped);
            }       
        }

        Total = milkFromDaisys + milkFromBessies; 
        return (Total);       
    }

    function QompoundSpoT(uint256 slippage) external {  
        if (SpoTerParlours[msg.sender].hasDaisys == true){
            shipSpoTersMilQ();
        }

        howMuchMilkV3();  
  
        uint256 spotAmt = SpoTerParlours[msg.sender].vitaliksMilkClaimable; 
        uint256 milqAmt = MilQerParlours[msg.sender].vitaliksMilkClaimable; 
        uint256 _ethAmount = spotAmt + milqAmt; 
  
        address[] memory path = new address[](2);  
        path[0] = uniswapRouter.WETH();  
        path[1] = swapSpot;  
  
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(_ethAmount, path);  
        uint256 minSpoTAmount = amountsOut[1];   
  
      
        uint256 beforeBalance = IERC20(spoT).balanceOf(address(this));  
        uint256 amountSlip = (minSpoTAmount * slippage) / 100;  
        uint256 amountAfterSlip = minSpoTAmount - amountSlip;  
  
      
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _ethAmount}(  
            amountAfterSlip,  
            path,  
            address(this),  
            block.timestamp  
        );  
  
        uint256 afterBalance = IERC20(spoT).balanceOf(address(this));  
  
        uint256 boughtAmount = afterBalance - beforeBalance;

        if (SpoTerParlours[msg.sender].ownsDaisys == true) {
            gspoT.transfer(msg.sender, boughtAmount);
        }

        if (SpoTerParlours[msg.sender].hasDaisys == true) { 
            SpoTerParlours[msg.sender].daisys += boughtAmount;  
            SpoTerParlours[msg.sender].QompoundedMilk += _ethAmount;  
            SpoTerParlours[msg.sender].vitaliksMilkClaimable = 0; 
            MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        }

        if (SpoTerParlours[msg.sender].hasDaisys == false) {
            SpoTerParlours[msg.sender].daisys += boughtAmount;
            SpoTerParlours[msg.sender].rentedDaisysSince = block.timestamp;
            SpoTerParlours[msg.sender].rentedDaisysTill = block.timestamp + daisysRentalTime; 
            SpoTerParlours[msg.sender].daisysOwnedSince = 0;
            SpoTerParlours[msg.sender].daisysOwnedTill = 32503680000;
            SpoTerParlours[msg.sender].hasDaisys = true;
            SpoTerParlours[msg.sender].ownsDaisys = false;
            SpoTerParlours[msg.sender].vitaliksMilkShipped = 0;
            SpoTerParlours[msg.sender].QompoundedMilk = 0;
            SpoTerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            SpoTerParlours[msg.sender].shipmentsRecieved = totalVitaliksMilkShipments;
            SpoTerParlours[msg.sender].vitaliksMilkClaimable = 0;
            SpoTerParlours[msg.sender].owedMilk = true;
            LpClaims[msg.sender].lastClaimed = totalMilQClaimed;
            LpClaims[msg.sender].totalClaimed = 0;
            MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
            daisys += boughtAmount;
            spoTers ++;
        }

        daisys += boughtAmount;
        vitaliksMilkQompounded += _ethAmount;
        emit Qompound(msg.sender, _ethAmount, boughtAmount);
    }
        
    function shipMilk() public {   
          
        howMuchMilkV3();

        uint256 spot = SpoTerParlours[msg.sender].vitaliksMilkClaimable;
        uint256 lp = MilQerParlours[msg.sender].vitaliksMilkClaimable;
        uint256 amount = spot + lp;

        require(address(this).balance >= amount);

        payable(msg.sender).transfer(amount);

        SpoTerParlours[msg.sender].vitaliksMilkShipped += spot;
        MilQerParlours[msg.sender].vitaliksMilkShipped += lp;
        SpoTerParlours[msg.sender].vitaliksMilkClaimable = 0;
        MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        vitaliksMilkShipped += amount;

        if (amount > highClaimThreshold){
            emit highClaim(msg.sender,amount);
        }

        if(address(this).balance < lowBalanceThreshold){
            emit lowBalance(block.timestamp,address(this).balance);
        }    
    }

    function shipFarmMilQ() external onlyOwner {

        uint256 beforeBalance = IERC20(milQ).balanceOf(address(this)); 

        ISPOT.claim();

        uint256 afterBalance = IERC20(milQ).balanceOf(address(this));

        uint256 claimed = afterBalance - beforeBalance;

         uint256 PerSpoT = (claimed * 10**18) / daisys;

        uint256 index = MilqShipments;

        MilQShipments[index] = MilQShipment(block.timestamp, claimed, daisys,PerSpoT);

        MilqShipments++;

        totalMilQClaimed += claimed;
    }

    function shipSpoTersMilQ() public {  
        uint256 CurrrentDis = totalMilQClaimed - LpClaims[msg.sender].lastClaimed;  
        uint256 tokensStaked = SpoTerParlours[msg.sender].daisys;  
         uint256 divDaisys = daisys / 10**18; 
        uint256 percentOwned = ((tokensStaked * 100) / divDaisys); 
        uint256 userDistro = CurrrentDis * (percentOwned / 100); 
        uint256 userDistroAmount = userDistro / 10**18; 
        milQ.transfer(msg.sender, userDistroAmount); 
  
        MilQerParlours[msg.sender].milQClaimed += userDistroAmount;
        LpClaims[msg.sender].lastClaimed = totalMilQClaimed;  
        LpClaims[msg.sender].totalClaimed += userDistroAmount;  
    }  
  
    function checkEstMilQRewards(address user) public view returns (uint256){  
        uint256 CurrrentDis = totalMilQClaimed - LpClaims[user].lastClaimed;  
        uint256 tokensStaked = SpoTerParlours[user].daisys;  
        uint256 divDaisys = daisys / 10**18; 
        uint256 percentOwned = ((tokensStaked * 100) / divDaisys); 
        uint256 userDistro = CurrrentDis * (percentOwned / 100); 
        uint256 userDistroAmount = userDistro / 10**18; 
 
        return userDistroAmount;  
    }

    receive() external payable {}
}