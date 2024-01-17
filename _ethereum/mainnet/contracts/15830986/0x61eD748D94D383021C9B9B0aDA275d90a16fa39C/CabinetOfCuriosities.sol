//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./console.sol";
import "./ERC1155.sol";

interface GameBalance {
    function updateOwners(address to) external;
}

contract CabinetOfCuriosities is ERC1155, Ownable {
    uint256 public _currentTokenID = 0;
    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => uint256) public tokenSupply;

    address public mirrorAddress;

    constructor() ERC1155("Cabinet Of Curiosities") {}

    function create(
        address initialOwner,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) external onlyOwner returns (uint256) {
        require(bytes(tokenUri).length > 0, "uri required");
        require(totalTokenSupply > 0, "supply must be more than 0");
        uint256 id = _currentTokenID;
        _currentTokenID++;

        tokenURIs[id] = tokenUri;
        tokenSupply[id] = totalTokenSupply;
        emit URI(tokenUri, id);
        _mint(initialOwner, id, totalTokenSupply, data);
        return id;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(tokenURIs[id]).length > 0, "That token does not exist");
        return tokenURIs[id];
    }

    function setTokenURI(uint256 tokenId, string calldata tokenUri)
        public
        onlyOwner
    {
        require(
            bytes(tokenURIs[tokenId]).length > 0,
            "That token does not exist"
        );
        emit URI(tokenUri, tokenId);
        tokenURIs[tokenId] = tokenUri;
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (operator == mirrorAddress) {
            return true;
        }
        return super.isApprovedForAll(account, operator);
    }

    function _beforeTokenTransfer(
        address operator,
        address,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal override {
        if (operator == mirrorAddress) {
            for (uint256 i = 0; i < ids.length; ++i) {
                if (
                    mirrorAddress != address(0) &&
                    mirrorAddress != to &&
                    super.balanceOf(to, i) == 0
                ) {
                    GameBalance(mirrorAddress).updateOwners(to);
                }
            }
        }
    }

    function setMirrorAddress(address _address) public onlyOwner {
        require(mirrorAddress == address(0), "Already set");
        mirrorAddress = _address;
    }
}
