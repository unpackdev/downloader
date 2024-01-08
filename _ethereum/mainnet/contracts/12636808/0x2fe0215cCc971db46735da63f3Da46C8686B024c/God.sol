// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract God is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;
    uint256 private constant MINTPRICE = 1;
    uint256 private constant BURNPRICE = 2;

    struct OP {
        uint256 datatype;
        address token;
        uint256 price;
        uint256 timestamp;
    }

    uint256 constant ONE = 0x100000000000000000000000000000000;

    uint256 public EXPIRY;
    uint256 public SIGNATURENUM;
    address public ATAN;
    address public GOV;

    mapping(address => bool) public authorization;
    mapping(address => mapping(address => uint256)) public tax_base;
    mapping(address => mapping(address => uint256)) public amt_mint;
    mapping(address => mapping(address => uint256)) public amt_burn;
    mapping(address => mapping(address => uint256)) public time_swap;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    function set_expiry(uint256 data) public onlyOwner {
        EXPIRY = data;
    }

    function set_signature_num(uint256 data) public onlyOwner {
        SIGNATURENUM = data;
    }

    function set_atan(address v) public onlyOwner {
        ATAN = v;
    }

    function set_gov(address v) public onlyOwner {
        GOV = v;
    }

    function add_authorization(address addr) public onlyOwner {
        authorization[addr] = true;
    }

    function remove_authorization(address addr) public onlyOwner {
        delete authorization[addr];
    }

    function set_tax_base(
        address src,
        address dst,
        uint256 num
    ) public onlyOwner {
        tax_base[src][dst] = num;
    }

    function swap(uint256[2] calldata ns, bytes[2] calldata oracle) public {
        OP memory x = decode_op(oracle[0]);
        OP memory y = decode_op(oracle[1]);
        require(x.datatype == BURNPRICE);
        require(y.datatype == MINTPRICE);
        require(x.timestamp == y.timestamp, "timestamp not match");
        uint256 t = tax(x.token, y.token, ns[0] * x.price, ns[1] * y.price);
        I(x.token).burn(msg.sender, ns[0]);
        I(y.token).mint(msg.sender, ns[1]);
        I(x.token).mint(GOV, t / x.price);
        emit Swap(msg.sender, x.token, y.token, ns[0], ns[1]);
    }

    function decode_op(bytes calldata data) public view returns (OP memory) {
        (bytes memory o, bytes[] memory s) = abi.decode(data, (bytes, bytes[]));
        OP memory op = abi.decode(o, (OP));
        require(s.length == SIGNATURENUM, "signature num error");
        bytes32 hash = keccak256(o).toEthSignedMessageHash();
        address auth = address(0);
        for (uint256 i = 0; i < s.length; i++) {
            address addr = hash.recover(s[i]);
            require(addr > auth, "signature order error");
            require(authorization[addr], "invalid Signature");
            auth = addr;
        }

        require(op.timestamp + EXPIRY > block.timestamp, "op expired");
        return op;
    }

    function tax(
        address src,
        address dst,
        uint256 burn,
        uint256 mint
    ) internal returns (uint256) {
        if (time_swap[src][dst] / (1 days) == block.timestamp / (1 days)) {
            amt_mint[src][dst] += mint;
            amt_burn[src][dst] += burn;
        } else {
            amt_mint[src][dst] = mint;
            amt_burn[src][dst] = burn;
        }
        time_swap[src][dst] = block.timestamp;

        uint256 n = (amt_burn[src][dst] * ONE) / tax_base[src][dst];
        n = (I(ATAN).arctan(n) * amt_burn[src][dst]) / ONE;
        require(amt_burn[src][dst] - amt_mint[src][dst] >= n, "overmint");
        return burn - mint;
    }

    function calculate_tax(
        address src,
        address dst,
        uint256 burn
    ) public view returns (uint256) {
        uint256 nb = amt_burn[src][dst];
        if (time_swap[src][dst] / (1 days) == block.timestamp / (1 days)) {
            nb += burn;
        } else {
            nb = burn;
        }

        uint256 n = (nb * ONE) / tax_base[src][dst];
        n = (I(ATAN).arctan(n) * nb) / ONE;
        uint256 n0 = amt_burn[src][dst] - amt_burn[src][dst];
        if (n <= n0) {
            return 0;
        }
        return n - n0;
    }

    function encode_op(
        uint256 datatype,
        address token,
        uint256 price,
        uint256 timestamp
    ) public pure returns (bytes memory) {
        OP memory op;
        op.datatype = datatype;
        op.token = token;
        op.price = price;
        op.timestamp = timestamp;
        return abi.encode(op);
    }

    function encode_sigs(bytes memory o, bytes[] memory s)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(o, s);
    }

    event Swap(address user, address x, address y, uint256 nx, uint256 ny);
}

interface I {
    function arctan(uint256) external view returns (uint256);

    function mint(address, uint256) external;

    function burn(address, uint256) external;
}
