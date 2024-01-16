// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./Owned.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

/// @notice abbreviated dai token (permit only) function
/// @dev refer https://raw.githubusercontent.com/makerdao/dss/master/src/dai.sol
interface DaiPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address) external view returns (uint256);
}

/// @title abbreviated curve interface for BZZ bonding curve
/// @dev refer https://github.com/ethersphere/bzzaar-contracts/blob/main/packages/chain/contracts/Curve.sol
interface ICurve {
    function buyPrice(uint256 _amount) external view returns (uint256);
    function sellReward(uint256 _amount) external view returns (uint256);
    function collateralToken() external view returns (address);
    function bondedToken() external view returns (address);
    function mint(uint256 _amount, uint256 _maxCollateralSpend) external returns (bool success);
    function mintTo(uint256 _amount, uint256 _maxCollateralSpend, address _to) external returns (bool);
    function redeem(uint256 _amount, uint256 _minCollateralReward) external returns (bool success);
}

interface ForeignBridge {
    function relayTokens(address token, address _receiver, uint256 _value) external;
    function relayTokensAndCall(address token, address _receiver, uint256 _value, bytes memory _data) external;
}

contract Exchange is Owned {
    using SafeTransferLib for ERC20;

    // maximum fee is hardcoded at 100 basis points (1%)
    uint256 public constant MAX_FEE = 100;

    // tokens that are processed in this exchange
    ERC20 private immutable dai;
    ERC20 private immutable bzz;

    // the bonding curve we use for exchanging
    ICurve public immutable bc;
    ForeignBridge public immutable bridge;

    uint256 public fee;

    constructor(address owner, address _bc, address _bridge, uint256 _fee) Owned(owner) {
        require(_fee <= MAX_FEE, "fee/too-high");

        // the bonding curve that we are going to use
        bc = ICurve(_bc);
        bridge = ForeignBridge(_bridge);

        // these are the tokens that we are exchanging
        dai = ERC20(bc.collateralToken());
        bzz = ERC20(bc.bondedToken());

        /// @notice pre-approve the bonding ciurve for unlimited approval of the exchange's bzz and dai
        dai.approve(address(bc), type(uint256).max);
        bzz.approve(address(bc), type(uint256).max);

        /// @notice pre-approve the bridge for unlimited spending approval of the exchange's bzz tokens
        /// @dev this may be a security risk if the bridge is hacked, and could subsequently drain
        ///      any fees that this contract may have accumulated, though this motivates the owners
        ///      to regularly sweep tokens from the exchange that have accumulated as fees
        bzz.approve(address(bridge), type(uint256).max);

        // what fee we should collect (maximum hardcoded at 100bps, ie. 1%)
        fee = _fee;
    }

    // administration functions (onlyOwner)

    /// Allow configuration of uint256 variables after contract deployment, respecting maximums.
    /// @param _fee the fee to set for the exchange
    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_FEE, "fee/too-high");
        fee = _fee;
    }

    // swap functions

    /// Buy BZZ from the bonding curve
    /// @param wad the amount of bzz to buy from the bonding curve
    /// @param max_collateral_spend the maximum amount of collateral to be used when buying (dai)
    /// @param permit the permit for dai to enable single transaction purchase
    /// @param bridge_cd calldata for bridging to gnosis chain
    function buy(uint256 wad, uint256 max_collateral_spend, bytes calldata permit, bytes calldata bridge_cd) external {
        // 1. calculate the price to buy wad bzz and enforce slippage constraint
        uint256 collateralCost = bc.buyPrice(wad);
        require(collateralCost <= max_collateral_spend, "exchange/slippage");

        // at this point should consider if the length of cd is not zero, in which case we
        // assume that there is a permit signature, and will execute such.
        if (permit.length > 0) {
            // we assume that there is a permit signature here, decode as such
            (uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) =
                abi.decode(permit, (uint256, uint256, uint8, bytes32, bytes32));

            /// @dev dai permit is not eip-2612.
            DaiPermit(address(dai)).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
        }
        // 2. transfer the dai from the user to this contract
        dai.safeTransferFrom(msg.sender, address(this), collateralCost);

        // 3. deduct our fees
        (wad, collateralCost) = (net(wad), net(collateralCost));

        // 4. mint and send logic
        if (bridge_cd.length == 0) {
            // no bridging data, therefore we are to just send to the user here on ethereum mainnet
            // use mintTo to save on a transfer
            bc.mintTo(wad, collateralCost, msg.sender);
        } else {
            bc.mint(wad, collateralCost);
            // there are two options here, depending on the calldata length
            // 1. if calldata is just an abi encoded address, then we send to an address on gnosis chain.
            //    this is handy if wanting to send direct to a bee node's wallet
            // 2. if calldata is longer than just an abi encoded address, we will relay tokens and provide
            //    callback data (allows for flexibility when sending to contracts on gnosis chain)
            if (bridge_cd.length == 32) {
                // relay direct to a wallet
                address dest = abi.decode(bridge_cd, (address));
                bridge.relayTokens(address(bzz), dest, wad);
            } else {
                (address dest, bytes memory cd) = abi.decode(bridge_cd, (address, bytes));
                bridge.relayTokensAndCall(address(bzz), dest, wad, cd);
            }
        }
    }

    /// Sell BZZ to the bonding curve in return for rewards (DAI)
    /// @dev This function assumes that the contract has already been authorised to spend msg.sender's bzz
    /// @param wad the amount of bzz to sell to the bonding curve
    /// @param min_collateral_receive the minimum amount of collateral we should get for selling wad (dai)
    function sell(uint256 wad, uint256 min_collateral_receive) external {
        // 1. calculate the reward for selling wad bzz and enforce slippage constraint
        uint256 collateralReward = bc.sellReward(wad);
        require(collateralReward >= min_collateral_receive, "exchange/slippage");

        // 2. transfer the bzz from the user to this contract
        bzz.safeTransferFrom(msg.sender, address(this), wad);

        // 3. redeem
        bc.redeem(wad, collateralReward);

        // 4. send the amount received to msg.sender after deducting any fee
        dai.safeTransfer(msg.sender, net(collateralReward));
    }

    /// Calculates the *net* amount that should be paid to msg.sender
    /// @param gross the gross amount in wei for consideration
    /// @return uint256 the gross amount less fees (fees specified in bps)
    function net(uint256 gross) internal view returns (uint256) {
        return (10000 - fee) * gross / 10000;
    }

    /// Sweeper function for any ERC20 tokens accidentally sent to the contract
    /// @notice this function will send the ERC20 tokens to the owner of the contract
    /// @param token the address of the token to sweep
    /// @param wad amount of ERC20 tokens to send to owner
    function sweep(ERC20 token, uint256 wad) external onlyOwner {
        token.safeTransfer(owner, wad);
    }
}
