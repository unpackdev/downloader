// SPDX-License-Identifier: MIT

///@title PricingV1
///@author Koto Protocol
///@notice

pragma solidity 0.8.23;

import "./IKotoV3.sol";
import "./SafeTransferLib.sol";
import "./IERC20Minimal.sol";
import "./FullMath.sol";

contract PricingV1 {
    // ====================================================== \\
    //                         CONSTANTS                      \\
    // ====================================================== \\

    IKotoV3 public constant KOTO = IKotoV3(0x64C7d8C8Abf28Daf9D441c507CfE9Be678A0929c);
    address public constant BOND_DEPOSITORY = 0xE58B33c813ac4077bd2519dE90FccB189a19FA71;
    address public constant PAIR = 0x47287d8d7C1a5854Aa11868E7d2186b138069F84;
    uint256 public constant INTERVAL = 86400;
    uint256 public constant LENGTH = 604800;
    address public constant OWNER = 0x946eF43867225695E29241813A8F41519634B36b;
    bool private constant zeroForOne = true;

    // ====================================================== \\
    //                         STRUCTS                        \\
    // ====================================================== \\

    struct Model {
        uint48 interval;
        uint48 last;
        uint48 conclusion;
        uint96 theta;
        uint96 price;
        uint96 capacity;
    }

    // ====================================================== \\
    //                         STORAGE                        \\
    // ====================================================== \\

    Model public ethModel;
    Model public lpModel;
    uint256 private ethCapacity;
    uint256 private lpCapacity;

    constructor() {}

    // ====================================================== \\
    //                   EXTERNAL FUNCTIONS                   \\
    // ====================================================== \\

    ///@notice bond Eth for koto
    function bond() external payable {
        if (block.timestamp > ethModel.conclusion) revert MarketClosed();
        if (ethModel.capacity != 0) {
            SafeTransferLib.safeTransferETH(address(KOTO), msg.value);
            // Cache variables for later use to minimize storage calls
            Model memory eth = ethModel;

            uint48 time = uint48(block.timestamp);
            uint256 theta = eth.theta * (time - eth.last);
            uint256 price = eth.price - theta;
            uint256 payout = (msg.value * 1e18 / price);
            if (payout > _max(eth)) revert MaxPayout();

            // Update market variables
            eth.price = uint96(_marketPrice(eth, payout));
            eth.theta = uint96(_decay(eth));
            eth.capacity -= uint96(payout);
            eth.last = time;
            ethModel = eth;

            bool success = KOTO.transfer(msg.sender, payout);
            if (!success) revert BondFailed();
            emit Bond(msg.sender, payout, price);
        } else {
            //If bonds are not available refund the eth sent to the contract
            SafeTransferLib.safeTransferETH(msg.sender, msg.value);
        }
    }

    ///@notice bond Koto / WETH LP tokens for Koto
    ///@param amount the amount of koto lp tokens to bond
    function bondLp(uint256 amount) external {
        if (block.timestamp > lpModel.conclusion) revert MarketClosed();
        if (lpModel.capacity != 0) {
            IERC20Minimal(PAIR).transferFrom(msg.sender, BOND_DEPOSITORY, amount);
            // Cache variables for later use to minimize storage calls
            Model memory lp = lpModel;
            uint48 time = uint48(block.timestamp);
            uint256 theta = lp.theta * (time - lp.last);

            uint256 price = lp.price - theta;

            uint256 payout = (amount * 1e18 / price);
            if (payout > _max(lp)) revert MaxPayout();

            // Update market variables
            lp.price = uint96(_marketPrice(lp, payout));
            lp.theta = uint96(_decay(lp));
            lp.capacity -= uint96(payout);
            lp.last = time;
            lpModel = lp;
            bool success = KOTO.transfer(msg.sender, payout);
            if (!success) revert BondFailed();
            emit Bond(msg.sender, payout, price);
        } else {
            revert BondsSoldOut();
        }
    }

    ///@notice transfer in the koto to be sold as bonds
    ///@param amount the amount of koto tokens to transfer in
    function notifyRewardAmount(uint256 amount) external {
        if (msg.sender != BOND_DEPOSITORY) revert OnlyDepository();
        KOTO.transferFrom(BOND_DEPOSITORY, address(this), amount);
    }

    ///@notice transfer eth bonded for koto to the koto contract
    function addReserves() external {
        SafeTransferLib.safeTransferETH(address(KOTO), address(this).balance);
    }

    ///@notice burn any unsold bonds
    function burn() external {
        if (msg.sender != OWNER) revert OnlyOwner();
        uint256 amount;
        if (KOTO.balanceOf(address(this)) - (ethModel.capacity + lpModel.capacity) > 0) {
            amount = KOTO.balanceOf(address(this)) - (ethModel.capacity + lpModel.capacity);
        }
        KOTO.burn(amount);
    }

    function create(uint256 ethBonds, uint256 lpBonds) external {
        if (msg.sender != OWNER) revert OnlyOwner();
        if (ethModel.conclusion > block.timestamp) revert OngoingMarket();
        if (ethBonds + lpBonds > KOTO.balanceOf(address(this))) revert BondOverflow();
        ethCapacity = ethBonds;
        lpCapacity = lpBonds;
        _create();
        _createLpMarket();
    }

    // ====================================================== \\
    //                   EXTERNAL VIEW FUNCTIONS               \\
    // ====================================================== \\

    function market() external view returns (Model memory, Model memory) {
        return (ethModel, lpModel);
    }

    function ethPrice() external view returns (uint256) {
        Model memory model = ethModel;
        return model.price - (model.theta * (block.timestamp - model.last));
    }

    function lpPrice() external view returns (uint256) {
        Model memory model = lpModel;
        return model.price - (model.theta * (block.timestamp - model.last));
    }

    // ====================================================== \\
    //                    INTERNAL FUNCTIONS                  \\
    // ====================================================== \\

    // Set the initial price to the current market price
    function _create() private {
        uint256 _capacity = ethCapacity;
        if (_capacity > 0) {
            uint256 initialPrice = _getPrice();
            uint96 capacity = uint96(_capacity);
            uint48 conclusion = uint48(block.timestamp + LENGTH);
            bool policy = _policy(capacity, initialPrice);

            if (policy) {
                Model memory _ethModel = Model(
                    uint48(INTERVAL),
                    uint48(block.timestamp),
                    uint48(conclusion),
                    0,
                    uint96(initialPrice),
                    uint96(capacity)
                );
                _ethModel.theta = uint96(_decay(_ethModel));
                ethModel = _ethModel;
                emit CreateMarket(capacity, block.timestamp, conclusion);
            } else {
                KOTO.burn(capacity);
                // Set the markets so that they will be closed for the next interval. Important step to make sure
                // that if anyone accidently tries to buy a bond they get refunded their eth.
                ethModel.conclusion = uint48(block.timestamp + INTERVAL);
                ethModel.capacity = 0;
            }
            ethCapacity = 0;
        } else {
            ethModel.conclusion = uint48(block.timestamp + LENGTH);
        }
    }

    function _createLpMarket() private {
        uint256 _capacity = lpCapacity;
        if (_capacity > 0) {
            uint256 initialPrice = _getLpPrice();
            uint96 capacity = uint96(_capacity);
            uint48 conclusion = uint48(block.timestamp + LENGTH);
            Model memory _lpModel = Model(
                uint48(INTERVAL), uint48(block.timestamp), uint48(conclusion), 0, uint96(initialPrice), uint96(capacity)
            );
            _lpModel.theta = uint96(_decay(_lpModel));
            lpModel = _lpModel;
            emit CreateMarket(capacity, block.timestamp, conclusion);
            lpCapacity = 0;
        } else {
            lpModel.conclusion = uint48(block.timestamp + LENGTH);
        }
    }

    // ====================================================== \\
    //                 INTERNAL VIEW FUNCTIONS                \\
    // ====================================================== \\

    function _policy(uint256 capacity, uint256 price) private view returns (bool decision) {
        uint256 supply = KOTO.totalSupply();
        uint256 burnRelative = (address(KOTO).balance * 1e18) / (supply - capacity);
        uint256 bondRelative = ((address(KOTO).balance * 1e18) + ((capacity * price))) / supply;
        decision = burnRelative >= bondRelative ? false : true;
    }

    ///@notice calculate the current decay per second required to sell all the bonds within the
    /// remaining amount of time.
    function _decay(Model memory model) private view returns (uint256) {
        uint256 delta = model.conclusion - block.timestamp;
        uint256 decay = model.price / delta;
        return decay;
    }

    ///@notice calculate the new market price based off of the previous bond sell.
    function _marketPrice(Model memory model, uint256 sold) private pure returns (uint256) {
        uint256 price = FullMath.mulDiv(model.price, model.capacity, model.capacity - sold);
        return price;
    }

    function _max(Model memory model) private view returns (uint256) {
        uint256 remaining = model.conclusion - block.timestamp;
        uint256 max = (model.capacity * model.interval) / remaining;
        return max;
    }

    ///@notice calculate the current market price based on the reserves of the Uniswap Pair
    ///@dev price is returned as the amount of ETH you would get back for 1 full (1e18) Koto tokens
    function _getPrice() private view returns (uint256 price) {
        uint112 reserve0;
        uint112 reserve1;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)
            let success := staticcall(gas(), PAIR, ptr, 4, 0, 0)
            if iszero(success) { revert(0, 0) }
            returndatacopy(0x00, 0, 32)
            returndatacopy(0x20, 0x20, 32)
            reserve0 := mload(0x00)
            reserve1 := mload(0x20)
        }

        if (zeroForOne) {
            price = FullMath.mulDiv(uint256(reserve1), 1e18, uint256(reserve0));
        } else {
            price = FullMath.mulDiv(uint256(reserve0), 1e18, uint256(reserve1));
        }
    }

    ///@notice return the current price in koto for 1 LP token
    function _getLpPrice() private view returns (uint256 _lpPrice) {
        uint112 reserve0;
        uint112 reserve1;
        uint256 lpTotalSupply;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)
            let success := staticcall(gas(), PAIR, ptr, 4, 0, 0)
            if iszero(success) { revert(0, 0) }
            returndatacopy(0x00, 0, 32)
            returndatacopy(0x20, 0x20, 32)
            reserve0 := mload(0x00)
            reserve1 := mload(0x20)
            mstore(add(ptr, 0x20), 0x18160ddd00000000000000000000000000000000000000000000000000000000)
            let result := staticcall(gas(), PAIR, add(ptr, 0x20), 4, 0, 32)
            lpTotalSupply := mload(0x00)
        }
        ///@dev with uniswap v2 we simply treat the other token total as equal value to simplify the pricing mechanism
        if (zeroForOne) {
            _lpPrice = FullMath.mulDiv(reserve0 * 2, 1e18, lpTotalSupply);
        } else {
            _lpPrice = FullMath.mulDiv(reserve1 * 2, 1e18, lpTotalSupply);
        }
    }

    // ====================================================== \\
    //                     ERROR AND EVENTS                   \\
    // ====================================================== \\

    error OnlyDepository();
    error MarketClosed();
    error MaxPayout();
    error BondFailed();
    error BondsSoldOut();
    error OngoingMarket();
    error OnlyOwner();
    error BondOverflow();

    event Bond(address indexed caller, uint256 payout, uint256 price);
    event CreateMarket(uint256 bonds, uint256 start, uint256 end);

    receive() external payable {}
}
