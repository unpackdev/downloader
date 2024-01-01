// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

contract MetaversalArt is ERC1155Supply, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;

    // Mapping from token ID to its max supply.
    mapping(uint256 => uint256) private _maxSupplies;
    // Mapping from token ID to its mint switch.
    mapping(uint256 => bool) private _mintSwitches;
    // Mapping from token ID to its price (new mapping for token prices).
    mapping(uint256 => uint256) private _tokenPrices;
    // Mapping from token ID to its URI.
    mapping(uint256 => string) private _tokenURIs;
    // Mapping from an address to a token ID to its minted count.
    mapping(address => mapping(uint256 => uint256))
        private _mintedCountsPerToken;

    uint256 public constant MAX_MINTABLE_PER_TOKEN_PER_ADDRESS = 5;

    constructor() ERC1155("") {
        name = "Metaversal Art";
        symbol = "MVART";
    }

    function setMaxSupply(
        uint256 tokenId,
        uint256 maxSupply
    ) external onlyOwner {
        _maxSupplies[tokenId] = maxSupply;
    }

    function setMintSwitch(uint256 tokenId, bool _switch) external onlyOwner {
        _mintSwitches[tokenId] = _switch;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function setURI(uint256 tokenId, string memory newuri) external onlyOwner {
        _tokenURIs[tokenId] = newuri;
        emit URI(newuri, tokenId);
    }

    function setTokenPrice(uint256 tokenId, uint256 price) external onlyOwner {
        _tokenPrices[tokenId] = price;
    }

    function mint(
        address account,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public payable nonReentrant {
        require(_mintSwitches[tokenId], "Minting for this token is disabled");
        require(
            totalSupply(tokenId) + amount <= _maxSupplies[tokenId],
            "Exceeds max supply"
        );
        require(
            _mintedCountsPerToken[account][tokenId] + amount <=
                MAX_MINTABLE_PER_TOKEN_PER_ADDRESS,
            "Exceeds max mintable count per token per address"
        );

        uint256 tokenPrice = _tokenPrices[tokenId];
        require(msg.value == tokenPrice * amount, "Insufficient payment");

        _mintedCountsPerToken[account][tokenId] += amount;
        _mint(account, tokenId, amount, data);
    }

    function mintBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        require(
            tokenIds.length == amounts.length,
            "Mismatch in length between tokenIds and amounts"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 totalAmountForToken = 0;
            for (uint256 j = 0; j < tokenIds.length; j++) {
                if (tokenIds[i] == tokenIds[j]) {
                    totalAmountForToken += amounts[j];
                }
            }
            require(
                totalSupply(tokenIds[i]) + totalAmountForToken <=
                    _maxSupplies[tokenIds[i]],
                "Exceeds max supply for one of the tokens"
            );
        }

        _mintBatch(account, tokenIds, amounts, data);
    }

    function airdrop(
        uint256 tokenId,
        address[] memory recipients,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            recipients.length == amounts.length,
            "Recipients and amounts length mismatch"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                totalSupply(tokenId) + amounts[i] <= _maxSupplies[tokenId],
                "Exceeds max supply for one of the tokens"
            );
            _mint(recipients[i], tokenId, amounts[i], "");
        }
    }

    function getMaxSupply(uint256 tokenId) external view returns (uint256) {
        return _maxSupplies[tokenId];
    }

    function getMintSwitch(uint256 tokenId) external view returns (bool) {
        return _mintSwitches[tokenId];
    }

    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        return _tokenPrices[tokenId];
    }

    function getMintedCountOfTokenByAddress(
        address account,
        uint256 tokenId
    ) external view returns (uint256) {
        return _mintedCountsPerToken[account][tokenId];
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether balance to withdraw");

        payable(msg.sender).transfer(balance);
    }
}
