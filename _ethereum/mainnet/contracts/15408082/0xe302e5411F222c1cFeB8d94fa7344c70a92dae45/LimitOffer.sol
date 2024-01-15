// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./IController.sol";
import "./Controller.sol";
import "./Ownable.sol";
import "./IEURB.sol";

contract LimitOffer is Ownable, ReentrancyGuard {
    using SafeERC20 for IEURB;

    address public controllerAddress;

    uint16 public constant royaltyDecimal = 4;

    struct Order {
        uint256 offerCollateralAmount;
        uint256 offerUAssetAmount;
        address uAssetAddress;
        address userAddress;
    }
    mapping(bytes => Order) public orders;     // id -> order
    mapping(bytes => uint256) public offerFee;

    uint256 public amountToClaim;
    

    event Offer(
        address indexed userAddress,
        address indexed uAssetAddress,
        bytes id,
        uint256 uAssetAmount,
        uint256 collateralAmount,
        uint256 timestamp
    );

    event WithDraw(
        address indexed userAddress,
        address indexed uAssetAddress,
        bytes id,
        uint256 uAssetAmount,
        uint256 collateralAmount,
        uint256 timestamp
    );

    event Buy(bytes[] ids);
    event Sell(bytes[] ids);

    constructor() {}
    
    modifier onlyAdmin() {
        require(IController(controllerAddress).admins(msg.sender) || msg.sender == owner(), "Only admin");
        _;
    }

    function setControllerAddress(address _controllerAddress) external onlyOwner {
        controllerAddress = _controllerAddress;
    }

    function offerBuy(address uAssetAddress, uint256 uAssetAmount, uint256 collateralAmount, bytes memory id) external nonReentrant {
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        {
            uint256 royaltyFee = IController(controllerAddress).royaltyFeeRatio();
            uint256 fee = collateralAmount * royaltyFee / (10 ** royaltyDecimal);
            
            IEURB(collateralAddress).safeTransferFrom(msg.sender, address(this), fee);
            IEURB(collateralAddress).safeTransferFrom(msg.sender, address(this), collateralAmount);
            offerFee[id] = fee - IEURB(collateralAddress).getTransactionFee(msg.sender, address(this), fee);
        }
        
        Order storage order = orders[id];
        require(order.offerCollateralAmount == 0, "Still being offered to buy");
        order.offerCollateralAmount = collateralAmount - IEURB(collateralAddress).getTransactionFee(msg.sender, address(this), collateralAmount);
        
        order.offerUAssetAmount = uAssetAmount;
        order.uAssetAddress = uAssetAddress;
        order.userAddress = msg.sender;

        emit Offer(msg.sender, uAssetAddress, id, uAssetAmount, collateralAmount, block.timestamp);
    }

    function offerSell(address uAssetAddress, uint256 uAssetAmount, uint256 collateralAmount, bytes memory id) external nonReentrant {
        uint256 royaltyFee = IController(controllerAddress).royaltyFeeRatio();
        
        {
            address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
            uint256 fee = collateralAmount * royaltyFee / (10 ** royaltyDecimal);

            if(IEURB(collateralAddress).isTransactionExcludedFromFee(msg.sender, address(this))) {
                IEURB(collateralAddress).safeTransferFrom(msg.sender, address(this), fee);
                offerFee[id] = fee;
            } else {
                uint256 totalFee = (collateralAmount * royaltyFee / (10 ** royaltyDecimal)) * 1e5 / (1e5 - IEURB(collateralAddress)._feePercentage());
                IEURB(collateralAddress).safeTransferFrom(msg.sender, address(this), totalFee);
                offerFee[id] = totalFee - totalFee * IEURB(collateralAddress)._feePercentage() / 1e5;
            }
            IEURB(uAssetAddress).safeTransferFrom(msg.sender, address(this), uAssetAmount);
        }
        
        Order storage order = orders[id];
        require(order.offerUAssetAmount == 0, "Still being offered to sell");
        order.offerCollateralAmount = collateralAmount;
        order.offerUAssetAmount = uAssetAmount;
        order.uAssetAddress = uAssetAddress;
        order.userAddress = msg.sender;

        emit Offer(msg.sender, uAssetAddress, id, uAssetAmount, collateralAmount, block.timestamp);
    }
    
    function buy(uint256 deadline, uint256[] memory amountOutMin, bytes[] memory ids) external onlyAdmin {
        for(uint256 i = 0; i < ids.length; i++) {
            buyNow(deadline, amountOutMin[i], ids[i]);
        }

        emit Buy(ids);
    }
    
    function sell(uint256 deadline, uint256[] memory amountOutMin, bytes[] memory ids) external onlyAdmin {
        for(uint256 i = 0; i < ids.length; i++) {
            sellNow(deadline, amountOutMin[i], ids[i]);
        }

        emit Sell(ids);
    }

    function buyNow(uint256 deadline, uint256 amountOutMin, bytes memory id) public nonReentrant onlyAdmin {
        Order storage order = orders[id];
        uint256 collateralAmount = order.offerCollateralAmount;
        address uAssetAddress = order.uAssetAddress;
        address user = order.userAddress;
        uint256 amountOut;
        {
            address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
            address[] memory path = new address[](2);
            uint256 deadline_ = deadline;
            uint256 amountOutMin_ = amountOutMin;
            {
                address poolAddress = IController(controllerAddress).pools(uAssetAddress);
                address token0 = IUniswapV2Pair(poolAddress).token0();
                address token1 = IUniswapV2Pair(poolAddress).token1();
                
                path[0] = collateralAddress;
                path[1] = token1;
                if (token1 == collateralAddress) {
                    path[1] = token0;
                }
            }
            address routerAddress = IController(controllerAddress).router();
            IEURB(collateralAddress).safeApprove(routerAddress, collateralAmount);

            uint256 balanceBefore = IEURB(path[1]).balanceOf(user);
            IUniswapV2Router02(IController(controllerAddress).router()).swapExactTokensForTokensSupportingFeeOnTransferTokens(collateralAmount, amountOutMin_, path, user, deadline_);
            amountOut = IEURB(path[1]).balanceOf(user) - balanceBefore;
        }
        order.offerCollateralAmount = 0;
        order.offerUAssetAmount = 0;
        amountToClaim += offerFee[id];

        emit Offer(msg.sender, uAssetAddress, id, amountOut, collateralAmount, block.timestamp);
    }

    function sellNow(uint256 deadline, uint256 amountOutMin, bytes memory id) public nonReentrant onlyAdmin {
        Order storage order = orders[id];
        uint256 uAssetAmount = order.offerUAssetAmount;
        address uAssetAddress = order.uAssetAddress;
        address user = order.userAddress;
        uint256 deadline_ = deadline;
        uint256 collateralAmount;
        {
            address[] memory path = new address[](2);
            
            {
                address poolAddress = IController(controllerAddress).pools(uAssetAddress);
                address token0 = IUniswapV2Pair(poolAddress).token0();
                address token1 = IUniswapV2Pair(poolAddress).token1();
                
                path[0] = uAssetAddress;
                path[1] = token1;
                if (token1 == uAssetAddress) {
                    path[1] = token0;
                }
            }
            address routerAddress = IController(controllerAddress).router();
            IEURB(uAssetAddress).safeApprove(routerAddress, uAssetAmount);

            uint256 balanceBefore = IEURB(path[1]).balanceOf(user);
            IUniswapV2Router02(IController(controllerAddress).router()).swapExactTokensForTokensSupportingFeeOnTransferTokens(uAssetAmount, amountOutMin, path, user, deadline_);
            collateralAmount = IEURB(path[1]).balanceOf(user) - balanceBefore;
        }
        order.offerCollateralAmount = 0;
        order.offerUAssetAmount = 0;
        amountToClaim += offerFee[id];

        emit Offer(msg.sender, uAssetAddress, id, uAssetAmount, collateralAmount, block.timestamp);
    }

    function withDrawBuy(bytes memory id) external nonReentrant {
        Order storage order = orders[id];
        uint256 collateralAmount = order.offerCollateralAmount;
        uint256 uAssetAmount = order.offerUAssetAmount;
        address uAssetAddress = order.uAssetAddress;
        address user = order.userAddress;
        
        require(msg.sender == user, "Caller is not the one offered");
        require(collateralAmount > 0 && uAssetAmount > 0, "No offer to be withdrawn");
        
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        IEURB(collateralAddress).safeTransfer(msg.sender, collateralAmount);
        IEURB(collateralAddress).safeTransfer(msg.sender, offerFee[id]);
        order.offerCollateralAmount = 0;
        order.offerUAssetAmount = 0;

        emit WithDraw(msg.sender, uAssetAddress, id, uAssetAmount, collateralAmount, block.timestamp);
    }

    function withDrawSell(bytes memory id) external nonReentrant {
        Order storage order = orders[id];
        uint256 collateralAmount = order.offerCollateralAmount;
        uint256 uAssetAmount = order.offerUAssetAmount;
        address uAssetAddress = order.uAssetAddress;
        address user = order.userAddress;
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        
        require(msg.sender == user, "Caller is not the one offered");
        require(collateralAmount > 0 && uAssetAmount > 0, "No offer to be withdrawn");

        IEURB(uAssetAddress).safeTransfer(msg.sender, uAssetAmount);
        IEURB(collateralAddress).safeTransfer(msg.sender, offerFee[id]);
        order.offerCollateralAmount = 0;
        order.offerUAssetAmount = 0;

        emit WithDraw(msg.sender, uAssetAddress, id, uAssetAmount, collateralAmount, block.timestamp);
    }

    function claim(address collateralAddress) external onlyOwner {
        IEURB(collateralAddress).safeTransfer(owner(), amountToClaim);
        amountToClaim = 0;
    }

}