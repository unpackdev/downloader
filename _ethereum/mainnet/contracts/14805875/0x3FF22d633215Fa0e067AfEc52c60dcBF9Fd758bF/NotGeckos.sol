//SPDX-License-Identifier: BSD 
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract NotGeckos is ERC721A, Ownable, ReentrancyGuard {
    uint16 public constant SUPPLY_TOTAL = 10000;
    uint16 public constant FREE_SUPPLY_TOTAL = 500;
    uint16 public constant MAX_PER_TXN = 30;
    uint16 public constant MAX_MINTS_PER_WALLET = 90;

    uint256 public constant MINT_PRICE = 0.01 ether;

    mapping (address => uint8) private _numberTokensMintedByAddr;
    bool private mintPaused = true;
    string private _URI;

    constructor() public ERC721A("NotGeckos", "!GGSG") payable {}

    function mint(uint256 quantity) external payable nonReentrant {
        require(mintPaused == false, "mint is paused");
        require(quantity <= MAX_PER_TXN, "quantity minted over max");
        require((_numberTokensMintedByAddr[msg.sender] + quantity) <= MAX_MINTS_PER_WALLET, "max mints per wallet exceeded");
        require((totalSupply() + quantity) <= SUPPLY_TOTAL, "total supply exceeded");
 

        if ((totalSupply() + quantity) > FREE_SUPPLY_TOTAL) {
            require(quantity*MINT_PRICE == msg.value, "Please send exact amount.");
        } 
        unchecked {
            _numberTokensMintedByAddr[msg.sender] += uint8(quantity);
        }
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'tokenId?');
        return string(abi.encodePacked(_URI, toString(tokenId)));
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    **/
    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Set halt minting 
    */
    function setMintState(bool v) public onlyOwner() {
        mintPaused = v;
    }

    /**
     * @dev Set URI 
    */
    function setURI(string memory v) public onlyOwner() {
        _URI = v;
    }

    //////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////

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
}
