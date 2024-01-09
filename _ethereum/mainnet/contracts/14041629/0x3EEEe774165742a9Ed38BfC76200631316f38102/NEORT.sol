//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";

contract NEORT is
  ERC721,
  ERC721URIStorage,
  EIP712,
  ERC2981,
  Ownable,
  ReentrancyGuard
{
  using ECDSA for bytes32;

  string private _baseTokenURI;

  mapping(address => uint256) private _balances;

  struct MintParams {
    uint256 tokenId;
    uint256 amountInWei;
    uint256 feeInWei;
    uint256 artistBalanceInWei;
    address artistAddress;
    string metadataCid;
  }

  bytes32 private constant _TYPEHASH =
    keccak256(
      "MintParams(uint256 tokenId,uint256 amountInWei,uint256 feeInWei,uint256 artistBalanceInWei,address artistAddress,string metadataCid)"
    );

  constructor(string memory baseTokenURI)
    ERC721("NEORT", "NEORT")
    EIP712("NEORT", "1.0.0")
  {
    _baseTokenURI = baseTokenURI;
  }

  function verifyParams(MintParams calldata params, bytes calldata signature)
    public
    view
    returns (bool)
  {
    address signer = _hashTypedDataV4(
      keccak256(
        abi.encode(
          _TYPEHASH,
          params.tokenId,
          params.amountInWei,
          params.feeInWei,
          params.artistBalanceInWei,
          params.artistAddress,
          keccak256(bytes(params.metadataCid))
        )
      )
    ).recover(signature);
    return signer == owner();
  }

  function mint(
    address to,
    MintParams calldata params,
    bytes calldata signature
  ) external payable returns (uint256) {
    require(verifyParams(params, signature), "NEORT: Invalid signature");
    require(
      params.amountInWei == msg.value,
      "NEORT: Invalid amountInWei in params"
    );
    require(
      params.artistBalanceInWei + params.feeInWei == msg.value,
      "NEORT: Invalid artistBalanceInWei or feeInWei in params"
    );
    _safeMint(to, params.tokenId);
    _setTokenURI(params.tokenId, params.metadataCid);
    _setTokenRoyalty(params.tokenId, params.artistAddress);

    // set balance
    _balances[params.artistAddress] += params.artistBalanceInWei;
    _balances[owner()] += params.feeInWei;
    return params.tokenId;
  }

  function getBalance(address targetAddress) external view returns (uint256) {
    return _balances[targetAddress];
  }

  function withdraw() external nonReentrant returns (uint256) {
    require(_balances[msg.sender] > 0, "NEORT: No balance");
    address payable drawer = payable(msg.sender);
    drawer.transfer(_balances[drawer]);
    _balances[drawer] = 0;
    return _balances[drawer];
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
    _baseTokenURI = baseTokenURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
