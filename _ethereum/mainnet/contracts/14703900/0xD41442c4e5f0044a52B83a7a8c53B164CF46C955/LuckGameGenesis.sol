// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";


contract LuckGameGenesis is ERC1155, ERC1155Burnable,  Ownable, ReentrancyGuard {
    string private _name = "Luck Game Genesis";
    string private _symbol = "LG";  
	string private baseURI;
	uint256 public price = 0.02 ether;
    uint256 public discPrice = 0.015 ether;
    uint256 public dailyReward = 0;
    uint256 public weekReward = 0;
    uint256 public megaReward  = 0;
    uint256 public jackpotReward  = 0;
    uint256 public projectReward  = 0;
    uint256 public dayPercentage = 20; 
    uint256 public weekPercentage = 8;
    uint256 public megaPercentage = 5;
    uint256 public jackpotPercentage = 30;    
    uint256 public projectPercentage = 20;
    uint256 public teamPercetage = 17;
    uint256 public _jackpot = 0;
    uint256 public _mega = 1;
    uint256 public _week = 2;
    uint256 public _day = 3;
    uint256 public currentToken = 4;
    uint256 public _totalSupply = 33;
    bool public _saleIsActive = false;
    bool public _freeSaleIsActive = false;    
    address private _teamSafe = address(0);
    address private _projectSafe = address(0);
    bytes32 public _signerroot;
    
    struct winnerData {
        string winnertype;
        uint256 amount;
        address winnerwallet;
    }
    mapping(address => bool) public discountClaimed;
    mapping(uint256 => winnerData) public winners;    
    
    constructor(
        address teamSafe, 
        address ProjectSafe,
        bytes32 Signerroot) 
        ERC1155(""){ 
        _teamSafe =  teamSafe;
        _projectSafe = ProjectSafe;
        _signerroot = Signerroot;
    }
	function Mint(uint256 mintCount) external payable {
	    require(_saleIsActive, "Minting not start");
        require( price * mintCount <= msg.value, "Incorrect Eth");
        mintLG(msg.sender,mintCount);
        calculatePrice(msg.value);
    }
    function calculatePrice(uint256 amount)internal {
        dailyReward = dailyReward + ( ( amount * dayPercentage ) / 100 );
        weekReward = weekReward + ( ( amount * weekPercentage ) / 100 ) ;
        megaReward = megaReward + ( ( amount * megaPercentage ) / 100 ) ;
        jackpotReward = jackpotReward + ( ( amount * jackpotPercentage ) / 100 );
        projectReward = projectReward + ( ( amount * projectPercentage ) / 100 );
    }
    function zeroMint() external  {
	    require((_freeSaleIsActive),"Closed");
        mintLG(msg.sender, 1);
    }
    function mintLG(address receiver, uint256 mintCount) internal{
        _mint(receiver, _day, mintCount, "");
        _mint(receiver, _week, mintCount, "");
        _mint(receiver, _mega, mintCount, "");
        _mint(receiver, _jackpot, mintCount, "");
    }    
    
    function DailyWinner(address winner) external onlyOwner {
        bool sent;
        require(
                 (!_saleIsActive),
                "Minting is Live");        
        uint256 contractBalance = address(this).balance;
        (sent,) = payable(winner).call{value: uint(dailyReward) }("");
        require(sent, "Failed Send");
        (sent,) = payable(_teamSafe).call{value: uint(( contractBalance * teamPercetage ) / 100) }("");
        require(sent, "Failed Send");
        (sent,) = payable(_projectSafe).call{value: uint(( contractBalance * (weekPercentage + megaPercentage + jackpotPercentage + projectPercentage) ) / 100) }("");
        require(sent, "Failed Send");
        winners[currentToken] = winnerData("daily", dailyReward, winner);
        _day  = currentToken;
        dailyReward = 0;
        currentToken = currentToken + 1;
        delete contractBalance;
        delete sent;
    }
    function weeklyWinner(address winner) external onlyOwner {
        require(
                 (!_saleIsActive),
                "Minting is Live"
        );
        winners[currentToken]= winnerData( "weekly", weekReward, winner ) ;
        _week  = currentToken;
        currentToken = currentToken + 1;
        weekReward = 0;
    }
    function megaWinner(address winner) external onlyOwner {
        require(
                 (!_saleIsActive),
                "Minting is Live"
        );
        winners[currentToken] = winnerData( "mega", megaReward, winner ) ;
        megaReward = 0;
    }
    function jackpotWinner(address winner) external onlyOwner {
        require(
                 (!_saleIsActive),
                "Minting is Live"
        );
        winners[currentToken] = winnerData("jackpot", jackpotReward, winner);
        _day = currentToken+3;
        _week = currentToken+2;
        _mega = currentToken+1;
        currentToken = currentToken+4;
        weekReward = megaReward = jackpotReward = 0;
    }
    function setDrawPercentage (uint256 day, uint256 week,
    uint256 mega, uint256 jackpot,uint256 project, uint256 team) external onlyOwner{
        dayPercentage = day;
        weekPercentage = week;
        megaPercentage = mega;
        jackpotPercentage = jackpot;
        projectPercentage = project;
        teamPercetage = team;
    }
    function setMintLive(bool status) external onlyOwner {
		_saleIsActive = status;
	}
    function setURI(string memory newBaseURI) public onlyOwner {
        _setURI(newBaseURI);
    }
    function giveaway(address receiver, uint256 mintCount) external onlyOwner {
        mintLG(receiver, mintCount);
    }
    function withdraw(uint256 amount, address toaddress) external onlyOwner {
      require(amount <= address(this).balance, "Amount > Balance");
      if(amount == 0){
          amount = address(this).balance;
      }
      payable(toaddress).transfer(amount);
    }
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
    function setDiscPrice(uint256 newPrice) external onlyOwner {
        discPrice = newPrice;
    }
    function discountMint(bytes32[] calldata signature, uint256 mintCount) public payable {
        require(!discountClaimed[msg.sender], "Discount already claimed");
        require( discPrice * mintCount <= msg.value, "Incorrect Eth");
        require(isValid(signature, keccak256(abi.encodePacked(msg.sender))), "Not a Allowlist");
        discountClaimed[msg.sender] = true;
        mintLG(msg.sender, mintCount);
        calculatePrice(msg.value);
    }
    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, _signerroot, leaf);
    }   
    function setSignerRoot(bytes32 Signerroot) external onlyOwner{
        _signerroot = Signerroot;
    }    
    function setFreeMint(bool status) external onlyOwner {
		_freeSaleIsActive = status;
	}
}