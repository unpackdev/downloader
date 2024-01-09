
/**
                    XMAZ TIME!!!

           *             ,
                       _/^\_    *           *
                      <     >
     *                 /.-.\         *
              *        `/&\`                   *
                      ,@.*;@,
                     /_o.I %_\    *
                   /`;--.,__ `')             *
                  ;@`o % O,*`'`&\
                 /`;--._`''--._O'@;
                /&*,()~o`;-.,_ `""`)
     *          /`,@ ;+& () o*`;-';\
               /-.,_    ``''--....-'`)  *
          *    /@%;o`:;'--,.__   __.'\
              ;*,&(); @ % &^;~`"`o;@();         *
        jgs   `"="==""==,,,.,="=="==="`
           __.----.(\-''#####---...___...-----._
                        #####
                    #############
                 `"""` `

------------------------------------------------

*/
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract XMAZ is ERC721,Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bool openForMintz=false;
	
	bool unveil = false;
	
	string private _BaseURI = '';
    string private _tokenRevealedBaseURI  = '';
    mapping(address => uint256) private _claimed;
    
    uint256 public xmazSupply = 500;

    mapping(bytes32 => bool) public whitelistCodez;

    constructor() ERC721("Reindeerz","XMAZ") {
        _BaseURI = '';
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    function mintz(uint amount) external  {
        require(openForMintz,"Mint Function is not Active yet");
        require(amount <=3,"Mint exceed max amount");
        require(_claimed[msg.sender] + amount <= 6, "Free token already claimed");
        _mint(amount);
    }
    

    function _mint(uint amount) internal{
        require(totalSupply() + amount <= (xmazSupply), "Minting would exceed max supply");
     
        for(uint i = 0; i < amount; i++) {
            
            uint lastIndex = _tokenIdCounter.current();
             _tokenIdCounter.increment();
               _claimed[msg.sender] += 1;
            _mint(msg.sender, lastIndex);
        }
    }
    
    function withdraw() external onlyOwner 
    {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    
    function reveal(string memory baseURI) external onlyOwner {
        unveil=true;
        _BaseURI = baseURI;
    }
    
    function setActive() external onlyOwner{
        openForMintz=true;
    }
    
    function setNonActive() external onlyOwner{
        openForMintz=false;
    }

    function max_supply() public view virtual returns (uint256) {
        return xmazSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return _BaseURI;
    }
    
    function setBaseURI(string calldata URI) public onlyOwner {
        _BaseURI = URI;
    }   
    
}