// SPDX-License-Identifier: MIT

/**
                                  :. .                                                    
                                -==*#%*+=-.                                               
                                +=+#@*++*##%%#+=:.        .:-.                            
                                 .%*%%**+++++++*@@= .+=:  *.+%                            
                                 ++++#%#*******#=#==*+*#%#%%+-                            
                                :*=+++*%%#*#***%#@#*****###%#+...                         
                    .-+=       :#-=+++++*%@%*##-=@#**%#+-+@*++##-                         
                    .=##=     .+-===++++++*#%#--=+@#*-::=*@***+=+#+.                      
          .:+=        -+-++=.-*-====+++++++++*#*+=++----+#%*****+==##-                    
          .-*%         #..:-+*+======+++++++++++====---=+%##*******%@##-                  
            .:*%++====-*=.:::-=======+++++++++++=====--++%@#******#**==##.                
               .*+:--:--: .:::-=======+++++++++++====--++#%###********+=+@*:..            
                 -*::::::...::-=======+++++++++++====+*##%@%%##**###****+=%%=:.           
                  .**@*-:: .:::-======++++++++=++*##%%#**##*%%%%%#*******+=%#             
                    +@@@=::..::-=======+**%@@%###*++++#+#*#*#**%%##*******+=%#            
                  .  +*#@=:.::-=******#@@%#**===%====+++*===+#*#%@%##******++@+           
                  *:.#+=+@#***++====+##*+===++**#*======+===+***#*#@%%###***=#@.          
                  #=**+=-+*=========++===+**+===**======+==+++*+####@##****#**@+          
                  *+=-*##+=============**++*%=-=#*=========+*+*+*##*#@##***#*+:           
                  .%+ *@+##+=========***#@= %:==%+============++=****%%#*****+%#          
                  =**+:@++%#=======+#+- %@*=@.*#+=============++=+*#%#@%#*****@*          
                  *=:+==@@+=*=====**:   #@@@*+*+==========++=====+*##*@#*****%@.          
                  *-:-===+:.=====++:....:*#*++=++++++====*+#===+#++***@#****#@=           
                  +=:-========================+*+###*+=+**##====+++*#%@#***#@-            
                  :#:===========================#@@#**+++*%+====*****%%*#*%%=-            
                   *-=========================*%@@@#++++**+====+%####%#*%@+               
                   -*=====================+*%@@@@@#+==+++=====+*######*#%.                
                  *+=================+*#%@@@@@@@@#+==========++***%####**:                
                  ++=========++**##%@@@@@@@@@@@%*+==========+***#@%%##**+#                
   .::         .:--++-=*#%%%@@@@@@@@@@*=---=#%#++========++***#%%%@%*##**+-               
  =+-      .:+=::-#***:::-+#%@%@@*-:=-:::-+**+=========++***#%%%%+-#****++-               
 =+=     ++==#+:::#**%***###%@=:=*****##**+==========++**#%%%%#=  ******=#                
 :*+    -*+++#====###%***####%+-===================++*#%%%%%+=:   ******+                 
  :+*--=**=  -**+*%%%%%%%%#+::*-=================+*#%@@%*=.     ...=++=:                  
     .::.      .-=++: ..      %:==============++##*+=::  ..==++++++*+++=:.                
                              +=-===========+*%*:=--=.*+++#=++****#****@%+                
                               #:=========+*%*.  #==+#+++******###*****#-                 
                               -*-=======+*%:   .#*****%*****#%#*****#+                   
                                ++-======+%-     -#***#%*#**%%###**#*.                    
                                 ++-=====+%:       :=+**%##%#%%%#*=.                      
                                  =*-====+*%.         :=**@%*=-:                          
                                   .#+=====+#*-:.:-=+*++*=.                               
                                     -#*======+***++=+*#.                                 
                                       :+##*+====++*#*:                                   
                                           :-=====-:     

 * Date: March 17th, 2022
 * 
 * ☘️Happy Saint Patrick's Day!
 *
 * The Aimless Fish Dynasty is dedicated to my ever beautiful Wife, Stephanie, and our three amazing children. Hi Steph! I love you with all my heart.
 * ❤️ LHK FOREVER
 *
 * As I move on from a family business which I personally experienced as toxic to my mental health (ultimately affecting my wife and kids), I want to make all who
 * may see this aware, that Stephanie has helped me climb out of the darkness with her energy, resilience, motivation, and get-it-done attitude.
 * She has shown me strength in all areas of life, and taught me to see beyond the darkness that had surrounded me in my professional life.
 * I am forever grateful to her for this and can't express it enough. I believe everyone needs a Stephanie!
 *
 * Life is mainly about creating yourself. Who are you going to be? How will others think of you? Have you perhaps lost the plot?
 * Surround yourself with inspiring, joyful people, like my Wife, and learn from them. I think this is how you live your best life.
 *
 * Finally, within this contract I have tried to share and be as open as possible with where we are going with the Aimless Fish Dynasty project.
 * I hard coded as much as my current knowledge allowed. Where my knowledge was lacking, I tried to leave fingerprints so you could make sure things occur as they should.
 * I hope you join on me and my family on this exciting new journey!
 * This is just the beginning.
 *
 * Founded, developed, and art by: @kenleybrowne
 * 
 * AFD Dynasty  DAO: 0x4c5260637C9D39919347C961fAb0fE4CEB79bCdf
 * AFD Genesis Fund: 0x23d5041C65151E80E13380f9266EA65FA6E37a8f
 * AFD Charity Fund: 0xE88d4a2c86094197036B3D7B7e22275a3A7C0b28
 * 
 */

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract AimlessFishDynasty is ERC721Enumerable, Ownable {  
    string public AFD_PROVENANCE;    
    using Address for address;

    // This will help the starting and stopping of the sale and presale.
    bool public saleActive = false;
    bool public presaleActive = false;

    // This is the amount of tokens reserved for Free-minting, the team, giveaways, collabs and so forth.
    uint256 public reserved = 225;
    uint256 public tgcReserved = 30;

    // This is the price of each Aimless Fish Dynasty token.
    // Up to 28 Aimless Fish Dynasty tokens or 1% of all tokens may be minted at a time.
    uint256 public price = 0.035 ether;
    uint256 public freePrice = 0.0 ether;    

    // Max Supply limits the maximum supply of Aimless Fish Dynasty tokens that can exist.
    // Free Max Supply allows up to 220 free mints to the community & public.
    uint256 constant max_SUPPLY = 2750;
    uint256 constant freeMAX_SUPPLY = 255; // Up to 220 for Free Mint + 30 Reserved + 5 tokens for the Founder, his wife, and their three little kiddos.

    // This is the base link that leads to the images of the Aimless Fish tokens.
    // This will be transitioned to IPFS after minting is complete. 
    string public baseURI;
 
    // Allows us to set the provenance for the entire collection.
    function setProvenance(string memory provenance) public onlyOwner {
        AFD_PROVENANCE = provenance;
    }

    // This allows for gasless Opensea Listing.
    address public proxyRegistryAddress;  

    // The following are the addresses for withdrawals.
    address public a1_DAO = 0x4c5260637C9D39919347C961fAb0fE4CEB79bCdf; // Aimless Fish Dynasty DAO
    address public a2_OMM = 0x3097617CbA85A26AdC214A1F87B680bE4b275cD0; // OMM&S Consulting and Marketing Team
    address public a3_DTC = 0xE88d4a2c86094197036B3D7B7e22275a3A7C0b28; // The AFD Charity Fund to Be Donated
    address public a4_ADT = 0xf770C9AC6bE46FF9D02e59945Ae54030A8A92d3F; // Founder @kenleybrowne
        // Additionally, the AFD Genesis Fund:0x23d5041C65151E80E13380f9266EA65FA6E37a8f will be set to receive secondary sales royalities on OS & LR.
        // 60% of the Genesis Fund will be forwarded to the DAO, while the final 40% will be used to further the project’s growth and development.

    // This is for reserved presale tokens.
    mapping (address => uint256) public presaleReserved;

    // This makes sure if someone already did a FREE mint, then they can no longer do so. We would love if you purchased one as well :)
    mapping(address => uint256) private _claimed;

    // This allows for gasless Opensea Listing.
    mapping(address => bool) public projectProxy;

    // This allows for gas(less) future collection approval for cross-collection interaction.
    mapping(address => bool) public proxyToApproved;

    // This initializes The Aimless Fish Dynasty contract and designates the name and symbol.
    constructor (string memory _baseURI, address _proxyRegistryAddress) ERC721("Aimless Fish Dynasty", "AFD") {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;

        // Kenley, the founder is gifting his Wife & three young kiddos the first four fish, plus retaining one for his continued access to the Dynasty.
        // These will be held in the his wallet and transfered to them in the future so they may access the Dynasty.
        _safeMint( a4_ADT, 0);
        _safeMint( a4_ADT, 1);
        _safeMint( a4_ADT, 2);
        _safeMint( a4_ADT, 3);
        _safeMint( a4_ADT, 4);
    }

    // To update the tokenURI.
    // All metadata & images will be on IPFS once mint is complete.
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    // 
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    // This helps see which address owns which tokens.
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // This allows for gasless Opensea Listing.
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // This allows for gas(less) future collection approval for cross-collection interaction.
    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    // This is for the exclusive FREE-sale/Reserved presale minting ability.
    function mintPresale(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        uint256 reservedAmt = presaleReserved[msg.sender];
        require( presaleActive,                      "The AFD presale isn't active yet." );
        require( reservedAmt > 0,                    "There are no tokens reserved for your address." );
        require( _amount <= reservedAmt,             "You are not able to mint more than what is reserved to you." );
        require( supply + _amount <= freeMAX_SUPPLY, "You are not able to mint more than the max supply of FREE Aimless Fish." );
        require( msg.value == freePrice * _amount,   "Opps! You sent the wrong amount of ETH." );
        presaleReserved[msg.sender] = reservedAmt - _amount;
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    // This is for the Public minting ability.
    function mintToken(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( saleActive,                     "The AFD public sale isn't active." );
        require( supply + _amount <= max_SUPPLY, "You are not able to mint more than max supply of total Aimless Fish." );
        require( _amount > 0 && _amount < 29,    "You are able to mint between 1-28 AFD tokens at the same time." );
        require( supply + _amount <= max_SUPPLY, "You are not able to mint more than max supply of total Aimless Fish." );
        require( msg.value == price * _amount,   "Opps! You sent the wrong amount of ETH." );
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    // This is for the FREE minting ability during public sale.
    // Important: The fish will no longer be free when the total fish minted, including paid mints, passes 255. Don't try or you risk losing your gas!
    function mintFREEToken(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( saleActive,                         "The AFD public sale isn't active." );
        require( _claimed[msg.sender] == 0,          "Your Free token is already claimed.");
        require( _amount > 0 && _amount < 2,         "You are able to mint one (1) Free AFD token." );
        require( supply + _amount <= freeMAX_SUPPLY, "You are not able to mint more than max supply of FREE Aimless Fish." );
        require( msg.value == freePrice * _amount,   "Opps! You sent the wrong amount of ETH." );
        for(uint256 i; i < _amount; i++){
            _claimed[msg.sender] += 1;
            _safeMint( msg.sender, supply + i );
        }
    }

    // Admin minting function to reserve tokens for the team, collabs, customs and giveaways.
    function mintReserved(uint256 _amount) public onlyOwner {
        // Limited to a publicly set amount as shown above.
        require( _amount <= tgcReserved, "You are not able to reserve more than the set amount." );
        tgcReserved -= _amount;
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    // This lets us add to and edit reserved presale spots.
    function editPresaleReserved(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            presaleReserved[_a[i]] = _amount[i];
        }
    }

    // This allows us to start and stop the AFD presale.
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // This allows us to start and stop the AFD Public sale.
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // This allows us to set a different selling price in case ETH changes drastically.
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Withdraw funds from inital sales for the team, DAO, Charity and founder.
    function withdrawTeam(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;
        require(payable(a1_DAO).send(percent * 33)); // 33% for the community-lead Aimless Fish Dynasty DAO.
        require(payable(a2_OMM).send(percent * 25)); // 25% for the OMM&S Consulting and Marketing Team.
        require(payable(a3_DTC).send(percent * 5));  // 5% to be Distributed to Charities that support Earth and Ocean conservation.
        require(payable(a4_ADT).send(percent * 38)); // 38% to further the project’s growth & development plus initial founders dev & marketing expenses.
    }

    // Allows gasless listing on Opensea and LooksRare.
    // Sumitted during Deployment of contract OS Mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    // NOT CODED (added after contract is deployed) LooksRare Mainnet: 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e
    // Also allows gas(less) future collection approval for cross-collection interaction including LooksRare.
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
/**
*
* Wherever you happen to be in the world, together, greater collective enlightenment is what we must strive for.
* Thank you for joining me and my family on this journey.
* Let's raise each other up.
*
* Cheers,
* Kenley
* 
*/