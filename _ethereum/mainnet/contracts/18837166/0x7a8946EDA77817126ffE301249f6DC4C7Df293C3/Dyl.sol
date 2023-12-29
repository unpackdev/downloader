// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";
import "./PoolAddress.sol";
import "./IUniswapRouterV2.sol";

/*

   $$\    $$$$$$$\            $$\ 
 $$$$$$\  $$  __$$\           $$ |
$$  __$$\ $$ |  $$ |$$\   $$\ $$ |
$$ /  \__|$$ |  $$ |$$ |  $$ |$$ |
\$$$$$$\  $$ |  $$ |$$ |  $$ |$$ |
 \___ $$\ $$ |  $$ |$$ |  $$ |$$ |
$$\  \$$ |$$$$$$$  |\$$$$$$$ |$$ |
\$$$$$$  |\_______/  \____$$ |\__|
 \_$$  _/           $$\   $$ |    
   \ _/             \$$$$$$  |    
                     \______/     

*/
contract Dyl is ERC20, ERC20Permit, Ownable {
    //------------------------------------------------------------------------------------//
    //                                      errors                                        //
    //------------------------------------------------------------------------------------//
    error MaxHoldingAmountExceeded();
    error ErrNotTokenRedeemer();
    error ErrTotalSupplyExceeded();
    error ErrNotLiquidtyProvider();
    error ErrExceedingMaxAmountInSellOrder();
    error ErrExceedingMaxAmountInBuyOrder();
    error ErrNoSandwhichesHere();
    //------------------------------------------------------------------------------------//
    //                                      constants                                     //
    //------------------------------------------------------------------------------------//

    /// @dev total supply
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 ether; //1 billion tokens

    /// @dev jared from subway address
    address private constant JARED = address(0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13);

    /// @dev uniswap v2 router address
    address constant UNISWAP_V2_ROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /// @dev uniswap v2 factory address
    address constant UNISWAP_V2_FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    /// @dev uniswap v3 factory address
    address constant UNISWAP_V3_FACTORY = address(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    //------------------------------------------------------------------------------------//
    //                                      immutable                                     //
    //------------------------------------------------------------------------------------//

    /**
     * @notice the primary uniswap(v2) pair for HER
     */
    address public immutable uniswapV2Pair;

    //------------------------------------------------------------------------------------//
    //                                      variables                                     //
    //------------------------------------------------------------------------------------//

    /**
     * @notice the address of the token redeemer
     * @dev
     */
    address public tokenRedeemer;

    //------------------------------------------------------------------------------------//
    //                                      mappings                                      //
    //------------------------------------------------------------------------------------//

    /// @notice A mapping of pool addresses to a boolean indicating if the pool is registered
    /// @dev only univ2 and univ3 her/weth pools are registered
    mapping(address => AddressData) private _addressData;

    struct AddressData {
        bool isPool;
        bool isExcludedFromTax;
    }
    //------------------------------------------------------------------------------------//
    //                                      constructor                                   //
    //------------------------------------------------------------------------------------//
    /**
     * @notice Constructs the HerToken contract
     * @param _owner The address to set as owner
     */

    constructor(address _owner) payable ERC20("Dyl", "Dyl") ERC20Permit("Dyl") Ownable(_owner) {
        address weth = IUniswapRouterV2(UNISWAP_V2_ROUTER).WETH();
        uniswapV2Pair = pairFor(UNISWAP_V2_FACTORY, address(this), weth);
        _addressData[uniswapV2Pair] = AddressData({isPool: true, isExcludedFromTax: false});
        _addressData[computeUniv3Address(weth, 500)] = AddressData({isPool: true, isExcludedFromTax: false});
        _addressData[computeUniv3Address(weth, 3000)] = AddressData({isPool: true, isExcludedFromTax: false});
        _addressData[computeUniv3Address(weth, 10000)] = AddressData({isPool: true, isExcludedFromTax: false});
        _addressData[_owner] = AddressData({isPool: false, isExcludedFromTax: true});
        _addressData[address(this)] = AddressData({isPool: false, isExcludedFromTax: true});
        _addressData[_owner] = AddressData({isPool: false, isExcludedFromTax: true});
        tokenRedeemer = _owner;
        _mint(_owner, TOTAL_SUPPLY);
    }

    //------------------------------------------------------------------------------------//
    //                                 ERC20 Overrides                                    //
    //------------------------------------------------------------------------------------//
    /**
     * @dev - overrides ERC20 update for custom logic
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param value The amount to transfer
     */
    function _update(address from, address to, uint256 value) internal override(ERC20) {
        uint256 _value = value;
        AddressData memory fromData = _addressData[from];
        AddressData memory toData = _addressData[to];
        if (from == JARED || to == JARED) {
            _revert(ErrNoSandwhichesHere.selector);
        }
        if (!fromData.isExcludedFromTax && !toData.isExcludedFromTax) {
            //If sending tokens to pool, that means it's a sell order
            if (toData.isPool) {
                uint256 tax = _computeSalesTax(value);
                _value = value - tax;
                super._update(from, address(this), tax);
            }
        }

        super._update(from, to, _value);
    }

    //------------------------------------------------------------------------------------//
    //                                  withdaraw tokens                                  //
    //------------------------------------------------------------------------------------//

    /**
     * @notice allows anyone to sent lost tokens back to the treasury
     * @param _token The token to withdraw, use address(0) for ETH
     */
    function withdrawERC20(address _token, address to) external {
        _checkTokenRedeemer();
        if (_token == address(0)) {
            (bool os,) = payable(to).call{value: address(this).balance}("");
            require(os, "withdrawERC20: ETH transfer failed");
        } else {
            ERC20(_token).transfer(to, ERC20(_token).balanceOf(address(this)));
        }
    }

    //------------------------------------------------------------------------------------//
    //                                    access-gated funcs                              //
    //------------------------------------------------------------------------------------//
    /**
     * @notice Allows the the token redeemer to declare a new token redeemer
     * @param _tokenRedeemer The new token redeemer
     */
    function setTokenRedeemer(address _tokenRedeemer) external {
        _checkTokenRedeemer();
        address _oldRedeemer = tokenRedeemer;
        _addressData[_oldRedeemer] = AddressData({isPool: false, isExcludedFromTax: false});
        tokenRedeemer = _tokenRedeemer;
        _addressData[_tokenRedeemer] = AddressData({isPool: false, isExcludedFromTax: true});
    }

    /**
     * @notice Allows the owner to manually override the address data
     * @param _address The address to override
     * @param _isPool A boolean indicating if the address is a pool
     * @param _isExcludedFromTax A boolean indicating if the address is excluded from tax
     */
    function emergencyOverrideAddressData(address _address, bool _isPool, bool _isExcludedFromTax) external onlyOwner {
        _addressData[_address] = AddressData({isPool: _isPool, isExcludedFromTax: _isExcludedFromTax});
    }

    //------------------------------------------------------------------------------------//
    //                                      getters                                       //
    //------------------------------------------------------------------------------------//

    function addressData(address _address) external view returns (AddressData memory) {
        return _addressData[_address];
    }

    //------------------------------------------------------------------------------------//
    //                                          utils                                     //
    //------------------------------------------------------------------------------------//
    /**
     * @dev Sort two tokens deterministically
     * @param tokenA The first token of a pair
     * @param tokenB The second token of a pair
     * @return token0 The token that sorts lower than the other token
     * @return token1 The token that sorts higher than the other token
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @dev Compute a pair address from the two tokens
     * @param factory The Uniswap V2 factory contract address
     * @param tokenA The first token of a pair
     * @param tokenB The second token of a pair
     * @return pair The pair address
     */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    /**
     * @param amount The amount to compute tax for
     * @return The amount of tax to pay
     */
    function _computeSalesTax(uint256 amount) internal pure returns (uint256) {
        return (amount * 2) / 100; //2% sell tax
    }

    /**
     * @dev Compute the univ3 pool address given the WETH address and fee level
     * @param weth The WETH address
     * @param fee The fee level
     * @return pool The pool address
     */
    function computeUniv3Address(address weth, uint24 fee) internal view returns (address) {
        PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(address(this), weth, fee);
        address pool = PoolAddress.computeAddress(UNISWAP_V3_FACTORY, key);
        return pool;
    }

    /**
     * @dev Check if the caller is the token redeemer
     */
    function _checkTokenRedeemer() internal view {
        if (msg.sender != tokenRedeemer) {
            _revert(ErrNotTokenRedeemer.selector);
        }
    }
    /**
     * @notice an efficient revert
     * @param selector The function selector to revert with
     */

    function _revert(bytes4 selector) private pure {
        assembly {
            mstore(0x0, selector)
            revert(0x0, 0x4)
        }
    }
}
