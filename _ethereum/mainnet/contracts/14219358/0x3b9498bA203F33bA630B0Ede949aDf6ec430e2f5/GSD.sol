// SPDX-License-Identifier: MIT
// dev address is 0x67145faCE41F67E17210A12Ca093133B3ad69592
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

contract GSDToken is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;

    uint256 public constant MAX_ELEMENTS = 5000;

    uint256 private constant PRESALE_TIMESTAMP = 1645142340;
    uint256 private constant PUBLIC_FIRST_TIMESTAMP = 1645228740;
    uint256 private constant PUBLIC_SECOND_TIMESTAMP = 1645315140;

    uint256 private constant PRESALE_PRICE = 0.05 ether;
    uint256 private constant PUBLIC_FIRST_PRICE = 0.07 ether;
    uint256 private constant PUBLIC_SECOND_PRICE = 0.09 ether;

    string public baseTokenURI;

    event GSDMinted(address indexed addr, uint256 indexed tokenId);

    constructor(string memory baseURI) ERC721("GSDToken", "GSD") {
        setBaseURI(baseURI);

        for (uint256 i = 1; i <= 30; i++) {
            _safeMint(msg.sender, i);
            emit GSDMinted(msg.sender, i);
        }
    }

    modifier notPaused() {
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    /**
     * @dev Mint the _amount of tokens
     * @param _amount is the token count
     */
    function mint(uint256 _amount) private {
        require(msg.sender == tx.origin);
        require(totalSupply() < MAX_ELEMENTS, "Sale end");
        require(totalSupply() + _amount <= MAX_ELEMENTS, "Max limit");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId + 1);
            emit GSDMinted(msg.sender, tokenId + 1);
        }
    }

    /**
     * @dev Mint the _amount of tokens
     * @param _amount is the token count
     */
    function PreSale(bytes32[] calldata _proof, uint256 _amount)
        external
        payable
        notPaused
    {
        require(
            block.timestamp >= PRESALE_TIMESTAMP,
            "Presale is not started yet"
        );
        require(block.timestamp < PUBLIC_FIRST_TIMESTAMP, "Presale is ended");
        require(msg.value >= _amount * PRESALE_PRICE, "Value is not enough");
        require(totalSupply() < 175, "Exceed PreSale Token Amount");
        require(
            totalSupply() + _amount < 175,
            "Exceed PreSale Amount, please decrease amount"
        );

        bytes32 merkleTreeRoot = 0xc84b97760163dbfa07774694f3d275ee58f7e22f59ffad986cfb8cf23b2cf3c3;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, merkleTreeRoot, leaf),
            "Sorry, you're not whitelisted. Please try Public Sale"
        );

        mint(_amount);
    }

    function PublicSale(uint256 _amount) external payable notPaused {
        if (totalSupply() + _amount < 500) {
            require(
                block.timestamp >= PUBLIC_FIRST_TIMESTAMP,
                "First PublicSale is not started yet"
            );
            require(
                msg.value >= _amount * PUBLIC_FIRST_PRICE,
                "Value is not enough (init)"
            );
        } else {
            require(
                block.timestamp >= PUBLIC_SECOND_TIMESTAMP,
                "Second PublicSale is not started yet"
            );
            require(
                msg.value >= _amount * PUBLIC_SECOND_PRICE,
                "Value is not enough (main)"
            );
        }

        mint(_amount);
    }

    function burn(uint256 tokenId) public virtual notPaused {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev set the _baseTokenURI
     * @param baseURI of the _baseTokenURI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (_msgSender() != owner()) {
            require(!paused(), "ERC721Pausable: token transfer while paused");
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
