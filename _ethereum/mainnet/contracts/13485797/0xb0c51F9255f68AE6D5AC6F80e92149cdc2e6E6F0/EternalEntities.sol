/*
 _____ _                        _   _____      _   _ _   _
|  ___| |                      | | |  ___|    | | (_) | (_)
| |__ | |_ ___ _ __ _ __   __ _| | | |__ _ __ | |_ _| |_ _  ___  ___ 
|  __|| __/ _ \ '__| '_ \ / _` | | |  __| '_ \| __| | __| |/ _ \/ __|
| |___| ||  __/ |  | | | | (_| | | | |__| | | | |_| | |_| |  __/\__ \
\____/ \__\___|_|  |_| |_|\__,_|_| \____/_| |_|\__|_|\__|_|\___||___/
                        ETERNALENTITIES.IO
*/
pragma solidity ^0.8.7;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract EternalEntities is ERC721Enumerable, Ownable, ReentrancyGuard{
    uint256 public mintPrice = 0.1 ether;
    uint256 public constant maxSupply = 10000;
    uint256 public constant mintLimit = 5;
    uint256 public constant presaleMintLimit = 5;
    uint256 public constant reserveLimit = 200;

    uint256 public reserveClaimed;
    uint256 public freeMintAvailable;

    bool public PresaleStarted;
    bool public PublicSaleStarted;

    mapping(address => uint256) public TotalMinted;
    mapping(address => uint256) public FreeMinted;
    
    mapping(address => bool) public PresaleWhitelist;
    uint256 public NrOfAddressesInWhitelist;

    string public BaseURI;

    constructor (string memory baseUri) public ERC721("EternalEntities", "EE"){
        BaseURI = baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BaseURI;
    }

    function Reserve(uint nr) onlyOwner external{
        require(reserveClaimed + nr <= reserveLimit, "Cannot reserve more than allowed");
        reserveClaimed += nr;
        _mint(nr, false);
    }

    function FreeMint() nonReentrant external{
        require(freeMintAvailable > 0, "No free mints available");
        require(FreeMinted[_msgSender()] + 1 <= 1, "Mint exceeds max of 1 allowed per address");
        FreeMinted[_msgSender()] += 1;
        freeMintAvailable -= 1;
        _mint(1, true);
    }

    function PublicMint(uint nr) nonReentrant external payable{
        require(PublicSaleStarted, "Public minting is not active");
        require(nr <= mintLimit, "Cannot mint more than allowed");
        require(TotalMinted[_msgSender()] + nr <= mintLimit, "Mint exceeds max allowed per address");
        require(msg.value >= mintPrice * nr, "Not enough eth send");
        _mint(nr, false);
    }

    function PresaleMint(uint nr) nonReentrant external payable{
        require(PresaleStarted, "Presale minting is not active");
        require(PresaleWhitelist[_msgSender()], "You are not whitelisted!");
        require(nr <= presaleMintLimit, "Cannot mint more than allowed");
        require(TotalMinted[_msgSender()] + nr <= presaleMintLimit, "Mint exceeds max allowed per address");
        require(msg.value >= mintPrice * nr, "Not enough eth send");
        _mint(nr, false);
    }

    function _mint(uint nr, bool exclude) private{
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require((totalSupply() + nr) <= maxSupply, "You cannot exceed max supply");
        for(uint256 i = 0; i < nr; i++)
        {
            if(!exclude) TotalMinted[_msgSender()] += 1;
            _safeMint(_msgSender(), totalSupply() + 1);
        }
    }

    function TransferEth() onlyOwner external{
        require(address(this).balance > 0, "No eth present");
        (bool onwerTransfer, ) = owner().call{value: address(this).balance}('');
        require(onwerTransfer, "Transfer to owner address failed.");
    }

    function TogglePresaleStarted() onlyOwner external{
        PresaleStarted = !PresaleStarted;
    }

    function TogglePublicSaleStarted() onlyOwner external{
        PublicSaleStarted = !PublicSaleStarted;
    }

    function SetBaseUri(string memory baseUri) onlyOwner external{
        BaseURI = baseUri;
    }

    function setPrice(uint256 _newPrice) onlyOwner external{
        mintPrice = _newPrice;
    }

    function AddToWhitelist(address[] memory addresses) onlyOwner external{
        for(uint256 i = 0; i < addresses.length; i++) {
            PresaleWhitelist[addresses[i]] = true;
            NrOfAddressesInWhitelist += 1;
        }
    }

    function RemoveFromWhitelist(address[] memory addresses) onlyOwner external{
        for(uint256 i = 0; i < addresses.length; i++) {
            PresaleWhitelist[addresses[i]] = false;
            NrOfAddressesInWhitelist -= 1;
        }
    }

    function UpdateFreeMintAvailable(uint256 amount) onlyOwner external{
        freeMintAvailable += amount;
    }

    function IsOnWhitelist(address account) public view returns(bool){
        return PresaleWhitelist[account];
    }

    uint256 private cantSeeTheCountBitch;
    //Don't be a !square
    function WhatDoesThisDoExactly() nonReentrant external{
        require(cantSeeTheCountBitch < 10, "Too late motherfucker!");
        require(PresaleWhitelist[_msgSender()] == false, "ah ah ah");
        cantSeeTheCountBitch += 1;
        NrOfAddressesInWhitelist += 1;
        PresaleWhitelist[_msgSender()] = true;
    }
}