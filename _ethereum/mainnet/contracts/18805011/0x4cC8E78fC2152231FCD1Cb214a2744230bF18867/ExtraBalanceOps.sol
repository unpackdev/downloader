import "./Balances.sol";
import "./BalancesLogic.sol";

library ExtraBalanceOps {
    using BalanceOps for Balance[];

    function tokenExists(Balance[] memory b, address token) internal pure returns (bool) {
        for (uint256 i; i < b.length;) {
            if (b[i].token == token) {
                return true;
            }

            unchecked {
                ++i;
            }
        }
        return false;
    }

    function copy(BalanceDelta[] memory b, uint256 len) internal pure returns (BalanceDelta[] memory res) {
        res = new BalanceDelta[](len);
        for (uint256 i; i < len;) {
            res[i] = BalanceDelta({token: b[i].token, amount: b[i].amount});
            unchecked {
                ++i;
            }
        }
    }

    function trim(BalanceDelta[] memory array) internal pure returns (BalanceDelta[] memory trimmed) {
        uint256 len = array.length;

        if (len == 0) return array;

        uint256 foundLen;
        while (array[foundLen].token != address(0)) {
            unchecked {
                ++foundLen;
                if (foundLen == len) return array;
            }
        }

        if (foundLen > 0) return copy(array, foundLen);
    }
}
