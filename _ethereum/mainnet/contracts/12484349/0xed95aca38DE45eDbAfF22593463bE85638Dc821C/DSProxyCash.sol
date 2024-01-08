pragma solidity ^0.8.0;


import "./ERC20.sol";

interface IDSProxyFactory {
    function build() external returns (address payable);
}

interface IDSProxy {
    function setOwner(address) external;
}

contract DSProxyCash is ERC20 {

    address[] _proxies;

    IDSProxyFactory public _DSFactory;

    uint8 constant private _decimals = 18;
    uint256 supply;

    constructor(address _dsFactory) ERC20("DS-ProxyCash", "DS-Proxy") {
        _DSFactory = IDSProxyFactory(_dsFactory);
    }

    // Creates a child contract that can only be destroyed by this contract.
    function makeChild() internal returns (address payable) {
        return _DSFactory.build();
    }

    // mints new DSProxies and stores them to the proxy array
    function mint(uint256 _value) public {
        require(_value % 1e18 == 0);

        uint newTokens = _value / 1e18;

        for (uint256 i = 0; i < newTokens; i++) {
            address proxy = address(makeChild());
            _proxies.push(proxy);
        }
        _mint(msg.sender, _value);
    }

    function claim(address _newOwner) public returns (bool) {
        return _claim(_newOwner);
    }

    function claimFrom(address from, address _newOwner) public returns (bool claimed) {
        require(_claim(_newOwner), "DS-ProxyCash::claimFrom: unable to claim");
        _approve(from, _msgSender(), (allowance(from, _msgSender()) - 1e18));
        return true;
    }

    function _claim(address _newOwner) internal returns (bool success) {

        uint256 from_balance = balanceOf(msg.sender);

        if (from_balance < 1e18) {
            return false;
        }

        uint lastPos = _proxies.length - 1;

        address proxy = _proxies[lastPos];

        _proxies.pop();

        IDSProxy(proxy).setOwner(_newOwner);

        _burn(_msgSender(), 1e18);

        return true;
    }
}
