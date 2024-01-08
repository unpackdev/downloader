// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Include.sol";

contract ApprovedERC20 is ERC20UpgradeSafe, Configurable {
    address public operator;

    function __ApprovedERC20_init_unchained(address operator_) public governance {
        operator = operator_;
    }

    modifier onlyOperator {
        require(msg.sender == operator, 'called only by operator');
        _;
    }

    function transferFrom_(address sender, address recipient, uint256 amount) external onlyOperator returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
}

contract MintableERC20 is ApprovedERC20 {
    function mint_(address acct, uint amt) external onlyOperator {
        _mint(acct, amt);
    }

    function burn_(address acct, uint amt) external onlyOperator {
        _burn(acct, amt);
    }
}

contract ONE is MintableERC20 {
    function __ONE_init(address governor_, address vault_, address oneMine) external initializer {
        __Context_init_unchained();
        __ERC20_init_unchained("One Eth", "ONE");
        __Governable_init_unchained(governor_);
        __ApprovedERC20_init_unchained(vault_);
        __ONE_init_unchained(oneMine);
    }

    function __ONE_init_unchained(address oneMine) public governance {
        _mint(oneMine, 100 * 10 ** uint256(decimals()));
    }

}

contract ONS is ApprovedERC20 {
    function __ONS_init(address governor_, address oneMinter_, address onsMine, address offering, address timelock) external initializer {
        __Context_init_unchained();
        __ERC20_init("One Share", "ONS");
        __Governable_init_unchained(governor_);
        __ApprovedERC20_init_unchained(oneMinter_);
        __ONS_init_unchained(onsMine, offering, timelock);
    }

    function __ONS_init_unchained(address onsMine, address offering, address timelock) public governance {
        _mint(onsMine, 90000 * 10 ** uint256(decimals()));		// 90%
        _mint(offering, 5000 * 10 ** uint256(decimals()));		//  5%
        _mint(timelock, 5000 * 10 ** uint256(decimals()));		//  5%
    }

}

contract ONB is MintableERC20 {
    function __ONB_init(address governor_, address vault_) virtual external initializer {
        __Context_init_unchained();
        __ERC20_init("One Bond", "ONB");
        __Governable_init_unchained(governor_);
        __ApprovedERC20_init_unchained(vault_);
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
        require(from == address(0) || to == address(0), 'ONB is untransferable');
    }
}

contract Offering is Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bytes32 internal constant _quota_      = 'quota';
    bytes32 internal _quota_0              = '';            // placeholder

    IERC20 public token;
    IERC20 public currency;
    uint public price;
    address public vault;
    uint public begin;
    uint public span;
    mapping (address => uint) public offeredOf;

    function __Offering_init(address governor_, address _token, address _currency, uint _price, uint _quota, address _vault, uint _begin, uint _span) external initializer {
        __Governable_init_unchained(governor_);
        __Offering_init_unchained(_token, _currency, _price, _quota, _vault, _begin, _span);
    }

    function __Offering_init_unchained(address _token, address _currency, uint _price, uint _quota, address _vault, uint _begin, uint _span) public governance {
        token = IERC20(_token);
        currency = IERC20(_currency);
        price = _price;
        vault = _vault;
        begin = _begin;
        span = _span;
        config[_quota_] = _quota;
    }

    function offer(uint vol) external {
        require(now >= begin, 'Not begin');
        if(now > begin.add(span))
            if(token.balanceOf(address(this)) > 0)
                token.safeTransfer(vault, token.balanceOf(address(this)));
            else
                revert('offer over');
        require(offeredOf[msg.sender] < config[_quota_], 'out of quota');
        vol = Math.min(Math.min(vol, config[_quota_].sub(offeredOf[msg.sender])), token.balanceOf(address(this)));
        offeredOf[msg.sender] = offeredOf[msg.sender].add(vol);
        uint amt = vol.mul(price).div(1e18);
        currency.safeTransferFrom(msg.sender, address(this), amt);
        currency.approve(vault, amt);
        IVault(vault).receiveAEthFrom(address(this), amt);
        token.safeTransfer(msg.sender, vol);
    }
}

interface IVault {
    function receiveAEthFrom(address from, uint vol) external;
}

contract Timelock is Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public token;
    address public recipient;
    uint public begin;
    uint public span;
    uint public times;
    uint public total;

    function start(address _token, address _recipient, uint _begin, uint _span, uint _times) external governance {
        require(address(token) == address(0), 'already start');
        token = IERC20(_token);
        recipient = _recipient;
        begin = _begin;
        span = _span;
        times = _times;
        total = token.balanceOf(address(this));
    }

    function unlockCapacity() public view returns (uint) {
        if(begin == 0 || now < begin)
            return 0;

        for(uint i=1; i<=times; i++)
            if(now < span.mul(i).div(times).add(begin))
                return token.balanceOf(address(this)).sub(total.mul(times.sub(i)).div(times));

        return token.balanceOf(address(this));
    }

    function unlock() public {
        token.safeTransfer(recipient, unlockCapacity());
    }

    fallback() external {
        unlock();
    }
}
