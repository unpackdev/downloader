pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./IRouter.sol";
import "./IAdapter.sol";
import "./Utils.sol";
import "./IAugustusSwapperV5.sol";
import "./AugustusStorage.sol";
import "./FeeModel.sol";

contract MultiPath is IRouter, FeeModel {
    using SafeMath for uint256;

    // bytes32 public constant override WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    constructor(
        uint256 _partnerSharePercent,
        uint256 _maxFeePercent,
        uint256 _minFeePercent,
        IFeeClaimer _feeClaimer
    ) 
        public
        FeeModel(_partnerSharePercent, _maxFeePercent, _minFeePercent, _feeClaimer) 
    {}

    function initialize(bytes calldata) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function getKey() external pure override returns (bytes32) {
        return keccak256(abi.encodePacked("MULTIPATH_ROUTER", "1.0.0"));
    }

    /**
     * @dev The function which performs the multi path swap.
     * @param data Data required to perform swap.
     */
    function multiSwap(
        Utils.SellData memory data,
        address sender
    ) public payable returns (uint256) {
        require(data.deadline >= block.timestamp, "MultiPath: Deadline breached");
        require(data.beneficiary != address(0), "MultiPath: invalid beneficiary");

        uint256 fromAmount = data.fromAmount;
        address fromToken = data.fromToken;
        require(msg.value == (fromToken == Utils.ethAddress() ? fromAmount : 0), "MultiPath: Incorrect msg.value");
        Utils.Path[] memory path = data.path;
        address toToken = path[path.length - 1].to;

        require(data.toAmount > 0, "MultiPath: To amount can not be 0");

        transferTokens(
            fromToken,
            fromAmount,
            msg.sender == address(this) ? sender : msg.sender
        );

        fromAmount = takeFromTokenFee(
            fromToken,
            fromAmount,
            data.partner,
            data.feePercent
        );

        performSwap(fromToken, fromAmount, path);
        
        uint256 receivedAmount = Utils.tokenBalance(toToken, address(this));
        
        require(    
            receivedAmount >= data.toAmount,
            "MultiPath: Received amount of tokens are less then expected"
        );
        
        if (!(msg.sender == address(this)))
            Utils.transferTokens(toToken, data.beneficiary, receivedAmount);
        
        emit Swapped(
            bytes16(0),
            msg.sender == address(this) ? sender : msg.sender,
            data.beneficiary,
            fromToken,
            toToken,
            fromAmount,
            receivedAmount,
            data.toAmount
        );
        return receivedAmount;
    }
    
    /**
     * @dev The function which performs the mega path swap.
     * @param data Data required to perform swap.
     */
    function megaSwap(
        Utils.MegaSwapSellData memory data,
        address sender
    ) public payable returns (uint256) {
        require(data.deadline >= block.timestamp, "MultiPath: Deadline breached");
        require(data.beneficiary != address(0), "MultiPath: invalid beneficiary");

        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        require(msg.value == (fromToken == Utils.ethAddress() ? fromAmount : 0), "MultiPath: Incorrect msg.value");
        uint256 toAmount = data.toAmount;
        Utils.MegaSwapPath[] memory path = data.path;
        address toToken = path[0].path[path[0].path.length - 1].to;

        require(toAmount > 0, "MultiPath: To amount can not be 0");
        transferTokens(
            fromToken,
            data.fromAmount,
            msg.sender == address(this) ? sender : msg.sender
        );

        takeFromTokenFee(
            data.fromToken,
            fromAmount,
            data.partner,
            data.feePercent
        );

        for (uint8 i = 0; i < uint8(path.length); i++) {
            uint256 _fromAmount = fromAmount.mul(path[i].fromAmountPercent).div(
                10000
            );
            if (i == path.length - 1) {
                _fromAmount = Utils.tokenBalance(
                    address(fromToken),
                    address(this)
                );
            }
            performSwap(fromToken, _fromAmount, path[i].path);
        }

        uint256 receivedAmount = Utils.tokenBalance(toToken, address(this));
        require(
            receivedAmount >= toAmount,
            "MultiPath: Received amount of tokens are less then expected"
        );
        if (!(msg.sender == address(this))) 
            Utils.transferTokens(toToken, data.beneficiary, receivedAmount);

        return receivedAmount;
    }

    //Helper function to perform swap
    function performSwap(
        address fromToken,
        uint256 fromAmount,
        Utils.Path[] memory path
    ) private {
        require(path.length > 0, "Path not provided for swap");

        //Assuming path will not be too long to reach out of gas exception
        for (uint256 i = 0; i < path.length; i++) {
            //_fromToken will be either fromToken or toToken of the previous path
            address _fromToken = i > 0 ? path[i - 1].to : fromToken;
            address _toToken = path[i].to;

            uint256 _fromAmount = i > 0
                ? Utils.tokenBalance(_fromToken, address(this))
                : fromAmount;

            for (uint256 j = 0; j < path[i].adapters.length; j++) {
                Utils.Adapter memory adapter = path[i].adapters[j];

                //Check if exchange is supported
                require(
                    IAugustusSwapperV5(address(this)).hasRole(
                        WHITELISTED_ROLE,
                        adapter.adapter
                    ),
                    "Exchange not whitelisted"
                );

                //Calculating tokens to be passed to the relevant exchange
                //percentage should be 200 for 2%
                uint256 fromAmountSlice = i > 0 &&
                    j == path[i].adapters.length.sub(1)
                    ? Utils.tokenBalance(address(_fromToken), address(this))
                    : _fromAmount.mul(adapter.percent).div(10000);

                //DELEGATING CALL TO THE ADAPTER
                (bool success, ) = adapter.adapter.delegatecall(
                    abi.encodeWithSelector(
                        IAdapter.swap.selector,
                        _fromToken,
                        _toToken,
                        fromAmountSlice,
                        uint256(0), //adapter.networkFee,
                        adapter.route
                    )
                );

                require(success, "Call to adapter failed");
            }
        }
    }

    function transferTokens(
        address token,
        uint256 amount,
        address sender
    ) private {
        if (token != Utils.ethAddress()) {
            require(msg.value == 0, "Incorrect msg.value");
            IERC20(token).transferFrom(sender, address(this), amount);
        }
    }
}
