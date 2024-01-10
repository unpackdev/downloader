// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

contract howlerzmfers is Ownable, ERC721A, PaymentSplitter{
//FOR PRODUCTION
    uint256 public constant MAX_QTY = 5555;
    uint256 public constant FREE_SUPPLY = 500;
    uint256 public constant PRICE = 0.02 ether;
    uint256 public constant QTY_PER_MINT = 20;

    address[] private addressList = [
	0x03EBd2D76E9EcD3666f05AA624ED2f653AaEb41e,
	0x088a807Cd88696273380B533a4F3bF37071A078D       
	];

	uint256[] private shareList = [50, 50];

    uint256 public MintedAmount = 0;

    bool public canRenounceOwnership = false;
    bool public paused = false;
    bool public saleLive = false;
    bool public revealed = false;

    string private baseTokenURI;
    string private notRevealedUri;

    constructor(string memory _notRevealedUri) ERC721A("howlerz mfers", "MFHOWL") PaymentSplitter( addressList, shareList) {
        notRevealedUri = _notRevealedUri;
    }

    function mint(uint256 amount)
        external
        payable
    {     
        require(
            MintedAmount + amount <=
                MAX_QTY,
            "AMOUNT EXCEEDS MAX SUPPLY"
        );
        require(amount <= QTY_PER_MINT, 
        "AMOUNT OVER MAX MINT AMOUNT");

        require(!paused, "SALE IS PAUSED");

        require(saleLive, "SALE NOT LIVE");
        
        if (MintedAmount + amount > FREE_SUPPLY) {
            require(msg.value >= PRICE * amount, "INSUFFICIENT ETH");
        }

        MintedAmount += amount;

        _safeMint(msg.sender, amount);
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    } 

    function _baseURI() internal view override virtual returns (string memory) {
	    return baseTokenURI;
	}
   
    function setRevealed(bool _state) external  onlyOwner {
        revealed = _state;
    } 

    function setPaused(bool _state) external  onlyOwner {
        paused = _state;
    }

    function setSaleLive(bool _state) external onlyOwner {
        saleLive = _state;
    }

    function setCanRenounceOwnership(bool _state) external  onlyOwner {
        canRenounceOwnership = _state;
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
        
        if(!revealed) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId)))
            : "";
    }

    function renounceOwnership() override public onlyOwner{
        require(canRenounceOwnership,"Not the time to Renounce Ownership");
        _transferOwnership(address(0));
    }

	function withdrawSplit() public onlyOwner {
        for (uint256 i = 0; i < addressList.length; i++) {
            address payable wallet = payable(addressList[i]);
            release(wallet);
        }
    }

}