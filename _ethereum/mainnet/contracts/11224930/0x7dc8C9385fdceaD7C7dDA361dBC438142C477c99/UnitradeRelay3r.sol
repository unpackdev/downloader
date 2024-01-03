// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "./Ownable.sol";
import "./UniswapV2Library.sol";
import "./IKeep3rV1Mini.sol";

enum OrderState {Placed, Cancelled, Executed}

interface UnitradeInterface {
    function cancelOrder(uint256 orderId) external returns (bool);

    function executeOrder(uint256 orderId)
        external
        returns (uint256[] memory amounts);

    function feeDiv() external view returns (uint16);

    function feeMul() external view returns (uint16);

    function getActiveOrderId(uint256 index) external view returns (uint256);

    function getActiveOrdersLength() external view returns (uint256);

    function getOrder(uint256 orderId)
        external
        view
        returns (
            uint8 orderType,
            address maker,
            address tokenIn,
            address tokenOut,
            uint256 amountInOffered,
            uint256 amountOutExpected,
            uint256 executorFee,
            uint256 totalEthDeposited,
            OrderState orderState,
            bool deflationary
        );

    function getOrderIdForAddress(address _address, uint256 index)
        external
        view
        returns (uint256);

    function getOrdersForAddressLength(address _address)
        external
        view
        returns (uint256);

    function incinerator() external view returns (address);

    function owner() external view returns (address);

    function placeOrder(
        uint8 orderType,
        address tokenIn,
        address tokenOut,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee
    ) external returns (uint256);

    function renounceOwnership() external;

    function splitDiv() external view returns (uint16);

    function splitMul() external view returns (uint16);

    function staker() external view returns (address);

    function transferOwnership(address newOwner) external;

    function uniswapV2Factory() external view returns (address);

    function uniswapV2Router() external view returns (address);

    function updateFee(uint16 _feeMul, uint16 _feeDiv) external;

    function updateOrder(
        uint256 orderId,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee
    ) external returns (bool);

    function updateSplit(uint16 _splitMul, uint16 _splitDiv) external;

    function updateStaker(address newStaker) external;
}

contract UnitradeRelay3r is Ownable{
    UnitradeInterface iUniTrade = UnitradeInterface(
        0xC1bF1B4929DA9303773eCEa5E251fDEc22cC6828
    );
    //change this to relay3r on deploy
    IKeep3rV1Mini public KP3R;
    bool TryDeflationaryOrders = false;

    constructor(address keepertoken) public {
        KP3R = IKeep3rV1Mini(keepertoken);
    }

    modifier upkeep() {
        require(KP3R.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;
        KP3R.workedETH(msg.sender);
    }

    function setTryBurnabletokens(bool fTry) public onlyOwner{
        TryDeflationaryOrders = fTry;
    }

    function getIfExecuteable(uint256 i) public view returns (bool) {
        (
            uint8 orderType,
            address maker,
            address tokenIn,
            address tokenOut,
            uint256 amountInOffered,
            uint256 amountOutExpected,
            uint256 executorFee,
            uint256 totalEthDeposited,
            OrderState orderState,
            bool deflationary
        ) = iUniTrade.getOrder(i);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        if(executorFee <= 0) return false;//Dont execute unprofitable orders
        if(deflationary && !TryDeflationaryOrders) return false;//Skip deflationary token orders as it is not supported atm
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            iUniTrade.uniswapV2Factory(),
            amountInOffered,
            path
        );
        if (
            amounts[1] >= amountOutExpected && orderState == OrderState.Placed
        ) {
            return true;
        }
        return false;
    }

    function hasExecutableOrdersPending() public view returns (bool) {
        for (uint256 i = 0; i < iUniTrade.getActiveOrdersLength(); i++) {
            if (getIfExecuteable(i)) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {
        //Add any eth received
        KP3R.addCreditETH{value:msg.value}(address(this));
    }

    function workable() public view returns (bool) {
        return hasExecutableOrdersPending();
    }

    function work() public upkeep{
        require(workable(),"No executable trades");
        for (uint256 i = 0; i < iUniTrade.getActiveOrdersLength(); i++) {
            if (getIfExecuteable(i)) {
                iUniTrade.executeOrder(i);
            }
        }
    }
}
