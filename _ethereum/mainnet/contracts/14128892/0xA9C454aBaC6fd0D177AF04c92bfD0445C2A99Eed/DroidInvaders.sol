// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

interface IStardust {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

contract DroidInvaders is ERC721Enumerable, Ownable {
  string public baseURI;

  address public proxyRegistryAddress;
  address public verifier;

  uint256 public constant PRICE = 250 ether;
  uint256 public constant MAX_SUPPLY = 7500;

  mapping(address => bool) public projectProxy;
  mapping(address => uint256) public mintedByWallet;

  bool public paused = true;

  IStardust private stardustContract;

  constructor(
    string memory _baseURI,
    address _proxyRegistryAddress,
    address _stardustContract
  ) ERC721("Droid Invaders", "DI") {
    baseURI = _baseURI;
    proxyRegistryAddress = _proxyRegistryAddress;
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

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setVerifier(address _newVerifier) public onlyOwner {
    verifier = _newVerifier;
  }

  function setStardustAddress(address _stardustContract) public onlyOwner {
    stardustContract = IStardust(_stardustContract);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(_tokenId), "Token does not exist");

    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress)
    external
    onlyOwner
  {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function flipProxyState(address _proxyAddress) public onlyOwner {
    projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function mintWithStardust() external {
    uint256 totalSupply = _owners.length;

    require(!paused, "Minting paused");
    require(totalSupply < MAX_SUPPLY, "Excedes max supply");

    stardustContract.transferFrom(
      _msgSender(),
      address(stardustContract),
      PRICE
    );

    _mint(_msgSender(), totalSupply);
  }

  function mintWithClaimableStardust(uint256 _count, bytes calldata _signature)
    external
  {
    address signer = _recoverWallet(_msgSender(), _count, _signature);

    require(signer == verifier, "Unverified transaction");

    uint256 totalSupply = _owners.length;

    require(!paused, "Minting paused");
    require(totalSupply < MAX_SUPPLY, "Excedes max supply");
    require(mintedByWallet[_msgSender()] < _count, "Invalid mint count");

    mintedByWallet[_msgSender()] = _count;

    _mint(_msgSender(), totalSupply);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
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

  function batchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds
  ) public {
    for (uint256 i; i < _tokenIds.length; i++) {
      transferFrom(_from, _to, _tokenIds[i]);
    }
  }

  function batchSafeTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    bytes memory _data
  ) public {
    for (uint256 i; i < _tokenIds.length; i++) {
      safeTransferFrom(_from, _to, _tokenIds[i], _data);
    }
  }

  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool)
  {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
      proxyRegistryAddress
    );

    if (
      address(proxyRegistry.proxies(_owner)) == _operator ||
      projectProxy[_operator]
    ) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }

  function _mint(address _to, uint256 _tokenId) internal virtual override {
    _owners.push(_to);

    emit Transfer(address(0), _to, _tokenId);
  }

  function withdraw() public onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw unsuccessful"
    );
  }
}

// solhint-disable-next-line no-empty-blocks
contract OwnableDelegateProxy {

}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}
