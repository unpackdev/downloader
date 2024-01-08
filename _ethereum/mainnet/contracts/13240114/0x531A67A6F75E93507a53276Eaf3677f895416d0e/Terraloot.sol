// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./TerralootSrc.sol";

contract Terraloot is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
    bytes32 internal hash;

    TerralootSrc internal terraloot;

    uint256 public constant TOTAL_SUPPLY = 10000;
    uint256 public constant OWNER_SUPPLY = 250;
    uint256 public constant PUBLIC_SUPPLY = TOTAL_SUPPLY - OWNER_SUPPLY;

    string internal constant INVALID_ID = "INVALID_ID";

    constructor(address _terraloot) ERC721("Terraloot", "TLOOT") {
        terraloot = TerralootSrc(_terraloot);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        return super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function contractURI() public pure returns (string memory) {
        return "https://terraloot.dev/contract.json";
    }

    function claim(uint256 _tokenId) public nonReentrant {
        require(!_exists(_tokenId), "ALREADY_MINTED");

        require(_tokenId < TOTAL_SUPPLY, INVALID_ID);

        require(totalSupply() < PUBLIC_SUPPLY, "SOLD_OUT");

        _safeMint(_msgSender(), _tokenId);

        if (totalSupply() == PUBLIC_SUPPLY) {
            uint256 rand = uint256(
                keccak256(
                    abi.encodePacked(
                        block.number,
                        block.basefee,
                        block.difficulty
                    )
                )
            );
            uint256 rewind = (rand % 200) + 1;
            hash = blockhash(block.number - rewind);
        }
    }

    function ownerClaim(uint256 _tokenId) public onlyOwner {
        require(totalSupply() >= PUBLIC_SUPPLY, "NO");
        require(_tokenId < TOTAL_SUPPLY, INVALID_ID);
        _safeMint(_msgSender(), _tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory prefix;

        if (_tokenId < 10) {
            prefix = "000";
        } else if (_tokenId < 100) {
            prefix = "00";
        } else if (_tokenId < 1000) {
            prefix = "0";
        }

        return
            terraloot.build(
                abi.encodePacked("TL:", prefix, Strings.toString(_tokenId)),
                random(_tokenId)
            );
    }

    function random(uint256 _tokenId) internal view returns (bytes32) {
        require(_tokenId < TOTAL_SUPPLY, INVALID_ID);
        return keccak256(abi.encodePacked(hash, _tokenId));
    }

    function synth(address _addr) public view returns (bytes32) {
        return keccak256(abi.encodePacked(hash, _addr));
    }

    function getOutfit(uint256 _tokenId) public view returns (string memory) {
        return terraloot.getOutfit(random(_tokenId));
    }

    function getOutfitComponents(uint256 _tokenId)
        public
        view
        returns (uint256[4] memory)
    {
        return terraloot.getOutfitComponents(random(_tokenId));
    }

    function getTool(uint256 _tokenId) public view returns (string memory) {
        return terraloot.getTool(random(_tokenId));
    }

    function getToolComponents(uint256 _tokenId)
        public
        view
        returns (uint256[4] memory)
    {
        return terraloot.getToolComponents(random(_tokenId));
    }

    function getHandheld(uint256 _tokenId) public view returns (string memory) {
        return terraloot.getHandheld(random(_tokenId));
    }

    function getHandheldComponents(uint256 _tokenId)
        public
        view
        returns (uint256[4] memory)
    {
        return terraloot.getHandheldComponents(random(_tokenId));
    }

    function getWearable(uint256 _tokenId) public view returns (string memory) {
        return terraloot.getWearable(random(_tokenId));
    }

    function getWearableComponents(uint256 _tokenId)
        public
        view
        returns (uint256[4] memory)
    {
        return terraloot.getWearableComponents(random(_tokenId));
    }

    function getShoulder(uint256 _tokenId) public view returns (string memory) {
        return terraloot.getShoulder(random(_tokenId));
    }

    function getShoulderComponents(uint256 _tokenId)
        public
        view
        returns (uint256[4] memory)
    {
        return terraloot.getShoulderComponents(random(_tokenId));
    }

    function getExternal(uint256 _tokenId) public view returns (string memory) {
        return terraloot.getExternal(random(_tokenId));
    }

    function getExternalComponents(uint256 _tokenId)
        public
        view
        returns (uint256[4] memory)
    {
        return terraloot.getExternalComponents(random(_tokenId));
    }

    function getBackpack(uint256 _tokenId) public view returns (string memory) {
        return terraloot.getBackpack(random(_tokenId));
    }

    function getBackpackComponents(uint256 _tokenId)
        public
        view
        returns (uint256[4] memory)
    {
        return terraloot.getBackpackComponents(random(_tokenId));
    }

    function getRig(uint256 _tokenId) public view returns (string memory) {
        return terraloot.getRig(random(_tokenId));
    }

    function getRigComponents(uint256 _tokenId)
        public
        view
        returns (uint256[4] memory)
    {
        return terraloot.getRigComponents(random(_tokenId));
    }
}
