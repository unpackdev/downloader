// SPDX-License-Identifier: MIT

// @title: Dobercity
// @author: Eugene

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./console.sol";

contract Dobercity is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {

    using Address for address payable;
    using SafeMath for uint256;

    uint256 public constant MAX_DOBERS = 10000;
    uint256 public constant MAX_PRESALE_DOBERS = 3000;
    uint256 public constant MAX_PURCHASE = 10;
    uint256 public constant AMOUNT_RESERVED = 20;
    uint256 public constant DOBER_PRICE = 0.066 ether;
    uint256 public constant PRESALE_DOBER_PRICE = 0.059 ether;

    enum State {
        Setup,
        PreSale,
        Sale,
        Pause
    }

    mapping(address => uint256) private _authorised;
    address payable[] private _devWallets = [payable(address(0xfA528fBAA85E8be1e72968aC283EAaaf5809C5a1)), payable(address(0x1Dac9dB572528fc9ae3aFE4c0A449Be53Eb98e86))];

    State private _state;

    string private _tokenUriBase;

    uint256 _nextTokenId;
    uint256 _startingIndex;

    function setStartingIndexAndMintReserve(address reserveAddress) public onlyOwner {
        require(_startingIndex == 0, "Starting index is already set.");
        _startingIndex = uint256(blockhash(block.number - 1)) % MAX_DOBERS;
   
        // Prevent default sequence
        if (_startingIndex == 0) {
            _startingIndex = _startingIndex.add(1);
        }

        _nextTokenId = _startingIndex;

        for(uint256 i = 0; i < AMOUNT_RESERVED; i++) {
            _safeMint(reserveAddress, _nextTokenId); 
            _nextTokenId = _nextTokenId.add(1).mod(MAX_DOBERS); 
        }
    }
  
    constructor() ERC721("DOBERCITY","DOBERCITY") {
        _state = State.Setup;
    }

    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        _tokenUriBase = tokenUriBase_;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _tokenUriBase;
    }

    function state() virtual public view returns (State) {
        return _state;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {

        return string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
 
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function pauseSale() public onlyOwner {
        _state = State.Pause;
    }

    function startPreSale() public onlyOwner {
        require(_state == State.Setup);
        _state = State.PreSale;
    }

    function startSale() public onlyOwner {
        _state = State.Sale;
    }


    function mintDober(address human, uint256 amountOfDobers) public nonReentrant payable virtual returns (uint256) {
        require(_state != State.Setup, "DOBERs aren't ready yet!");
        require(_state != State.Pause, "DOBER Sale is currently Paused!");
        require(amountOfDobers <= MAX_PURCHASE, "Hey, that's too many DOBERs. Save some for the rest of us!");

        require(totalSupply().add(amountOfDobers) <= MAX_DOBERS, "Sorry, there's not that many DOBERs left.");

        if(_state == State.PreSale) {
            require(totalSupply().add(amountOfDobers) <= MAX_PRESALE_DOBERS, "Sorry, the amount of dobers you are trying to mint is more than is left in the presale.");
            require(_authorised[human] >= amountOfDobers, "Hey, you're not allowed to buy this many DOBERs during the presale.");
            require(PRESALE_DOBER_PRICE.mul(amountOfDobers) <= msg.value, "Hey, that's not the right presale price.");
            _authorised[human] -= amountOfDobers;
        }
        else if(_state == State.Sale) {
            require(DOBER_PRICE.mul(amountOfDobers) <= msg.value, "Hey, that's not the right price.");
        }

        uint256 firstDoberRecieved = _nextTokenId;

        for(uint i = 0; i < amountOfDobers; i++) {
            _safeMint(human, _nextTokenId); 
            _nextTokenId = _nextTokenId.add(1).mod(MAX_DOBERS);
        }

        return firstDoberRecieved;

    }

     function withdrawAllEth(address payable payee) public virtual onlyOwner {
         uint256 currentBalance = address(this).balance;
         for(uint i = 0; i < _devWallets.length; i++) {
             _devWallets[i].transfer(currentBalance * 2 / 100);
         }
        payee.sendValue(address(this).balance);
    }

    function authoriseDober(address human, uint256 amountOfDobers)
        public
        onlyOwner
    {
      _authorised[human] += amountOfDobers;
    }

    function authoriseDoberBatch(address[] memory humans, uint256 amountOfDobers)
        public
        onlyOwner
    {
        for (uint8 i = 0; i < humans.length; i++) {
            authoriseDober(humans[i], amountOfDobers);
        }
    }
}