//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// import "./console.sol";
import "./ERC721.sol";

contract TFIL is ERC721 {
    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

    bool public saleActive;
    // max number of tokens that can be minted - 3333 in production
    uint256 public constant MAX_SUPPLY = 3_333;
    mapping(address => bool) public auth;
    string private baseURI;

    address constant w1 = 0xF6857dEFBF03b6f88Faf51b367705589288C0b4d;
    address constant w2 = 0x19eeE77D33E3e7747BDfb8a237Cd5D70D09D2AA3;

    function setAuth(address add, bool isAuth) external onlyOwner {
        auth[add] = isAuth;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        admin = newOwner;
    }

    function setSaleStatus(bool _status) external onlyOwner {
        saleActive = _status;
    }

    /*///////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() ERC721() {
        admin = msg.sender;
        auth[msg.sender] = true;

        // initialize state
        saleActive = false;
        baseURI = "";
    }

    /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            auth[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintReserved(address to, uint8 amount) public onlyOwner {
        require(minted + amount < MAX_SUPPLY, "all minted");
        uint256 start = minted;
        for (uint256 i = start; i < start+amount; i++) {
            _mint(to, i);
        }
    }

    function mint(uint8 amount) public payable noCheaters {
        require(saleActive, "Sale must be active to mint");
        require(amount <= 10, "Exceeds number");
        require(minted + amount < MAX_SUPPLY, "all minted");
        require(msg.value >= _getMintingPrice() * amount, "Value below price");
        uint256 start = minted;

        for (uint256 i = start; i < start+amount; i++) {
            _mint(msg.sender, i);
        }
    }

    /**
    * allows owner to withdraw funds from minting
    */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(w1).transfer(balance*80/100);
        payable(w2).transfer(address(this).balance);
    }

    /** RENDER */

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(tokenId < minted, "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(tokenId))) : "";
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return "The Floor Is Lava";
    }

    function symbol() external pure returns (string memory) {
        return "TFIL";
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

    function _getMintingPrice() internal view returns (uint256) {
        return (minted / 333) * 0.01 ether;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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
