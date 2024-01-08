// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
        ######  #     #  #####      ####### #######  #####  #     # 
        #     # #     # #     #        #    #       #     # #     # 
        #     # #     # #              #    #       #       #     # 
        ######  #     # #  ####        #    #####   #       ####### 
        #   #   #     # #     # ###    #    #       #       #     # 
        #    #  #     # #     # ###    #    #       #     # #     # 
        #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender
contract YEETH is ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    event Winner (address indexed winner);
    event YEETHBURN ();

    uint256 public totalCount = 10000;
    uint256 public maxBatch = 10; 
    uint256 public price = 0.01 * 10**18; //Mint Price
    string public baseURI = "ipfs://QmPwFhgHthT71SvyE5ao9omdMUYYpBtqnKqxV61ByXNK1X/";
    bool private _started = false;
    uint public endDate = 0;

    constructor()
    ERC721("YEETH", "YEETH")
    {}

    receive() external payable {}

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        _started = _start;
        endDate = block.timestamp + 72 hours;
    }

    function _destroy() internal {
      require(endDate != 0);
      require(block.timestamp > endDate);
      require(totalSupply() < totalCount);
      uint256 currentBalance = address(this).balance;
      (bool sent, ) = address(0x000000000000000000000000000000000000dEaD).call{value: currentBalance}('');
      require(sent, "Error while transfering eth");
      emit YEETHBURN();
    }

    function distribute() public {
      require(endDate != 0);
      require(totalSupply() >= totalCount);
      uint256 currentBalance = address(this).balance;
      address winner = findWinner();
      emit Winner(winner);
      (bool sent, ) = winner.call{value: currentBalance}('');
      require(sent, "Error while transfering eth");   
    }

    function findWinner() public view returns(address) {
      return ownerOf((uint(keccak256(abi.encodePacked(_msgSender(), msg.sig, block.timestamp, block.difficulty, block.coinbase))) % totalCount) + 1);
    }

    function claim(uint256 _batchCount) payable public {
        require(_started, "Sale not started");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch must be between 0 and 11");
        require(totalSupply() + _batchCount <= totalCount, "Can't mint anymore");
        require(msg.value == _batchCount * price, "Wrong value sent");
        if (block.timestamp > endDate) {
            return _destroy();
        }
        emit Claim(msg.sender, totalSupply(), _batchCount);
        for(uint256 i = 0; i< _batchCount; i++) {
            uint mintID = totalSupply() + 1;
            require(totalSupply() < totalCount);
            emit Claim(_msgSender(), mintID, _batchCount);
            _mint(_msgSender(), mintID);
        }
        if (totalSupply() == totalCount) {
           return distribute();
        }
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        address winner = ownerOf((uint(keccak256(abi.encodePacked(_msgSender(), msg.sig, block.timestamp, block.difficulty, block.coinbase))) % totalSupply()) + 1);
        (bool sent, ) = winner.call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply()) < totalCount);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
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

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}