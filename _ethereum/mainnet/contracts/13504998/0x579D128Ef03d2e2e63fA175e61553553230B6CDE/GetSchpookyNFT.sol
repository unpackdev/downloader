// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


contract GetSchpookyNFT is ERC721Enumerable, PaymentSplitter, Ownable {

    using SafeMath for uint256;

    string private _apiURI;
    IERC721Enumerable private _GSC;
    mapping(uint256 => bool) public claimed;
    bool public mintActive;
    
    address[] private _team = [0x99DB1930c6800ed26E46b870a42167d85cE08f19];
    uint256[] private _shares = [100];

    constructor() ERC721("Get Schpooky Club", "SCHP") PaymentSplitter(_team, _shares) {
        _apiURI = "https://api-getschwifty.club/schpooky/meta/";
        mintActive = false;
        _GSC = IERC721Enumerable(0x0d6BF5a6443c201D772607419eC5a897c564219C);
    }

    function withdrawAll() public onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }    

    function mint(uint256[] memory ids) public {
        require(mintActive, "Sale not acitve!");
        uint256 ts = totalSupply();
        for (uint256 i = 0; i < ids.length; i++) {
            require(_GSC.ownerOf(ids[i]) == msg.sender, "You aren't the token owner");
            require(!claimed[ids[i]], "Already claimed");
            ts++;
            _mint(msg.sender, ts);
            claimed[ids[i]] = true;
        }
    }

    function giveaway(address _address, uint256 amount) public onlyOwner{
        uint256 ts = totalSupply();
        for (uint256 i = ts + 1; i <= ts + amount; i++) {
            _safeMint(_address, i);
        }        
    }

    function setMintActive(bool _active) public onlyOwner {
        mintActive = _active;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _apiURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setGSC(address _address) public onlyOwner {
        _GSC = IERC721Enumerable(_address);
    }
}
