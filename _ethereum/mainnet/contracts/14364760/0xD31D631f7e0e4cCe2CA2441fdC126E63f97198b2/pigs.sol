// SPDX-License-Identifier: MIT

    /**
    ___ _            __           ___                 
   | _ (_)__ _ ___  / _|___ _ _  | _ \___ __ _ __ ___ 
   |  _/ / _` (_-< |  _/ _ \ '_| |  _/ -_) _` / _/ -_)
   |_| |_\__, /__/ |_| \___/_|   |_| \___\__,_\__\___|
         |___/                                        
                    www.pigs4peace.com

    */


pragma solidity 0.8.10;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract PigsForPeace is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    event TokenURISet(string indexed newUri);

    uint256 public constant PRICE = .03 ether;
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant PER_TX_LIMIT = 50;

    uint256 public totalSupply;
    string private _baseTokenUri;

    constructor() ERC721("PIGS", "Pigs for Peace") {
        _baseTokenUri = "https://pigs4peace.com/metadata/";
        _pause();
    }

    function mint(uint256 qt) external payable whenNotPaused nonReentrant {
        require(qt > 0, "ZeroTokensRequested");
        require(qt <= PER_TX_LIMIT, "MintingExceedsTxLimit");
        require(qt * PRICE == msg.value, "InvalidETHAmount");
        require(qt + totalSupply <= MAX_SUPPLY, "MintingExceedsMaxSupply");

        for (uint256 t = 0; t < qt; t++) {
            _safeMint(msg.sender, totalSupply + t);
        }

        totalSupply += qt;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "UnknownTokenId");

        return
            string(
                abi.encodePacked(_baseTokenUri, tokenId.toString(), ".json")
            );
    }

    // The function below will withdraw the entire balance to the below address, 
    // which is the official address for "Crypto Donations Ukraine"
    // Confirm on Etherscan: 
    // https://etherscan.io/address/0x165cd37b4c644c2921454429e7f9358d18a45e14

    function withdraw() external {
        payable(0x165CD37b4C644C2921454429E7F9358d18A45e14).transfer(address(this).balance);
    }

    function setTokenURI(string memory newUri) external onlyOwner {
        _baseTokenUri = newUri;
        emit TokenURISet(_baseTokenUri);
    }

    function toggle() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}