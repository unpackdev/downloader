// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./Strings.sol";

contract Mews is ERC721, Ownable, ERC2981 {
    /**
    ==============
    Introducing...
             ____    __      __           
     /'\_/`\/\  _`\ /\ \  __/\ \          
    /\      \ \ \L\_\ \ \/\ \ \ \   ____  
    \ \ \__\ \ \  _\L\ \ \ \ \ \ \ /',__\ 
     \ \ \_/\ \ \ \L\ \ \ \_/ \_\ /\__, `\
      \ \_\\ \_\ \____/\ `\___x___\/\____/
       \/_/ \/_/\/___/  '\/__//__/ \/___/ 
                                          
    MEWs or Meta Exo Whips are a 3D digital collectible fashion art item designed and developed by Metadrip. 

    Contract written by 0xhanvalen via Raidguild for Metadrip.
    ==============
    */

    using Strings for uint256;

    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 private currentIndex;
    string private baseURI;
    string private unrevealedURI;
    bool private isRevealed;
    mapping(address => uint16) public amountMinted;
    uint16 private maxMintedPerUser = 10;

    constructor() ERC721("Metadrip Mews", "MEWS") {
        mintPrice = 0.33 ether;
        totalSupply = 200;
        currentIndex = 0;
        isRevealed = false;
        unrevealedURI = "https://mews-metadrip.s3.amazonaws.com/prereveal/preReveal.json";
        _setDefaultRoyalty(0xf5f4B601879Cc90653947402295E2FB29807a788, 690);
    }

    function teamMint() public onlyOwner {
        for (uint256 i = 0; i < 20; i++) {
            require(currentIndex + 1 <= totalSupply, "Sold Out");
            currentIndex++;
            _mint(0xf5f4B601879Cc90653947402295E2FB29807a788, currentIndex);
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealedURI(string memory newURI) public onlyOwner {
        unrevealedURI = newURI;
    }

    function toggleReveal() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function mint(uint16 amount) public payable {
        require(
            amountMinted[msg.sender] + amount <= maxMintedPerUser,
            "Too Many"
        );
        require(msg.value >= mintPrice * amount, "Not Enough Money");
        for (uint256 i = 0; i < amount; i++) {
            require(currentIndex + 1 <= totalSupply, "Sold Out");
            currentIndex++;
            amountMinted[msg.sender]++;
            _mint(msg.sender, currentIndex);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId <= totalSupply, "Unreal Token");
        require(tokenId >= 0, "Unreal Token");
        if (isRevealed) {
            return
                string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        } else {
            return string(abi.encodePacked(unrevealedURI));
        }
    }

    function withdraw() public {
        payable(0xf5f4B601879Cc90653947402295E2FB29807a788).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
