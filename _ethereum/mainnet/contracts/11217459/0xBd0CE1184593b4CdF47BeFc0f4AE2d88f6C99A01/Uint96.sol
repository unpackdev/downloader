library Uint96 {

    function cast(uint256 a) public pure returns (uint96) {
        require(a < 2**96);
        return uint96(a);
    }

    function add(uint96 a, uint96 b) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint96 a, uint96 b) internal pure returns (uint96) {
        require(a >= b, "subtraction overflow");
        return a - b;
    }

    function mul(uint96 a, uint96 b) internal pure returns (uint96) {
        if (a == 0) {
            return 0;
        }
        uint96 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }

    function div(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b != 0, "division by 0");
        return a / b;
    }

    function mod(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b != 0, "modulo by 0");
        return a % b;
    }

    function toString(uint96 a) internal pure returns (string memory) {
        bytes32 retBytes32;
        uint96 len = 0;
        if (a == 0) {
            retBytes32 = "0";
            len++;
        } else {
            uint96 value = a;
            while (value > 0) {
                retBytes32 = bytes32(uint256(retBytes32) / (2 ** 8));
                retBytes32 |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
                value /= 10;
                len++;
            }
        }

        bytes memory ret = new bytes(len);
        uint96 i;

        for (i = 0; i < len; i++) {
            ret[i] = retBytes32[i];
        }
        return string(ret);
    }
}