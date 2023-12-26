pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BoonkBots is ERC721Enumerable, Ownable {

//  ........................................
//  .....4LL UR B00NKS 4R3 B3L0NG TO U5.....
//  ........................................
//  .............';'..';;'..,;,.............
//  ...........'lxkxllkOOkllkOko,...........
//  ...........lkxxxxxxxxxxxxxxOl...........
//  ...........lo'............'dl...........
//  ...........ld;'''''''''''';do...........
//  ...........lOOOOOOOOOOOOOOO0o...........
//  ...........l00O0000000000000o...........
//  ....,ll:...o0000000000000000o...:oo;....
//  ..,ok00Od,.:xdxxxxxxxxxxxxxxc.,xOK0Od;..
//  .lO00000O:.';;;;;;;;;;;;;;;;'.:0KKKKK0l.
//  .,oO000kl..o0000000000000000o.'lOKKK0d;.
//  ...,:::'..lkKKKKKKKKKKKKKKKKkl..,:::;...
//  ....,co;..;d0KKKKKKKKKKKKKK0d;..:ol,....
//  ...olckd....;dxxxxkkkkkkkkd;....dOloo'..
//  ..,kxoOd.....,::::::::::::;.....dOdkO,..
//  ..,kxcc;....'kKKKKKKKKKKKXk,....;llkO,..
//  ...;:;......,OXXXOl::lOXXXO,......;:;...
//  ............,OXXXd....dXXNO,............
//  ............'dkkkl....lOOOd'............
//  ........................................

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 37;
    uint256 private _maxBoonkbotSupply = 1337;
    uint256 private _price = 0.064 ether;
    bool public _publicSale = false;
    bool public _preSale = false;
    mapping (address => uint256) private _presaleMints;
    mapping (address => bool) public _allowlist;

    address t1 = 0x2083aBBE7a3Cbf3cC19F3C76DC7fD48eB6C50763;

    constructor(string memory baseURI) ERC721("BoonkBots", "BOONKBOTS")  {
        setBaseURI(baseURI);
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( _publicSale, "Public sale not active" );
        require( num <= 24, "You can get a maximum of 24 B00NKB0TS per transaction" );
        require( supply + num <= _maxBoonkbotSupply - _reserved, "Exceeds maximum B00NKB0TS supply" );
        require( msg.value == _price * num, "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function mintPresale(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( _preSale, "Presale not active" );
        require(_allowlist[msg.sender], "Address not allowed");
        require(_presaleMints[msg.sender] + num <= 4, "Max 4 mints per address in presale");
        require( supply + num <= _maxBoonkbotSupply - _reserved, "Exceeds maximum B00NKB0TS supply" );
        require( msg.value == _price * num, "Ether sent is not correct" );

        _presaleMints[msg.sender] += num;

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function setAllowlistAddress (address[] memory users) public onlyOwner {
      for (uint256 i; i < users.length; i++) {
          _allowlist[users[i]] = true;
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved B00NKB0TS supply" );
        uint256 supply = totalSupply();
        require( supply + _amount <= _maxBoonkbotSupply, "Exceeds maximum B00NKB0TS supply" );

        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function setPreSale(bool val) public onlyOwner {
        _preSale = val;
    }

    function setPublicSale(bool val) public onlyOwner {
        _publicSale = val;
    }

    function withdrawAll() public onlyOwner {
        uint256 _amount = address(this).balance;
        require(payable(t1).send(_amount));
    }

}
