pragma solidity >=0.6.0 <0.8.9;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

//import "./console.sol";
import "./ERC721.sol";
//import "./ERC721Enumerable.sol";

import "./Counters.sol";
import "./Ownable.sol";
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two


contract SimpsDao is ERC721, Ownable {
    uint16 public version=8;
    uint public MAX_TOKENS = 3888;
    uint constant public MINT_PER_TX_LIMIT = 20;

    uint16 public tokensMinted = 0;
    uint16 public phase = 0;
    //uint16 public queenMinted = 0;

    bool private _paused = true;

    mapping(uint16 => uint) public phasePrice;


    string private _apiURI = "https://api.simpsdao.io/";
   

    constructor() ERC721("Simps", "SIMPS"){

        phasePrice[0] = 0 ether;
        phasePrice[1] = 0.03 ether;
        phasePrice[2] = 0.04 ether;
        phasePrice[3] = 0.05 ether;

    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function setPaused(bool _state) external  {
        _paused = _state;
    }

    function giveAway(uint16 _amount, address _address) public onlyOwner {
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        //equire(_availableTokens.length > 0, "All tokens for this Phase are already sold");
        
        for (uint i = 0; i < _amount; i++) {
            tokensMinted += 1;
            uint16 tokenId = tokensMinted;  
            _safeMint(_address, tokenId);
        }
    }

    function mint(uint16 _amount) public payable whenNotPaused{

        require(tx.origin == msg.sender, "Only EOA");
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        require(_amount > 0 && _amount <= MINT_PER_TX_LIMIT, "Invalid mint amount");
        require(mintPrice(_amount) == msg.value, "Invalid payment amount");

        

        for (uint16 i = 0; i < _amount; i++) {
            tokensMinted += 1;
            uint16 tokenId = tokensMinted;  
            _safeMint(msg.sender, tokenId);    
        }

    }


    function mintPrice(uint _amount) public view returns (uint) {

        if(tokensMinted<=888){
            return _amount*phasePrice[0];
        }else if(889<=tokensMinted&&tokensMinted<=1888){
            return _amount*phasePrice[1];
        }else if(1889<=tokensMinted&&tokensMinted<=2888){
            return _amount*phasePrice[2];
        }else if(2889<=tokensMinted&&tokensMinted<=3888){
            return _amount*phasePrice[3];
        }

    }


    function changePhasePrice(uint16 _phase, uint _weiPrice) external onlyOwner {
        phasePrice[_phase] = _weiPrice;
    }

    function transferFrom(address from, address to, uint tokenId) public virtual override {
        // Hardcode the Manager's approval so that users don't have to waste gas approving
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function totalSupply() public view returns (uint16) {
        return tokensMinted;
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _apiURI = uri;
    }

    function withdraw(address to) external onlyOwner {
        uint balance = address(this).balance;
        payable(to).transfer(balance);
    }

}




