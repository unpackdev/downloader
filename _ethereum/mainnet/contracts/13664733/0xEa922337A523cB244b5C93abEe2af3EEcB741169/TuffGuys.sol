// SPDX-License-Identifier: None


pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./String.sol";

contract TuffGuys is Ownable, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;
    
    address public TuffGuy1 = 0x09E1f1f5672dcF434d0Ce872050E4C2EdBE47e76; //tox
    address public TuffGuy2 = 0x56f6DaF0F8696F9952d471D6c447E497A39E805E; //nicks
    address public TuffGuy3 = 0xCB31144f983859968E242844C4ed3dDB565589c2; //BV: ZAV Invest - Eindhoven, The Netherlands
    address public TuffGuy4 = 0x89EF51E9cA619952EB364Ec6f4111009EF66F75E; //nathan
    address public TuffGuy5 = 0xf5D71a9d75AbCAB2fC79Cf7306Fbc38e33ED6f2D; //Carter
    address public TuffGuy6 = 0x39fF53cEAA56f6761bB938500a1449Eee67d9399; //iSynx
    address public TuffGuy7 = 0x1653fA06DE581f59270ED861cedCd46Ef94d01aa; //Griffin
    address public TuffGuy9 = 0x414f9e2F943DFB3A6B97d7828134FfD9608F553D; //Samed
    address public TuffGuy10 = 0x6479a51298Be79645e936405Fb9a783Ddbf13Ce3; //Community
    
    uint256 public fusionSupply = 0;
    uint256 public _fusionID = 10000;
    
    uint256 public CurrentTuffGuys = 0;
    uint256 public CurrentGiveawayTuffGuys = 0;
    uint256 public GiveawayTuffGuyAmount = 30;
    uint256 public price = 0.08 ether;
    uint256 public TuffGuyAmount;
    uint256 public PreSaleTuffGuyAmount;

    uint256 public Maximum_Allowed_Mint = 10;
    uint256 public Presale_Maximum_Allowed_Mint = 5;
    
    string public baseURI = "";
    
    bool public MainSaleActive = false;
    bool public PreSaleActive = false;
    bool public PreSaleWhitelistActive = true;
    bool public fusionEnabled = false;

    address[] public TuffGuysPresale;

    constructor(
        uint256 TotalTuffGuys,
        uint256 PresaleTuffGuys,
        string memory _baseURI
    ) ERC721("Tuff Guys", "TG") {
        TuffGuyAmount = TotalTuffGuys;
        PreSaleTuffGuyAmount = PresaleTuffGuys;
        baseURI = _baseURI;
    }
    
    function tokenURI(uint256 TuffGuyID) public view override returns (string memory) {
        require(_exists(TuffGuyID), "nonexistent token");
        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, TuffGuyID.toString())) : "";
    }
    
    function toggle_sales(uint256 num) external onlyOwner {
        if (num == 0) {
            PreSaleActive = !PreSaleActive;
        } else if (num == 1) {
            MainSaleActive = !MainSaleActive;
        } else if (num == 2) {
            PreSaleWhitelistActive = !PreSaleWhitelistActive;
        } else if (num == 3) {
            fusionEnabled = !fusionEnabled;
        }
    }
    
    function populate_PreSaleWhitelist(address[] calldata addresses) external onlyOwner {
        delete TuffGuysPresale;
        TuffGuysPresale = addresses;
  	    return;
  	}
    
    function write_TuffGuyAmount(uint256 _TuffGuyAmount, uint256 num) external onlyOwner {
        if (num == 0) {
            require(_TuffGuyAmount >= CurrentTuffGuys, "Error changing Tuff Guy Amount");
            TuffGuyAmount = _TuffGuyAmount;
        } else {
            require(_TuffGuyAmount >= PreSaleTuffGuyAmount, "Error changed Pre Sale Tuff Guy Amount");
            PreSaleTuffGuyAmount = _TuffGuyAmount;
        }
    }
    
    function write_URI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }



    function withdraw_first() external onlyOwner {
        require(address(this).balance > 0, "Not enough eth");

        (bool initialES,) = TuffGuy7.call{value: 36 ether}(""); //

        require(initialES, "Woah! Not enough ETH in the contract");
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "None");
        uint256 walletBalance = address(this).balance;
        (bool withdraw1,) = TuffGuy1.call{value: walletBalance.mul(1734).div(10000)}(""); // 17.33 Tox
        (bool withdraw2,) = TuffGuy2.call{value: walletBalance.mul(1734).div(10000)}(""); //17.33 Nicks
        (bool withdraw3,) = TuffGuy3.call{value: walletBalance.mul(1734).div(10000)}(""); //17.33 Zav 
        (bool withdraw4,) = TuffGuy4.call{value: walletBalance.mul(11).div(100)}(""); //11
        (bool withdraw5,) = TuffGuy5.call{value: walletBalance.mul(15).div(1000)}(""); //1.5
        (bool withdraw6,) = TuffGuy6.call{value: walletBalance.mul(3).div(100)}(""); //3
        (bool withdraw7,) = TuffGuy7.call{value: walletBalance.mul(175).div(1000)}(""); //17.5
        (bool withdraw9,) = TuffGuy9.call{value: walletBalance.mul(5).div(100)}(""); //5
        (bool withdraw10,) = TuffGuy10.call{value: walletBalance.mul(10).div(100)}(""); //10
        require(withdraw1 && withdraw2 && withdraw3 && withdraw4 && withdraw5 && withdraw6 && withdraw7 && withdraw9 && withdraw10, "Withdrawal Unsuccesfull");
    }
    
    function emergencyWithdraw() external onlyOwner {
        (bool withES,) = TuffGuy7.call{value: address(this).balance}("");
        require(withES, "Not enough ethereum to withdraw");
    }


    
    function purchase_mainSale(uint TuffGuyNFT) external payable {
        require(MainSaleActive, "Slow Down! Main Sale isn't available just yet.");
        require(TuffGuyNFT <= Maximum_Allowed_Mint, "Woah! Leave some TuffGuys for the rest of us");
        require(msg.value >= price.mul(TuffGuyNFT), "Oops! Looks like we didn't receive the require funds");
        require(CurrentTuffGuys.add(TuffGuyNFT) <= TuffGuyAmount, "Not enough Tuff Guys left :(");

        uint256 TuffGuyID = CurrentTuffGuys;
        for(uint i = 0; i < TuffGuyNFT; i++) {
            TuffGuyID += 1;
            CurrentTuffGuys = CurrentTuffGuys.add(1);
            _safeMint(msg.sender, TuffGuyID);
        }

        return;
    }
    
    function purchase_preSale(uint TuffGuyNFT) external payable {
        require(PreSaleActive, "Slow Down! Pre Sale isn't available just yet.");
        require(TuffGuyNFT <= Presale_Maximum_Allowed_Mint, "Woah! Leave some TuffGuys for the rest of us");
        require(msg.value >= price.mul(TuffGuyNFT), "Oops! Looks like we didn't receive the require funds");
        require(CurrentTuffGuys.add(TuffGuyNFT) <= PreSaleTuffGuyAmount, "Not enough Tuff Guys left for presale :(");
        
        if (!PreSaleWhitelistActive) {
            uint256 TuffGuyID = CurrentTuffGuys;
            for(uint i = 0; i < TuffGuyNFT; i++) {
                TuffGuyID += 1;
                CurrentTuffGuys = CurrentTuffGuys.add(1);
                _safeMint(msg.sender, TuffGuyID);
            }
        } else {
            require(allowThrough(msg.sender), "Not in Presale");
            uint256 TuffGuyID = CurrentTuffGuys;
            for(uint i = 0; i < TuffGuyNFT; i++) {
                TuffGuyID += 1;
                CurrentTuffGuys = CurrentTuffGuys.add(1);
                _safeMint(msg.sender, TuffGuyID);
            }
        }

    }
    
    function mint_giveaway(uint TuffGuyNFT) external onlyOwner  {
        require(CurrentTuffGuys.add(TuffGuyNFT) <= TuffGuyAmount, "Not enough Tuff Guys left :(");
        require(CurrentGiveawayTuffGuys.add(TuffGuyNFT) <= GiveawayTuffGuyAmount, "Not enough Tuff Guys left to mint for giveaways and community events :(");

        uint256 TuffGuyID = CurrentTuffGuys;
        for(uint i = 0; i < TuffGuyNFT; i++) {
            TuffGuyID += 1;
            CurrentTuffGuys = CurrentTuffGuys.add(1);
            CurrentGiveawayTuffGuys = CurrentGiveawayTuffGuys.add(1);
            _safeMint(msg.sender, TuffGuyID);
        }
    }
    
  	function allowThrough(address __address) public view returns (bool) {
        for(uint256 i = 0; i < TuffGuysPresale.length; i++) {
            if (TuffGuysPresale[i] == __address) {
                return true;
            }
        }
        return false;
    }
    
    
    function fusion(uint256[] memory _tg) public meetsOwnership(_tg) {
        require(fusionSupply > 0, "No Fusion Left");
        require(fusionEnabled, "Fusions not enabled");
        require(_tg.length >= 2, "Woah. Provide me some more Tuff Guys");
      
        for (uint256 i = 0; i < _tg.length; i++) {
          _burn(_tg[i]);
        }
        
        uint256 token_id = _fusionID;

        token_id += 1;
        _fusionID = _fusionID.add(1);
        _safeMint(msg.sender, token_id);

        fusionSupply -= 1;
    }
         
    function setFuseID(uint256 fuseID) public onlyOwner {
        _fusionID = fuseID;
    }

    function setfusionSupply(uint256 newfusionSupply) public onlyOwner {
        fusionSupply = newfusionSupply;
    }
    
    modifier meetsOwnership(uint256[] memory _tg) {
        for (uint256 i = 0; i < _tg.length; i++) {
          require(this.ownerOf(_tg[i]) == msg.sender, "Tuff Guys not owned");
        }
        _;
    }
    
}