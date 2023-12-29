// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./Strings.sol";

contract uNite is ERC1155, Ownable, ERC1155Burnable {
    string public name = "uNite";
    string public symbol = "uNite";
    uint256 public minted;
    uint256 public mintPrice; // Price in ETH for each mint
    uint256 public maxBatchSize = 20;

    mapping(address => bool) public whitelist;

    event EthCollected(address indexed collector, uint256 amount);
    event Mint(address indexed account, uint256 tokenId, uint256 amount);

    constructor(
        address initialOwner,
        uint256 _mintPrice
    )
        ERC1155(
            "https://ipfs.io/ipfs/QmYtGLo6ZzjzuSxnfCHx2JzWFqVvbDYReyCzyNjggv9Pst/{id}.json"
        )
        Ownable(initialOwner)
    {
        minted = 0;
        mintPrice = _mintPrice;
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(
        address[] calldata addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function mint() external payable {
        if (whitelist[msg.sender]) {
            // Remove user from whitelist after minting
            whitelist[msg.sender] = false;
        } else if (msg.sender != owner()) {
            require(msg.value >= mintPrice, "Insufficient funds");
        }
        // Mint one token to the sender
        _mint(msg.sender, minted + 1, 1, "");
        minted += 1;

        emit Mint(msg.sender, minted + 1, 1);
    }

    function mintBatchTo(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            minted += 1;
            _mint(addresses[i], minted, 1, "");
            emit Mint(addresses[i], minted, 1);
        }
    }

    function mintBatch(uint256 numberOfTokens) external payable {
        require(
            numberOfTokens > 0 && numberOfTokens <= maxBatchSize,
            "Invalid batch size"
        );

        if (msg.sender != owner()) {
            require(
                msg.value >= mintPrice * numberOfTokens,
                "Insufficient funds"
            );
        }

        uint256[] memory tokenIds = new uint256[](numberOfTokens);
        uint256[] memory amounts = new uint256[](numberOfTokens);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            minted += 1;
            tokenIds[i] = minted;
            amounts[i] = 1;
        }
        _mintBatch(msg.sender, tokenIds, amounts, "");
        // Mint the tokens to the sender
        for (uint256 i = 0; i < numberOfTokens; i++) {
            emit Mint(msg.sender, tokenIds[i], amounts[i]);
        }
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function collectEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to collect");
        payable(owner()).transfer(balance);
        emit EthCollected(owner(), balance);
    }

    function uri(
        uint256 _tokenid
    ) public pure override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/QmYtGLo6ZzjzuSxnfCHx2JzWFqVvbDYReyCzyNjggv9Pst/",
                    Strings.toString(_tokenid),
                    ".json"
                )
            );
    }

    function contractURI() public pure returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmYtGLo6ZzjzuSxnfCHx2JzWFqVvbDYReyCzyNjggv9Pst/collection.json";
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
