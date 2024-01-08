// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract LuxMario is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant TX_MAX = 10;
    uint256 public constant MINT_PRICE = 0.045 ether;
    uint256 public constant MAX_LUXM = 6666;

    bool saleActive = true;

    string private baseURI = "https://cloudflare-ipfs.com/ipfs/bafybeig5q4d762qxyyprzzevh23xl2mgou552iafofsfhnc5easmvmqzca/";

    address public dev1;
    address public dev2;
    address public dev3;
    address public dev4;

    constructor() ERC721("LuxMario", "LUXM") {}

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function forAirdrop() public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < 30; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function activateSale(bool active) public onlyOwner {
        saleActive = active;
    }

    function mint(uint256 qty) public payable {
        require(saleActive, "Sale is not active");
        require(qty <= TX_MAX, "Can mint up to 10 maximum per tx");
        require(totalSupply().add(qty) <= MAX_LUXM, "Total supply is 6666");
        require(MINT_PRICE.mul(qty) <= msg.value, "Insufficient ether");

        uint256 i;
        uint256 supply = totalSupply();
        for (i = 0; i < qty; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : "";
    }

    function setDevAddresses(address[] memory _a) public onlyOwner {
        dev1 = _a[0];
        dev2 = _a[1];
        dev3 = _a[2];
        dev4 = _a[3];
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 percent = balance / 100;
        require(payable(dev1).send(percent * 25));
        require(payable(dev2).send(percent * 25));
        require(payable(dev3).send(percent * 25));
        require(payable(dev4).send(percent * 25));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
