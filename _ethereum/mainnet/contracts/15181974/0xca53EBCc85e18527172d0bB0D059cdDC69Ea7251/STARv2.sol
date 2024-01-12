
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Address.sol";

import "./Delegated.sol";
import "./Signed.sol";

contract STARv2 is Delegated, ERC20, Signed {
  using Address for address;

  event StarClaimed(uint indexed claimId, address indexed to, uint256 value);

  struct ClaimData{
    uint256 claimId;
    uint256 value;
    uint256 deadline;
  }

  mapping(uint256 => bool) public claimed;

  constructor()
    Delegated()
    ERC20( "Star",  "STAR" )
    Signed( address(0) ){
  }

  function initialize() external onlyOwner {}

  receive() external payable {}

  function name() public view virtual override returns (string memory) {
    return "Star2";
  }

  function symbol() public view virtual override returns (string memory) {
    return "STAR2";
  }


  //
  function claim(bytes memory claimData, bytes calldata signature) external {
    ClaimData memory claim_ = abi.decode( claimData, (ClaimData));
    require(block.timestamp <= claim_.deadline, "ERC20Permit: expired deadline");
    require(_isAuthorizedSigner( claimData, signature ), "ERC20Permit: invalid signature");
    require(!claimed[ claim_.claimId ], "ERC20Permit: claim used" );

    claimed[ claim_.claimId ] = true;
    _mint(msg.sender, claim_.value);
    emit StarClaimed( claim_.claimId, msg.sender, claim_.value );
  }

  function transferOwnership(address newOwner) public override( Delegated, Ownable ) onlyOwner {
    Ownable.transferOwnership( newOwner );
  }

  function withdraw() external {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }

  function withdraw(address token) external {
    IERC20 erc20 = IERC20(token);
    erc20.transfer( owner(), erc20.balanceOf(address(this)) );
  }

  //delegated
  function burnFrom( address account, uint quantity ) external onlyDelegates{
    _burn( account, quantity );
  }

  function mintTo( address[] calldata accounts, uint[] calldata quantities ) external onlyDelegates{
    require( accounts.length == quantities.length, "equal counts required" );

    for(uint i; i < accounts.length; ++i ){
      _mint( accounts[i], quantities[i] );
    }
  }
}
