// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

contract AiryokuDragonz is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string  public  baseTokenURI = "ipfs://QmSXdENNXUXiPwgzHTEsJpxCQUNezgP51asjhUfZBwdSLe";

    uint256 public  maxSupply = 7777;
    uint256 public  MAX_MINTS_PER_TX = 10;
    uint256 public  FREE_MINTS_PER_TX = 4;
    uint256 public  PUBLIC_SALE_PRICE = 0.025 ether;
    uint256 public  TOTAL_FREE_MINTS = 1111;


    constructor(

    ) ERC721A("AiryokuDragonz", "AiryokuDragonz") {

    }

    function mint(uint256 numberOfTokens)
    external
    payable
    {

        require(
            totalSupply() + numberOfTokens <= maxSupply,
            "Maximum supply exceeded"
        );
        if(totalSupply() + numberOfTokens > TOTAL_FREE_MINTS || numberOfTokens > FREE_MINTS_PER_TX){
            require(
                (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value,
                "Incorrect ETH value sent"
            );
        }
        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseURI)
    public
    onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function treasuryMint(uint quantity, address user)
    public
    onlyOwner
    {
        require(
            quantity > 0,
            "Invalid mint amount"
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "Maximum supply exceeded"
        );
        _safeMint(user, quantity);
    }

    function withdraw()
    public
    onlyOwner
    nonReentrant
    {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function tokenURI(uint _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString()));
    }

    function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
    {
        return baseTokenURI;
    }


    function setNumFreeMints(uint256 _numfreemints)
    external
    onlyOwner
    {
        TOTAL_FREE_MINTS = _numfreemints;
    }

    function setSalePrice(uint256 _price)
    external
    onlyOwner
    {
        PUBLIC_SALE_PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit)
    external
    onlyOwner
    {
        MAX_MINTS_PER_TX = _limit;
    }

}