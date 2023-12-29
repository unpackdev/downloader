pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./console.sol";


/**
 * @title ERC20 Token
 *
 * Basic ERC20 Implementation
 */
contract BaseERC20 {
    using SafeMath for uint256;

    // ============ Variables ============

    string tokenName;
    string tokenSymbol;
    uint256 tokenSupply;
    uint256 tokenSupplyCap;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    // ============ Events ============

    event Transfer(
        address token,
        address from,
        address to,
        uint256 value
    );

    event Approval(
        address token,
        address owner,
        address spender,
        uint256 value
    );

    // ============ Constructor ============

    constructor(
        string memory name,
        string memory symbol,
        uint256 supplyCap
    )
        public
    {
        tokenName = name;
        tokenSymbol = symbol;
        tokenSupplyCap = supplyCap;
    }

    // ============ Public Functions ============

    function symbol()
        public
        view
        returns (string memory)
    {
        return tokenSymbol;
    }

    function name()
        public
        view
        returns (string memory)
    {
        return tokenName;
    }

    function decimals()
        public
        virtual
        pure
        returns (uint8)
    {
        return 18;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return tokenSupply;
    }

    function supplyCap()
        public
        view
        returns (uint256)
    {
        return tokenSupplyCap;
    }

    function balanceOf(
        address who
    )
        public
        view returns (uint256)
    {
        return balances[who];
    }

    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    // ============ Internal Functions ============

    function _mint(address to, uint256 value) internal {
        console.log("mint(to: %s, value: %s)", to, value);

        require(to != address(0), "Cannot mint to zero address");
        require (tokenSupply.add(value) <= tokenSupplyCap, "Cannot exceed supply cap");

        balances[to] = balances[to].add(value);
        tokenSupply = tokenSupply.add(value);

        emit Transfer(address(this), address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        console.log("burn(from: %s, value: %s)", from, value);
        require(from != address(0), "Cannot burn to zero");

        balances[from] = balances[from].sub(value);
        tokenSupply = tokenSupply.sub(value);

        emit Transfer(address(this), from, address(0), value);
    }

    // ============ Token Functions ============

    function transfer(
        address to,
        uint256 value
    )
        public
        virtual
        returns (bool)
    {
        console.log("transfer(to: %s, value: %s)", to, value);

        if (balances[msg.sender] >= value) {
            balances[msg.sender] = balances[msg.sender].sub(value);
            balances[to] = balances[to].add(value);
            emit Transfer(address(this), msg.sender, to, value);
            console.log("transfer succeeded");
            return true;
        } else {
            console.log("transfer failed");
            return false;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        virtual
        returns (bool)
    {
        console.log(
            "transferFrom(from: %s, to: %s, value: %s",
            from,
            to,
            value
        );

        if (
            balances[from] >= value &&
            allowances[from][msg.sender] >= value
        ) {
            balances[to] = balances[to].add(value);
            balances[from] = balances[from].sub(value);
            allowances[from][msg.sender] = allowances[from][msg.sender].sub(
                value
            );
            emit Transfer(address(this), from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function approve(
        address spender,
        uint256 value
    )
        public
        returns (bool)
    {
        return _approve(msg.sender, spender, value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    )
        internal
        returns (bool)
    {
        console.log("approve(spender: %s, value: %s, sender: %s", spender, value, owner);

        allowances[owner][spender] = value;

        emit Approval(
            address(this),
            owner,
            spender,
            value
        );

        return true;
    }
}
