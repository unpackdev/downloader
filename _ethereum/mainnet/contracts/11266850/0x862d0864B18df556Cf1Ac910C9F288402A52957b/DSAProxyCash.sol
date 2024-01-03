pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";


interface IGST2 {
  function mint(uint256 value) external;
  function free(uint256 value) external returns (bool success);
}

interface IInstaIndex {
  function build(
    address _owner,
    uint accountVersion,
    address _origin
  ) external returns (address);
}

interface IRecord {
  function cast(
    address[] calldata _targets,
    bytes[] calldata _datas,
    address _origin
  ) external payable;
}

contract DSAProxyCash is ERC20 {

  address[] public proxies;

  address constant public connectAuth = address(0xB3242e09C8E5cE6E14296b3d3AbC4C6965F49b98);

  IInstaIndex constant public factory = IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

  IGST2 constant public gst2 = IGST2(0x0000000000b3F879cb30FE243b4Dfee438691c04);

  constructor() public ERC20("DSA-ProxyCash", "DSA") {}

  function mintProxy() internal returns (address) {
    return factory.build(address(this), 1, address(this));
  }

  // mints new Proxies and stores them to the proxy array
  function mint(uint256 _value) public {
    require(_value % 1e18 == 0);
    uint newTokens = _value / 1e18;
    for (uint256 i = 0; i < newTokens; i++) {
      address proxy = mintProxy();
      proxies.push(proxy);
      gst2.mint(_value);
    }
    _mint(_msgSender(), _value);
  }

  function claim() public returns (address payable proxy) {
    proxy = payable(_claim(_msgSender()));
  }

  function claimFor(address _newOwner) public returns (address payable proxy) {
    proxy = payable(_claim(_newOwner));
  }

  function _claim(address _newOwner) internal returns (address payable proxy) {
    gst2.free(1e18);
    uint256 from_balance = balanceOf(_msgSender());

    require(from_balance >= 1e18);

    uint lastPos = proxies.length - 1;

    proxy = payable(proxies[lastPos]);
    
    proxies.pop();

    address[] memory targets = new address[](2);

    targets[0] = connectAuth;
    targets[1] = connectAuth;

    bytes[] memory spells = new bytes[](2);

    spells[0] = abi.encodeWithSignature("add(address)", _newOwner);
    spells[1] = abi.encodeWithSignature("remove(address)", address(this));

    IRecord(proxy).cast(targets, spells, address(this));

    _burn(_msgSender(), 1e18);
  }
}