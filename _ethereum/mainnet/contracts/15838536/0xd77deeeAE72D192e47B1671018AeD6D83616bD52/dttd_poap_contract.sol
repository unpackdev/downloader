// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title DTTD POAPs Contract
/// @author irreverent.eth @ DTTD
/// @notice https://dttd.io/

//    ___    _____   _____    ___   
//   |   \  |_   _| |_   _|  |   \  
//   | |) |   | |     | |    | |) | 
//   |___/   _|_|_   _|_|_   |___/  
// _|"""""|_|"""""|_|"""""|_|"""""| 
// "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 

import "./ERC1155.sol";
import "./Ownable.sol";

contract DTTDPOAPContract is ERC1155, Ownable {
    struct Token {
        string name;
        string symbol;
        uint256 maxSupply;
        uint256 totalSupply;
        string uri;
    }

    uint256 public numberOfTokens;
    mapping(uint256 => Token) public tokens;
    mapping(bytes32 => bool) public tidUsed;
    mapping(bytes32 => bool) public claimed;

    constructor() payable ERC1155("") {
    }

    modifier tidCheck(bytes32 tid) {
        require (tidUsed[tid] == false, "Already minted: tid");
        _;
    }

    // Setup new POAP

    function setupPOAP(string memory tokenName, string memory tokenSymbol, uint256 tokenMaxSupply, string memory tokenURI) external onlyOwner {
        require(bytes(tokenName).length > 0, "Missing name");
        require(bytes(tokenSymbol).length > 0, "Missing symbol");
        require(tokenMaxSupply > 0, "Missing max supply");
        require(bytes(tokenURI).length > 0, "Missing URI");

        Token memory token = Token({
            name: tokenName,
            symbol: tokenSymbol,
            maxSupply: tokenMaxSupply,
            totalSupply: 0,
            uri: tokenURI
        });

        tokens[numberOfTokens] = token;
        ++numberOfTokens;
    }

    function setURI(uint256 tokenID, string memory tokenURI) external onlyOwner {
        require(tokenID < numberOfTokens, "Invalid ID");
        require(bytes(tokenURI).length > 0, "Missing URI");

        Token storage token = tokens[tokenID];
        token.uri = tokenURI;
        emit URI(tokenURI, tokenID);
    }

    // Airdrop

    function airdropPOAP(bytes32 tid, bytes32 pid, address to, uint256 tokenID) external onlyOwner tidCheck(tid) {
        require(tokenID < numberOfTokens, "Invalid ID");

        bytes32 claimHash = keccak256(abi.encode(pid, tokenID));
        require(claimed[claimHash] == false, "Already claimed: pid-tokenId");

        Token memory token = tokens[tokenID];
        uint256 tokenMaxSupply = token.maxSupply;
        uint256 tokenTotalSupply = token.totalSupply;
        require (tokenTotalSupply + 1 <= tokenMaxSupply, "Insufficient remaining supply");

        claimed[claimHash] = true;
        tidUsed[tid] = true;
        _mint(to, tokenID, 1, "");
    }

    function batchMint(address to, uint256 tokenID, uint256 quantity) external onlyOwner {
        require(tokenID < numberOfTokens, "Invalid ID");
        require(quantity > 0, "Zero quantity");

        Token memory token = tokens[tokenID];
        uint256 tokenMaxSupply = token.maxSupply;
        uint256 tokenTotalSupply = token.totalSupply;
        require (tokenTotalSupply + quantity <= tokenMaxSupply, "Insufficient remaining supply");

        _mint(to, tokenID, quantity, "");
    }

    // Token data

    function uri(uint256 tokenID) public view override returns (string memory) {
        Token memory token = tokens[tokenID];
        return token.uri;
    }

    function name(uint256 tokenID) public view returns (string memory) {
        Token memory token = tokens[tokenID];
        return token.name;
    }

    function symbol(uint256 tokenID) public view returns (string memory) {
        Token memory token = tokens[tokenID];
        return token.symbol;
    }

    function maxSupply(uint256 tokenID) public view returns (uint256) {
        Token memory token = tokens[tokenID];
        return token.maxSupply;
    }

    function totalSupply(uint256 tokenID) public view returns (uint256) {
        Token memory token = tokens[tokenID];
        return token.totalSupply;
    }

    // Override for token total supply

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                Token storage token = tokens[ids[i]];
                token.totalSupply += amounts[i];
            }
        }
    }
}
