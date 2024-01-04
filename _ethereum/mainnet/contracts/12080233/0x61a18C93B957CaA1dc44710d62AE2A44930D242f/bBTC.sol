pragma solidity 0.6.11;

import "./ERC20.sol";

import "./ICore.sol";
import "./IbBTC.sol";

contract bBTC is ERC20, IbBTC {
    address public immutable core;

    constructor(address _core)
        public
        ERC20("Interest-Bearing BTC", "ibBTC")
    {
        require(_core != address(0), "NULL_ADDRESS");
        core = _core;
    }

    modifier onlyCore() {
        require(msg.sender == core, "bBTC: NO_AUTH");
        _;
    }

    function mint(address account, uint amount) override external onlyCore {
        _mint(account, amount);
    }

    function burn(address account, uint amount) override external onlyCore {
        _burn(account, amount);
    }

    function getPricePerFullShare() external view returns (uint) {
        return ICore(core).getPricePerFullShare();
    }
}
