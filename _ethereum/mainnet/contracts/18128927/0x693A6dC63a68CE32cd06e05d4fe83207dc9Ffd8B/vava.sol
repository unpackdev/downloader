/**
 * 𝐕𝐀𝐕𝐀 𝐋𝐚𝐛𝐬
 * X: https://twitter.com/vava_labs
 * Website: https://vava-labs.com
 * Telegram: https://t.me/vavalabs
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract VAVA is ERC721A, Ownable {
    constructor() ERC721A("VAVA", "VAVA") {
        config = Config(7777, 100, 900000000000000, 0);
    }

    struct Config {
        uint256 maxSupply;
        uint256 maxMint;
        uint256 price;
        uint256 phase;
    }

    string public uri;
    uint public seed;
    Config public config;

    function buyVAVA(uint256 count) external payable {
        require(config.phase == 1, "Invalid phase.");
        
        _mint(count);
    }

    function forTeam(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= config.maxSupply, "");
        _safeMint(msg.sender, _quantity);
    }

    function _mint(uint256 count) private {
        uint256 pay = count * config.price;

        require(pay <= msg.value, "No enough Ether.");
        require(totalSupply() + count <= config.maxSupply, "Exceed maxmiumn.");
        require(
            _numberMinted(msg.sender) + count <= config.maxMint,
            "Cant mint more."
        );

        _safeMint(msg.sender, count);
    }

    function tokenURI(uint256 _id)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_id > 0 && _id <= totalSupply(), "Invalid token ID.");

        return string(abi.encodePacked(uri, shuffleIds(_id)));
    }

    function shuffleIds(uint256 _id) private view returns (string memory) {
        uint256 maxSupply = config.maxSupply;
        uint256[] memory temp = new uint256[](maxSupply + 1);

        for (uint256 i = 1; i <= maxSupply; i += 1) {
            temp[i] = i;
        }

        for (uint256 i = 1; i <= maxSupply; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(seed, i))) %
                (maxSupply)) + 1;

            (temp[i], temp[j]) = (temp[j], temp[i]);
        }

        return Strings.toString(temp[_id]);
    }

    function numberMinted(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }

    function tokensOfOwner(address owner)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function setSeed(uint _seed) external onlyOwner {
        seed = _seed;
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        require(max <= config.maxSupply, "invalid.");
        config.maxSupply = max;
    }

    function setURI(string calldata _uri) external onlyOwner {
        uri = _uri;
    }

    function setPrice(uint256 price) external onlyOwner {
        config.price = price;
    }

    function setPhase(uint256 phase) external onlyOwner {
        config.phase = phase;
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "error.");
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "");
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
}
