// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IERC721Receiver.sol";

interface IStardust {
  function withdraw(address _address, uint256 _amount) external;
}

interface IApeInvaders {
  function ownerOf(uint256 tokenId) external returns (address);

  function batchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds
  ) external;
}

contract Spaceport is Ownable, IERC721Receiver {
  IStardust private stardustContract;
  IApeInvaders private apeInvadersContract;

  address private verifier = address(0);

  mapping(address => uint256) public claimedStardust;
  mapping(address => uint256[]) internal stakedTokens;

  constructor(address _apeInvadersContract, address _stardustContract) {
    apeInvadersContract = IApeInvaders(_apeInvadersContract);
    stardustContract = IStardust(_stardustContract);
  }

  function _recoverWallet(
    address _wallet,
    uint256 _amount,
    bytes memory _signature
  ) internal pure returns (address) {
    return
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked(_wallet, _amount))
        ),
        _signature
      );
  }

  function claim(uint256 _amount, bytes calldata _signature) external {
    require(
      claimedStardust[_msgSender()] < _amount,
      "Invalid $Stardust amount"
    );

    address signer = _recoverWallet(_msgSender(), _amount, _signature);

    require(signer == verifier, "Unverified transaction");

    uint256 claimAmount = _amount - claimedStardust[_msgSender()];

    claimedStardust[_msgSender()] = _amount;
    stardustContract.withdraw(_msgSender(), claimAmount);
  }

  function unstake() external {
    apeInvadersContract.batchTransferFrom(
      address(this),
      _msgSender(),
      stakedTokens[_msgSender()]
    );

    delete stakedTokens[_msgSender()];
  }

  function setVerifier(address _newVerifier) public onlyOwner {
    verifier = _newVerifier;
  }

  function stakeOf(address _stakeholder)
    public
    view
    returns (uint256[] memory)
  {
    return stakedTokens[_stakeholder];
  }

  function onERC721Received(
    address,
    address,
    uint256 _tokenId,
    bytes memory
  ) public virtual override returns (bytes4) {
    // solhint-disable-next-line avoid-tx-origin
    stakedTokens[tx.origin].push(_tokenId);

    return this.onERC721Received.selector;
  }
}
