// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./Address.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "./Ownable.sol";
import "./BytesLib.sol";
import "./base64.sol";

interface IPunksOnChain {
  function punkImageSvg(uint16) external view returns (string calldata);
  function punkAttributes(uint16) external view returns (string calldata);
}

interface IERC2981 {
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

contract LegitimatePhunks is ERC165, IERC2981, IERC1155MetadataURI, Ownable {
  using Address for address;
  using BytesLib for bytes;
  using Strings for uint256;

  string public constant name = "Legitimate Phunks";
  string public constant symbol = "LEGIT-PHUNK";
  uint256 private constant mintPrice = 0.01 ether;
  address private constant outerpockets = 0xcB4B6bd8271B4f5F81d46CbC563ae9e4F97B5a37;
  address private constant punksOnChainData = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;

  mapping(address => mapping(address => bool)) private operatorApprovals;
  mapping(uint256 => address) public ownerOf;

  constructor() {
    transferOwnership(outerpockets);
  }
  
  function supportsInterface(bytes4 _interfaceId) public view override(ERC165, IERC165) returns (bool) {
    return
      _interfaceId == type(IERC1155).interfaceId ||
      _interfaceId == type(IERC1155MetadataURI).interfaceId ||
      _interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
    return (
      owner(),
      _salePrice * 500 / 10000
    );
  }

  /// @notice Mint price is 0.01 ETH
  function mint(uint256 _tokenId) external payable {
    require(msg.value == mintPrice, "INSUFFICIENT ETH SENT");
    require(!exists(_tokenId), "TOKEN ID ALREADY EXISTS");
    ownerOf[_tokenId] = msg.sender;
    emit TransferSingle(msg.sender, address(0), msg.sender, _tokenId, 1);
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(owner()), address(this).balance);
  }

  // 1155

  function balanceOf(address _account, uint256 _tokenId) public view override returns (uint256) {
    address owner = ownerOf[_tokenId];
    require(exists(_tokenId), "TOKEN DOESN'T EXIST");
    return  owner == _account ? 1 : 0;
  }

  function balanceOfBatch(
    address[] calldata _accounts,
    uint256[] calldata _tokenIds
  ) public view override returns (uint256[] memory) {
    require(
      _accounts.length == _tokenIds.length,
      "ARRAYS NOT SAME LENGTH"
    );
    uint256[] memory batchBalances = new uint256[](_accounts.length);
    for (uint256 i = 0; i < _accounts.length; ++i) {
      batchBalances[i] = balanceOf(_accounts[i], _tokenIds[i]);
    }
    return batchBalances;
  }
  
  function exists(uint256 _tokenId) public view returns (bool) {
    return ownerOf[_tokenId] != address(0);
  }

  function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external {
    safeTransferFrom(_from, _to, _tokenId, 1, _data);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    bytes calldata _data
  ) public override {
    require(_to != address(0), "INVALID RECEIVER");
    require(
      _from == msg.sender || isApprovedForAll(_from, msg.sender),
      "NOT AUTHED"
    );
    require(
        _amount == 1 && ownerOf[_tokenId] == _from,
        "INVALID SENDER"
    );
    ownerOf[_tokenId] = _to;
    emit TransferSingle(msg.sender, _from, _to, _tokenId, 1);
    _safeTransferCheck(msg.sender, _from, _to, _tokenId, 1, _data);
  }

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) public override {
    uint256 length = _tokenIds.length;
    require(
      length == _amounts.length,
      "ARRAYS NOT SAME LENGTH"
    );
    require(_to != address(0), "INVALID RECEIVER");
    require(
      _from == msg.sender || isApprovedForAll(_from, msg.sender),
      "NOT AUTHED"
    );

    for (uint256 i = 0; i < length; ++i) {
      uint256 id = _tokenIds[i];
      require(
        _amounts[i] == 1 && ownerOf[id] == _from,
        "INVALID SENDER"
      );
      ownerOf[id] = _to;
    }
    
    emit TransferBatch(msg.sender, _from, _to, _tokenIds, _amounts);

    _safeBatchTransferCheck(
      msg.sender,
      _from,
      _to,
      _tokenIds,
      _amounts,
      _data
    );
  }

  function setApprovalForAll(address _operator, bool _approved) public override {
    require(msg.sender != _operator, "CAN'T APPROVE SELF");
    operatorApprovals[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function uri(uint256 _tokenId) external view returns (string memory) {
    bytes memory slices;
    bytes memory attributeString = bytes(
      IPunksOnChain(punksOnChainData).punkAttributes(uint16(_tokenId))
    );

    uint256 attributeCount;
    uint256 leftCursor;
    uint256 rightCursor;

    for(uint256 i; i<attributeString.length; ++i) {
      ++rightCursor;
      if (
        attributeString[i] == bytes1(0x2C)
        || i == attributeString.length - 1
      ) {
        slices = slices.concat(attributeCount != 0
          ? _generateAccessoryProp(
            attributeString.slice(
              leftCursor + 1,
              i == attributeString.length - 1 ?
              rightCursor - 1 : rightCursor - 2
            )
          )
          : _generateTypeProp(
            attributeString.slice(
              leftCursor,
              attributeString[leftCursor] == bytes1(0x4D)
                || attributeString[leftCursor] == bytes1(0x46)
                ? rightCursor - 3 : rightCursor - 1
          )
          )
        );
        leftCursor = i + 1;
        rightCursor = 0;
        ++attributeCount;
      }
    }
    
    bytes memory attributesList = abi.encodePacked(
      '"attributes":[',
        slices,
        '{'
          '"trait_type": "accessory",'
          '"value": "', (attributeCount-1).toString(), ' Attributes"'
        '}'
      '],'
    );

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(abi.encodePacked(
        '{'
          '"name": "Phunk #', _tokenId.toString(), '",'
          '"background_color": "638596",',
          attributesList,
          '"image": "', _encodeSvg(IPunksOnChain(punksOnChainData).punkImageSvg(uint16(_tokenId))), '"'
        '}'
      ))
    ));
  }

  function _encodeSvg(string memory _svg) private pure returns (bytes memory) {
    bytes memory svg = bytes(_svg);
    svg = svg.slice(28, svg.length-28);
    svg = bytes('<svg transform="scale(-1, 1)"').concat(svg);
    svg = bytes(Base64.encode(svg));
    return bytes('data:image/svg+xml;base64,').concat(svg);
  }

  function _generateAccessoryProp(bytes memory _accessory) private pure returns (bytes memory) {
    return abi.encodePacked(
      '{'
        '"trait_type": "accessory",'
        '"value": "', _accessory, '"'
      '},'
    );
  }

  function _generateTypeProp(bytes memory _type) private pure returns (bytes memory) {
    return abi.encodePacked(
      '{'
        '"trait_type": "type",'
        '"value": "', _type, '"'
      '},'
    );
  }

  function _safeTransferCheck(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    bytes calldata _data
  ) private {
    if (_to.isContract()) {
      try
        IERC1155Receiver(_to).onERC1155Received(
          _operator,
          _from,
          _tokenId,
          _amount,
          _data
        )
      returns (bytes4 response) {
        if (
          response != IERC1155Receiver(_to).onERC1155Received.selector
        ) {
          revert("INVALID RECEIVER");
        }
      } catch Error(string memory reason) {
          revert(reason);
      } catch {
          revert("INVALID RECEIVER");
      }
    }
  }

  function _safeBatchTransferCheck(
    address _operator,
    address _from,
    address _to,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) private {
    if (_to.isContract()) {
      try
        IERC1155Receiver(_to).onERC1155BatchReceived(
          _operator,
          _from,
          _tokenIds,
          _amounts,
          _data
        )
      returns (bytes4 response) {
        if (
          response != IERC1155Receiver(_to).onERC1155BatchReceived.selector
        ) {
          revert("INVALID RECEIVER");
        }
      } catch Error(string memory reason) {
          revert(reason);
      } catch {
          revert("INVALID RECEIVER");
      }
    }
  }
}