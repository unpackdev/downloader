// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Skulls is Ownable, ERC721A {
    using Strings for uint256;

    uint256 public start; // Start time
    uint256 public price; // Price of each tokens
    uint256 public freeMinted;
    uint256 public totalFree;
    string public baseTokenURI; // Placeholder during mint
    string public revealedTokenURI; // Revealed URI
    mapping(address => bool) public claimed;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), 'contract not allowed');
        require(msg.sender == tx.origin, 'proxy contract not allowed');
        _;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /** @notice Public mint day after whitelist */
    function publicMint() external payable notContract {
        // Wait until public start
        require(
            start <= block.timestamp,
            'Mint: Public sale not yet started, bud.'
        );

        // Check ethereum paid
        uint256 mintAmount = msg.value / price;
        if (freeMinted < totalFree && !claimed[msg.sender]) {
            claimed[msg.sender] = true;
            mintAmount += 1;
            freeMinted += 1;
        }

        if (totalSupply() + mintAmount > collectionSize) {
            uint256 over = (totalSupply() + mintAmount) - collectionSize;
            safeTransferETH(msg.sender, over * price);

            mintAmount = collectionSize - totalSupply(); // Last person gets the rest.
        }

        require(mintAmount > 0, 'Mint: Can not mint 0 fren.');

        _safeMint(msg.sender, mintAmount);
    }

    /** @notice Gift mints after all minted */
    function mint(address to, uint256 amount) external onlyOwner {
        require(
            totalSupply() + amount < collectionSize,
            'Mint: Bruh you are overminting.'
        );
        _safeMint(to, amount);
    }

    /** @notice Set Base URI */
    function setStart(uint256 time) external onlyOwner {
        start = time;
    }

    /** @notice Set Base URI */
    function setBaseTokenURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    /** @notice Set Reveal URI */
    function setRevealedTokenUri(string memory uri) external onlyOwner {
        revealedTokenURI = uri;
    }

    /** @notice Set Reveal URI */
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    /** @notice Withdraw Ethereum */
    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;

        safeTransferETH(to, balance);
    }

    /** Utility Function */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function getCollectionSize() external view returns (uint256) {
        return collectionSize;
    }

    /** @notice Image URI */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), 'URI: Token does not exist');

        // Convert string to bytes so we can check if it's empty or not.
        return
            bytes(revealedTokenURI).length > 0
                ? string(abi.encodePacked(revealedTokenURI, tokenId.toString()))
                : baseTokenURI;
    }

    /** @notice initialize contract */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxBatchSize, // 20 per
        uint256 _collectionSize, // 8000
        uint256 _totalFree // 750
    ) ERC721A(_name, _symbol, _maxBatchSize, _collectionSize) {
        baseTokenURI = 'ipfs://QmUt6k68sjxVrmz5U6X1DTxYLxP6tfPXe93ZfbNVbzL8PL';
        totalFree = _totalFree;

        start = 1642701570;
        price = 0.03 ether;
    }
}
