// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "./ERC721.sol";
import "./SummerMoments.sol";
import "./iERC998ERC721TopDown.sol";

contract Summer is ERC721, iERC998ERC721TopDown {

    using Strings for uint256;

    SummerMoments public moments;
    uint16 public currentMomentId = 1;
    uint256 public constant SUMMER_TOKEN_ID = 0;

    constructor(address moments_) ERC721("Summer", "SUMMER") {
        _mint(owner(), SUMMER_TOKEN_ID);
        moments = SummerMoments(moments_);
    }

    function getMoment() external {
        require(moments.balanceOf(address(this)) > 0, "Summer: No moments is owned");
        Summer(address(this)).safeTransferChild(SUMMER_TOKEN_ID, msg.sender, address(moments), currentMomentId++);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(moments.totalSupply() > 0, "Summer: Moments are not minted yet");
        require(_exists(tokenId), "Summer: URI query for nonexistent token");

        uint256 id = currentMomentId <= moments.totalSupply() ? currentMomentId : SUMMER_TOKEN_ID;
        return string(abi.encodePacked("https://ipfs.io/ipfs/QmSnsb5vUhhXWbPjgAFyGQUpTrGv2H6HixotzJxTgmBxB7/", id.toString(), ".json"));
    }
    
    function owner() public view virtual returns(address) {
        return IERC721(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85).ownerOf(46115204191989145517182997463894886476175430296292312167639913498843229671398);
    }

    ///////////////////////////////////
    /// ERC998ERC721TopDown implementations
    ///////////////////////////////////
    bytes32 constant ERC998_MAGIC_VALUE = 0x00000000000000000000000000000000000000000000000000000000cd740db5;

    function rootOwnerOf(uint256 _tokenId) public view override returns (bytes32 rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) public view override returns (bytes32 rootOwner) {
        address rootOwnerAddress;
        if (_childContract != address(0)) {
            (rootOwner, _childTokenId) = ownerOfChild(_childContract, _childTokenId);
            rootOwnerAddress = address(uint160(uint256(rootOwner)));
        } else {
            rootOwnerAddress = ownerOf(_childTokenId);
        }
        while (rootOwnerAddress == address(this)) {
            (rootOwner, _childTokenId) = ownerOfChild(rootOwnerAddress, _childTokenId);
            rootOwnerAddress = address(uint160(uint256(rootOwner)));
        }
        (bool success, bytes memory data) = rootOwnerAddress.staticcall(abi.encodeWithSelector(0xed81cdda, address(this), _childTokenId));
        if (data.length != 0) { rootOwner = abi.decode(data, (bytes32)); }
        if(success && rootOwner >> 224 == ERC998_MAGIC_VALUE) { 
            return rootOwner; 
        } else { 
            return ERC998_MAGIC_VALUE << 224 | bytes32(uint256(uint160(rootOwnerAddress))); 
        }
    } 

    function ownerOfChild(address _childContract, uint256 _childTokenId) public view override returns (bytes32 parentTokenOwner, uint256 parentTokenId) {
        require(_childContract == address(moments), "Summer: Non moment address is given");
        address childOwner = moments.ownerOf(_childTokenId);
        require(childOwner == address(this) && _childTokenId >= currentMomentId, "Summer: Child token is not owned by token of this contract");
        return (ERC998_MAGIC_VALUE << 224 | bytes32(uint256(uint160(ownerOf(SUMMER_TOKEN_ID)))), SUMMER_TOKEN_ID);
    }
    
    function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes memory _data) external override returns(bytes4) { revert("disabled"); }
    function transferChild(uint256 _fromTokenId,address _to, address _childContract, uint256 _childTokenId) external override { revert("disabled"); }

    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external override { 
        require(msg.sender == address(this), "Summer: Only contract itself is able to transfer");
        require(_fromTokenId == SUMMER_TOKEN_ID, "Summer: Invalid token id is given");
        address rootOwner = address(uint160(uint256(rootOwnerOf(SUMMER_TOKEN_ID))));
        require(msg.sender == rootOwner || isApprovedForAll(rootOwner, msg.sender) || getApproved(SUMMER_TOKEN_ID) == msg.sender, "Summer: not an owner nor not approved");
        moments.safeTransferFrom(address(this), _to, _childTokenId, "");
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }
    
    function safeTransferChild(uint256 _fromTokenId,address _to, address _childContract, uint256 _childTokenId, bytes memory _data) external override { revert("disabled"); }
    function transferChildToParent(uint256 _fromTokenId, address _toContract, uint256 _toTokenId, address _childContract, uint256 _childTokenId, bytes memory _data) external override { revert("disabled"); }
    function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external override { revert("disabled"); }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(iERC998ERC721TopDown).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}
