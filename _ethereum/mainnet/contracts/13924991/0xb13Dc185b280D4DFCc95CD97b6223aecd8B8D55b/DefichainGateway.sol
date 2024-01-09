// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./Initializable.sol";
import "./ECDSAUpgradeable.sol";

interface ERC20Defi {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract DefichainGateway is Initializable{
  using ECDSAUpgradeable for bytes32;
  
  address public owner;
  bytes1 parity;
  address signer;
  address last_signer;
  uint nonce;
  mapping(string => address) public supported_bridges;
  mapping(bytes => bool) public spent_outputs;

  event DepositToDefichain(address _from, string indexed _to, string bridge, uint _value, uint indexed extradata);

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function transferOwnership(address new_owner) external restricted {
      owner = new_owner;
  }

  function addNewToken(string memory name, address tokenAddress) external restricted {
      supported_bridges[name] = tokenAddress;
  }

  function removeToken(string memory name) external restricted {
      supported_bridges[name] = address(0);
  }

  function haveBridge(string memory bridge) public view returns (bool){
    if (supported_bridges[bridge] == address(0)) return false;
    return true;
  }

  function messageToSign(address targetAddress, string memory txid, uint n, uint amount, string memory bridge) public pure returns(bytes memory){
      
      bytes memory s = abi.encodePacked("{\"address\":\"0x", toAsciiString(targetAddress), "\",\"chain\":\"ETH\",\"bridge\":\"", bridge, "\",\"txid\":\"", txid , "\",\"n\":", uint2str(n), ",\"amount\":", uint2str(amount), "}");

      return s;
  }

  function hashToSign(address targetAddress, string memory txid, uint n, uint amount, string memory bridge) public pure returns(bytes32){
      
      bytes memory s = messageToSign(targetAddress, txid, n, amount, bridge);
      bytes32 hash = sha256(s);
      return hash;
  }

  function burnToken(string memory targetAddress, string memory bridge, uint amount) public returns (uint) {
      require(haveBridge(bridge), "bridge is not supported");
      address token = supported_bridges[bridge];

      ERC20Defi(token).burn(msg.sender, amount);
      uint reducedPrecision = reducePrecision(amount);
      nonce = nonce + 1; // every burn gets unique ID
      emit DepositToDefichain(msg.sender, targetAddress, bridge, reducedPrecision, nonce);
      return nonce;

  }
  function whoSignedThis(address targetAddress, string memory txid, uint n, uint amount, string memory bridge, bytes32 signature_r, bytes32 signature_s, uint8 signature_v) public pure returns (address){
      bytes memory preimage = messageToSign(targetAddress, txid, n, amount, bridge);
      bytes32 hash = sha256(preimage);
      address message_signer = hash.recover(signature_v, signature_r, signature_s);
      return message_signer;
  }

  function mintToken(address targetAddress, string memory txid, uint n, uint amount, string memory bridge, bytes32 signature_r, bytes32 signature_s, uint8 signature_v) external {
      require(haveBridge(bridge), "bridge is not supported");
      require(spent_outputs[abi.encodePacked(txid,n)] == false, "utxo already minted");

      address token = supported_bridges[bridge];

      address message_signer = whoSignedThis(targetAddress, txid, n, amount, bridge, signature_r, signature_s, signature_v);

      require(signer == message_signer || last_signer == message_signer, "wrong signer");

      ERC20Defi(token).mint(targetAddress, precisionRebase(amount));
      spent_outputs[abi.encodePacked(txid,n)] = true;
  }

  function initialize_gateway(address in_signer) public initializer {
    owner = msg.sender;
    signer = in_signer;
    last_signer = in_signer;
    nonce = 0;
  }

  function newSigner(address new_signer) external {
      require(msg.sender == signer, "only signer can nominate new signer");
      last_signer = signer;
      signer = new_signer;
  }

  function precisionRebase(uint amount) public pure returns (uint) {
      uint rebased = amount * 10e10;
      require(rebased > amount, "overflow");
      return rebased;
  }
  function reducePrecision(uint amount) public pure returns (uint) {
      uint rebased = amount / 10e10;
      require(rebased < amount, "unterflow");
      return rebased;
  }
function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
}

function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
}

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
