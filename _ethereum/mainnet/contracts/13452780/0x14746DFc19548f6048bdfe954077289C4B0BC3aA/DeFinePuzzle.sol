// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./DFA721NFT.sol";
import "./DFA1155NFT.sol";

contract DeFinePuzzle is IERC1155Receiver, Ownable {
    uint256 private nonce;
    uint256 private _counter = 1;
    address private _address721;
    address private _address1155;
    
    struct Box {
        uint256 types;
        uint256 price;
        uint256 totalCount;
        uint256 startTime;
    }

    constructor(address address721, address address1155) {
        _address721 = address721;
        _address1155 = address1155;
    }
    
    mapping (string => Box) Boxes;
    mapping (string => uint256) offsets;
    mapping (string => mapping (uint256 => uint256)) remainingTokens; // boxName -> types -> remaining_count
    
    function createBox(
        string memory boxName,
        uint256 types,
        uint256 price,
        uint256 totalCount,
        uint256 startTime) external onlyOwner {
            Box memory box = Box(types, price, totalCount, startTime);
            Boxes[boxName] = box;
        }
        
    function setCount(
        string memory boxName,
        uint256 types,
        uint256 amount) external onlyOwner {
            remainingTokens[boxName][types] = amount;
        }
        
    function setOffset(
        string memory boxName,
        uint256 offset) external onlyOwner {
            offsets[boxName] = offset;
        }
    
    function setCountBatch(string memory boxName, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < Boxes[boxName].types; i++) {
            remainingTokens[boxName][i] = amount;
        }
    }

    function set721Address(address _address) external onlyOwner {
        _address721 = _address;
    }

    function set1155Address(address _address) external onlyOwner {
        _address1155 = _address;
    }

    function rand(uint256 _range) internal returns (uint256) {
        uint256 _random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce))) % _range;
        nonce++;
        return _random;
    }
    
    function getIndex(string memory boxName, uint256 random) internal returns (uint256) {
        for (uint256 i = 0; i < (Boxes[boxName].types); i++) {
            if (random < remainingTokens[boxName][i]) {
                remainingTokens[boxName][i]--;
                return i;
            } else {
                random = random - remainingTokens[boxName][i];
            }
        }
    }
    
    function mintBox(string memory boxName, uint256 amount) public payable returns (uint256[] memory) {
        require(Boxes[boxName].types > 0, 'Box not exist');
        require(amount > 0, 'Must bigger than 0');
        require(Boxes[boxName].totalCount >= amount, 'insufficient boxes');
        require(msg.value >= amount * Boxes[boxName].price, 'insufficient funds.');
        require(Boxes[boxName].startTime < block.timestamp, 'mint not started.');
        uint256[] memory tokenIdList = new uint256[](amount);
        
        for (uint256 i = 0; i < amount; i++) {
            uint256 random = rand(Boxes[boxName].totalCount);
            uint256 index = getIndex(boxName, random) + offsets[boxName];
            (Boxes[boxName].totalCount)--;
            tokenIdList[i] = index;
            DFA1155NFT(_address1155).mint(msg.sender, index, 1, "");
        }
        
        emit Mint(msg.sender, boxName, amount, tokenIdList, _address1155);
        return tokenIdList;
    }
    
    function compound(string memory boxName) public returns (uint256) {
        require(Boxes[boxName].types > 0, 'Box is not exist');
        for (uint256 i = offsets[boxName]; i < (offsets[boxName] + Boxes[boxName].types); i++) {
            IERC1155(_address1155).safeTransferFrom(msg.sender, address(this), i, 1, "");
        }
        uint256 tokenId = DFA721NFT(_address721).mint(msg.sender);
        emit Compound(msg.sender, boxName, tokenId, _address721);
        return tokenId;
    }
    
    function getBoxInfo(string memory boxName) public view returns (Box memory) {
        return Boxes[boxName];
    }
    
    function getOffset(string memory boxName) public view returns (uint256) {
        return offsets[boxName];
    }
    
    function getRemainingTokens(string memory boxName, uint256 tokenId) public view returns (uint256) {
        uint256 types = tokenId - offsets[boxName];
        return remainingTokens[boxName][types];
    }
            
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }
    
    function emergencyWithdraw(address _payee, uint256 _amount) external onlyOwner {
        payable(_payee).transfer(_amount);
    }
    
    event Mint(address minter, string boxName, uint256 amount, uint256[] tokenIdList, address pieceAddress);
    event Compound(address operator, string boxName, uint256 tokenId, address nftAddress);
}