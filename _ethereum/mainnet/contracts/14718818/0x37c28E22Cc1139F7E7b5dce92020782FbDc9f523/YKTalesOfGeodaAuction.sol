// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";

contract YKTalesOfGeodaAuction is Ownable {
    using Address for address;
    using SafeMath for uint256;

    /**
    @notice Tracks total number of items sold by this contract.
    */
    address public paymentToken = 0x88a07dE49B1E97FdfeaCF76b42463453d48C17cD;
    address public inventoryCollection = 0x8250dD5F90116BeB0bD6ef647AE1A2C5081F7867;
    address public oracleAddress;
    /// @notice Emitted on end sale event.
    event EndSale(address indexed beneficiary, uint256 finalAmount);

    constructor() {}

    function setOracle(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }

    function setInventoryCollection(address _inventoryCollection) external onlyOwner {
        inventoryCollection = _inventoryCollection;
    }

    function setPaymentToken(address _paymentToken) external onlyOwner {
        paymentToken = _paymentToken;
    }

    function finalizeAuction(uint256 _tokenId, address _winner, uint256 _amount) public {
        require(msg.sender == owner() || msg.sender == oracleAddress, "finalizeAuction: invalid!");
        // transfer YOH
        require(IYohToken(paymentToken).transferFrom(_winner, owner(), _amount) == true, 'finalizeAuction: balance not enough?');

        InventoryCollectionInterface(inventoryCollection).transferFrom(address(this), _winner, _tokenId);

        emit EndSale(_winner, _amount);
    }

    function removeAllTokens() public onlyOwner {
        uint256[] memory tokenIds = InventoryCollectionInterface(inventoryCollection).tokensOfOwner(address(this));
        for(uint256 i = 0; i < tokenIds.length; i++){
            InventoryCollectionInterface(inventoryCollection).transferFrom(address(this), owner(), tokenIds[i]);
        }
    }

    /*
    function claimTokenId(uint256 _tokenId, uint256 _amount, bytes memory _signature) external whenNotPaused {
      string memory _message = string(abi.encodePacked(uint2str(_tokenId),",",uint2str(_amount),",",msg.sender));

      require(verify(_message, _signature) == oracleVerification, string(abi.encodePacked("claimTokenId: wrong message! ", _message)));

      // transfer YOH
      TransferHelper.safeTransferFrom(paymentToken, msg.sender, owner(), _amount);
      _handlePurchase(msg.sender, _tokenId);

      emit EndSale(msg.sender, _amount);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32){
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    // the output of this function will be the account number that signed the original message
    function verify(string memory message, bytes memory _signature) public pure returns (address) {
        bytes32 _ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(message))));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
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
    */
}



interface IYohToken {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface InventoryCollectionInterface {
  function transferFrom(address from, address to, uint256 tokenId) external;
  function tokensOfOwner(address owner) external view returns (uint256[] memory);
  //function ownerOf(uint256 tokenId) external view returns (address);
}
