pragma solidity 0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IConverter.sol";
import "./ICurvePoolMinimal.sol";

contract CurvePoolConverter is IConverter {
    using SafeERC20 for IERC20;
    using Address for address;

    address public immutable pool;

    mapping(address => uint256) public indices; // int128 is 0 by default. It is need check in swap, what token is correct?
    bytes4 public immutable exchangeSelector;
    bytes4 public immutable getDySelector;

    constructor(address _pool, uint256 coinsLength, bool usesUint256ForIndices) {
        pool = _pool;
        for (uint256 i = 0; i < coinsLength; i++) {
            address token = ICurvePoolMinimal(pool).coins(i);
            IERC20(token).safeIncreaseAllowance(address(pool), type(uint256).max);
            indices[token] = i;
        }

        // To make contract more generic, we are using such approach to be able to work with
        // curve pools using different types of arguments
        // It is safe because positive values are encoded in the same way for uint256 and int128
        string memory indicesType = usesUint256ForIndices ? "uint256" : "int128";
        string memory exchangeSignature = string.concat("exchange(", indicesType, ",", indicesType, ",uint256,uint256)");
        string memory getDySignature = string.concat("get_dy(", indicesType, ",", indicesType, ",uint256)");
        exchangeSelector = bytes4(keccak256(bytes(exchangeSignature)));
        getDySelector = bytes4(keccak256(bytes(getDySignature)));
    }

    function swap(address source, address destination, uint256 value, address beneficiary)
        external
        returns (uint256 amountOut)
    {
        uint256 i = indices[source];
        uint256 j = indices[destination];

        pool.functionCall(abi.encodeWithSelector(exchangeSelector, i, j, value, 0));

        amountOut = IERC20(destination).balanceOf(address(this));
        IERC20(destination).safeTransfer(beneficiary, amountOut);
    }

    function previewSwap(address source, address destination, uint256 value) external view returns (uint256) {
        uint256 i = indices[source];
        uint256 j = indices[destination];
        bytes memory result = pool.functionStaticCall(abi.encodeWithSelector(getDySelector, i, j, value));
        return abi.decode(result, (uint256));
    }
}
