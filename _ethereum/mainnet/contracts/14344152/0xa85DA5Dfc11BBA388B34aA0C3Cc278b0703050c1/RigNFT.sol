// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

contract RigNFT is ERC721, ERC721Enumerable, ERC721URIStorage {
    address immutable private creator;
    constructor() ERC721("RigNFT","RIG"){
        creator = msg.sender;
    }
    event Log (string message);
    event PermanentURI(string _value, uint256 indexed _id);
    struct Rig {
        uint power;
        uint period;
    }
    //store each created id in an array for enumeration
    uint256 [] private rigIds;
    mapping(uint256 => Rig) rigs;
    function safeMint(uint256 tokenId) public {

        string memory id = toString(tokenId);
        string memory url = append("ipfs://QmR6f6zhLNfsE6upkZkJCeuSSw2SJosy3Z6aJgAC5DQFfU/", id);
        //5000 rig cap
        require(rigIds.length < 5000, "Oops. There will only ever be 5000 Rigs and they've all been created. All future attemtps to create more Rigs will fail and result in the loss of gas.");
        require(tokenId >= 1 && tokenId <=5000, "The ID range is 1 - 5000. You entered a value outside of this range. Try again!");
        //public rigs
        if (tokenId <= 4500) {
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, url);
            emit PermanentURI(url, tokenId);
            rigs[tokenId].period = random(7) * 1 days;
            rigs[tokenId].power = random(50);
            rigIds.push(tokenId);
        //creator rigs
        } else if (tokenId >=4501 && tokenId <= 5000) {
            require(msg.sender == creator, "Only the creator can mint these.");
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, url);
            emit PermanentURI(url, tokenId);
            rigs[tokenId].period = random(3) * 1 days;
            rigs[tokenId].power = random(30);
            rigIds.push(tokenId);
        } else {
            revert("Something went wrong");
        }
    }
    function periodOf(uint256 id) public view returns (uint) {
        return rigs[id].period;
    }

    function powerOf(uint256 id) public view returns (uint) {
        return rigs[id].power;
    }
    function existingRigs() public view returns (uint256[] memory) {
        return rigIds;
    }
    function existingRigsTotal() public view returns (uint) {
        return rigIds.length;
    }
    /*
    *
    * @notice please read deeper into the following for more info.
    *
    * The current block timestamp must be strictly larger than the
    * timestamp of the last block, but the only guarantee is that
    * it will be somewhere between the timestamps of two consecutive
    * blocks in the canonical chain.
    * https://docs.soliditylang.org/en/latest/units-and-global-variables.html?highlight=block.timestamp
    */
    function random(uint number) private view returns (uint) {
        uint i = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % number;
        return i >= 1 ? i : 1;
    }
    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
