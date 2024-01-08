//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Initializable.sol";

// https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
interface IWETH {
  function deposit() payable external;
  function balanceOf(address guy) external returns (uint256);
  function approve(address guy, uint256 wad) external returns (bool);
}

// https://etherscan.io/address/0x2147935d9739da4e691b8ae2e1437492a394ebf5
interface IUbiVault {
  function deposit(uint256 wethAmount) external returns (uint256);
  function withdraw() external returns (uint256);
}

/**
  To deposit, simply send ETH to the contract address. The ETH will collect
  in the contract until anyone calls the deposit() function to put the ETH
  into the vault. Only the admin can call withdraw(), this is needed for
  rare vault maintenance.
 */
contract UbiVaultFund is Initializable {
  IWETH public weth;
  IUbiVault public ubiVault;
  address public admin;

  modifier onlyByAdmin() {
    require(admin == msg.sender, "The caller is not the admin.");
    _;
  }

  // This contract is upgradeable but should be managed by the same entity that governs the UBI
  // contract and only should be modified by UIP.
  function initialize(address _admin, IWETH _weth, IUbiVault _ubiVault) public initializer {
    weth = _weth;
    ubiVault = _ubiVault;
    admin = _admin;
    weth.approve(address(ubiVault), type(uint256).max);
  }

  // Allows ETH to be sent to the contract.
  receive() external payable {}

  // Anyone can call this to gas a deposit when enough ETH has collected in the contract.
  function deposit() public {
    uint256 ethBalance = address(this).balance;
    if (ethBalance > 0) {
      (bool success, ) = address(weth).call{value: ethBalance}(abi.encodeWithSignature("deposit()"));
      require(success, "Failed to convert to WETH");
    }
    uint256 wethBalance = weth.balanceOf(address(this));
    require(wethBalance > 0, "No WETH to deposit.");
    ubiVault.deposit(wethBalance);
  }

  // The admin can use this method as part of rare vault maintenance.
  // Note: this withdraws from the vault to the contract, not to the caller.
  function withdraw() public onlyByAdmin {
    ubiVault.withdraw();
  }

  function setAdmin(address _admin) public onlyByAdmin {
    admin = _admin;
  }

  function setUbiVault(IUbiVault _ubiVault) public onlyByAdmin {
    ubiVault = _ubiVault;
  }
}
