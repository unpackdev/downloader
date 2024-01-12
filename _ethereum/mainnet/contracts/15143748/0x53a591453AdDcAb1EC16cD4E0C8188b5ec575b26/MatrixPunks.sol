//      ██     █   ,▄   ▄∞▄█"▀▓▌▀▀   `█   █   █        █▀▀▌`█▌   ▐ ▐█▄   ▌█" █▀"▄▀▀▀
//      ▐▀█   ▀█  ,▀▀█    ▐▌  ¬▌ ▄    ▐   ▐█▄▀         █ ,█ █▌   ▐ ▐▌▀█  ▌█▄▌   █▄,
//      ▐  █▄▀ █  ▀ⁿⁿ█    ▐▌  ¬▌▀█    ▐   ▄▀█          █    █▌   ▐ ▐⌐  █▄▌█ ▀█▄   `█▄
//      █   ▀  █ █.  .█   ▐█-  ▌. █▄  █ ▄█  ▐█▄        █.   ▐█ ▐ █ ▐▌   ▀Ü▀   - ▄▄,▄▀

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract MatrixPunks is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public mintPrice = 0.002 ether;
    uint public MAX_PER_WALLET = 3;

    bool public isSaleActive;
    address private receiver;

    string baseURI;
    string public extension = ".json"; 

    address private _openseaMarketplace = 0x1E0049783F008A0085193E00003D00cd54003c71;

    mapping(address => uint) private mintedPerAddress;
    mapping(address => bool) private _openseaDisapproval;

    constructor(string memory baseURI_,address _receiver) ERC721A("Matrix Punks", "MPK") {
        baseURI = baseURI_;
        receiver = _receiver;
        _safeMint(_msgSender(), 1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        return string(abi.encodePacked(base, Strings.toString(tokenId),extension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function mint(uint256 _amount) external payable {
        require(isSaleActive, "Mint must be active");
        require(_msgSender() == tx.origin, "Only User");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
        require(mintedPerAddress[_msgSender()] + _amount <= MAX_PER_WALLET, "Max mint per wallet");

        uint256 minted = mintedPerAddress[_msgSender()];
        if(minted > 0){
            require(msg.value >= _amount * mintPrice, "Insufficient funds");
        }else {
            require(msg.value >= (_amount -1) * mintPrice, "Insufficient funds");
        }

        mintedPerAddress[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount);
    }


    function activeSale(bool _activeSale) external onlyOwner {
        isSaleActive = _activeSale;
    }

    //Opensea pre approved if you mint 2 or more
    function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721AI: approve to caller");

    if (operator == _openseaMarketplace && mintedPerAddress[_msgSender()] > 1){
      _openseaDisapproval[_msgSender()] = !approved;
    }

    return super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
      if(operator == _openseaMarketplace && !_openseaDisapproval[_msgSender()] && mintedPerAddress[_msgSender()] > 1){
         return true;
        } 
        return super.isApprovedForAll(owner, operator);
    }

    //Withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(receiver).transfer(balance);
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

}