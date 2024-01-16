// SPDX-License-Identifier: GPL-3.0

//     _           _        ___       ____  __                              
//    FJ          /.\     ,"___".    /_  _\ LJ    ___ _     ____     _ ___  
//   J |         //_\\    FJ---L]    [J  L]      F __` L   F __ J   J '__ ",
//   | |        / ___ \  J |   LJ     |  |  FJ  | |--| |  | _____J  | |__|-J
//   F L_____  / L___J \ | \___--.    F  J J  L F L__J J  F L___--. F L  `-'
//  J________LJ__L   J__LJ\_____/F   J____LJ__L )-____  LJ\______/FJ__L     
//  |________||__L   J__| J_____F    |____||__|J\______/F J______F |__L     
//                                              J______F                    

pragma solidity 0.8.7;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract LACTiger is ERC721A {
    uint256 public immutable maxSupply = 1200;
    string  uri = "ipfs://Qme199Zd2gcBYCk9aDVo1FMwzZ5rjVunnayWBZ5u2bdzPD/";
    uint256 extra_tiger_price = 0.001 ether;
    uint256 maxTxTiger = 10;
    address public owner;

    modifier verify {
        require(gasleft() > 80000, "Need_More");       
        require(msg.sender == tx.origin, "No_BOT");
        _;
    }

    function publicMint(uint256 amount) payable public {
        require(totalSupply() + amount <= maxSupply, "Sold_Out");
        require(amount <= maxTxTiger);
        require(msg.value >= amount * extra_tiger_price, "NeedEther");
        _safeMint(msg.sender, amount);
    }

    function free() public verify {
        require(totalSupply() + 1 <= maxSupply, "Sold_Out");
        if (!canfree()) return;
        _safeMint(msg.sender, 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    constructor() ERC721A("LAC.Tiger", "LAC") {
        owner = msg.sender;
    }

    function canfree() public view returns(bool) {
        return (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100) > (totalSupply() * 100 / maxSupply);
    }

    function seturi(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(uri, _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

