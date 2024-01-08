pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./console.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract Linkedao is ERC721Enumerable, ReentrancyGuard, Ownable {

    event Claimed(uint256 index, address account, uint256 amount);

    string public purpose = "hire me";
    bool public tradable;
    bool public mintable;
    bool public jointAvailable;
    uint256 public jointExchangeRate;
    mapping (address => uint256) public signingBonusOffers;

    uint256 private balance;

    modifier onlyWhenTradable() {
        require(tradable, "Linkedao: cannot trade, try fire()");
        _;
    }

    constructor() ERC721("Linkedao", "EMPLOYEE") Ownable() {
        tradable = true;
        mintable = true;
        jointExchangeRate = 0.042069 ether;
    }

    function setTradability(bool tradability) public onlyOwner {
        tradable = tradability;
    }

    function setMintability(bool mintability) public onlyOwner {
        mintable = mintability;
    }

    function setJointExchangeRate(uint256 rate) payable public onlyOwner {
        jointExchangeRate = rate;
        balance += msg.value;
    }

    function toggleJointAvailability() public onlyOwner {
        jointAvailable = !jointAvailable;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyWhenTradable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyWhenTradable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override onlyWhenTradable {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function approve(address to, uint256 tokenId) public override onlyWhenTradable {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyWhenTradable {
        super.setApprovalForAll(operator, approved);
    }

    function BRIBE_EMPLOYEE_NO_TAKE_BACKS_OR_REFUNDS() payable public nonReentrant {
        require(msg.value != 0 ether, "Linkedao: > 0 ETH to bribe");
        signingBonusOffers[msg.sender] += msg.value;
        balance += msg.value;
    }

    function CLAIM_EMPLOYEE() payable public nonReentrant {
        require(mintable || _msgSender() == owner(), "Linkedao: cannot claim employee");
        if (msg.value != 0 ether) {
            signingBonusOffers[msg.sender] += msg.value;
        }
        _mint(_msgSender(), totalSupply());
    }

    function CLAIM_WEED_MONEY_FROM_APPLICANT() public nonReentrant {
        require(jointAvailable, "Linkedao: no free joint available");
        require(balance >= jointExchangeRate, "Linkedao: insufficient weed fund");
        jointAvailable = false;
        balance -= jointExchangeRate;
        payable(msg.sender).transfer(jointExchangeRate);
    }

    function RUG() public nonReentrant onlyOwner {
        uint256 b = balance;
        balance = 0;
        payable(msg.sender).transfer(b);
    }

}
