// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./UUPSUpgradeable.sol";

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

contract SpaceportUpgradeable is OwnableUpgradeable, UUPSUpgradeable {
  IStardust private stardustContract;
  IApeInvaders private apeInvadersContract;

  address private verifier;

  mapping(address => uint256) public claimedStardust;

  address[] internal _owners;

  bool public allowStaking;
  bool public allowUnstaking;

  function initialize(address _apeInvadersContract, address _stardustContract)
    public
    initializer
  {
    __Ownable_init();
    apeInvadersContract = IApeInvaders(_apeInvadersContract);
    stardustContract = IStardust(_stardustContract);

    allowStaking = true;
    allowUnstaking = true;

    for (uint256 i; i < 5500; i++) {
      _owners.push(address(0));
    }
  }

  function _recoverWallet(
    address _wallet,
    uint256 _amount,
    bytes memory _signature
  ) internal pure returns (address) {
    return
      ECDSAUpgradeable.recover(
        ECDSAUpgradeable.toEthSignedMessageHash(
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

  function unstake(uint256[] calldata _tokenIds) external {
    require(allowUnstaking, "Unstaking paused");
    require(_tokenIds.length > 0, "tokenIds must not be empty");

    for (uint256 i; i < _tokenIds.length; i++) {
      require(ownerOf(_tokenIds[i]) == _msgSender(), "Not token owner");

      _owners[_tokenIds[i]] = address(0);
    }

    apeInvadersContract.batchTransferFrom(
      address(this),
      _msgSender(),
      _tokenIds
    );
  }

  function setVerifier(address _newVerifier) public onlyOwner {
    verifier = _newVerifier;
  }

  function stakeOf(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](0);
    }

    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function stake(uint256[] calldata _tokenIds) external {
    require(allowStaking, "Staking paused");
    require(_tokenIds.length > 0, "tokenIds must not be empty");

    for (uint256 i; i < _tokenIds.length; i++) {
      require(
        apeInvadersContract.ownerOf(_tokenIds[i]) == _msgSender(),
        "Not token owner"
      );

      _owners[_tokenIds[i]] = _msgSender();
    }

    apeInvadersContract.batchTransferFrom(
      _msgSender(),
      address(this),
      _tokenIds
    );
  }

  function balanceOf(address _owner) public view virtual returns (uint256) {
    require(_owner != address(0), "Zero address not allowed");

    uint256 count;

    for (uint256 i; i < _owners.length; ++i) {
      if (_owner == _owners[i]) {
        ++count;
      }
    }

    return count;
  }

  function ownerOf(uint256 _tokenId) public view virtual returns (address) {
    address owner = _owners[_tokenId];

    require(owner != address(0), "Token not staked");

    return owner;
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    public
    view
    virtual
    returns (uint256 _tokenId)
  {
    require(_index < balanceOf(_owner), "Owner index out of bounds");

    uint256 count;

    for (uint256 i; i < _owners.length; i++) {
      if (_owner == _owners[i]) {
        if (count == _index) {
          return i;
        } else {
          count++;
        }
      }
    }

    revert("Owner index out of bounds");
  }

  function flipAllowStaking() external onlyOwner {
    allowStaking = !allowStaking;
  }

  function flipAllowUnstaking() external onlyOwner {
    allowUnstaking = !allowUnstaking;
  }

  function setClaimedStardust(
    address[] memory _addresses,
    uint256[] memory _amounts
  ) external onlyOwner {
    require(
      _addresses.length == _amounts.length,
      "Missmatch addresses and amounts"
    );

    for (uint256 i; i < _addresses.length; i++) {
      claimedStardust[_addresses[i]] = _amounts[i];
    }
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {} // solhint-disable-line no-empty-blocks
}
