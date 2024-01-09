pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Receiver.sol";
// import "./console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract ERC1155_ is ERC1155 {
  bytes32 public immutable DOMAIN_SEPARATOR;
  mapping(address => uint256) public nonces;
  string public name = "Bad Trip";

  constructor(address to, string memory _uri)
  ERC1155(
        _uri
  )
  {
    uint256 chainId;
    assembly {
        chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(abi.encode(keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"), keccak256("BadTrip NFT"), keccak256("1"), chainId, address(this)));
    _mint(to, 0, 300, "");
  }
  // See https://eips.ethereum.org/EIPS/eip-191
  string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
  // keccak256("Permit(address owner,address spender,bool approved,uint256 nonce,uint256 deadline)");
  bytes32 private constant PERMIT_SIGNATURE_HASH = keccak256("Permit(address owner,address spender,bool approved,uint256 nonce,uint256 deadline)");

  function permit(
      address owner_,
      address spender,
      bool approved,
      uint256 deadline,
      uint8 v,
      bytes32 r,
      bytes32 s
  ) external {
      require(owner_ != address(0), "ERC1155: Owner cannot be 0");
      require(block.timestamp < deadline, "ERC1155: Expired");
      bytes32 digest =
          keccak256(
              abi.encodePacked(
                  EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                  DOMAIN_SEPARATOR,
                  keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, approved, nonces[owner_]++, deadline))
              )
          );
      address recoveredAddress = ecrecover(digest, v, r, s);
      require(recoveredAddress == owner_, "ERC1155: Invalid Signature");
      _setApprovalForAll(owner_, spender, approved);
  }
}

contract LSDHelper is ERC1155Receiver {
  IERC20 public immutable token;
  ERC1155_ public immutable nft;

  address BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  event PhysicalRedemption(address indexed redeemer, uint256 indexed amount);

  constructor(address _token, string memory _uri)
  {
    token = IERC20(_token);
    nft = new ERC1155_(address(this), _uri);
  }

  function redeem(uint256 amount) public {
    uint256 balance = token.balanceOf(msg.sender) / 10**18;
    require(amount <= balance, "Amount of redemption token less than token balance");
    require(balance > 0, "Balance of redemption token less than 1");
    token.transferFrom(msg.sender, BURN_ADDRESS, amount * 10**18);
    nft.safeTransferFrom(address(this), msg.sender, 0, amount, "");
    emit PhysicalRedemption(msg.sender, amount);
  }

  function permitAndRedeem(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amount
    ) external {
      token.permit(owner, spender, value, deadline, v, r, s);
      redeem(amount);
  }

  function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) override external pure returns (bytes4){
      return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  function onERC1155BatchReceived(
      address operator,
      address from,
      uint256[] calldata ids,
      uint256[] calldata values,
      bytes calldata data
  ) override external returns (bytes4){
  }
}