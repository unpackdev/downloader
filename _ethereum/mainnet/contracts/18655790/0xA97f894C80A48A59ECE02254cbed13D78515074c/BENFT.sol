// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./MessageHashUtils.sol";
import "./ECDSA.sol";

contract BLOXESTATE_MARKETPLACE is ERC721, Ownable, ReentrancyGuard {
    using Address for address;

    struct rentData {
        address lastTenant;
        uint256 endOfLeaseTime;
    }

    address private authorizedSigner;
    address public tokenAddress;
    uint256 public rentDuration;
    string public uri;

    mapping(uint256 propId => rentData) public rentStatus; 
    
    error SafeERC20FailedOperation(address token);

    constructor(string memory _name, string memory _symbol, address _signer, address _tokenAddress, uint256 _rentDuration, string memory _uri)
        ERC721(_name, _symbol)
        Ownable(_msgSender())
    {
        uri = _uri;
        rentDuration = _rentDuration;
        authorizedSigner = _signer;
        tokenAddress = _tokenAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function _convertToBytes(string memory message) private pure returns (bytes memory) {
        return bytes(abi.encodePacked(message));
    }

    function _convertToString(bytes memory message) private pure returns (string memory) {
        return string(abi.encodePacked(message));
    }

    function _verify(bytes memory data, uint256 value, bytes memory signature) private view returns (bool) {
        string memory dataString = _convertToString(data);
        string memory fullDataString = string.concat(dataString, "\"", Strings.toString(value), "\"}");
        bytes memory dataBytes = _convertToBytes(fullDataString);
        bytes32 dataHash = MessageHashUtils.toEthSignedMessageHash(dataBytes);
        address signer = ECDSA.recover(dataHash, signature);
        return signer == authorizedSigner;
    }

    function _safeTransferToken(address from, address to, uint256 value) private {
        bytes memory data;

        if (from == address(this)) {
            data = abi.encodeWithSignature("transfer(address,uint256)", to, value);
        } else {
            data = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value);
        }

        bytes memory returndata = tokenAddress.functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(tokenAddress);
        }
    }

    function buy(bytes memory data, uint256 value, uint256 tokenId, bytes memory signature) public nonReentrant {
        require(_verify(data, value, signature), "This transaction is not verified!");
        _safeTransferToken(_msgSender(), address(this), value);
        _safeMint(_msgSender(), tokenId);
    }

    function rent(bytes memory data, uint256 value, uint256 _propId, bytes memory signature) public nonReentrant {
        require(block.timestamp > rentStatus[_propId].endOfLeaseTime, "This property is still rented!");
        require(_verify(data, value, signature), "This transaction is not verified!");
        _safeTransferToken(_msgSender(), address(this), value);
        rentStatus[_propId].lastTenant = _msgSender();
        rentStatus[_propId].endOfLeaseTime = block.timestamp + rentDuration;
    }

    function changeAuthorizedSigner(address _signer) public onlyOwner {
        authorizedSigner = _signer;
    }

    function changeRentDuration(uint256 _rentDuration) public onlyOwner {
        rentDuration = _rentDuration;
    }

    function changeBaseURI(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function withdrawToken(uint256 value) public onlyOwner {
        _safeTransferToken(address(this), _msgSender(), value);
    }

    function withdrawEth(uint256 value) public onlyOwner {
        payable(_msgSender()).transfer(value);
    }
}